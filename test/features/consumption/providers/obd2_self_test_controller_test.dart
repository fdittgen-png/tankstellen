// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/adapter_registry.dart';
import 'package:tankstellen/features/consumption/data/obd2/bluetooth_facade.dart';
import 'package:tankstellen/features/consumption/data/obd2/elm_byte_channel.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_comm_diagnostics.dart';
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
