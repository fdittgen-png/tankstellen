// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/driving_insights_analyzer.dart';
import 'package:tankstellen/features/consumption/data/driving_score_calculator.dart';
import 'package:tankstellen/features/consumption/domain/accel_event_gate.dart';
import 'package:tankstellen/features/consumption/domain/gps_driving_features.dart';
import 'package:tankstellen/features/consumption/domain/harsh_event_detector.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';

/// Reconciliation tests for Fix D / Epic #2647 C3 / #2667.
///
/// Before this change THREE independent accel-event detectors disagreed
/// on the count for the same physical event:
///   (a) [HarshEventDetector] — canonical 3.0/3.5 m/s² + the #2653
///       sustained-window + accuracy + min-speed gate.
///   (b) [GpsDrivingFeatures.from] — a *2.0 m/s²* threshold (no canonical
///       constant, no accuracy / min-speed gate).
///   (c) [analyzeTrip] / [hardAccelSampleIndices] — a *raw* dvMps/dt at
///       3.0 m/s² with NO sustained window at all.
///
/// They now route through ONE shared evaluator ([countAccelEvents]) keyed
/// off the ONE canonical [kHardAccelThresholdMps2] /
/// [kHardBrakeThresholdMps2], so a given physical event yields the SAME
/// count across the score, the insights, and the GPS features.
void main() {
  final t0 = DateTime.utc(2026, 6, 1, 9);

  /// A speed series (km/h) with KNOWN true accel/brake events at a clean
  /// ~1 Hz cadence, chosen so every event is a genuine sustained (≥ 1 s),
  /// above-min-speed crossing of the canonical thresholds — i.e. exactly
  /// the regime in which all three detectors are designed to agree.
  ///
  /// Two distinct hard accelerations and two distinct hard brakes, each
  /// separated by a calm cruise plateau so the duration-accumulator
  /// re-arms between them:
  ///   • t 0→2 s: 0 → 40 km/h  (+5.56 m/s², hard accel #1)
  ///   • t 2→7 s: cruise 40
  ///   • t 7→9 s: 40 → 80 km/h (+5.56 m/s², hard accel #2)
  ///   • t 9→14 s: cruise 80
  ///   • t 14→16 s: 80 → 40 km/h (-5.56 m/s², hard brake #1)
  ///   • t 16→21 s: cruise 40
  ///   • t 21→23 s: 40 → 0 km/h (-5.56 m/s², hard brake #2)
  List<({DateTime t, double speedKmh})> knownSeries() {
    final pts = <({DateTime t, double speedKmh})>[];
    void add(int sec, double v) =>
        pts.add((t: t0.add(Duration(seconds: sec)), speedKmh: v));
    // accel #1: 0 → 40 over 2 s, sampled each second.
    add(0, 0);
    add(1, 20);
    add(2, 40);
    // cruise
    for (var s = 3; s <= 7; s++) {
      add(s, 40);
    }
    // accel #2: 40 → 80 over 2 s
    add(8, 60);
    add(9, 80);
    // cruise
    for (var s = 10; s <= 14; s++) {
      add(s, 80);
    }
    // brake #1: 80 → 40 over 2 s
    add(15, 60);
    add(16, 40);
    // cruise
    for (var s = 17; s <= 21; s++) {
      add(s, 40);
    }
    // brake #2: 40 → 0 over 2 s
    add(22, 20);
    add(23, 0);
    return pts;
  }

  // -- expected ground truth for the fixture ------------------------------
  const expectedAccels = 2;
  const expectedBrakes = 2;

  group('the 3 detectors agree on the count (RED on master) — #2667', () {
    final series = knownSeries();

    /// Map the fixture to [TripSample]s for the score / insights / harsh
    /// paths (rpm is irrelevant to the accel detector).
    List<TripSample> tripSamples() => [
          for (final p in series)
            TripSample(timestamp: p.t, speedKmh: p.speedKmh, rpm: 1500),
        ];

    test('shared evaluator counts the known events', () {
      final counts = countAccelEvents([
        for (final p in series)
          AccelSamplePoint(timestamp: p.t, speedKmh: p.speedKmh),
      ]);
      expect(counts.accelEvents, expectedAccels);
      expect(counts.brakeEvents, expectedBrakes);
    });

    test('HarshEventDetector path agrees', () {
      final d = HarshEventDetector();
      for (final p in series) {
        d.onSample(p.speedKmh, p.t);
      }
      expect(d.accelerations, expectedAccels);
      expect(d.brakes, expectedBrakes);
    });

    test('GpsDrivingFeatures path agrees', () {
      final f = GpsDrivingFeatures.from(tripSamples())!;
      expect(f.accelEvents, expectedAccels);
      expect(f.brakeEvents, expectedBrakes);
    });

    test('driving-insights analyzer path agrees on the accel count', () {
      final samples = tripSamples();
      final counts = countAccelEvents([
        for (final p in series)
          AccelSamplePoint(timestamp: p.t, speedKmh: p.speedKmh),
      ]);
      // The analyzer surfaces its hard-accel count in the insight
      // metadata; it must equal the shared evaluator's accel count.
      final insights = analyzeTrip(samples);
      final hardAccel =
          insights.where((i) => i.labelKey == 'insightHardAccel').toList();
      expect(hardAccel, hasLength(1));
      expect(hardAccel.single.metadata['eventCount'], counts.accelEvents);
      expect(counts.accelEvents, expectedAccels);
    });

    test('all three paths report the SAME accel + brake count', () {
      final samples = tripSamples();

      final d = HarshEventDetector();
      for (final p in series) {
        d.onSample(p.speedKmh, p.t);
      }

      final f = GpsDrivingFeatures.from(samples)!;

      final insights = analyzeTrip(samples);
      final analyzerAccels = insights
              .where((i) => i.labelKey == 'insightHardAccel')
              .map((i) => i.metadata['eventCount'] as int)
              .fold<int>(0, (a, b) => a + b);

      // accel: harsh-detector == gps-features == analyzer.
      expect(d.accelerations, f.accelEvents);
      expect(f.accelEvents, analyzerAccels);
      // brake: harsh-detector == gps-features (analyzer surfaces accel
      // only, by its existing contract).
      expect(d.brakes, f.brakeEvents);
    });
  });

  group('canonical constants are the single source — #2667', () {
    test('the shared gate re-exports the score calculator constants', () {
      // The accel-event gate and the score calculator MUST be the same
      // numbers — that is the whole point of the reconciliation.
      expect(kHardAccelThresholdMps2, 3.0);
      expect(kHardBrakeThresholdMps2, 3.5);
    });

    test('a 2.0 m/s² ramp is NOT an event under the canonical 3.0 threshold',
        () {
      // The old gps_driving_features fired at 2.0 m/s²; under the
      // canonical 3.0 it must not. 0 → 36 km/h over 5 s = exactly
      // 2.0 m/s² — below 3.0.
      final pts = <AccelSamplePoint>[];
      for (var i = 0; i <= 5; i++) {
        pts.add(AccelSamplePoint(
          timestamp: t0.add(Duration(seconds: i)),
          speedKmh: i * 36.0 / 5,
        ));
      }
      for (var i = 1; i <= 5; i++) {
        pts.add(AccelSamplePoint(
          timestamp: t0.add(Duration(seconds: 5 + i)),
          speedKmh: 36.0,
        ));
      }
      final counts = countAccelEvents(pts);
      expect(counts.accelEvents, 0);
    });

    test('a sub-1 s spike is debounced by the shared sustained window', () {
      // A single 0.5 s bump must not fire — the sustained-window gate is
      // shared, so the analyzer no longer counts raw single-interval
      // spikes the way it used to.
      final pts = <AccelSamplePoint>[
        AccelSamplePoint(timestamp: t0, speedKmh: 50),
        AccelSamplePoint(
            timestamp: t0.add(const Duration(milliseconds: 500)),
            speedKmh: 75),
        AccelSamplePoint(
            timestamp: t0.add(const Duration(milliseconds: 1000)),
            speedKmh: 50),
        AccelSamplePoint(
            timestamp: t0.add(const Duration(seconds: 2)), speedKmh: 50),
      ];
      final counts = countAccelEvents(pts);
      expect(counts.accelEvents, 0);
      expect(counts.brakeEvents, 0);
    });

    test('a bad-fix (> gate) interval is dropped from the shared count', () {
      // A jittery 25 m fix in the middle of an otherwise-hard accel must
      // not contribute — the accuracy gate is shared with the detector.
      final pts = <AccelSamplePoint>[
        AccelSamplePoint(timestamp: t0, speedKmh: 0, hAccuracyM: 4),
        AccelSamplePoint(
            timestamp: t0.add(const Duration(seconds: 1)),
            speedKmh: 20,
            hAccuracyM: 4),
        AccelSamplePoint(
            timestamp: t0.add(const Duration(seconds: 2)),
            speedKmh: 40,
            hAccuracyM: 25), // bad fix breaks the anchor
        AccelSamplePoint(
            timestamp: t0.add(const Duration(seconds: 3)),
            speedKmh: 40,
            hAccuracyM: 4),
      ];
      final counts = countAccelEvents(pts);
      // With the bad fix gated, the only clean ≥1 s accel window is
      // 0 → 20 km/h over 1 s = 5.56 m/s² — one event.
      expect(counts.accelEvents, 1);
    });
  });
}
