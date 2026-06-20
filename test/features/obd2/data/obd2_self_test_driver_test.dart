// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/adapter_registry.dart';
import 'package:tankstellen/features/obd2/data/bluetooth_facade.dart';
import 'package:tankstellen/features/obd2/data/elm_byte_channel.dart';
import 'package:tankstellen/features/obd2/data/obd2_comm_diagnostics.dart';
import 'package:tankstellen/features/obd2/data/obd2_connect_trace.dart';
import 'package:tankstellen/features/obd2/data/obd2_connect_trace_log.dart';
import 'package:tankstellen/features/obd2/data/obd2_connection_service.dart';
import 'package:tankstellen/features/obd2/data/obd2_permissions.dart';
import 'package:tankstellen/features/obd2/data/obd2_self_test_driver.dart';
import 'package:tankstellen/features/obd2/data/obd2_service.dart';
import 'package:tankstellen/features/obd2/data/obd2_transport.dart';

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

  group('engine-off verdict (#3009)', () {
    test(
        'adapter-capability steps PASS but the live-data steps are ECU-silent '
        '→ verdict engineOff (adapter OK), NOT a red failure', () async {
      // Every AT command answers (connect / info / reconnect / disconnect all
      // pass), but the vehicle bus is silent: 0100 → SEARCHING...STOPPED and
      // the sample reads → NO DATA. This is the engine-off field condition.
      final conn = _FakeConnection(
        transportFor: () => FakeObd2Transport({
          ..._initResponses,
          'AT@1': 'OBDII to RS232 Interpreter>',
          'ATRV': '12.4V>',
          '0100': 'SEARCHING...STOPPED>',
          '010C': 'NO DATA>',
          '010D': 'NO DATA>',
          '0105': 'NO DATA>',
        }),
      );

      final report = await runObd2SelfTest(conn, pinnedMac: 'AA:BB:CC:DD:EE:FF');

      // RED on master: the report only had passed=false → a red failure.
      expect(report.verdict, Obd2SelfTestVerdict.engineOff);
      expect(report.passed, isFalse);
      // The adapter-capability steps all passed.
      for (final id in const [
        Obd2SelfTestStepId.scan,
        Obd2SelfTestStepId.connect,
        Obd2SelfTestStepId.info,
        Obd2SelfTestStepId.reconnect,
        Obd2SelfTestStepId.disconnect,
      ]) {
        expect(report.steps.firstWhere((s) => s.id == id).status,
            Obd2SelfTestStepStatus.ok,
            reason: '$id is an adapter-capability step and must pass');
      }
      // The live-data steps show the engine-off signature, not a hard fault.
      final pids = report.steps
          .firstWhere((s) => s.id == Obd2SelfTestStepId.supportedPids);
      final sample = report.steps
          .firstWhere((s) => s.id == Obd2SelfTestStepId.sampleReads);
      expect(kObd2EngineOffStatuses, contains(pids.status));
      expect(kObd2EngineOffStatuses, contains(sample.status));
    });

    test('a genuine connect failure still yields verdict failed (stays RED)',
        () async {
      final conn = _FakeConnection(transportFor: () => FakeObd2Transport())
        ..connectReturnsNull = true;

      final report = await runObd2SelfTest(conn, pinnedMac: 'M');

      expect(report.verdict, Obd2SelfTestVerdict.failed);
    });

    test('a live-data TIMEOUT (adapter went silent) is failed, NOT engineOff',
        () async {
      // A timeout is the adapter itself stopping — a real fault, not engine-off.
      final conn = _FakeConnection(
        transportFor: () => _DelayingTransport(
          {
            ..._happyPathResponses,
            '0100': 'SEARCHING...STOPPED>',
          },
          delayFor: {'010C': const Duration(milliseconds: 600)},
        ),
      );

      final report = await runObd2SelfTest(
        conn,
        pinnedMac: 'M',
        stepDeadline: const Duration(milliseconds: 250),
      );

      // sampleReads timed out → a hard fault → the run stays RED.
      expect(report.verdict, Obd2SelfTestVerdict.failed);
    });

    test('a full happy path is verdict passed (not engineOff)', () async {
      final conn = _FakeConnection(
        transportFor: () => FakeObd2Transport(Map.of(_happyPathResponses)),
      );

      final report = await runObd2SelfTest(conn, pinnedMac: 'M');

      expect(report.verdict, Obd2SelfTestVerdict.passed);
      expect(report.passed, isTrue);
    });
  });

  group('obd2SelfTestVerdict pure classifier (#3009)', () {
    Obd2SelfTestStepResult s(
            Obd2SelfTestStepId id, Obd2SelfTestStepStatus status) =>
        Obd2SelfTestStepResult(id: id, status: status);

    List<Obd2SelfTestStepResult> withLiveData(
            Obd2SelfTestStepStatus pids, Obd2SelfTestStepStatus sample) =>
        [
          s(Obd2SelfTestStepId.scan, Obd2SelfTestStepStatus.ok),
          s(Obd2SelfTestStepId.connect, Obd2SelfTestStepStatus.ok),
          s(Obd2SelfTestStepId.info, Obd2SelfTestStepStatus.ok),
          s(Obd2SelfTestStepId.supportedPids, pids),
          s(Obd2SelfTestStepId.sampleReads, sample),
          s(Obd2SelfTestStepId.reconnect, Obd2SelfTestStepStatus.ok),
          s(Obd2SelfTestStepId.disconnect, Obd2SelfTestStepStatus.ok),
        ];

    test('all ok → passed', () {
      expect(
        obd2SelfTestVerdict(withLiveData(
            Obd2SelfTestStepStatus.ok, Obd2SelfTestStepStatus.ok)),
        Obd2SelfTestVerdict.passed,
      );
    });

    test('live-data noResponse/garbage with adapter steps OK → engineOff', () {
      expect(
        obd2SelfTestVerdict(withLiveData(Obd2SelfTestStepStatus.garbage,
            Obd2SelfTestStepStatus.noResponse)),
        Obd2SelfTestVerdict.engineOff,
      );
    });

    test('an adapter-capability step failing → failed (not engineOff)', () {
      final steps = withLiveData(
          Obd2SelfTestStepStatus.garbage, Obd2SelfTestStepStatus.noResponse)
        ..[1] = s(Obd2SelfTestStepId.connect, Obd2SelfTestStepStatus.fail);
      expect(obd2SelfTestVerdict(steps), Obd2SelfTestVerdict.failed);
    });

    test('a live-data timeout → failed (a real fault, not engineOff)', () {
      expect(
        obd2SelfTestVerdict(withLiveData(Obd2SelfTestStepStatus.timeout,
            Obd2SelfTestStepStatus.noResponse)),
        Obd2SelfTestVerdict.failed,
      );
    });

    test('empty steps → failed', () {
      expect(obd2SelfTestVerdict(const []), Obd2SelfTestVerdict.failed);
    });
  });

  group('transport-aware self-test (#2969 — the reliability fix)', () {
    setUp(Obd2ConnectTraceLog.clear);
    tearDown(Obd2ConnectTraceLog.clear);

    test(
        'a CLASSIC adapter with transportHint:classic takes the RFCOMM path '
        'and PASSES (the vLinker FS fix)', () async {
      final conn = _FakeConnection(
        transportFor: () => FakeObd2Transport(Map.of(_happyPathResponses)),
        adapterIsClassic: true,
      );

      final report = await runObd2SelfTest(
        conn,
        pinnedMac: 'AA:BB:CC:DD:EE:FF',
        transportHint: Obd2ConnectTransport.classic,
      );

      // Both connects took the Classic RFCOMM path, NOT the doomed BLE direct.
      expect(conn.pathsTaken, everyElement('classic'));
      expect(report.passed, isTrue);
    });

    test(
        'the SAME classic adapter with NO hint routes through the '
        'transport-aware resolver and still CONNECTS over RFCOMM (#3380 — no '
        'blind BLE 4 s-timeout)', () async {
      final conn = _FakeConnection(
        transportFor: () => FakeObd2Transport(Map.of(_happyPathResponses)),
        adapterIsClassic: true,
      );

      // #3380 — a null transportHint NO LONGER defaults to the doomed BLE
      // direct path; it takes the production `connectByMacTransportAware`
      // resolver, which scan-classifies the Classic adapter → RFCOMM.
      final report = await runObd2SelfTest(conn, pinnedMac: 'AA:BB:CC:DD:EE:FF');

      expect(report.passed, isTrue);
      // Every connect resolved to the Classic RFCOMM path, not blind BLE.
      expect(conn.pathsTaken, everyElement('classic'));
    });

    test(
        'a null transportHint records origin:selfTest + no-hint-transport-aware '
        'on the trace the REAL service opens (#3380)', () async {
      // Drive the REAL Obd2ConnectionService. With no hint the run takes the
      // transport-aware resolver; the facade's direct open throws + the scan is
      // empty, so the connect fails — but the trace is the artefact under test.
      final service = Obd2ConnectionService(
        registry: Obd2AdapterRegistry.defaults(),
        permissions: _GrantedPermissions(),
        bluetooth: _ThrowingDirectFacade(),
        scanSettleDelay: Duration.zero,
      );

      await runObd2SelfTest(service, pinnedMac: 'AA:BB:CC:DD:EE:FF');

      final traces = Obd2ConnectTraceLog.snapshot();
      expect(traces, isNotEmpty,
          reason: 'a FAILED self-test connect must leave a trace');
      // The self-test stamped its origin + the no-blind-BLE decision (#3380).
      expect(traces.first.origin, Obd2ConnectOrigin.selfTest);
      expect(
        traces.first.transportDecisionReason,
        'no-hint-transport-aware',
      );
    });
  });
}

/// A BLE facade whose direct channel always throws on open() so the real
/// service's connect path fails and the trace captures the failure.
class _ThrowingDirectFacade implements BluetoothFacade {
  @override
  Stream<List<Obd2AdapterCandidate>> scan({
    required Set<String> serviceUuids,
    Duration timeout = const Duration(seconds: 8),
  }) async* {}

  @override
  Future<void> stopScan() async {}

  @override
  ElmByteChannel channelFor(String deviceId, Obd2AdapterProfile profile) =>
      _ThrowingOpenChannel();

  @override
  ElmByteChannel channelForDirect(
    String mac, {
    Duration connectTimeout = const Duration(seconds: 4),
    bool autoConnect = false,
  }) =>
      _ThrowingOpenChannel();
}

class _ThrowingOpenChannel implements ElmByteChannel {
  final StreamController<List<int>> _ctrl = StreamController.broadcast();
  @override
  bool get isOpen => false;
  @override
  Stream<List<int>> get incoming => _ctrl.stream;
  @override
  Future<void> open() async => throw StateError('GATT_ERROR 133');
  @override
  Future<void> write(List<int> bytes) async {}
  @override
  Future<void> close() async {
    if (!_ctrl.isClosed) await _ctrl.close();
  }
}

/// Fake connection service whose connect/reconnect return an [Obd2Service]
/// backed by a freshly-scripted transport per call.
///
/// #2969 — TRANSPORT-AWARE (de-false-greened). The old fake let
/// `connectByMacDirect` (the BLE GATT path) succeed for ANY MAC, hiding the
/// real bug: a Classic-SPP adapter (vLinker FS) can ONLY 4 s-timeout on the BLE
/// direct path. This fake now mimics production: when [adapterIsClassic] the
/// BLE direct path FAILS (returns null) and only `connectByMacClassicDirect`
/// (RFCOMM) succeeds. It records which path each connect took so a test can
/// assert the transport-aware routing.
class _FakeConnection extends Obd2ConnectionService {
  _FakeConnection({required this.transportFor, this.adapterIsClassic = false})
      : super(
          registry: Obd2AdapterRegistry.defaults(),
          permissions: _GrantedPermissions(),
          bluetooth: _UnusedBluetoothFacade(),
        );

  final Obd2Transport Function() transportFor;

  /// When true, the BLE direct path is doomed (returns null, like the real
  /// 4 s-timeout) and only the Classic RFCOMM path can connect.
  final bool adapterIsClassic;

  bool connectReturnsNull = false;
  bool reconnectReturnsNull = false;
  int reconnectCalls = 0;

  /// The connect path each successful connect took: 'ble-direct' / 'classic'.
  final List<String> pathsTaken = [];

  Future<Obd2Service?> _open(String path) async {
    if (connectReturnsNull) return null;
    pathsTaken.add(path);
    final service = Obd2Service(transportFor())
      ..adapterMac = 'AA:BB:CC:DD:EE:FF'
      ..linkKind = adapterIsClassic ? 'classic' : 'ble';
    await service.connect();
    return service;
  }

  @override
  Future<Obd2Service?> connectBest() => _open('ble-direct');

  @override
  Future<Obd2Service?> connectByMacDirect(
    String mac, {
    Duration? timeout,
    bool fallbackToScan = true,
    String? adapterName,
  }) async {
    reconnectCalls++;
    if (reconnectCalls > 1 && reconnectReturnsNull) return null;
    // A Classic adapter cannot connect over the BLE direct path — exactly the
    // production trap. Returning null models the 4 s-timeout-then-null.
    if (adapterIsClassic) return null;
    return _open('ble-direct');
  }

  @override
  Future<Obd2Service?> connectByMacClassicDirect(String mac,
      {String? adapterName}) async {
    reconnectCalls++;
    if (reconnectCalls > 1 && reconnectReturnsNull) return null;
    // The RFCOMM path only works for a Classic adapter (mirrors the facade
    // being absent / wrong for a BLE adapter).
    if (!adapterIsClassic) return null;
    return _open('classic');
  }

  /// #3380 — models the production transport-aware resolver the self-test now
  /// takes when it has NO hint: it scan-classifies the MAC and routes to the
  /// correct transport (Classic → RFCOMM), so a hint-less Classic adapter still
  /// connects instead of burning a doomed BLE 4 s-timeout.
  @override
  Future<Obd2Service?> connectByMacTransportAware(
    String mac, {
    String? adapterName,
    bool fallbackToScan = true,
  }) async {
    reconnectCalls++;
    if (reconnectCalls > 1 && reconnectReturnsNull) return null;
    return adapterIsClassic ? _open('classic') : _open('ble-direct');
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
