import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/adapter_registry.dart';
import 'package:tankstellen/features/consumption/data/obd2/bluetooth_facade.dart';
import 'package:tankstellen/features/consumption/data/obd2/elm_byte_channel.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_connection_service.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_permissions.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/obd2_adapter_picker.dart';

void main() {
  group('Obd2AdapterPickerSheet (#743)', () {
    testWidgets('shows the scanning state on open', (tester) async {
      final svc = _buildService(const [[]]);
      await _pump(tester, svc);
      expect(find.byKey(const Key('obdPickerScanning')), findsOneWidget);
    });

    testWidgets('renders the ranked candidates once scan emits',
        (tester) async {
      final svc = _buildService([
        [
          _scanHit(name: 'vLinker FS', rssi: -55),
          _scanHit(name: 'OBDLink MX+', rssi: -40),
        ],
      ]);
      await _pump(tester, svc);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byKey(const Key('obdPickerSelecting')), findsOneWidget);
      // OBDLink is stronger → ranks first by RSSI.
      expect(find.text('OBDLink MX+'), findsOneWidget);
      expect(find.text('vLinker FS'), findsOneWidget);
    });

    testWidgets('tapping a candidate transitions to connecting state',
        (tester) async {
      final svc = _buildService([
        [_scanHit(name: 'vLinker FS', rssi: -55)],
      ]);
      await _pump(tester, svc);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('vLinker FS'));
      await tester.pump(); // state flip only — don't settle, the silent
      // channel intentionally leaves a pending 5 s timeout that
      // eventually surfaces as Obd2AdapterUnresponsive; we're only
      // asserting the optimistic "connecting" state got rendered.
      expect(find.byKey(const Key('obdPickerConnecting')), findsOneWidget);
      // Drain the transport's 5s timeout so the test harness exits cleanly.
      await tester.pump(const Duration(seconds: 6));
      await tester.pump();
    });

    testWidgets('shows the retry button + error message on permission denied',
        (tester) async {
      final svc = Obd2ConnectionService(
        registry: Obd2AdapterRegistry.defaults(),
        permissions: _FakePermissions(Obd2PermissionState.denied),
        bluetooth: _StreamingFacade(const []),
      );
      await _pump(tester, svc);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('obdPickerError')), findsOneWidget);
      expect(find.byKey(const Key('obdPickerRetry')), findsOneWidget);
      expect(find.textContaining('permission', findRichText: false),
          findsOneWidget);
    });
  });
}

// --- helpers ---------------------------------------------------------

Future<void> _pump(
  WidgetTester tester,
  Obd2ConnectionService svc,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [obd2ConnectionProvider.overrideWith((_) => svc)],
      child: const MaterialApp(
        home: Scaffold(body: Obd2AdapterPickerSheet()),
      ),
    ),
  );
}

Obd2ConnectionService _buildService(
    List<List<Obd2AdapterCandidate>> batches) {
  return Obd2ConnectionService(
    registry: Obd2AdapterRegistry.defaults(),
    permissions: _FakePermissions(Obd2PermissionState.granted),
    bluetooth: _StreamingFacade(batches),
  );
}

Obd2AdapterCandidate _scanHit({required String name, int rssi = -60}) =>
    Obd2AdapterCandidate(
      deviceId: 'id-$name',
      deviceName: name,
      advertisedServiceUuids: const [],
      rssi: rssi,
    );

class _FakePermissions implements Obd2Permissions {
  final Obd2PermissionState state;
  _FakePermissions(this.state);
  @override
  Future<Obd2PermissionState> current() async => state;
  @override
  Future<Obd2PermissionState> request() async => state;
}

class _StreamingFacade implements BluetoothFacade {
  final List<List<Obd2AdapterCandidate>> batches;
  _StreamingFacade(this.batches);

  @override
  Stream<List<Obd2AdapterCandidate>> scan({
    required Set<String> serviceUuids,
    Duration timeout = const Duration(seconds: 8),
  }) async* {
    for (final batch in batches) {
      yield batch;
    }
  }

  @override
  Future<void> stopScan() async {}

  @override
  ElmByteChannel channelFor(
    String deviceId,
    Obd2AdapterProfile profile,
  ) =>
      _SilentChannel();
}

/// Silent channel — never answers, so the transport's init sequence
/// eventually times out. Used only by the "connecting" test; it's
/// there to prove the transition fires, not to complete the connect.
class _SilentChannel implements ElmByteChannel {
  final StreamController<List<int>> _ctrl = StreamController.broadcast();
  bool _open = false;
  @override
  bool get isOpen => _open;
  @override
  Stream<List<int>> get incoming => _ctrl.stream;
  @override
  Future<void> open() async {
    _open = true;
  }

  @override
  Future<void> write(List<int> bytes) async {}
  @override
  Future<void> close() async {
    _open = false;
    await _ctrl.close();
  }
}
