// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/logging/error_logger.dart';
import 'package:tankstellen/core/telemetry/models/error_trace.dart';
import 'package:tankstellen/core/telemetry/trace_recorder.dart';
import 'package:tankstellen/features/obd2/data/elm327_protocol.dart';
import 'package:tankstellen/features/obd2/data/obd2_service.dart';
import 'package:tankstellen/features/obd2/data/obd2_transport.dart';
import 'package:tankstellen/features/obd2/data/trip_recording_controller.dart';

/// #2428 (follow-up to #2379/#2424) — [TripRecordingController]'s one-shot
/// VIN (0902) read at [TripRecordingController.start] is a best-effort
/// identity lookup. On a flaky/slow ELM327 the `sendCommand` times out (or
/// the legacy concurrent-send / device-not-connected fires) and the trip
/// records fine without a VIN — but the catch still spooled one `[storage]`
/// trace per affected user, exactly the flood #2379/#2424 reclassified
/// elsewhere. This file pins the same contract: the recovered path records
/// the trip AND produces ZERO `errorLogger` traces for that transient.

/// Records every [errorLogger] trace so the test can assert on count —
/// mirrors `supported_pids_resolver_logging_test.dart` (#2424) and
/// `obd2_service_odometer_logging_test.dart` (#2379).
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

/// A [FakeObd2Transport] whose VIN (0902) command throws the supplied
/// transient — the flaky-adapter scenario from the user logs. Every other
/// command (the AT init handshake + odometer) answers normally, so the
/// service connects and the trip records cleanly; only the VIN probe fails.
class _VinThrowingTransport extends FakeObd2Transport {
  _VinThrowingTransport(this._onVin, [super.responses]);

  final Object Function() _onVin;

  @override
  Future<String> sendCommand(String command) async {
    if (command.trim() == Elm327Protocol.vinCommand.trim()) {
      throw _onVin();
    }
    return super.sendCommand(command);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _CaptureRecorder recorder;

  setUp(() {
    errorLogger.resetForTest();
    recorder = _CaptureRecorder();
    errorLogger.testRecorderOverride = recorder;
  });

  tearDown(errorLogger.resetForTest);

  // The init handshake + a valid odometer so `start()` succeeds; the VIN
  // command is the only one that throws (via _VinThrowingTransport).
  Map<String, String> baseResponses() => {
        'ATZ': 'ELM327 v1.5>',
        'ATE0': 'OK>',
        'ATL0': 'OK>',
        'ATH0': 'OK>',
        'ATSP0': 'OK>',
        '01A6': '41 A6 00 01 6A 2C>', // 92716 raw → 9271.6 km
      };

  group('TripRecordingController VIN-read transient → zero traces (#2428)',
      () {
    test(
        'a VIN-command TimeoutException leaves vin null, still records the '
        'trip, and logs NO error trace', () async {
      final transport = _VinThrowingTransport(
        () => TimeoutException('ELM327 did not respond within 2.5s'),
        baseResponses(),
      );
      final service = Obd2Service(transport);
      await service.connect();

      final ctl = TripRecordingController(
        service: service,
        pollInterval: const Duration(minutes: 1), // never ticks in-test
      );

      await ctl.start();
      // The trip proceeds normally: odometer was still read, recording is
      // live — the VIN failure is a graceful no-op.
      expect(ctl.isRecording, isTrue,
          reason: 'a VIN-read transient must not abort the trip');
      expect(ctl.odometerStartKm, closeTo(9271.6, 0.01),
          reason: 'the trip records fine without a VIN');

      final summary = await ctl.stop();

      expect(ctl.vin, isNull,
          reason: 'best-effort: a timed-out 0902 probe leaves the VIN null');
      expect(summary.distanceKm, 0);
      expect(recorder.calls, isEmpty,
          reason: 'a transient VIN-read failure is expected/recoverable — '
              'it must not pollute the user error log (#2379/#2424)');
    });

    test(
        'the legacy concurrent-sendCommand StateError on the VIN command is '
        'also silent', () async {
      final transport = _VinThrowingTransport(
        () => StateError('A sendCommand is in flight'),
        baseResponses(),
      );
      final service = Obd2Service(transport);
      await service.connect();

      final ctl = TripRecordingController(
        service: service,
        pollInterval: const Duration(minutes: 1),
      );

      await ctl.start();
      await ctl.stop();

      expect(ctl.vin, isNull);
      expect(recorder.calls, isEmpty,
          reason: 'the legacy concurrent-sendCommand StateError is a '
              'recoverable transient — no trace');
    });
  });
}
