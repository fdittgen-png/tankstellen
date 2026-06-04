// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/logging/error_logger.dart';
import 'package:tankstellen/core/telemetry/models/error_trace.dart';
import 'package:tankstellen/core/telemetry/trace_recorder.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_service.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_transport.dart';

/// #2855 — the high-frequency OBD2 live-poll reads (`readSpeedKmh`,
/// `readRpm`, and the shared `_readDouble`-backed PID reads) already return
/// null on failure as graceful degradation, but they ERROR-logged EVERY
/// failure — including the routine `TimeoutException` of an engine-off /
/// busy adapter. A real log showed 50× `readSpeed failed` traces in 2 min.
///
/// This file pins the contract: a transient (TimeoutException) read failure
/// produces ZERO error traces (the null return IS the signal), while a
/// GENUINE non-transient failure still logs exactly once. Persistent
/// non-response is surfaced by comm-health diagnostics (#2464) + the
/// passive-waiting banner (#2767), so suppressing per-poll timeout traces
/// loses no real signal. Same spirit as the #2379 odometer fix.

const _initResponses = {
  'ATZ': 'ELM327 v1.5>',
  'ATE0': 'OK>',
  'ATL0': 'OK>',
  'ATH0': 'OK>',
  'ATSP0': 'OK>',
};

/// Live-poll PID commands exercised here: speed (010D), RPM (010C) and a
/// `_readDouble`-backed read, engine load (0104).
const _liveReadCommands = {'010D', '010C', '0104'};

/// Transport that connects + inits normally (so connect() is quiet), but
/// throws a [TimeoutException] for the live-read PIDs — the engine-off /
/// busy-adapter scenario that produced the real flood.
class _LiveReadTimingOutTransport implements Obd2Transport {
  bool _connected = false;

  @override
  bool get isConnected => _connected;

  @override
  Future<void> connect() async => _connected = true;

  @override
  Future<String> sendCommand(String command) async {
    if (!_connected) throw StateError('Not connected');
    final cmd = command.trim();
    if (_liveReadCommands.contains(cmd)) {
      throw TimeoutException('ELM327 did not respond within 2.5s');
    }
    return _initResponses[cmd] ?? 'NO DATA>';
  }

  @override
  Future<void> disconnect() async => _connected = false;
}

/// Transport that connects + inits normally but throws a GENUINE
/// non-transient fault (a plain [FormatException], standing in for a
/// parse/IO fault) for the live-read PIDs — this MUST still be logged.
class _LiveReadGenuineFaultTransport implements Obd2Transport {
  bool _connected = false;

  @override
  bool get isConnected => _connected;

  @override
  Future<void> connect() async => _connected = true;

  @override
  Future<String> sendCommand(String command) async {
    if (!_connected) throw StateError('Not connected');
    final cmd = command.trim();
    if (_liveReadCommands.contains(cmd)) {
      throw const FormatException('corrupt OBD2 frame');
    }
    return _initResponses[cmd] ?? 'NO DATA>';
  }

  @override
  Future<void> disconnect() async => _connected = false;
}

class _CaptureRecorder implements TraceRecorder {
  final calls = <Object>[];

  @override
  Future<void> record(
    Object error,
    StackTrace stackTrace, {
    ServiceChainSnapshot? serviceChainState,
  }) async {
    calls.add(error);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

void main() {
  late _CaptureRecorder recorder;

  setUp(() {
    errorLogger.resetForTest();
    recorder = _CaptureRecorder();
    errorLogger.testRecorderOverride = recorder;
  });

  tearDown(errorLogger.resetForTest);

  group('live-read transient timeouts do NOT flood the error log (#2855)', () {
    test(
        'N readSpeedKmh timeouts each return null and log ZERO error traces',
        () async {
      final service = Obd2Service(_LiveReadTimingOutTransport());
      await service.connect();
      expect(recorder.calls, isEmpty,
          reason: 'connect() should be quiet for this transport');

      const cycles = 50; // the real flood was 50 traces in ~2 min.
      for (var i = 0; i < cycles; i++) {
        expect(await service.readSpeedKmh(), isNull,
            reason: 'best-effort: a timeout yields null');
      }

      expect(recorder.calls, isEmpty,
          reason: 'a transient readSpeed timeout is the no-reply path — '
              'it must NOT pollute the error log ($cycles cycles = was '
              '$cycles traces)');
    });

    test('N readRpm timeouts each return null and log ZERO error traces',
        () async {
      final service = Obd2Service(_LiveReadTimingOutTransport());
      await service.connect();
      expect(recorder.calls, isEmpty);

      const cycles = 50;
      for (var i = 0; i < cycles; i++) {
        expect(await service.readRpm(), isNull);
      }

      expect(recorder.calls, isEmpty,
          reason: 'a transient readRpm timeout must NOT pollute the log');
    });

    test(
        'N _readDouble (engine load) timeouts each return null and log ZERO '
        'error traces', () async {
      final service = Obd2Service(_LiveReadTimingOutTransport());
      await service.connect();
      expect(recorder.calls, isEmpty);

      const cycles = 50;
      for (var i = 0; i < cycles; i++) {
        expect(await service.readEngineLoad(), isNull);
      }

      expect(recorder.calls, isEmpty,
          reason: 'the shared _readDouble live-read path must NOT pollute '
              'the log on a transient timeout');
    });
  });

  group('genuine non-transient read faults still log (#2855)', () {
    test('readSpeedKmh parse/IO fault returns null AND logs once', () async {
      final service = Obd2Service(_LiveReadGenuineFaultTransport());
      await service.connect();
      expect(recorder.calls, isEmpty,
          reason: 'connect() should be quiet for this transport');

      expect(await service.readSpeedKmh(), isNull);

      expect(recorder.calls, hasLength(1),
          reason: 'a genuine (non-transient) read fault must still surface '
              'as exactly one error trace');
    });

    test('readEngineLoad parse/IO fault returns null AND logs once', () async {
      final service = Obd2Service(_LiveReadGenuineFaultTransport());
      await service.connect();
      expect(recorder.calls, isEmpty);

      expect(await service.readEngineLoad(), isNull);

      expect(recorder.calls, hasLength(1),
          reason: 'a genuine _readDouble fault must still surface once');
    });
  });
}
