// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/degraded_gps_emitter.dart';
import 'package:tankstellen/features/consumption/data/obd2/trip_live_reading.dart';
import 'package:tankstellen/features/consumption/data/obd2/trip_sample_buffer.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';

/// #3029 — the `degradedGpsOnly` emit tick (OBD2 dropped mid-trip, GPS
/// alive) must feed its GPS samples to the recorder tagged
/// `distanceSource: kDistanceSourceGps`, so the recorder suppresses harsh
/// scoring on the noisy ~1 Hz Doppler ground speed. Before #3029 the
/// emitter called `recorder.onSample(sample)` with no source, leaving the
/// GPS-noise harsh detector ungated → phantom hard-accel/brake penalties
/// with no visible IMU source.
///
/// Asserted by OBSERVABLE behaviour (not a mock spy on the arg): drive the
/// emitter with a real [TripRecorder] over a noisy GPS speed stream that
/// over-counted on master, then assert the recorder's harsh counts are 0.
/// A missing/`real`/null source would leave them > 0.
void main() {
  group('DegradedGpsEmitter harsh-source tagging (#3029)', () {
    // A noisy ground-speed staircase: the kind of GPS Doppler bounce the
    // field report differentiated into impossible >1 g harsh events.
    const bounce = <double>[45, 60, 45, 30];

    DegradedGpsEmitter buildEmitter(
      TripRecorder recorder,
      DateTime Function() now,
    ) {
      return DegradedGpsEmitter(
        now: now,
        recorder: recorder,
        sampleBuffer: TripSampleBuffer(),
        gpsAliveWindow: const Duration(seconds: 30),
        onEscalate: () {},
        onSampleAt: (_) {},
        // Identity overlay — the test only cares about what reaches the
        // recorder, not the live-reading shaping.
        overlayEstimate: (reading, {
          required nowTs,
          required effectiveSpeedKmh,
          required altitudeM,
        }) =>
            reading,
      );
    }

    test(
        'noisy GPS stream through the degraded emitter → recorder harsh '
        'counts 0 (source tagged gps → suppressed)', () {
      final recorder = TripRecorder();
      final start = DateTime.utc(2026);
      var clock = start;
      final emitter = buildEmitter(recorder, () => clock);

      var latched = bounce[0];
      var stepIdx = 0;
      var lastStepSec = 0;
      for (var i = 0; i < 1200; i++) {
        clock = start.add(Duration(seconds: i));
        if (i - lastStepSec >= 6) {
          stepIdx++;
          latched = bounce[stepIdx % bounce.length];
          lastStepSec = i;
        }
        emitter.emitTick(
          latestGpsSpeedKmh: latched,
          latitude: 48.0,
          longitude: 2.0,
          altitudeM: 100,
          hAccuracyM: 5,
          bearingDeg: 90,
          // Keep GPS "alive" so the tick records instead of escalating.
          lastGpsFixAt: clock,
          startedAt: start,
          resolverDistanceKm: 0,
          odometerStartKm: null,
          odometerLatestKm: null,
        );
      }

      final summary = recorder.buildSummary();
      expect(summary.distanceKm, greaterThan(10), reason: 'sanity: ~15 km');
      expect(summary.harshBrakes, 0,
          reason: 'degraded GPS feed must be tagged gps → suppressed (#3029)');
      expect(summary.harshAccelerations, 0,
          reason: 'degraded GPS feed must be tagged gps → suppressed (#3029)');
    });

    test('emitTick returns a live reading on a fresh GPS fix (no throw)', () {
      // Smoke: the tagged onSample call still flows through to a published
      // reading — proves the source-tagging change did not break the tick.
      final recorder = TripRecorder();
      final start = DateTime.utc(2026);
      final emitter = buildEmitter(recorder, () => start);
      final TripLiveReading? reading = emitter.emitTick(
        latestGpsSpeedKmh: 50,
        latitude: 48.0,
        longitude: 2.0,
        altitudeM: 100,
        hAccuracyM: 5,
        bearingDeg: 90,
        lastGpsFixAt: start,
        startedAt: start,
        resolverDistanceKm: 0,
        odometerStartKm: null,
        odometerLatestKm: null,
      );
      expect(reading, isNotNull);
    });
  });
}
