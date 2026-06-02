// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

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

/// Mirrors the shared AT-init boilerplate the other Obd2Service tests use
/// so `service.connect()` succeeds + tees an init transcript.
const _initResponses = {
  'ATZ': 'ELM327 v1.5>',
  'ATE0': 'OK>',
  'ATL0': 'OK>',
  'ATH0': 'OK>',
  'ATSP0': 'OK>',
  'ATI': 'ELM327 v1.5>',
};

const _happyPathResponses = {
  ..._initResponses,
  'AT@1': 'OBDII to RS232 Interpreter>',
  'ATRV': '12.4V>',
  '0100': '41 00 BE 3F A8 13>',
  '010C': '41 0C 1A F8>',
  '010D': '41 0D 50>',
  '0105': '41 05 5A>',
};

void main() {
  setUp(Obd2CommDiagnostics.instance.reset);
  tearDown(() {
    Obd2CommDiagnostics.instance.enabled = false;
    Obd2CommDiagnostics.instance.reset();
  });

  group('runObd2SelfTest (#2645)', () {
    test('happy path: every step ok + a finalised self-test session persists',
        () async {
      final conn = _FakeConnection(
        transportFor: () => FakeObd2Transport(Map.of(_happyPathResponses)),
      );

      final steps = <Obd2SelfTestStepResult>[];
      final report = await runObd2SelfTest(
        conn,
        pinnedMac: 'AA:BB:CC:DD:EE:FF',
        onStep: steps.add,
      );

      // All seven steps ran and passed.
      expect(report.passed, isTrue);
      expect(report.stepCount, Obd2SelfTestStepId.values.length);
      expect(
        report.steps.map((s) => s.status).toSet(),
        {Obd2SelfTestStepStatus.ok},
      );

      // The trace was finalised into the collector ring. The deliberate
      // reconnect splits the run into a rich pre-reconnect session + a
      // post-reconnect session (both self-test-tagged) — exactly like a
      // real dropped-then-reconnected trip.
      final finished = Obd2CommDiagnostics.instance.finishedSessions;
      expect(finished, hasLength(2));
      // Every finished session is identifiable as a self-test.
      expect(
        finished.every((s) => s.initTranscript.any((l) => l.cmd == selfTestTag)),
        isTrue,
      );

      // The rich pre-reconnect session carries the info + supported-PID raw
      // lines + the sample-read per-PID table.
      final rich = finished.firstWhere((s) => s.pidStats.isNotEmpty);
      final cmds = rich.initTranscript.map((l) => l.cmd).toList();
      expect(cmds, containsAll(<String>['AT@1', 'ATRV', '0100']));
      expect(rich.pidStats['010C']?.ok, 1);
      expect(rich.pidStats['010D']?.ok, 1);
      expect(rich.pidStats['0105']?.ok, 1);
      expect(rich.discoveredSupported['0100'], 'supported');
      // The drop landed on the pre-reconnect session.
      expect(rich.connection.drops, greaterThanOrEqualTo(1));
      // The visible reconnect + timing landed on the post-reconnect session.
      final post = finished.firstWhere((s) => s.connection.visibleReconnects > 0);
      expect(post.connection.visibleReconnects, 1);
    });

    test('timeout on a sample read is classified timeout and the run CONTINUES',
        () async {
      final conn = _FakeConnection(
        transportFor: () => _DelayingTransport(
          Map.of(_happyPathResponses),
          // Delay 010C well past the step deadline; the connect init's own
          // post-reset settle stays comfortably under it.
          delayFor: {'010C': const Duration(milliseconds: 600)},
        ),
      );

      final report = await runObd2SelfTest(
        conn,
        pinnedMac: 'AA:BB:CC:DD:EE:FF',
        stepDeadline: const Duration(milliseconds: 250),
      );

      // The sequence still produced a full trace through to disconnect.
      expect(report.stepCount, Obd2SelfTestStepId.values.length);
      final sample = report.steps
          .firstWhere((s) => s.id == Obd2SelfTestStepId.sampleReads);
      expect(sample.status, Obd2SelfTestStepStatus.timeout);
      // A timeout was recorded against 010C in the pre-reconnect session's
      // per-PID table.
      final session = Obd2CommDiagnostics.instance.finishedSessions
          .firstWhere((s) => s.pidStats.isNotEmpty);
      expect(session.pidStats['010C']?.timeout, 1);
      // The disconnect step still ran (full trace on failure).
      expect(
        report.steps.last.id,
        Obd2SelfTestStepId.disconnect,
      );
    });

    test('garbage replies classify garbage and a full session still finalises',
        () async {
      final conn = _FakeConnection(
        transportFor: () => FakeObd2Transport({
          ..._initResponses,
          'AT@1': 'OK>',
          'ATRV': '12.0V>',
          '0100': 'SEARCHING...>',
          '010C': '41 0C 1A F8>',
          '010D': 'SEARCHING...>',
          '0105': '41 05 5A>',
        }),
      );

      final report = await runObd2SelfTest(conn, pinnedMac: 'M');

      final pids = report.steps
          .firstWhere((s) => s.id == Obd2SelfTestStepId.sampleReads);
      expect(pids.status, Obd2SelfTestStepStatus.garbage);
      final supported = report.steps
          .firstWhere((s) => s.id == Obd2SelfTestStepId.supportedPids);
      expect(supported.status, Obd2SelfTestStepStatus.garbage);
      // A full session still finalised despite the garbage replies.
      final sessions = Obd2CommDiagnostics.instance.finishedSessions;
      expect(sessions, isNotEmpty);
      expect(sessions.any((s) => s.pidStats.isNotEmpty), isTrue);
    });

    test('connect failure ABORTS but finalises a partial trace', () async {
      final conn = _FakeConnection(transportFor: () => FakeObd2Transport())
        ..connectReturnsNull = true;

      final report = await runObd2SelfTest(conn, pinnedMac: 'M');

      expect(report.passed, isFalse);
      // The scan step reflects the no-adapter outcome.
      final scan =
          report.steps.firstWhere((s) => s.id == Obd2SelfTestStepId.scan);
      expect(scan.status, Obd2SelfTestStepStatus.noResponse);
      // Later steps are marked skipped (test died early) — never ok.
      final connect =
          report.steps.firstWhere((s) => s.id == Obd2SelfTestStepId.connect);
      expect(connect.status, Obd2SelfTestStepStatus.skipped);
    });

    test('reconnect failure CONTINUES to a clean disconnect', () async {
      final conn = _FakeConnection(
        transportFor: () => FakeObd2Transport(Map.of(_happyPathResponses)),
      )..reconnectReturnsNull = true;

      final report = await runObd2SelfTest(conn, pinnedMac: 'M');

      final reconnect =
          report.steps.firstWhere((s) => s.id == Obd2SelfTestStepId.reconnect);
      expect(reconnect.status, Obd2SelfTestStepStatus.noResponse);
      // The disconnect step still runs after a failed reconnect.
      expect(report.steps.last.id, Obd2SelfTestStepId.disconnect);
      // The drop was still recorded.
      final session = Obd2CommDiagnostics.instance.finishedSessions.single;
      expect(session.connection.drops, greaterThanOrEqualTo(1));
    });

    test('restores Obd2CommDiagnostics.enabled to its prior value in finally',
        () async {
      Obd2CommDiagnostics.instance.enabled = false;
      final conn = _FakeConnection(
        transportFor: () => FakeObd2Transport(Map.of(_happyPathResponses)),
      );

      await runObd2SelfTest(conn, pinnedMac: 'M');

      // The driver armed the collector for the run, then restored it.
      expect(Obd2CommDiagnostics.instance.enabled, isFalse);
    });
  });
}

/// Fake connection service whose connect/reconnect return an [Obd2Service]
/// backed by a freshly-scripted transport per call. Overrides only the two
/// methods the driver uses.
class _FakeConnection extends Obd2ConnectionService {
  _FakeConnection({required this.transportFor})
      : super(
          registry: Obd2AdapterRegistry.defaults(),
          permissions: _GrantedPermissions(),
          bluetooth: _UnusedBluetoothFacade(),
        );

  final Obd2Transport Function() transportFor;
  bool connectReturnsNull = false;
  bool reconnectReturnsNull = false;
  int reconnectCalls = 0;

  Future<Obd2Service?> _open() async {
    if (connectReturnsNull) return null;
    final service = Obd2Service(transportFor())
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
  }) async {
    // The first call is the initial connect; the second is the reconnect.
    reconnectCalls++;
    if (reconnectCalls > 1 && reconnectReturnsNull) return null;
    return _open();
  }
}

/// A [FakeObd2Transport] subclass that delays the listed commands so the
/// driver's `.timeout(stepDeadline)` fires deterministically.
class _DelayingTransport extends FakeObd2Transport {
  _DelayingTransport(super.responses, {required this.delayFor});

  final Map<String, Duration> delayFor;

  @override
  Future<String> sendCommand(String command) async {
    final delay = delayFor[command.trim()];
    if (delay != null) await Future<void>.delayed(delay);
    return super.sendCommand(command);
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
