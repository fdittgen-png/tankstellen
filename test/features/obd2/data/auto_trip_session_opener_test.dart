// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/logging/error_logger.dart';
import 'package:tankstellen/core/telemetry/collectors/breadcrumb_collector.dart';
import 'package:tankstellen/core/telemetry/models/error_trace.dart';
import 'package:tankstellen/core/telemetry/trace_recorder.dart';
import 'package:tankstellen/features/obd2/data/auto_record_trace_log.dart';
import 'package:tankstellen/features/obd2/data/auto_trip_session_opener.dart';
import 'package:tankstellen/features/obd2/data/obd2_service.dart';
import 'package:tankstellen/features/obd2/data/obd2_speed_stream.dart';
import 'package:tankstellen/features/obd2/data/obd2_transport.dart';

/// Seam-level fault-injection tests for [AutoTripSessionOpener] (#3727 —
/// extracted from `AutoTripCoordinator`). The coordinator's own
/// state-machine tests (`auto_trip_coordinator_test.dart`) still drive
/// the full open/watch/hand-off flow end-to-end; this file pins the
/// swallow-and-log contracts of the extracted unit in isolation:
///
/// - `tuneLinkForBackground` / `tuneLinkForRecording` document that a
///   tuning failure never throws into the connect path (#2349 — a
///   documented never-throws boundary needs a fault-path test).
/// - `closeSessionIfHeld` and the drop-orphan disconnect inside
///   `openAndWatch` swallow transport errors.
class _FakeTransport implements Obd2Transport {
  bool throwOnDisconnect;
  bool _connected = true;
  int disconnectCalls = 0;

  _FakeTransport({this.throwOnDisconnect = false});

  @override
  bool get isConnected => _connected;

  @override
  Future<void> connect() async {
    _connected = true;
  }

  @override
  Future<void> disconnect() async {
    disconnectCalls++;
    if (throwOnDisconnect) {
      throw StateError('injected disconnect fault');
    }
    _connected = false;
  }

  @override
  Future<String> sendCommand(String command) async => 'NO DATA';
}

/// [Obd2Service] whose BLE link-tuning entry points throw — injects the
/// fault behind the never-throws contract of
/// `AutoTripSessionOpener.tuneLinkForBackground` / `tuneLinkForRecording`.
class _ThrowingTuneService extends Obd2Service {
  _ThrowingTuneService(super.transport);

  @override
  Future<void> tuneLinkForBackground() async {
    throw StateError('injected tuneLinkForBackground fault');
  }

  @override
  Future<void> tuneLinkForRecording() async {
    throw StateError('injected tuneLinkForRecording fault');
  }
}

/// In-memory [TraceRecorder] draining `errorLogger.log` calls so the
/// swallow paths don't spool through Hive (not initialized in plain
/// unit-test mode).
class _FakeTraceRecorder implements TraceRecorder {
  final List<Object> errors = <Object>[];

  @override
  Future<void> record(
    Object error,
    StackTrace stackTrace, {
    ServiceChainSnapshot? serviceChainState,
  }) async {
    errors.add(error);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

void main() {
  const String mac = 'AA:BB:CC:DD:EE:FF';

  late _FakeTraceRecorder rec;

  AutoTripSessionOpener buildOpener({bool abandonOpen = false}) {
    return AutoTripSessionOpener(
      mac: mac,
      linkSupervisor: null,
      speedStreamFactory: (Obd2Service service, {String? mac}) =>
          Obd2SpeedStream(
        service,
        mac: mac,
        pollPeriod: const Duration(milliseconds: 5),
      ),
      startTrip: (Obd2Service service) async => null,
      onSpeedSample: (double kmh) {},
      onLinkDrop: () async {},
      shouldAbandonOpen: () => abandonOpen,
      clearTripActive: () {},
    );
  }

  setUp(() {
    AutoRecordTraceLog.clear();
    errorLogger.resetForTest();
    rec = _FakeTraceRecorder();
    errorLogger.testRecorderOverride = rec;
    BreadcrumbCollector.clear();
  });

  tearDown(() {
    errorLogger.resetForTest();
  });

  test(
      'tuneLinkForBackground swallows a throwing service — '
      'never throws into the connect path (#2349 fault path)', () async {
    final opener = buildOpener();
    final service = _ThrowingTuneService(_FakeTransport());

    await expectLater(opener.tuneLinkForBackground(service), completes);
    expect(rec.errors, isNotEmpty,
        reason: 'the tuning fault must be logged, not silently dropped');
  });

  test(
      'tuneLinkForRecording swallows a throwing service — '
      'never throws into the hand-off path (#2349 fault path)', () async {
    final opener = buildOpener();
    final service = _ThrowingTuneService(_FakeTransport());

    await expectLater(opener.tuneLinkForRecording(service), completes);
    expect(rec.errors, isNotEmpty,
        reason: 'the tuning fault must be logged, not silently dropped');
  });

  test('closeSessionIfHeld swallows a throwing transport disconnect',
      () async {
    final transport = _FakeTransport();
    final service = Obd2Service(transport);
    final opener = buildOpener();

    await opener.openAndWatch((String mac) async => service);
    expect(opener.hasOpenSession, isTrue,
        reason: 'precondition: the dialed session is held');

    transport.throwOnDisconnect = true;
    await expectLater(opener.closeSessionIfHeld(), completes);
    expect(opener.hasOpenSession, isFalse,
        reason: 'the session pointer is nulled even when close faults');
    expect(transport.disconnectCalls, 1);

    await opener.stopWatching();
  });

  test(
      'openAndWatch drop-orphan path swallows a throwing disconnect '
      'when the open was abandoned mid-dial', () async {
    final transport = _FakeTransport(throwOnDisconnect: true);
    final service = Obd2Service(transport);
    final opener = buildOpener(abandonOpen: true);

    await expectLater(
      opener.openAndWatch((String mac) async => service),
      completes,
    );
    expect(opener.hasOpenSession, isFalse,
        reason: 'an abandoned open must not retain the orphan session');
    expect(transport.disconnectCalls, 1,
        reason: 'the orphan session is dropped, not leaked');
  });
}
