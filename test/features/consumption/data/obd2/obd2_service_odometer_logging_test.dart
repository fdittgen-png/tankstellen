// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/logging/error_logger.dart';
import 'package:tankstellen/core/telemetry/models/error_trace.dart';
import 'package:tankstellen/core/telemetry/trace_recorder.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_service.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_transport.dart';

/// #2379 — `readOdometerKm` is a best-effort one-shot that already returns
/// null on failure. A timeout (engine off / odometer-not-readable car)
/// flooded a real user's error log, so its catch must NOT produce an
/// error trace. This file pins that contract.

const _initResponses = {
  'ATZ': 'ELM327 v1.5>',
  'ATE0': 'OK>',
  'ATL0': 'OK>',
  'ATH0': 'OK>',
  'ATSP0': 'OK>',
};

/// Odometer-chain commands `readOdometerKm` walks: standard PID A6, the
/// distance-since-DTC-cleared PID 31, and the VIN probe 0902. The engine-
/// off car times these out.
const _odometerChain = {'01A6', '0131', '0902'};

/// Transport that completes connect() + init normally (unknown init/AT
/// commands answer the benign `NO DATA>`, matching [FakeObd2Transport]),
/// but throws a [TimeoutException] for the odometer-chain commands —
/// exactly the engine-off-car scenario from the user logs.
class _OdometerTimingOutTransport implements Obd2Transport {
  bool _connected = false;

  @override
  bool get isConnected => _connected;

  @override
  Future<void> connect() async => _connected = true;

  @override
  Future<String> sendCommand(String command) async {
    if (!_connected) throw StateError('Not connected');
    final cmd = command.trim();
    if (_odometerChain.contains(cmd)) {
      throw TimeoutException('ELM327 did not respond within 2.5s');
    }
    // AT init handshake + everything else answers benignly so connect()
    // fully succeeds (no connect-path error to confound the assertion).
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

  test(
      'readOdometerKm timeout returns null and logs NO error trace (#2379)',
      () async {
    final service = Obd2Service(_OdometerTimingOutTransport());
    await service.connect();
    // Guard: connect() itself produced no error trace, so any trace seen
    // after readOdometerKm would be attributable to the odometer path.
    expect(recorder.calls, isEmpty,
        reason: 'connect() should be quiet for this transport');

    final km = await service.readOdometerKm();

    expect(km, isNull, reason: 'best-effort: a timeout yields null');
    expect(recorder.calls, isEmpty,
        reason: 'a readOdometer timeout is expected/recoverable — it must '
            'not pollute the error log');
  });
}
