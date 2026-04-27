import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/adapter_registry.dart';
import 'package:tankstellen/features/consumption/data/obd2/bluetooth_facade.dart';
import 'package:tankstellen/features/consumption/data/obd2/elm_byte_channel.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_connection_service.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_permissions.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_service.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/obd2_adapter_picker.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

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
          _scanHit(name: 'vLinker FD', rssi: -55),
          _scanHit(name: 'OBDLink MX+', rssi: -40),
        ],
      ]);
      await _pump(tester, svc);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byKey(const Key('obdPickerSelecting')), findsOneWidget);
      // OBDLink is stronger → ranks first by RSSI.
      expect(find.text('OBDLink MX+'), findsOneWidget);
      expect(find.text('vLinker FD'), findsOneWidget);
    });

    testWidgets('tapping a candidate transitions to connecting state',
        (tester) async {
      final svc = _buildService([
        [_scanHit(name: 'vLinker FD', rssi: -55)],
      ]);
      await _pump(tester, svc);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('vLinker FD'));
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

  // #1188 — pinned-MAC fast path. `showObd2AdapterPicker` accepts a
  // [pinnedMac] for the active vehicle's adapter. When set, it tries
  // a silent direct connect via [Obd2ConnectionService.connectByMac]
  // and only falls back to the modal sheet when that fails.
  group('showObd2AdapterPicker pinned-MAC fast path (#1188)', () {
    testWidgets('pinnedMac=null shows the sheet (regression check)',
        (tester) async {
      final svc = _RecordingFakeConnection.success();
      final completer = Completer<Obd2Service?>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [obd2ConnectionProvider.overrideWith((_) => svc)],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () {
                    completer.complete(showObd2AdapterPicker(ctx));
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pump();
      // Sheet rendered → its title is on screen.
      expect(find.text('Pick an OBD2 adapter'), findsOneWidget);
      expect(svc.connectByMacCalls, isEmpty);
      // Tear down the open future cleanly.
      Navigator.of(tester.element(find.text('Pick an OBD2 adapter')))
          .pop();
      await tester.pumpAndSettle();
      await completer.future;
    });

    testWidgets(
        'pinnedMac with successful connect resolves silently (no sheet)',
        (tester) async {
      final fakeService = _NoopObd2Service();
      final svc = _RecordingFakeConnection(
        connectByMacResult: fakeService,
      );
      final completer = Completer<Obd2Service?>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [obd2ConnectionProvider.overrideWith((_) => svc)],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () {
                    completer.complete(showObd2AdapterPicker(
                      ctx,
                      pinnedMac: 'AA:BB:CC:DD:EE:FF',
                      pinnedAdapterName: 'vLinker FS',
                    ));
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(svc.connectByMacCalls, ['AA:BB:CC:DD:EE:FF']);
      // No sheet rendered.
      expect(find.text('Pick an OBD2 adapter'), findsNothing);
      // Future resolved with the service.
      final resolved = await completer.future;
      expect(resolved, same(fakeService));
    });

    testWidgets(
        'pinnedMac with failed connect (returns null) opens sheet + snackbar',
        (tester) async {
      final svc = _RecordingFakeConnection(
        connectByMacResult: null, // simulate timeout / out-of-range
      );
      final completer = Completer<Obd2Service?>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [obd2ConnectionProvider.overrideWith((_) => svc)],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () {
                    completer.complete(showObd2AdapterPicker(
                      ctx,
                      pinnedMac: 'AA:BB:CC:DD:EE:FF',
                      pinnedAdapterName: 'vLinker FS',
                    ));
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(svc.connectByMacCalls, ['AA:BB:CC:DD:EE:FF']);
      // Sheet IS rendered now (fallback) — its title shows.
      expect(find.text('Pick an OBD2 adapter'), findsOneWidget);
      // Snackbar with the pinned name carries the localized message.
      expect(
        find.textContaining("Couldn't reach 'vLinker FS'"),
        findsOneWidget,
      );

      // Drain the picker — the underlying scan stream is empty so it
      // sits in `scanning`. Pop the sheet to resolve the future.
      Navigator.of(tester.element(find.text('Pick an OBD2 adapter')))
          .pop();
      await tester.pumpAndSettle();
      await completer.future;
    });
  });
}

/// Recording fake for [Obd2ConnectionService] that lets the pinned-MAC
/// tests drive `connectByMac` without spinning up a real BLE stack.
/// Sheet-fallback paths still need a working `scan` because the
/// underlying [Obd2AdapterPickerSheet] subscribes to it on init —
/// returning an empty stream sits the sheet in its scanning state
/// indefinitely, which is exactly what the tests need to assert
/// "the sheet IS rendered" without chasing further state transitions.
class _RecordingFakeConnection extends Obd2ConnectionService {
  _RecordingFakeConnection({this.connectByMacResult})
      : super(
          registry: Obd2AdapterRegistry.defaults(),
          permissions: _FakePermissions(Obd2PermissionState.granted),
          bluetooth: _StreamingFacade(const []),
        );
  factory _RecordingFakeConnection.success() =>
      _RecordingFakeConnection(connectByMacResult: _NoopObd2Service());

  final Obd2Service? connectByMacResult;
  final List<String> connectByMacCalls = [];

  @override
  Future<Obd2Service?> connectByMac(
    String mac, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    connectByMacCalls.add(mac);
    return connectByMacResult;
  }

  @override
  Stream<List<ResolvedObd2Candidate>> scan({
    Duration timeout = const Duration(seconds: 8),
  }) async* {
    // Empty stream — the picker sheet sits in its scanning state.
  }
}

/// Minimal [Obd2Service] stand-in. The pinned-MAC tests only need
/// identity comparison (`same(fakeService)`); no transport calls fire.
class _NoopObd2Service implements Obd2Service {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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
