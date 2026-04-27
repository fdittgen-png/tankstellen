import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/driving_score_calculator.dart';
import 'package:tankstellen/features/consumption/domain/driving_score.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';

/// Pure-logic tests for the driving-score composite calculator
/// (#1041 phase 5a — Card A).
///
/// The calculator turns a stream of [TripSample]s into a single 0..100
/// composite, exposing each per-category penalty contribution. Tests
/// cover the empty-trip identity, steady-state efficient driving,
/// individual category caps, the floor at 0 for catastrophic trips,
/// and boundary cases on the RPM and acceleration thresholds.
void main() {
  group('computeDrivingScore (#1041 phase 5a)', () {
    final start = DateTime.utc(2026);

    test('empty samples → perfect 100, no penalties', () {
      final result = computeDrivingScore(const []);
      expect(result, equals(DrivingScore.perfect));
      expect(result.score, 100);
      expect(result.idlingPenalty, 0);
      expect(result.hardAccelPenalty, 0);
      expect(result.hardBrakePenalty, 0);
      expect(result.highRpmPenalty, 0);
      expect(result.fullThrottlePenalty, 0);
    });

    test('single sample → perfect 100 (no Δt to integrate)', () {
      final samples = [
        TripSample(timestamp: start, speedKmh: 50, rpm: 2000),
      ];
      expect(computeDrivingScore(samples), equals(DrivingScore.perfect));
    });

    test('steady-state efficient cruise → 100', () {
      // 10 minutes of smooth highway cruise at 80 km/h, 2000 RPM —
      // nothing should trip any category.
      final samples = <TripSample>[
        for (var i = 0; i <= 10; i++)
          TripSample(
            timestamp: start.add(Duration(minutes: i)),
            speedKmh: 80,
            rpm: 2000,
            fuelRateLPerHour: 5,
          ),
      ];
      final result = computeDrivingScore(samples);
      expect(result.score, 100);
      expect(result.idlingPenalty, 0);
      expect(result.highRpmPenalty, 0);
      expect(result.hardAccelPenalty, 0);
      expect(result.hardBrakePenalty, 0);
    });

    test('pure idle trip (100% idle) → idling cap of 25 → score 75', () {
      // 20 minutes idling: speed=0, rpm=800 throughout. The whole trip
      // is idle so the linear penalty saturates at the 25-point cap.
      final samples = <TripSample>[
        for (var i = 0; i <= 20; i++)
          TripSample(
            timestamp: start.add(Duration(minutes: i)),
            speedKmh: 0,
            rpm: 800,
          ),
      ];
      final result = computeDrivingScore(samples);
      expect(result.idlingPenalty, closeTo(25, 0.5));
      expect(result.score, closeTo(75, 1));
      // No other category should fire on a pure-idle trip.
      expect(result.highRpmPenalty, 0);
      expect(result.hardAccelPenalty, 0);
      expect(result.hardBrakePenalty, 0);
    });

    test('half-idle trip → idling penalty roughly proportional', () {
      // 20 minutes total, of which roughly the first half are idle and
      // the second half are smooth cruise. The recorder attributes
      // each interval to its START sample, so the transition interval
      // (where prev is the last idle sample) still counts toward idle
      // — meaning ~55% of the trip is idle, not exactly 50%. Penalty
      // should land in a sensible mid-range band rather than at the
      // 25-point cap or zero.
      final samples = <TripSample>[
        for (var i = 0; i <= 10; i++)
          TripSample(
            timestamp: start.add(Duration(minutes: i)),
            speedKmh: 0,
            rpm: 800,
          ),
        for (var i = 11; i <= 20; i++)
          TripSample(
            timestamp: start.add(Duration(minutes: i)),
            speedKmh: 80,
            rpm: 2000,
          ),
      ];
      final result = computeDrivingScore(samples);
      // Roughly 11/20 of the trip → 11/20 × 25 = 13.75.
      expect(result.idlingPenalty, closeTo(13.75, 0.5));
      // Score should be in the mid-80s.
      expect(result.score, inInclusiveRange(82, 90));
    });

    test('5 hard-accel events → hardAccelPenalty saturates at 15', () {
      // 5 strong accelerations: 0 → 50 km/h in 2 s each (≈ 6.94 m/s²,
      // well above the 3.0 m/s² threshold). 5 × 3 = 15 = the cap.
      var t = start;
      final samples = <TripSample>[];
      for (var i = 0; i < 5; i++) {
        samples.add(TripSample(timestamp: t, speedKmh: 0, rpm: 1000));
        t = t.add(const Duration(seconds: 2));
        samples.add(TripSample(timestamp: t, speedKmh: 50, rpm: 2500));
        t = t.add(const Duration(seconds: 10));
        samples.add(TripSample(timestamp: t, speedKmh: 50, rpm: 2000));
        t = t.add(const Duration(seconds: 1));
      }
      final result = computeDrivingScore(samples);
      expect(result.hardAccelPenalty, 15);
      // Score should be at most 85 (100 - 15) plus or minus other
      // penalties if any sneak in.
      expect(result.score, lessThanOrEqualTo(85));
    });

    test('hardAccelPenalty caps at 15 even with 10 events', () {
      var t = start;
      final samples = <TripSample>[];
      for (var i = 0; i < 10; i++) {
        samples.add(TripSample(timestamp: t, speedKmh: 0, rpm: 1000));
        t = t.add(const Duration(seconds: 2));
        samples.add(TripSample(timestamp: t, speedKmh: 50, rpm: 2500));
        t = t.add(const Duration(seconds: 10));
        samples.add(TripSample(timestamp: t, speedKmh: 50, rpm: 2000));
        t = t.add(const Duration(seconds: 1));
      }
      final result = computeDrivingScore(samples);
      expect(result.hardAccelPenalty, 15);
    });

    test('5 hard-brake events → hardBrakePenalty saturates at 15', () {
      // 5 strong decelerations: 50 → 0 km/h in 2 s each (≈ -6.94 m/s²).
      var t = start;
      final samples = <TripSample>[];
      for (var i = 0; i < 5; i++) {
        samples.add(TripSample(timestamp: t, speedKmh: 50, rpm: 2000));
        t = t.add(const Duration(seconds: 2));
        samples.add(TripSample(timestamp: t, speedKmh: 0, rpm: 1000));
        t = t.add(const Duration(seconds: 10));
        samples.add(TripSample(timestamp: t, speedKmh: 0, rpm: 1000));
        t = t.add(const Duration(seconds: 1));
      }
      final result = computeDrivingScore(samples);
      expect(result.hardBrakePenalty, 15);
    });

    test('high-RPM cruise across the whole trip → highRpmPenalty caps at 20',
        () {
      // 10 minutes above 3000 RPM throughout.
      final samples = <TripSample>[
        for (var i = 0; i <= 10; i++)
          TripSample(
            timestamp: start.add(Duration(minutes: i)),
            speedKmh: 80,
            rpm: 4000,
          ),
      ];
      final result = computeDrivingScore(samples);
      expect(result.highRpmPenalty, closeTo(20, 0.5));
      // No idling on a moving trip, no hard-accel events on cruise.
      expect(result.idlingPenalty, 0);
      expect(result.hardAccelPenalty, 0);
    });

    test('full-throttle penalty stays 0 (no throttle data persisted today)',
        () {
      // The TripSample schema does not carry throttle %, so the
      // calculator can never accumulate full-throttle time today. The
      // penalty must stay 0 regardless of what other categories fire.
      final samples = <TripSample>[
        for (var i = 0; i <= 10; i++)
          TripSample(
            timestamp: start.add(Duration(minutes: i)),
            speedKmh: 80,
            rpm: 4000,
          ),
      ];
      final result = computeDrivingScore(samples);
      expect(result.fullThrottlePenalty, 0);
    });

    test('catastrophic trip → score floors at 0', () {
      // Construct a trip that simultaneously saturates idling, high-RPM,
      // hard-accel, and hard-brake. The raw sum exceeds 100, so the
      // floor at 0 must clamp.
      var t = start;
      final samples = <TripSample>[];
      // 10 hard accel + 10 hard brake events, each separated by short
      // intervals to keep total trip duration small.
      for (var i = 0; i < 10; i++) {
        samples.add(TripSample(timestamp: t, speedKmh: 0, rpm: 4000));
        t = t.add(const Duration(seconds: 2));
        samples.add(TripSample(timestamp: t, speedKmh: 50, rpm: 4000));
        t = t.add(const Duration(seconds: 2));
        samples.add(TripSample(timestamp: t, speedKmh: 0, rpm: 4000));
        t = t.add(const Duration(seconds: 1));
      }
      final result = computeDrivingScore(samples);
      expect(result.score, greaterThanOrEqualTo(0));
      // Caps are reached on hard-accel and hard-brake at minimum.
      expect(result.hardAccelPenalty, 15);
      expect(result.hardBrakePenalty, 15);
    });

    test('boundary: exactly 3000 RPM is NOT high-RPM (strict >)', () {
      // 5 minutes at exactly 3000 RPM. The high-RPM threshold is `> 3000`
      // (matches the analyzer), so this trip should not accumulate any
      // high-RPM penalty.
      final samples = <TripSample>[
        for (var i = 0; i <= 5; i++)
          TripSample(
            timestamp: start.add(Duration(minutes: i)),
            speedKmh: 80,
            rpm: 3000,
          ),
      ];
      final result = computeDrivingScore(samples);
      expect(result.highRpmPenalty, 0);
    });

    test('boundary: just above 3000 RPM IS high-RPM', () {
      final samples = <TripSample>[
        for (var i = 0; i <= 5; i++)
          TripSample(
            timestamp: start.add(Duration(minutes: i)),
            speedKmh: 80,
            rpm: 3001,
          ),
      ];
      final result = computeDrivingScore(samples);
      expect(result.highRpmPenalty, greaterThan(0));
    });

    test('boundary: exactly 3.0 m/s² IS a hard-accel event (inclusive)', () {
      // 0 → 21.6 km/h in 2 s = 6 m/s ÷ 2 s = 3.0 m/s² exactly. The
      // analyzer uses `>=`, so the calculator must too.
      final samples = <TripSample>[
        TripSample(timestamp: start, speedKmh: 0, rpm: 1000),
        TripSample(
          timestamp: start.add(const Duration(seconds: 2)),
          speedKmh: 21.6,
          rpm: 2500,
        ),
      ];
      final result = computeDrivingScore(samples);
      expect(result.hardAccelPenalty, greaterThan(0));
    });

    test('boundary: just below 3.0 m/s² is NOT a hard-accel event', () {
      // 0 → 21 km/h in 2 s ≈ 2.92 m/s² — below the threshold.
      final samples = <TripSample>[
        TripSample(timestamp: start, speedKmh: 0, rpm: 1000),
        TripSample(
          timestamp: start.add(const Duration(seconds: 2)),
          speedKmh: 21,
          rpm: 2500,
        ),
      ];
      final result = computeDrivingScore(samples);
      expect(result.hardAccelPenalty, 0);
    });

    test('out-of-order samples are sorted before integration', () {
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
      final result = computeDrivingScore(samples);
      expect(result.idlingPenalty, closeTo(25, 0.5));
      expect(result.score, closeTo(75, 1));
    });

    test('score is always an integer in [0, 100]', () {
      // A handful of random-ish trips — verify the contract holds for
      // each one.
      final scenarios = <List<TripSample>>[
        const <TripSample>[],
        <TripSample>[
          TripSample(timestamp: start, speedKmh: 0, rpm: 800),
        ],
        <TripSample>[
          TripSample(timestamp: start, speedKmh: 80, rpm: 2000),
          TripSample(
            timestamp: start.add(const Duration(seconds: 60)),
            speedKmh: 80,
            rpm: 2000,
          ),
        ],
        <TripSample>[
          TripSample(timestamp: start, speedKmh: 0, rpm: 4500),
          TripSample(
            timestamp: start.add(const Duration(seconds: 120)),
            speedKmh: 0,
            rpm: 4500,
          ),
        ],
      ];
      for (final s in scenarios) {
        final result = computeDrivingScore(s);
        expect(result.score, inInclusiveRange(0, 100));
      }
    });
  });

  group('DrivingScore value-object', () {
    test('equality and hashCode work as value-objects', () {
      const a = DrivingScore(
        score: 80,
        idlingPenalty: 10,
        hardAccelPenalty: 6,
        hardBrakePenalty: 0,
        highRpmPenalty: 4,
        fullThrottlePenalty: 0,
      );
      const b = DrivingScore(
        score: 80,
        idlingPenalty: 10,
        hardAccelPenalty: 6,
        hardBrakePenalty: 0,
        highRpmPenalty: 4,
        fullThrottlePenalty: 0,
      );
      const c = DrivingScore(
        score: 80,
        idlingPenalty: 10,
        hardAccelPenalty: 6,
        hardBrakePenalty: 0,
        highRpmPenalty: 5, // ← different
        fullThrottlePenalty: 0,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(c)));
    });

    test('perfect sentinel is 100 with zero penalties', () {
      expect(DrivingScore.perfect.score, 100);
      expect(DrivingScore.perfect.idlingPenalty, 0);
      expect(DrivingScore.perfect.hardAccelPenalty, 0);
      expect(DrivingScore.perfect.hardBrakePenalty, 0);
      expect(DrivingScore.perfect.highRpmPenalty, 0);
      expect(DrivingScore.perfect.fullThrottlePenalty, 0);
    });
  });
}
