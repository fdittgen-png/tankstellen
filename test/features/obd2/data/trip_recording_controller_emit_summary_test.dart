// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/obd2_service.dart';
import 'package:tankstellen/features/obd2/data/obd2_transport.dart';
import 'package:tankstellen/features/obd2/data/trip_recording_controller.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';
import '../../../helpers/silence_error_logger.dart';

/// #2304 — `_emit()` used to call `_recorder.buildSummary()` twice per
/// 4 Hz tick (two `TripSummary` allocations): once for the fuel-litres
/// read, once for the live-reading distance. It now builds the summary
/// once per tick and reuses it. This counting recorder asserts the
/// single-allocation invariant: a future refactor that reintroduces an
/// extra `buildSummary()` call inside `_emit()` flips the count and
/// fails here.
class _CountingRecorder extends TripRecorder {
  _CountingRecorder() : super(maxIntegrationGapSeconds: 30);

  int buildSummaryCalls = 0;

  @override
  TripSummary buildSummary() {
    buildSummaryCalls++;
    return super.buildSummary();
  }
}

Map<String, String> _elmOk() => const {
      'ATZ': 'ELM327 v1.5>',
      'ATE0': 'OK>',
      'ATL0': 'OK>',
      'ATH0': 'OK>',
      'ATSP0': 'OK>',
      '01A6': 'NO DATA>',
    };

void main() {
  silenceErrorLoggerSpool();

  group('TripRecordingController._emit summary caching (#2304)', () {
    test('a single emit tick builds the trip summary exactly once', () async {
      final recorder = _CountingRecorder();
      final service = Obd2Service(FakeObd2Transport(_elmOk()));
      await service.connect();

      final ctl = TripRecordingController(
        service: service,
        recorder: recorder,
        pollInterval: const Duration(minutes: 1), // never auto-ticks in-test
      );
      await ctl.start();

      // Drive the recorder so the summary has a non-trivial state, then
      // force exactly one emit tick.
      final t = DateTime.now();
      ctl.debugInjectSample(
        speedKmh: 50,
        rpm: 2200,
        at: t,
        fuelRateLPerHour: 6.0,
      );
      recorder.buildSummaryCalls = 0; // ignore start-path / inject reads
      ctl.debugEmitNow();

      expect(recorder.buildSummaryCalls, 1,
          reason: '_emit must allocate exactly one TripSummary per tick — '
              'the cached `final summary` is reused for both the fuel-litres '
              'and the distance reads');

      await ctl.stop();
    });

    test('two emit ticks build the summary exactly twice (no per-call '
        'doubling)', () async {
      final recorder = _CountingRecorder();
      final service = Obd2Service(FakeObd2Transport(_elmOk()));
      await service.connect();

      final ctl = TripRecordingController(
        service: service,
        recorder: recorder,
        pollInterval: const Duration(minutes: 1),
      );
      await ctl.start();

      recorder.buildSummaryCalls = 0;
      ctl.debugEmitNow();
      ctl.debugEmitNow();

      expect(recorder.buildSummaryCalls, 2,
          reason: 'one summary per tick, deterministically');

      await ctl.stop();
    });
  });
}
