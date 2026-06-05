// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sensors/imu_sample.dart';
import 'package:tankstellen/features/consumption/data/driving_insights_analyzer.dart';
import 'package:tankstellen/features/consumption/data/driving_score_calculator.dart';
import 'package:tankstellen/features/consumption/domain/accel_event_gate.dart';
import 'package:tankstellen/features/consumption/domain/gps_driving_features.dart';
import 'package:tankstellen/features/consumption/domain/harsh_event_detector.dart';
import 'package:tankstellen/features/consumption/domain/services/imu_event_detector.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';

/// #2895 — GPS-only driving score over-counts hard accelerations.
///
/// Concrete evidence (real export, Peugeot 107, gpsPlusObd2): the phone IMU
/// (accurate inertial reading) saw **0/0/0** hard accel/brake/corner, but the
/// GPS speed-derivative path manufactured **16** accel events with
/// **maxAccelG 1.086** — physically impossible for a 68 hp economy car — and
/// the score applied a 15-point hard-accel + 15-point hard-brake penalty plus
/// a "16 hard accelerations: wasted 0.8 L" lesson.
///
/// Two RED-on-master behaviours are fixed here:
///   (1) the GPS speed-derivative gate has NO physical-plausibility clamp, so
///       a ~1 g noise spike (impossible for a real car) counts as a hard
///       accel. The clamp rejects it at the source — score, insights, AND
///       GPS features.
///   (2) the IMU truth (0) could not VETO the GPS over-count: the override
///       only fired when the IMU count was non-zero, so a genuinely-smooth
///       trip's accurate inertial zero lost to the noisy GPS 16. The override
///       now keys off the sensor having RUN, so an IMU zero wins.
void main() {
  final t0 = DateTime.utc(2026, 6, 5, 9);

  /// A speed series (km/h) at a clean ~1 Hz cadence that the GPS
  /// speed-derivative differentiates into a SUSTAINED (≥ 1 s) physically
  /// IMPOSSIBLE acceleration spike — the shape the #2895 export produced:
  /// a ~1.1 g forward "acceleration" no 68 hp car can make. 30 → 70 → 110
  /// over two 1 s steps is +11.1 m/s² ≈ 1.13 g each (well past the ~0.9 g
  /// plausibility ceiling), held for 2 s so the sustained-window gate would
  /// otherwise confirm an event.
  List<AccelSamplePoint> impossibleAccelSpike() => [
        AccelSamplePoint(timestamp: t0, speedKmh: 30),
        AccelSamplePoint(
            timestamp: t0.add(const Duration(seconds: 1)), speedKmh: 70),
        AccelSamplePoint(
            timestamp: t0.add(const Duration(seconds: 2)), speedKmh: 110),
        // settle on a cruise so any episode would be confirmed + closed.
        for (var s = 3; s <= 8; s++)
          AccelSamplePoint(
              timestamp: t0.add(Duration(seconds: s)), speedKmh: 110),
      ];

  /// The same shape as [TripSample]s (rpm null → GPS-only / no-engine trip).
  List<TripSample> impossibleAccelTrip() => [
        for (final p in impossibleAccelSpike())
          TripSample(timestamp: p.timestamp, speedKmh: p.speedKmh, rpm: null),
      ];

  group('GPS plausibility clamp (#2895) — impossible spikes are not events', () {
    test('countAccelEvents: a ~1.1 g forward spike yields ZERO hard accels '
        '(RED on master: counted as a hard accel)', () {
      final counts = countAccelEvents(impossibleAccelSpike());
      expect(counts.accelEvents, 0,
          reason: 'a >0.61 g forward derivative is GPS noise, not a manoeuvre');
      expect(counts.brakeEvents, 0);
    });

    test('a genuine 0.71 g hard launch STILL counts (clamp does not clip a '
        'real hard acceleration the score already penalises)', () {
      // 0 → 50 km/h over 2 s = +6.94 m/s² ≈ 0.71 g — the exact "hard accel"
      // shape the existing score / GPS-feature fixtures use. It is under the
      // ~0.9 g ceiling, so the clamp must leave it untouched.
      final pts = <AccelSamplePoint>[
        AccelSamplePoint(timestamp: t0, speedKmh: 0),
        AccelSamplePoint(
            timestamp: t0.add(const Duration(seconds: 1)), speedKmh: 25),
        AccelSamplePoint(
            timestamp: t0.add(const Duration(seconds: 2)), speedKmh: 50),
        for (var s = 3; s <= 8; s++)
          AccelSamplePoint(
              timestamp: t0.add(Duration(seconds: s)), speedKmh: 50),
      ];
      final counts = countAccelEvents(pts);
      expect(counts.accelEvents, 1,
          reason: 'a real 0.71 g hard launch is preserved');
    });

    test('a genuine ~1.0 g emergency brake STILL counts (asymmetric ceiling — '
        'braking legitimately reaches ~1 g)', () {
      // 100 → 65 km/h over 1 s held → -9.7 m/s² ≈ 0.99 g, under the 1.12 g
      // brake ceiling, then a second 1 s step so the episode is sustained.
      final pts = <AccelSamplePoint>[
        AccelSamplePoint(timestamp: t0, speedKmh: 100),
        AccelSamplePoint(
            timestamp: t0.add(const Duration(seconds: 1)), speedKmh: 65),
        AccelSamplePoint(
            timestamp: t0.add(const Duration(seconds: 2)), speedKmh: 30),
        for (var s = 3; s <= 8; s++)
          AccelSamplePoint(
              timestamp: t0.add(Duration(seconds: s)), speedKmh: 30),
      ];
      final counts = countAccelEvents(pts);
      expect(counts.brakeEvents, 1, reason: 'a real ~1 g hard brake is kept');
    });

    test('an impossible >1.12 g brake spike is rejected as noise', () {
      // 110 → 40 over 1 s = -19.4 m/s² ≈ 1.98 g — impossible; must not count.
      final pts = <AccelSamplePoint>[
        AccelSamplePoint(timestamp: t0, speedKmh: 110),
        AccelSamplePoint(
            timestamp: t0.add(const Duration(seconds: 1)), speedKmh: 40),
        AccelSamplePoint(
            timestamp: t0.add(const Duration(seconds: 2)), speedKmh: 0),
        for (var s = 3; s <= 8; s++)
          AccelSamplePoint(
              timestamp: t0.add(Duration(seconds: s)), speedKmh: 0),
      ];
      final counts = countAccelEvents(pts);
      expect(counts.brakeEvents, 0);
    });
  });

  group('the clamp reaches every GPS-derived consumer (#2895)', () {
    test('GpsDrivingFeatures.from: impossible spike → 0 accel events', () {
      final f = GpsDrivingFeatures.from(impossibleAccelTrip())!;
      expect(f.accelEvents, 0);
    });

    test('HarshEventDetector (recorder source): impossible spike → 0 accels', () {
      final d = HarshEventDetector();
      for (final p in impossibleAccelSpike()) {
        d.onSample(p.speedKmh, p.timestamp);
      }
      expect(d.accelerations, 0,
          reason: 'the recorder harshAccelerations no longer counts the spike');
    });

    test('driving-insights analyzer: NO insightHardAccel lesson for the spike '
        '(RED on master: "N hard accelerations: wasted L")', () {
      final insights = analyzeTrip(impossibleAccelTrip());
      final hardAccel =
          insights.where((i) => i.labelKey == 'insightHardAccel').toList();
      expect(hardAccel, isEmpty,
          reason: 'no hard-accel cost line is built from GPS noise');
    });

    test('computeDrivingScore: impossible spike → no hard-accel penalty '
        '(RED on master: 15-point hard-accel penalty)', () {
      final score = computeDrivingScore(impossibleAccelTrip());
      expect(score.hardAccelPenalty, 0);
      expect(score.hardBrakePenalty, 0);
    });
  });

  group('IMU truth VETOES the GPS over-count (#2895)', () {
    test('ImuEventDetector.isActive is false before any real sample, true once '
        'the sensor has run', () {
      final det = ImuEventDetector();
      expect(det.isActive, isFalse, reason: 'no samples yet');
      // First sample only seeds the dt anchor.
      det.currentSpeedKmh = 50;
      det.onSample(ImuSample(
          t: t0, axMps2: 0, ayMps2: 0, azMps2: 0, gyroZRadPerSec: 0));
      expect(det.isActive, isFalse, reason: 'one stray emit is not "ran"');
      det.onSample(ImuSample(
          t: t0.add(const Duration(milliseconds: 20)),
          axMps2: 0,
          ayMps2: 0,
          azMps2: 0,
          gyroZRadPerSec: 0));
      expect(det.isActive, isTrue, reason: 'the sensor produced a usable signal');
    });

    test('an IMU ZERO overrides a GPS-derived count to zero penalty — the '
        'override fires on a genuine zero (RED on master: zero never won)', () {
      // A GPS-derived count that DOES clear the (plausible) gate — e.g. a real
      // moderate accel the speed path saw but the IMU, with its direct reading,
      // judged smooth. Without the fix the score takes the GPS count; with it,
      // the IMU-active zero wins.
      final samples = <TripSample>[
        TripSample(timestamp: t0, speedKmh: 0, rpm: null),
        TripSample(
            timestamp: t0.add(const Duration(seconds: 1)),
            speedKmh: 18,
            rpm: null),
        TripSample(
            timestamp: t0.add(const Duration(seconds: 2)),
            speedKmh: 36,
            rpm: null),
        for (var s = 3; s <= 8; s++)
          TripSample(
              timestamp: t0.add(Duration(seconds: s)),
              speedKmh: 36,
              rpm: null),
      ];
      // Sanity: the GPS gate alone WOULD count this as one hard accel.
      expect(
        countAccelEvents([
          for (final s in samples)
            AccelSamplePoint(timestamp: s.timestamp, speedKmh: s.speedKmh),
        ]).accelEvents,
        1,
      );
      // The trip-detail recompute threads the pipeline's IMU-resolved zero as
      // the override (what `imuActive` gates on the summary).
      final score = computeDrivingScore(
        samples,
        hardAccelEventsOverride: 0,
        hardBrakeEventsOverride: 0,
      );
      expect(score.hardAccelPenalty, 0,
          reason: 'an active-IMU zero vetoes the GPS-derived count');
    });
  });
}
