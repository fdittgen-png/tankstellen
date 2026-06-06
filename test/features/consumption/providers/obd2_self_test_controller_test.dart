// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/adapter_registry.dart';
import 'package:tankstellen/features/consumption/data/obd2/bluetooth_facade.dart';
import 'package:tankstellen/features/consumption/data/obd2/elm_byte_channel.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_comm_diagnostics.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_connect_trace.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_connection_service.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_permissions.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_self_test_driver.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_service.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_transport.dart';
import 'package:tankstellen/features/consumption/providers/obd2_self_test_controller.dart';
import 'package:tankstellen/features/consumption/providers/trip_recording_provider.dart';

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

ProviderContainer _container({TripRecordingState? recording}) {
  final conn = _FakeConnection();
  return ProviderContainer(
    overrides: [
      obd2ConnectionProvider.overrideWith((_) => conn),
      if (recording != null) tripRecordingProvider.overrideWithValue(recording),
    ],
  );
}

void main() {
  setUp(Obd2CommDiagnostics.instance.reset);
  tearDown(() {
    Obd2CommDiagnostics.instance.enabled = false;
    Obd2CommDiagnostics.instance.reset();
  });

  group('Obd2SelfTestController (#2645)', () {
    test('run() transitions idle → done with a pass summary + per-step list',
        () async {
      final container = _container();
      addTearDown(container.dispose);

      expect(
        container.read(obd2SelfTestControllerProvider).phase,
        Obd2SelfTestPhase.idle,
      );

      await container.read(obd2SelfTestControllerProvider.notifier).run();

      final state = container.read(obd2SelfTestControllerProvider);
      expect(state.phase, Obd2SelfTestPhase.done);
      expect(state.passed, isTrue);
      expect(state.steps, hasLength(Obd2SelfTestStepId.values.length));
      expect(state.passCount, Obd2SelfTestStepId.values.length);
      expect(state.failCount, 0);
      expect(state.elapsedMs, isNotNull);
      // The driver persisted the self-test trace into the collector ring.
      expect(Obd2CommDiagnostics.instance.finishedSessions, isNotEmpty);
    });

    test('run() pushes live per-step progress before completing', () async {
      final container = _container();
      addTearDown(container.dispose);

      final phases = <Obd2SelfTestPhase>[];
      container.listen(
        obd2SelfTestControllerProvider,
        (_, next) => phases.add(next.phase),
        fireImmediately: true,
      );

      await container.read(obd2SelfTestControllerProvider.notifier).run();

      // Saw idle → running → done in order.
      expect(phases.first, Obd2SelfTestPhase.idle);
      expect(phases, contains(Obd2SelfTestPhase.running));
      expect(phases.last, Obd2SelfTestPhase.done);
    });

    test('a second run() while running is rejected (reentrancy guard)',
        () async {
      final container = _container();
      addTearDown(container.dispose);
      final notifier = container.read(obd2SelfTestControllerProvider.notifier);

      // Start a run but do not await it; immediately attempt a second.
      final first = notifier.run();
      await notifier.run(); // returns immediately — phase is running
      // The first run's state machine is still the live one.
      await first;
      expect(
        container.read(obd2SelfTestControllerProvider).phase,
        Obd2SelfTestPhase.done,
      );
    });

    test('run() refuses while a trip recording is active', () async {
      final container = _container(
        recording: const TripRecordingState(phase: TripRecordingPhase.recording),
      );
      addTearDown(container.dispose);

      await container.read(obd2SelfTestControllerProvider.notifier).run();

      expect(
        container.read(obd2SelfTestControllerProvider).phase,
        Obd2SelfTestPhase.blockedByRecording,
      );
      // No session was opened.
      expect(Obd2CommDiagnostics.instance.finishedSessions, isEmpty);
    });

    test('run() restores collector.enabled to its prior value', () async {
      Obd2CommDiagnostics.instance.enabled = false;
      final container = _container();
      addTearDown(container.dispose);

      await container.read(obd2SelfTestControllerProvider.notifier).run();

      expect(Obd2CommDiagnostics.instance.enabled, isFalse);
    });

    test('run(targetMac:) connects BY MAC and never blind-scans (#2938)',
        () async {
      final conn = _FakeConnection();
      final container = ProviderContainer(
        overrides: [obd2ConnectionProvider.overrideWith((_) => conn)],
      );
      addTearDown(container.dispose);

      await container
          .read(obd2SelfTestControllerProvider.notifier)
          .run(targetMac: 'AA:BB:CC:DD:EE:FF');

      // The initial connect went through connectByMacDirect with the chosen
      // MAC, and the blind scan (connectBest) was never used.
      expect(conn.connectBestCalls, 0);
      expect(conn.macsConnected.first, 'AA:BB:CC:DD:EE:FF');
      expect(container.read(obd2SelfTestControllerProvider).passed, isTrue);
    });

    test('run() with no targetMac still blind-scans (back-compat #2938)',
        () async {
      final conn = _FakeConnection();
      final container = ProviderContainer(
        overrides: [obd2ConnectionProvider.overrideWith((_) => conn)],
      );
      addTearDown(container.dispose);

      await container.read(obd2SelfTestControllerProvider.notifier).run();

      expect(conn.connectBestCalls, 1);
    });

    test('run(targetMac:) with an empty MAC blind-scans (treated as none)',
        () async {
      final conn = _FakeConnection();
      final container = ProviderContainer(
        overrides: [obd2ConnectionProvider.overrideWith((_) => conn)],
      );
      addTearDown(container.dispose);

      await container
          .read(obd2SelfTestControllerProvider.notifier)
          .run(targetMac: '');

      // An empty MAC is treated as "no adapter chosen" → the INITIAL connect
      // blind-scans. (The reconnect step later connects by the live service's
      // own MAC regardless, so we only assert the scan path was taken.)
      expect(conn.connectBestCalls, 1);
    });

    test(
        'run(transportHint:classic) routes a CLASSIC adapter over RFCOMM, NOT '
        'the doomed BLE direct path (#2969)', () async {
      final conn = _FakeConnection(adapterIsClassic: true);
      final container = ProviderContainer(
        overrides: [obd2ConnectionProvider.overrideWith((_) => conn)],
      );
      addTearDown(container.dispose);

      await container.read(obd2SelfTestControllerProvider.notifier).run(
            targetMac: 'AA:BB:CC:DD:EE:FF',
            transportHint: Obd2ConnectTransport.classic,
          );

      // The connect + reconnect both took the Classic RFCOMM path.
      expect(conn.classicMacsConnected, isNotEmpty);
      // The BLE direct path was NEVER used for this Classic adapter.
      expect(conn.macsConnected, isEmpty);
      expect(container.read(obd2SelfTestControllerProvider).passed, isTrue);
    });
  });
}

class _FakeConnection extends Obd2ConnectionService {
  _FakeConnection({this.adapterIsClassic = false})
      : super(
          registry: Obd2AdapterRegistry.defaults(),
          permissions: _GrantedPermissions(),
          bluetooth: _UnusedBluetoothFacade(),
        );

  /// #2969 — when true the BLE direct path fails (a Classic adapter can only
  /// 4 s-timeout on it) and only the RFCOMM path connects, like production.
  final bool adapterIsClassic;

  /// How many times the blind-scan path (connectBest) was taken.
  int connectBestCalls = 0;

  /// The MACs passed to the BLE no-scan connect-by-MAC path, in call order.
  final List<String> macsConnected = [];

  /// The MACs passed to the Classic RFCOMM connect-by-MAC path (#2969).
  final List<String> classicMacsConnected = [];

  Future<Obd2Service?> _open() async {
    final service = Obd2Service(FakeObd2Transport(Map.of(_happyPathResponses)))
      ..adapterMac = 'AA:BB:CC:DD:EE:FF'
      ..linkKind = adapterIsClassic ? 'classic' : 'ble';
    await service.connect();
    return service;
  }

  @override
  Future<Obd2Service?> connectBest() {
    connectBestCalls++;
    return _open();
  }

  @override
  Future<Obd2Service?> connectByMacDirect(
    String mac, {
    Duration timeout = const Duration(seconds: 4),
    bool fallbackToScan = true,
  }) async {
    macsConnected.add(mac);
    // A Classic adapter cannot answer the BLE direct path.
    if (adapterIsClassic) return null;
    return _open();
  }

  @override
  Future<Obd2Service?> connectByMacClassicDirect(String mac) async {
    classicMacsConnected.add(mac);
    if (!adapterIsClassic) return null;
    return _open();
  }
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
