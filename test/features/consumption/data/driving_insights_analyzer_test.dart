import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/driving_insights_analyzer.dart';
import 'package:tankstellen/features/consumption/domain/driving_insight.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';

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
}
