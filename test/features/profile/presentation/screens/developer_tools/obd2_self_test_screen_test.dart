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
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';

import '../../../../../helpers/pump_app.dart';

const _pairedMac = 'AA:BB:CC:DD:EE:FF';
const _pairedName = 'vLinker FS';

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

  List<Object> overrides({
    TripRecordingState? recording,
    _FakeConnection? connection,
    bool withPairedAdapter = false,
  }) =>
      [
        enabledFeaturesProvider.overrideWithValue({Feature.debugMode}),
        obd2ConnectionProvider
            .overrideWith((_) => connection ?? _FakeConnection()),
        if (recording != null)
          tripRecordingProvider.overrideWithValue(recording),
        vehicleProfileListProvider.overrideWith(
          withPairedAdapter ? _PairedVehicleList.new : _NoVehicles.new,
        ),
        activeVehicleProfileProvider.overrideWith(
          withPairedAdapter ? _PairedActiveVehicle.new : _NoActiveVehicle.new,
        ),
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

  // --- #2938: adapter choice + connect-by-MAC --------------------------

  testWidgets(
      'with a paired adapter, the choice defaults to it and the run connects '
      'BY MAC (no blind scan)', (tester) async {
    final conn = _FakeConnection();
    await pumpApp(
      tester,
      const Obd2HealthScreen(),
      overrides: overrides(connection: conn, withPairedAdapter: true),
    );

    // The adapter choice is shown, defaulting to the active vehicle's adapter,
    // with its inferred transport tag (#2969 — "vLinker FS" → Classic SPP).
    expect(
      find.byKey(const ValueKey('obd2-self-test-adapter-choice')),
      findsOneWidget,
    );
    expect(find.textContaining(_pairedName), findsWidgets);
    expect(find.textContaining('Classic (SPP)'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('obd2-self-test-run')));
    await tester.pumpAndSettle();

    // #2969 — "vLinker FS" name-matches the Classic profile, so the run took
    // the RFCOMM path (connectByMacClassicDirect), NOT the BLE direct path and
    // NOT the blind scan.
    expect(conn.connectBestCalls, 0);
    expect(conn.macsConnected, isEmpty);
    expect(conn.classicMacsConnected, contains(_pairedMac));
    // The first step is relabelled "Connect to <adapter>", not "Scan…".
    expect(find.text('Connect to $_pairedName'), findsOneWidget);
    expect(find.text('Scan for adapter'), findsNothing);
    expect(find.text('Adapter test passed'), findsOneWidget);
  });

  testWidgets(
      'with no paired adapter, the choice is hidden and the run blind-scans '
      '(back-compat)', (tester) async {
    final conn = _FakeConnection();
    await pumpApp(
      tester,
      const Obd2HealthScreen(),
      overrides: overrides(connection: conn),
    );

    // No paired adapter → no choice control.
    expect(
      find.byKey(const ValueKey('obd2-self-test-adapter-choice')),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey('obd2-self-test-run')));
    await tester.pumpAndSettle();

    // The legacy blind scan (connectBest) ran — no MAC was pinned.
    expect(conn.connectBestCalls, 1);
    expect(find.text('Adapter test passed'), findsOneWidget);
  });
}

class _FakeConnection extends Obd2ConnectionService {
  _FakeConnection()
      : super(
          registry: Obd2AdapterRegistry.defaults(),
          permissions: _GrantedPermissions(),
          bluetooth: _UnusedBluetoothFacade(),
        );

  /// How many times the blind-scan path (connectBest) was taken.
  int connectBestCalls = 0;

  /// The MACs passed to the BLE no-scan connect-by-MAC path, in call order.
  final List<String> macsConnected = [];

  /// The MACs passed to the Classic RFCOMM connect-by-MAC path (#2969). The
  /// `vLinker FS` paired profile name-matches the Classic profile, so the
  /// transport-aware self-test takes THIS path, not the BLE one.
  final List<String> classicMacsConnected = [];

  Future<Obd2Service?> _open(String linkKind) async {
    final service = Obd2Service(FakeObd2Transport(Map.of(_happyPathResponses)))
      ..adapterMac = _pairedMac
      ..linkKind = linkKind;
    await service.connect();
    return service;
  }

  @override
  Future<Obd2Service?> connectBest() {
    connectBestCalls++;
    return _open('ble');
  }

  @override
  Future<Obd2Service?> connectByMacDirect(
    String mac, {
    Duration? timeout,
    bool fallbackToScan = true,
    String? adapterName,
  }) {
    macsConnected.add(mac);
    return _open('ble');
  }

  @override
  Future<Obd2Service?> connectByMacClassicDirect(String mac,
      {String? adapterName}) {
    classicMacsConnected.add(mac);
    return _open('classic');
  }
}

/// No stored vehicle profiles — the panel hides the adapter choice.
class _NoVehicles extends VehicleProfileList {
  @override
  List<VehicleProfile> build() => const [];
}

class _NoActiveVehicle extends ActiveVehicleProfile {
  @override
  VehicleProfile? build() => null;
}

/// One vehicle with a paired adapter — the panel shows + defaults to it.
const _pairedProfile = VehicleProfile(
  id: 'car-1',
  name: 'Daily Driver',
  type: VehicleType.combustion,
  obd2AdapterMac: _pairedMac,
  obd2AdapterName: _pairedName,
);

class _PairedVehicleList extends VehicleProfileList {
  @override
  List<VehicleProfile> build() => const [_pairedProfile];
}

class _PairedActiveVehicle extends ActiveVehicleProfile {
  @override
  VehicleProfile? build() => _pairedProfile;
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
