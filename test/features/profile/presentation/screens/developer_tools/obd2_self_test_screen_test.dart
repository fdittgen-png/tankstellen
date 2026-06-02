// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/adapter_registry.dart';
import 'package:tankstellen/features/consumption/data/obd2/bluetooth_facade.dart';
import 'package:tankstellen/features/consumption/data/obd2/elm_byte_channel.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_comm_diagnostics.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_connection_service.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_permissions.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_service.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_transport.dart';
import 'package:tankstellen/features/consumption/providers/trip_recording_provider.dart';
import 'package:tankstellen/features/feature_management/application/feature_flags_provider.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';
import 'package:tankstellen/features/profile/presentation/screens/developer_tools/obd2_health_screen.dart';

import '../../../../../helpers/pump_app.dart';

const _happyPathResponses = {
  'ATZ': 'ELM327 v1.5>',
  'ATE0': 'OK>',
  'ATL0': 'OK>',
  'ATH0': 'OK>',
  'ATSP0': 'OK>',
  'ATI': 'ELM327 v1.5>',
  'AT@1': 'OBDII to RS232 Interpreter>',
  'ATRV': '12.4V>',
  '0100': '41 00 BE 3F A8 13>',
  '010C': '41 0C 1A F8>',
  '010D': '41 0D 50>',
  '0105': '41 05 5A>',
};

/// Widget coverage for the #2645 adapter self-test panel on the OBD2
/// communication-health screen. No real BLE — the connection provider is
/// overridden with a fake that returns a scripted [Obd2Service].
void main() {
  final collector = Obd2CommDiagnostics.instance;
  setUp(() => collector
    ..reset()
    ..enabled = false);
  tearDown(() => collector
    ..reset()
    ..enabled = false);

  List<Object> overrides({TripRecordingState? recording}) => [
        enabledFeaturesProvider.overrideWithValue({Feature.debugMode}),
        obd2ConnectionProvider.overrideWith((_) => _FakeConnection()),
        if (recording != null)
          tripRecordingProvider.overrideWithValue(recording),
      ];

  testWidgets('shows the Run adapter test button under Developer mode',
      (tester) async {
    await pumpApp(tester, const Obd2HealthScreen(), overrides: overrides());
    expect(find.byKey(const ValueKey('obd2-self-test-run')), findsOneWidget);
  });

  testWidgets('tapping Run drives the live step list + pass banner',
      (tester) async {
    await pumpApp(tester, const Obd2HealthScreen(), overrides: overrides());

    await tester.tap(find.byKey(const ValueKey('obd2-self-test-run')));
    await tester.pumpAndSettle();

    // Every step row rendered.
    expect(
      find.byKey(const ValueKey('obd2-self-test-step-scan')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('obd2-self-test-step-disconnect')),
      findsOneWidget,
    );
    // The pass/fail summary banner appeared.
    expect(
      find.byKey(const ValueKey('obd2-self-test-summary')),
      findsOneWidget,
    );
    expect(find.text('Adapter test passed'), findsOneWidget);
  });

  testWidgets('passed-step rows show an accessible-labelled check icon',
      (tester) async {
    await pumpApp(tester, const Obd2HealthScreen(), overrides: overrides());

    await tester.tap(find.byKey(const ValueKey('obd2-self-test-run')));
    await tester.pumpAndSettle();

    // Passed steps render a check-circle icon carrying the "OK" a11y label.
    final okIcons = find.byWidgetPredicate(
      (w) => w is Icon &&
          w.icon == Icons.check_circle &&
          w.semanticLabel == 'OK',
    );
    expect(okIcons, findsWidgets);
  });

  testWidgets('the run button is disabled while a recording is active',
      (tester) async {
    await pumpApp(
      tester,
      const Obd2HealthScreen(),
      overrides: overrides(
        recording: const TripRecordingState(
          phase: TripRecordingPhase.recording,
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('obd2-self-test-run')));
    await tester.pumpAndSettle();

    // The blocked notice surfaces; no run started.
    expect(
      find.text('Stop the active recording before running the adapter test.'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('obd2-self-test-summary')), findsNothing);
  });
}

class _FakeConnection extends Obd2ConnectionService {
  _FakeConnection()
      : super(
          registry: Obd2AdapterRegistry.defaults(),
          permissions: _GrantedPermissions(),
          bluetooth: _UnusedBluetoothFacade(),
        );

  Future<Obd2Service?> _open() async {
    final service = Obd2Service(FakeObd2Transport(Map.of(_happyPathResponses)))
      ..adapterMac = 'AA:BB:CC:DD:EE:FF'
      ..linkKind = 'ble';
    await service.connect();
    return service;
  }

  @override
  Future<Obd2Service?> connectBest() => _open();

  @override
  Future<Obd2Service?> connectByMacDirect(
    String mac, {
    Duration timeout = const Duration(seconds: 4),
    bool fallbackToScan = true,
  }) =>
      _open();
}

class _GrantedPermissions implements Obd2Permissions {
  @override
  Future<Obd2PermissionState> current() async => Obd2PermissionState.granted;
  @override
  Future<Obd2PermissionState> request() async => Obd2PermissionState.granted;
  @override
  Future<bool> requestNotifications() async => true;
}

class _UnusedBluetoothFacade implements BluetoothFacade {
  @override
  Stream<List<Obd2AdapterCandidate>> scan({
    required Set<String> serviceUuids,
    Duration timeout = const Duration(seconds: 8),
  }) async* {}
  @override
  Future<void> stopScan() async {}
  @override
  ElmByteChannel channelFor(String deviceId, Obd2AdapterProfile profile) =>
      throw UnimplementedError();
  @override
  ElmByteChannel channelForDirect(
    String mac, {
    Duration connectTimeout = const Duration(seconds: 4),
    bool autoConnect = false,
  }) =>
      throw UnimplementedError();
}
