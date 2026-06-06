// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/driving_insights_analyzer.dart';
import 'package:tankstellen/features/consumption/domain/driving_insight.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/trip_detail_charts.dart';

/// Pure-logic tests for the driving-insights analyzer (#1041 phase 1).
///
/// The analyzer turns a stream of [TripSample]s into the "Top-3 cost
/// lines" surfaced on the trip Insights tab. Tests cover the noise
/// floor, sort order, top-N cap, and the three phase-1 categories
/// (high RPM, hard accel, idling).
void main() {
  group('analyzeTrip (#1041 phase 1)', () {
    final start = DateTime.utc(2026);

    test('empty samples → empty list', () {
      expect(analyzeTrip(const []), isEmpty);
    });

    test('single sample → empty list (no Δt to integrate)', () {
      final samples = [
        TripSample(timestamp: start, speedKmh: 0, rpm: 800),
      ];
      expect(analyzeTrip(samples), isEmpty);
    });

    test('pure idle trip → idling insight only', () {
      // 20 minutes idling: speed=0, rpm=800 throughout. At the default
      // 0.6 L/h idle rate that's 0.2 L wasted, well above the 0.05 L
      // noise floor.
      final samples = <TripSample>[];
      for (var i = 0; i <= 20; i++) {
        samples.add(TripSample(
          timestamp: start.add(Duration(minutes: i)),
          speedKmh: 0,
          rpm: 800,
        ));
      }

      final insights = analyzeTrip(samples);
      expect(insights, hasLength(1));
      expect(insights.single.labelKey, 'insightIdling');
      expect(insights.single.litersWasted, closeTo(0.2, 0.01));
      expect(insights.single.percentOfTrip, closeTo(100.0, 0.5));
      expect(insights.single.metadata['idleSeconds'], closeTo(1200, 1));
    });

    test(
        'mixed trip with high-RPM segment → high-rpm insight ranked first, '
        'idling second', () {
      // Build a trip:
      //   0-300s: cruising at 80 km/h, rpm=4000, fuelRate=12 L/h
      //           (high-rpm window).
      //   300-1200s: idling — speed=0, rpm=800 (15 minutes).
      //
      // Each interval attributes the whole Δt to the START sample
      // (matches TripRecorder convention). So:
      //   i=1: prev = (0s, rpm=4000)        → 300s of high-RPM
      //                                       waste = (12 − 12*0.6) × 300/3600 = 0.4 L
      //   i=2: prev = (300s, rpm=4000)      → 900s of high-RPM
      //                                       no fuelRate on either side this step,
      //                                       but cur sample at 1200s has none
      //                                       either, and prev (300s) has 12 L/h
      //                                       → adds (12−12*0.6) × 900/3600 = 1.2 L
      //   i=3: prev = (1200s, speed=0)      → idle 0..0 (no-op)
      // Wait — i=2 prev is the SECOND sample (still rpm=4000,
      // fuelRate=12). High-RPM accumulator runs for 900 more seconds.
      // Total high-RPM = 0.4 + 1.2 = 1.6 L over 1200s.
      // Idle:
      //   i=3: prev = (1200s, speed=0, rpm=800) → idle for 0s (no
      //                                            following sample)
      // We need an extra idle sample so the integrator sees a non-zero
      // dt with prev=idle.
      final samples = <TripSample>[
        TripSample(
          timestamp: start,
          speedKmh: 80,
          rpm: 4000,
          fuelRateLPerHour: 12,
        ),
        TripSample(
          timestamp: start.add(const Duration(seconds: 300)),
          speedKmh: 80,
          rpm: 4000,
          fuelRateLPerHour: 12,
        ),
        TripSample(
          timestamp: start.add(const Duration(seconds: 1200)),
          speedKmh: 0,
          rpm: 800,
        ),
        TripSample(
          timestamp: start.add(const Duration(seconds: 2400)),
          speedKmh: 0,
          rpm: 800,
        ),
      ];

      final insights = analyzeTrip(samples);
      expect(insights.length, greaterThanOrEqualTo(2));
      // High-RPM waste dominates (~1.6 L), idle is ~0.2 L (1200s ×
      // 0.6 L/h ÷ 3600). Insights are sorted descending.
      expect(insights.first.labelKey, 'insightHighRpm');
      expect(insights.first.litersWasted, greaterThan(0.5));
      // Idle insight is ranked after high-RPM; verify it's present.
      final keys = insights.map((i) => i.labelKey).toList();
      expect(keys.indexOf('insightIdling'),
          greaterThan(keys.indexOf('insightHighRpm')));
      // Confirm descending order.
      for (var i = 1; i < insights.length; i++) {
        expect(
          insights[i - 1].litersWasted,
          greaterThanOrEqualTo(insights[i].litersWasted),
        );
      }
    });

    test('5 hard-accel events → hard-accel insight present', () {
      // 5 strong accelerations: 0 → 50 km/h in 2 s each (≈ 6.94 m/s²,
      // well above the 3.0 m/s² threshold). Separated by 10 s of
      // cruising at 50 km/h to avoid retriggering. Each event adds
      // 0.05 L → 0.25 L total, above the 0.05 L noise floor.
      var t = start;
      final samples = <TripSample>[];
      for (var i = 0; i < 5; i++) {
        samples.add(TripSample(timestamp: t, speedKmh: 0, rpm: 1000));
        t = t.add(const Duration(seconds: 2));
        samples.add(TripSample(timestamp: t, speedKmh: 50, rpm: 3000));
        t = t.add(const Duration(seconds: 10));
        samples.add(TripSample(timestamp: t, speedKmh: 50, rpm: 2000));
        t = t.add(const Duration(seconds: 1));
      }

      final insights = analyzeTrip(samples);
      final hardAccel = insights.firstWhere(
        (i) => i.labelKey == 'insightHardAccel',
        orElse: () => throw StateError('expected hardAccel insight'),
      );
      expect(hardAccel.metadata['eventCount'], 5);
      expect(hardAccel.litersWasted, closeTo(0.25, 0.001));
    });

    test('a SINGLE hard-accel event no longer fires the lesson (#2963)', () {
      // One sustained acceleration: 0 → 50 km/h in 2 s (≈ 6.94 m/s², over
      // the 3.0 threshold, sustained ≥ 1 s). One event × 0.05 L exactly
      // equals the 0.05 L noise floor — on the old `>=` it cleared and
      // rendered "0.1 L" (a 2× overstatement of a single near-zero event).
      // The `>` gate now drops it.
      final samples = <TripSample>[
        TripSample(timestamp: start, speedKmh: 0, rpm: 1000),
        TripSample(
            timestamp: start.add(const Duration(seconds: 2)),
            speedKmh: 50,
            rpm: 3000),
        TripSample(
            timestamp: start.add(const Duration(seconds: 12)),
            speedKmh: 50,
            rpm: 2000),
      ];
      final insights = analyzeTrip(samples);
      expect(
        insights.where((i) => i.labelKey == 'insightHardAccel'),
        isEmpty,
        reason: 'a single 0.05 L event must not clear the noise floor by '
            'equality and surface as "0.1 L"',
      );
    });

    test('all-below-noise-floor trip → empty list', () {
      // 10s of low-RPM, gentle cruising — nothing trips a category.
      final samples = <TripSample>[
        TripSample(
          timestamp: start,
          speedKmh: 50,
          rpm: 2000,
          fuelRateLPerHour: 5,
        ),
        TripSample(
          timestamp: start.add(const Duration(seconds: 5)),
          speedKmh: 51,
          rpm: 2000,
          fuelRateLPerHour: 5,
        ),
        TripSample(
          timestamp: start.add(const Duration(seconds: 10)),
          speedKmh: 50,
          rpm: 2000,
          fuelRateLPerHour: 5,
        ),
      ];
      expect(analyzeTrip(samples), isEmpty);
    });

    test('top-3 cap respected when all 3 categories trigger', () {
      // Construct a trip that triggers all three categories above the
      // noise floor. The top-3 cap means the result is exactly the 3
      // categories — but if more were ever added, the cap stays at 3.
      //
      // Segment A — 0..600s: 80 km/h, rpm=4000, fuelRate=12 L/h
      //   → high-RPM waste = 0.8 L
      // Segment B — 600..602s: 0 → 50 km/h (hard accel event #1)
      // Segment C — 602..612s: 50 km/h, rpm=2500
      // Segment D — 612..614s: 0 → 50 km/h (hard accel event #2 — needs
      //   a fresh "stopped" sample to retrigger).
      // Segment E — 1200..1500s: idling (300s × 0.6 L/h = 0.05 L).
      final t = start;
      final samples = <TripSample>[
        TripSample(
          timestamp: t,
          speedKmh: 80,
          rpm: 4000,
          fuelRateLPerHour: 12,
        ),
        TripSample(
          timestamp: t.add(const Duration(seconds: 600)),
          speedKmh: 80,
          rpm: 4000,
          fuelRateLPerHour: 12,
        ),
        // Hard accel #1.
        TripSample(
          timestamp: t.add(const Duration(seconds: 600)),
          speedKmh: 0,
          rpm: 1000,
        ),
        TripSample(
          timestamp: t.add(const Duration(seconds: 602)),
          speedKmh: 50,
          rpm: 3000,
        ),
        // Stopped again.
        TripSample(
          timestamp: t.add(const Duration(seconds: 612)),
          speedKmh: 0,
          rpm: 1000,
        ),
        // Hard accel #2.
        TripSample(
          timestamp: t.add(const Duration(seconds: 614)),
          speedKmh: 50,
          rpm: 3000,
        ),
        // Idling segment — 1200s at 0 km/h, rpm=800
        // → 1200s × 0.6 L/h ÷ 3600 = 0.2 L well above noise floor.
        TripSample(
          timestamp: t.add(const Duration(seconds: 1200)),
          speedKmh: 0,
          rpm: 800,
        ),
        TripSample(
          timestamp: t.add(const Duration(seconds: 2400)),
          speedKmh: 0,
          rpm: 800,
        ),
      ];

      final insights = analyzeTrip(samples);
      expect(insights.length, lessThanOrEqualTo(3));
      final keys = insights.map((i) => i.labelKey).toSet();
      expect(keys, containsAll(<String>{
        'insightHighRpm',
        'insightHardAccel',
        'insightIdling',
      }));
      // High-RPM should rank first (largest waste).
      expect(insights.first.labelKey, 'insightHighRpm');
      // Sorted descending.
      for (var i = 1; i < insights.length; i++) {
        expect(
          insights[i - 1].litersWasted,
          greaterThanOrEqualTo(insights[i].litersWasted),
        );
      }
    });

    test('out-of-order samples are sorted before integration', () {
      // Same as the pure-idle case but with the middle sample shoved
      // to the end of the list. The analyzer must still produce the
      // idling insight.
      final samples = <TripSample>[
        TripSample(timestamp: start, speedKmh: 0, rpm: 800),
        TripSample(
          timestamp: start.add(const Duration(minutes: 20)),
          speedKmh: 0,
          rpm: 800,
        ),
        TripSample(
          timestamp: start.add(const Duration(minutes: 10)),
          speedKmh: 0,
          rpm: 800,
        ),
      ];
      final insights = analyzeTrip(samples);
      expect(insights, hasLength(1));
      expect(insights.single.labelKey, 'insightIdling');
    });

    test('high-RPM with no fuel-rate samples falls back to synthetic baseline',
        () {
      // 600s above 3000 RPM but no fuelRateLPerHour readings.
      // Synthetic baseline: 6 L/h × (1 - 0.6) × 600/3600 = 0.4 L.
      final samples = <TripSample>[
        TripSample(timestamp: start, speedKmh: 80, rpm: 4000),
        TripSample(
          timestamp: start.add(const Duration(seconds: 600)),
          speedKmh: 80,
          rpm: 4000,
        ),
      ];
      final insights = analyzeTrip(samples);
      expect(insights, hasLength(1));
      expect(insights.single.labelKey, 'insightHighRpm');
      expect(insights.single.litersWasted, closeTo(0.4, 0.05));
    });

    test('DrivingInsight equality and hashCode work as value-objects', () {
      const a = DrivingInsight(
        labelKey: 'insightIdling',
        litersWasted: 0.2,
        percentOfTrip: 100.0,
        metadata: {'idleSeconds': 1200, 'pctTime': 100.0},
      );
      const b = DrivingInsight(
        labelKey: 'insightIdling',
        litersWasted: 0.2,
        percentOfTrip: 100.0,
        metadata: {'idleSeconds': 1200, 'pctTime': 100.0},
      );
      const c = DrivingInsight(
        labelKey: 'insightIdling',
        litersWasted: 0.3,
        percentOfTrip: 100.0,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(c)));
    });
  });

  group('hardAccelSampleIndices (#1458 phase 1)', () {
    final start = DateTime.utc(2026);

    TripDetailSample sample({
      required int sec,
      required double speedKmh,
    }) =>
        TripDetailSample(
          timestamp: start.add(Duration(seconds: sec)),
          speedKmh: speedKmh,
        );

    test('empty samples → empty list', () {
      expect(hardAccelSampleIndices(const []), isEmpty);
    });

    test('single sample → empty list (no Δt to derive accel)', () {
      expect(
        hardAccelSampleIndices([sample(sec: 0, speedKmh: 0)]),
        isEmpty,
      );
    });

    test('two samples at constant speed → no events', () {
      final samples = [
        sample(sec: 0, speedKmh: 50),
        sample(sec: 1, speedKmh: 50),
      ];
      expect(hardAccelSampleIndices(samples), isEmpty);
    });

    test('two samples crossing the threshold → index 1 reported', () {
      // 0 → 50 km/h in 2 s: dv = 50/3.6 ≈ 13.89 m/s, accel ≈ 6.94 m/s²,
      // well above the 3.0 m/s² threshold.
      final samples = [
        sample(sec: 0, speedKmh: 0),
        sample(sec: 2, speedKmh: 50),
      ];
      expect(hardAccelSampleIndices(samples), [1]);
    });

    test(
        'five samples with one accel event in the middle → only that index '
        'is reported', () {
      // Indices and segments (#2895 — the middle event is a PLAUSIBLE hard
      // accel, ≤ the ~0.9 g physical ceiling, so the clamp leaves it):
      //   0 → 1: 30 → 32 km/h over 1 s → accel ≈ 0.56 m/s² (below).
      //   1 → 2: 32 → 60 km/h over 1 s → accel ≈ 7.78 m/s² ≈ 0.79 g (above
      //          threshold, below the ceiling — a real hard launch).
      //   2 → 3: 60 → 62 km/h over 1 s → accel ≈ 0.56 m/s² (below).
      //   3 → 4: 62 → 60 km/h over 1 s → DECEL (negative, ignored).
      // Only index 2 (the end of the middle interval) trips the
      // threshold.
      final samples = [
        sample(sec: 0, speedKmh: 30),
        sample(sec: 1, speedKmh: 32),
        sample(sec: 2, speedKmh: 60),
        sample(sec: 3, speedKmh: 62),
        sample(sec: 4, speedKmh: 60),
      ];
      expect(hardAccelSampleIndices(samples), [2]);
    });

    test('intervals with dt == 0 are skipped (no spurious events)', () {
      // Duplicate timestamps at sec=1 — the second pair has a huge
      // speed delta but dt = 0, so the analyzer must NOT emit an event
      // there. The genuine accel between sec=1 and sec=3 still fires.
      final samples = [
        sample(sec: 0, speedKmh: 0),
        sample(sec: 1, speedKmh: 0),
        sample(sec: 1, speedKmh: 80), // dt = 0 — must be skipped
        sample(sec: 3, speedKmh: 80),
      ];
      // After internal sort by timestamp the dup-timestamp pair stays
      // adjacent; only the (1s, 0) → (1s, 80) interval has dt == 0 and
      // is skipped. The other intervals are below threshold.
      expect(hardAccelSampleIndices(samples), isEmpty);
    });

    test(
        'samples passed in reverse timestamp order are sorted internally '
        'before detection', () {
      // Same single-event setup as the two-sample test, but the caller
      // hands the samples in REVERSE order. The helper must sort
      // internally and still report the event at the post-sort index 1.
      final samples = [
        sample(sec: 2, speedKmh: 50),
        sample(sec: 0, speedKmh: 0),
      ];
      expect(hardAccelSampleIndices(samples), [1]);
    });

    test('caller is not mutated when samples arrive out of order', () {
      // Defensive contract — the helper must copy before sorting so
      // the caller's list keeps its original order. Mirrors the same
      // safety [analyzeTrip] provides.
      final original = [
        sample(sec: 2, speedKmh: 50),
        sample(sec: 0, speedKmh: 0),
      ];
      final snapshot = List<TripDetailSample>.from(original);
      hardAccelSampleIndices(original);
      expect(original, snapshot);
    });
  });

  group('full-throttle + λ-enrichment insights (#2461)', () {
    final start = DateTime.utc(2026);

    TripSample s(
      int minute, {
      double speedKmh = 80,
      double rpm = 2500,
      double? pedalPercent,
      double? throttlePercent,
      double? lambda,
      double? fuelRate,
    }) =>
        TripSample(
          timestamp: start.add(Duration(minutes: minute)),
          speedKmh: speedKmh,
          rpm: rpm,
          pedalPercent: pedalPercent,
          throttlePercent: throttlePercent,
          lambda: lambda,
          fuelRateLPerHour: fuelRate,
        );

    DrivingInsight? find(List<DrivingInsight> list, String key) {
      for (final i in list) {
        if (i.labelKey == key) return i;
      }
      return null;
    }

    test('full-throttle cost line surfaces from persisted pedal %', () {
      final samples = [
        for (var i = 0; i <= 10; i++)
          s(i, pedalPercent: 100, fuelRate: 16),
      ];
      final insight = find(analyzeTrip(samples), 'insightFullThrottle');
      expect(insight, isNotNull);
      expect(insight!.litersWasted, greaterThan(0));
    });

    test('full-throttle falls back to a synthetic rate without fuel data', () {
      final samples = [for (var i = 0; i <= 10; i++) s(i, pedalPercent: 95)];
      final insight = find(analyzeTrip(samples), 'insightFullThrottle');
      expect(insight, isNotNull);
    });

    test('no full-throttle line when pedal/throttle stay below 90 %', () {
      final samples = [for (var i = 0; i <= 10; i++) s(i, pedalPercent: 40)];
      expect(find(analyzeTrip(samples), 'insightFullThrottle'), isNull);
    });

    test('λ-enrichment cost line surfaces when commanded λ < 1', () {
      final samples = [
        for (var i = 0; i <= 10; i++)
          s(i, lambda: 0.85, fuelRate: 12),
      ];
      final insight = find(analyzeTrip(samples), 'insightLambdaEnrichment');
      expect(insight, isNotNull);
      expect(insight!.litersWasted, greaterThan(0));
    });

    test('no λ-enrichment line at stoichiometric λ == 1', () {
      final samples = [
        for (var i = 0; i <= 10; i++)
          s(i, lambda: 1.0, fuelRate: 12),
      ];
      expect(find(analyzeTrip(samples), 'insightLambdaEnrichment'), isNull);
    });
  });

  group('#2692 C4-G — GPS-only (rpm null) raises no rpm-based insight', () {
    final start = DateTime.utc(2026);

    DrivingInsight? find(List<DrivingInsight> list, String key) {
      for (final i in list) {
        if (i.labelKey == key) return i;
      }
      return null;
    }

    test(
        'a GPS-only stream (rpm null) at standstill + high speed yields '
        'NO high-RPM and NO idling insight', () {
      final samples = <TripSample>[
        for (var i = 0; i <= 60; i++)
          TripSample(
            timestamp: start.add(Duration(seconds: i)),
            speedKmh: i.isEven ? 0 : 60,
            rpm: null, // GPS-only — no engine signal
          ),
      ];
      final insights = analyzeTrip(samples);
      expect(find(insights, 'insightHighRpm'), isNull,
          reason: 'rpm null must never trip the high-RPM insight');
      expect(find(insights, 'insightIdling'), isNull,
          reason: 'rpm null must never be counted as an idling engine');
    });
  });

  group('#2693 C6 — climbing-fuel insight from confident grade', () {
    final start = DateTime.utc(2026);

    DrivingInsight? find(List<DrivingInsight> list, String key) {
      for (final i in list) {
        if (i.labelKey == key) return i;
      }
      return null;
    }

    List<TripSample> climb(double gradeFraction) {
      final samples = <TripSample>[];
      var altitude = 100.0;
      for (var i = 0; i < 40; i++) {
        samples.add(TripSample(
          timestamp: start.add(Duration(seconds: i * 3)),
          speedKmh: 36,
          rpm: 2200,
          altitudeM: altitude,
          fuelRateLPerHour: 10,
        ));
        altitude += 30.0 * gradeFraction;
      }
      return samples;
    }

    test('a confident ~6% climb surfaces an insightClimbingCost line', () {
      final insight = find(analyzeTrip(climb(0.06)), 'insightClimbingCost');
      expect(insight, isNotNull);
      expect(insight!.litersWasted, greaterThan(0));
      // The metadata carries the peak confident grade for the subtitle.
      final gradePct = insight.metadata['gradePercent']! as double;
      expect(gradePct, greaterThan(3.0));
      expect(gradePct, lessThan(7.0));
    });

    test('a flat trip raises NO climbing insight', () {
      expect(find(analyzeTrip(climb(0.0)), 'insightClimbingCost'), isNull);
    });
  });

  group('#2694 C8 — stop-and-go restart insight', () {
    final start = DateTime.utc(2026);

    DrivingInsight? find(List<DrivingInsight> list, String key) {
      for (final i in list) {
        if (i.labelKey == key) return i;
      }
      return null;
    }

    List<TripSample> stopGo(int restarts) {
      final samples = <TripSample>[];
      var t = start;
      for (var r = 0; r < restarts; r++) {
        for (var i = 0; i < 3; i++) {
          samples.add(TripSample(timestamp: t, speedKmh: 0, rpm: 800));
          t = t.add(const Duration(seconds: 1));
        }
        for (final v in [5.0, 15.0, 30.0]) {
          samples.add(TripSample(timestamp: t, speedKmh: v, rpm: 2500));
          t = t.add(const Duration(seconds: 1));
        }
      }
      return samples;
    }

    test('several restarts surface an insightRestartCost with the count', () {
      final insight = find(analyzeTrip(stopGo(3)), 'insightRestartCost');
      expect(insight, isNotNull);
      expect(insight!.metadata['restartCount'], 3);
      expect(insight.litersWasted, greaterThan(0));
    });

    test('a steady cruise (no stops) raises NO restart insight', () {
      final samples = <TripSample>[
        for (var i = 0; i <= 30; i++)
          TripSample(
            timestamp: start.add(Duration(seconds: i)),
            speedKmh: 80,
            rpm: 2000,
          ),
      ];
      expect(find(analyzeTrip(samples), 'insightRestartCost'), isNull);
    });
  });
}
