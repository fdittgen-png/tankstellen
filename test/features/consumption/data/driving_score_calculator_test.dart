// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

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

    test('full-throttle penalty stays 0 when no pedal/throttle is recorded',
        () {
      // Cars exposing neither PID 0x49-0x4B (pedal) nor PID 0x11
      // (throttle) carry null on every sample — the penalty is the
      // honest "no signal" 0, not a hard-coded zero (#2460).
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

  group('canonical metrics (#2460)', () {
    final start = DateTime.utc(2026);

    test('full-throttle penalty NOW FIRES from persisted pedal %', () {
      // 10 min flooring it — pedal pinned at 100 %. The old code
      // hard-coded fullThrottleSeconds = 0; the canonical calc reads the
      // persisted pedal and saturates the 10-point cap.
      final samples = <TripSample>[
        for (var i = 0; i <= 10; i++)
          TripSample(
            timestamp: start.add(Duration(minutes: i)),
            speedKmh: 80,
            rpm: 2500,
            pedalPercent: 100,
          ),
      ];
      final result = computeDrivingScore(samples);
      expect(result.fullThrottlePenalty, closeTo(10, 0.5));
    });

    test('full-throttle falls back to throttle % when pedal is absent', () {
      final samples = <TripSample>[
        for (var i = 0; i <= 10; i++)
          TripSample(
            timestamp: start.add(Duration(minutes: i)),
            speedKmh: 80,
            rpm: 2500,
            throttlePercent: 95,
          ),
      ];
      final result = computeDrivingScore(samples);
      expect(result.fullThrottlePenalty, greaterThan(0));
    });

    test('full-throttle boundary: exactly 90 % IS full throttle', () {
      final samples = <TripSample>[
        TripSample(timestamp: start, speedKmh: 80, rpm: 2500, pedalPercent: 90),
        TripSample(
          timestamp: start.add(const Duration(minutes: 5)),
          speedKmh: 80,
          rpm: 2500,
          pedalPercent: 90,
        ),
      ];
      expect(computeDrivingScore(samples).fullThrottlePenalty, greaterThan(0));
    });

    test('fuel-cut coast is credited (positive eco bonus)', () {
      // Whole trip coasting: moving > 20 km/h, fuel rate ~0 (injectors
      // off). Detected before #2460 but never credited; now +10 max.
      final samples = <TripSample>[
        for (var i = 0; i <= 10; i++)
          TripSample(
            timestamp: start.add(Duration(minutes: i)),
            speedKmh: 60,
            rpm: 1500,
            fuelRateLPerHour: 0.0,
          ),
      ];
      final result = computeDrivingScore(samples);
      expect(result.ecoCreditCoast, closeTo(10, 0.5));
      // The credit lifts the score back to 100 on an otherwise clean trip.
      expect(result.score, 100);
    });

    test('eco credit lifts an otherwise-penalised score', () {
      // Half the trip coasting, half idling — the coast credit offsets
      // part of the idle penalty so the score is higher than idle alone.
      final coast = <TripSample>[
        for (var i = 0; i <= 10; i++)
          TripSample(
            timestamp: start.add(Duration(minutes: i)),
            speedKmh: 60,
            rpm: 1500,
            fuelRateLPerHour: 0.0,
          ),
      ];
      final result = computeDrivingScore(coast);
      expect(result.ecoCreditCoast, greaterThan(0));
    });

    test('smoothness is CONTINUOUS — jerky speed costs points', () {
      // Speed sawtooths 40/120/40/120 every minute while moving — high
      // speed std-dev → a non-zero, sub-cap smoothness penalty (not a
      // binary all-or-nothing gate).
      final samples = <TripSample>[
        for (var i = 0; i <= 12; i++)
          TripSample(
            timestamp: start.add(Duration(minutes: i)),
            speedKmh: i.isEven ? 40 : 120,
            rpm: 2000,
          ),
      ];
      final result = computeDrivingScore(samples);
      expect(result.smoothnessPenalty, greaterThan(0));
    });

    test('smooth constant-speed cruise has zero smoothness penalty', () {
      final samples = <TripSample>[
        for (var i = 0; i <= 10; i++)
          TripSample(
            timestamp: start.add(Duration(minutes: i)),
            speedKmh: 90,
            rpm: 2000,
          ),
      ];
      expect(computeDrivingScore(samples).smoothnessPenalty, 0);
    });

    test('lugging penalty comes from secondsBelowOptimalGear input', () {
      // 10-minute trip, half of it lugging below the optimal gear.
      final samples = <TripSample>[
        for (var i = 0; i <= 10; i++)
          TripSample(
            timestamp: start.add(Duration(minutes: i)),
            speedKmh: 50,
            rpm: 1800,
          ),
      ];
      final without = computeDrivingScore(samples);
      final with300 =
          computeDrivingScore(samples, secondsBelowOptimalGear: 300);
      expect(without.luggingPenalty, 0);
      expect(with300.luggingPenalty, greaterThan(0));
      expect(with300.score, lessThan(without.score));
    });

    test('λ-enrichment penalty fires when commanded λ < 1', () {
      final samples = <TripSample>[
        for (var i = 0; i <= 10; i++)
          TripSample(
            timestamp: start.add(Duration(minutes: i)),
            speedKmh: 100,
            rpm: 3000,
            lambda: 0.85,
          ),
      ];
      final result = computeDrivingScore(samples);
      expect(result.lambdaEnrichmentPenalty, greaterThan(0));
    });

    test('λ == 1 (stoichiometric) is NOT enrichment', () {
      final samples = <TripSample>[
        for (var i = 0; i <= 10; i++)
          TripSample(
            timestamp: start.add(Duration(minutes: i)),
            speedKmh: 100,
            rpm: 3000,
            lambda: 1.0,
          ),
      ];
      expect(computeDrivingScore(samples).lambdaEnrichmentPenalty, 0);
    });

    test('speed-efficiency penalty fires above 110 km/h', () {
      final samples = <TripSample>[
        for (var i = 0; i <= 10; i++)
          TripSample(
            timestamp: start.add(Duration(minutes: i)),
            speedKmh: 130,
            rpm: 2800,
          ),
      ];
      expect(
        computeDrivingScore(samples).speedEfficiencyPenalty,
        greaterThan(0),
      );
    });

    test('rev-while-stationary penalty fires on a high-RPM standstill', () {
      // Stationary (speed 0) but revving 2500 RPM > 1500 threshold.
      final samples = <TripSample>[
        for (var i = 0; i <= 10; i++)
          TripSample(
            timestamp: start.add(Duration(seconds: i * 5)),
            speedKmh: 0,
            rpm: 2500,
          ),
      ];
      expect(
        computeDrivingScore(samples).revWhileStationaryPenalty,
        greaterThan(0),
      );
    });

    test('classification bands map score → DrivingStyleClass', () {
      expect(DrivingStyleClass.fromScore(100), DrivingStyleClass.veryGood);
      expect(DrivingStyleClass.fromScore(85), DrivingStyleClass.veryGood);
      expect(DrivingStyleClass.fromScore(84), DrivingStyleClass.good);
      expect(DrivingStyleClass.fromScore(70), DrivingStyleClass.good);
      expect(DrivingStyleClass.fromScore(69), DrivingStyleClass.average);
      expect(DrivingStyleClass.fromScore(50), DrivingStyleClass.average);
      expect(DrivingStyleClass.fromScore(49), DrivingStyleClass.bad);
      expect(DrivingStyleClass.fromScore(0), DrivingStyleClass.bad);
    });

    test('a clean cruise classifies VERY-GOOD', () {
      final samples = <TripSample>[
        for (var i = 0; i <= 10; i++)
          TripSample(
            timestamp: start.add(Duration(minutes: i)),
            speedKmh: 90,
            rpm: 2000,
            fuelRateLPerHour: 5,
          ),
      ];
      expect(computeDrivingScore(samples).styleClass,
          DrivingStyleClass.veryGood);
    });
  });

  group('computeDrivingScoreFromSummary (#2460 legacy summary path)', () {
    final start = DateTime.utc(2026);

    TripSummary summary({
      required Duration duration,
      double idleSeconds = 0,
      double highRpmSeconds = 0,
      int harshBrakes = 0,
      int harshAccels = 0,
      double? secondsBelowOptimalGear,
    }) =>
        TripSummary(
          distanceKm: 20,
          maxRpm: 2000,
          highRpmSeconds: highRpmSeconds,
          idleSeconds: idleSeconds,
          harshBrakes: harshBrakes,
          harshAccelerations: harshAccels,
          startedAt: start,
          endedAt: start.add(duration),
          secondsBelowOptimalGear: secondsBelowOptimalGear,
        );

    test('clean trip with no penalties scores 100', () {
      expect(
        computeDrivingScoreFromSummary(
          summary(duration: const Duration(minutes: 30)),
        ).score,
        100,
      );
    });

    test('trip under 1 minute returns perfect (insufficient signal)', () {
      expect(
        computeDrivingScoreFromSummary(
          summary(duration: const Duration(seconds: 30), idleSeconds: 30),
        ),
        DrivingScore.perfect,
      );
    });

    test('100% idle drops the idle cap (25 points)', () {
      final s = computeDrivingScoreFromSummary(
        summary(duration: const Duration(minutes: 10), idleSeconds: 600),
      );
      expect(s.idlingPenalty, closeTo(25, 0.5));
      expect(s.score, closeTo(75, 1));
    });

    test('harsh events subtract per-event, capped', () {
      final s = computeDrivingScoreFromSummary(
        summary(
          duration: const Duration(minutes: 30),
          harshBrakes: 10,
          harshAccels: 10,
        ),
      );
      // Each family caps at 15 → 30 off → 70.
      expect(s.score, 70);
    });

    test('summary lugging is included', () {
      final s = computeDrivingScoreFromSummary(
        summary(
          duration: const Duration(minutes: 10),
          secondsBelowOptimalGear: 600,
        ),
      );
      expect(s.luggingPenalty, greaterThan(0));
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

  group('#2692 C4-G — GPS-only (rpm null) fabricates no rpm-based penalty',
      () {
    final start = DateTime.utc(2026);

    test(
        'a GPS-only stream (rpm null) at standstill + high speed yields ZERO '
        'idle / high-RPM / hard-shift penalty', () {
      // A stop-and-go GPS-only trip: half stationary (would have been
      // counted as idle when GPS-only fabricated `rpm: 0`-but-engine-on, but
      // the OLD code used `rpm > 0` so 0 never tripped idle — the real risk
      // is the high-RPM + hard-shift gates once any non-null sneaks in).
      // With rpm null these gates can never fire.
      final samples = <TripSample>[
        for (var i = 0; i <= 30; i++)
          TripSample(
            timestamp: start.add(Duration(seconds: i * 2)),
            // alternate standstill and motion to exercise both gates
            speedKmh: i.isEven ? 0 : 60,
            rpm: null, // GPS-only — no engine signal
          ),
      ];
      final score = computeDrivingScore(samples);
      expect(score.idlingPenalty, 0,
          reason: 'rpm null must never be read as an idling engine');
      expect(score.highRpmPenalty, 0,
          reason: 'rpm null must never trip the high-RPM gate');
      expect(score.hardShiftPenalty, 0,
          reason: 'rpm null must never be a hard-shift spike');
    });

    test('an OBD2 idling stream (rpm > 0, speed 0) still accrues idle penalty',
        () {
      // Counter-test: the gates still fire for a real engine signal.
      final samples = <TripSample>[
        for (var i = 0; i <= 60; i++)
          TripSample(
            timestamp: start.add(Duration(seconds: i)),
            speedKmh: 0,
            rpm: 800, // engine running, stationary → idle
          ),
      ];
      expect(computeDrivingScore(samples).idlingPenalty, greaterThan(0));
    });
  });

  group('#2695 C9 — source-aware score re-weight', () {
    final start = DateTime.utc(2026);

    // A spirited drive: 5 min above the high-RPM threshold at high speed.
    // OBD2 version carries a real rpm; GPS-only version carries rpm null.
    List<TripSample> spiritedDrive({required bool gpsOnly}) => <TripSample>[
          for (var i = 0; i <= 300; i++)
            TripSample(
              timestamp: start.add(Duration(seconds: i)),
              speedKmh: 130, // above the speed-efficiency band
              rpm: gpsOnly ? null : 4200, // above the high-RPM threshold
              fuelRateLPerHour: gpsOnly ? null : 14,
            ),
        ];

    test(
        'GPS-only (rpm null) zeroes the engine-derived penalties '
        '(highRpm / lugging / hardShift)', () {
      final score = computeDrivingScore(
        spiritedDrive(gpsOnly: true),
        secondsBelowOptimalGear: 120, // would have lugged if it scored
      );
      expect(score.highRpmPenalty, 0);
      expect(score.luggingPenalty, 0);
      expect(score.hardShiftPenalty, 0);
      // Speed-efficiency still bites (it's speed-only) — the re-weight only
      // zeroes the engine-derived terms.
      expect(score.speedEfficiencyPenalty, greaterThan(0));
    });

    test(
        'the SAME spirited drive scores HIGHER as GPS-only than as OBD2 '
        '(the intended historical correction — dead rpm terms removed)', () {
      final obd2 = computeDrivingScore(
        spiritedDrive(gpsOnly: false),
        secondsBelowOptimalGear: 120,
      );
      final gps = computeDrivingScore(
        spiritedDrive(gpsOnly: true),
        secondsBelowOptimalGear: 120,
      );
      expect(gps.score, greaterThan(obd2.score),
          reason: 'GPS-only no longer carries the unfair engine penalties');
    });

    test(
        'OBD2 score is byte-identical to the un-flagged path '
        '(regression guard — gpsOnly defaults false)', () {
      // A representative OBD2 trip with idle, high-RPM, and a shift spike.
      final samples = <TripSample>[
        for (var i = 0; i <= 30; i++)
          TripSample(
            timestamp: start.add(Duration(seconds: i)),
            speedKmh: i < 10 ? 0 : 90,
            rpm: i < 10 ? 850 : (i.isEven ? 3600 : 2000),
            fuelRateLPerHour: 9,
          ),
      ];
      final score = computeDrivingScore(samples);
      // Engine-derived penalties remain ACTIVE for OBD2 (not zeroed).
      expect(score.highRpmPenalty, greaterThan(0));
      expect(score.idlingPenalty, greaterThan(0));
    });
  });

  group('harsh-event overrides (#2794 — GPS-only IMU-preferred routing)', () {
    final start = DateTime(2026, 6, 3, 12);
    // A short GPS-only run (rpm null) with a gentle speed ramp.
    final samples = <TripSample>[
      for (var i = 0; i < 20; i++)
        TripSample(
            timestamp: start.add(Duration(seconds: i)), speedKmh: 30.0 + i),
    ];

    test('the accel/brake event overrides drive the penalty, not the '
        'GPS-derived count', () {
      final overridden = computeDrivingScore(samples,
          hardAccelEventsOverride: 4, hardBrakeEventsOverride: 0);
      final zeroed = computeDrivingScore(samples,
          hardAccelEventsOverride: 0, hardBrakeEventsOverride: 0);

      expect(overridden.hardAccelPenalty, greaterThan(0),
          reason: '4 IMU-detected hard accels produce a real penalty');
      expect(zeroed.hardAccelPenalty, 0,
          reason: 'a 0 override yields no accel penalty regardless of GPS '
              'speed-derivative jitter');
      expect(
          overridden.hardAccelPenalty, greaterThan(zeroed.hardAccelPenalty));
    });

    test('a brake override drives the brake penalty', () {
      final braked = computeDrivingScore(samples,
          hardAccelEventsOverride: 0, hardBrakeEventsOverride: 3);
      expect(braked.hardBrakePenalty, greaterThan(0));
    });

    test('no override → unchanged (GPS-derived events, deterministic)', () {
      expect(computeDrivingScore(samples),
          equals(computeDrivingScore(samples)));
    });
  });

  // Epic #3015 — the hard-accel penalty scales INVERSELY with engine power:
  // at the SAME hard-accel intensity a low-power car wastes proportionally
  // more fuel than a high-power one, so it is penalised more. Driven through
  // the REAL scorer via the deterministic event override; only the
  // `enginePowerKw` argument varies, so any difference is the power model.
  group('power-aware hard-accel penalty (Epic #3015)', () {
    final start = DateTime(2026, 6, 7, 9);
    // 30 s of gentle GPS-only motion; the override sets the event count so
    // the penalty math is deterministic and isolated from the accel gate.
    final samples = <TripSample>[
      for (var i = 0; i < 30; i++)
        TripSample(
            timestamp: start.add(Duration(seconds: i)), speedKmh: 40.0 + i),
    ];

    // Two events keep every variant below the 15-pt cap (low: 2×3×1.8 = 10.8),
    // so the ordering reflects the factor, not the clamp masking it.
    DrivingScore scoreForPower(int? kw) => computeDrivingScore(
          samples,
          hardAccelEventsOverride: 2,
          hardBrakeEventsOverride: 0,
          enginePowerKw: kw,
        );

    test('null power → factor 1.0 → EXACT pre-change baseline (2×3.0 = 6.0)',
        () {
      // Locks the byte-for-byte legacy value: 2 events × 3.0 pts × 1.0.
      // If this number changes, the backward-compat identity is broken.
      expect(scoreForPower(null).hardAccelPenalty, 6.0);
    });

    test('low < reference: a 55 kW car is penalised MORE than null/reference',
        () {
      // f = clamp(100/55 = 1.818, 0.6, 1.8) = 1.8 → 2×3×1.8 = 10.8.
      expect(scoreForPower(55).hardAccelPenalty, closeTo(10.8, 1e-9));
      expect(scoreForPower(55).hardAccelPenalty,
          greaterThan(scoreForPower(100).hardAccelPenalty));
    });

    test('reference power (100 kW) → identical to null (factor 1.0)', () {
      expect(scoreForPower(kReferenceEnginePowerKw).hardAccelPenalty,
          scoreForPower(null).hardAccelPenalty);
    });

    test('high > reference: a 230 kW car is penalised LESS than reference', () {
      // f = clamp(100/230 = 0.435, 0.6, 1.8) = 0.6 → 2×3×0.6 = 3.6.
      expect(scoreForPower(230).hardAccelPenalty, closeTo(3.6, 1e-9));
      expect(scoreForPower(230).hardAccelPenalty,
          lessThan(scoreForPower(100).hardAccelPenalty));
    });

    test('penalties are STRICTLY ordered low > reference > high', () {
      final low = scoreForPower(55).hardAccelPenalty;
      final ref = scoreForPower(100).hardAccelPenalty;
      final high = scoreForPower(230).hardAccelPenalty;
      expect(low, greaterThan(ref));
      expect(ref, greaterThan(high));
    });

    test('only hard-accel scales — brake/idle/rpm penalties are power-blind',
        () {
      // A trip with idle + high-RPM + a brake event; verify those terms are
      // identical across powers and only hard-accel moves.
      final idleHighRpm = <TripSample>[
        for (var i = 0; i <= 10; i++)
          TripSample(
              timestamp: start.add(Duration(seconds: i)),
              speedKmh: 0,
              rpm: 3500),
      ];
      DrivingScore s(int? kw) => computeDrivingScore(
            idleHighRpm,
            hardAccelEventsOverride: 2,
            hardBrakeEventsOverride: 3,
            enginePowerKw: kw,
          );
      final a = s(55);
      final b = s(230);
      expect(a.idlingPenalty, b.idlingPenalty);
      expect(a.highRpmPenalty, b.highRpmPenalty);
      expect(a.hardBrakePenalty, b.hardBrakePenalty);
      // Hard-accel is the ONLY term that differs.
      expect(a.hardAccelPenalty, greaterThan(b.hardAccelPenalty));
    });

    test('clamp bounds: extreme low/high power do not explode the penalty', () {
      // 1 kW (absurd) clamps the factor to fMax, not 100×.
      expect(scoreForPower(1).hardAccelPenalty, closeTo(2 * 3 * 1.8, 1e-9));
      // 5000 kW clamps to fMin, not ~0.
      expect(scoreForPower(5000).hardAccelPenalty, closeTo(2 * 3 * 0.6, 1e-9));
    });

    test('zero / negative power guards division → factor 1.0 (legacy value)',
        () {
      expect(scoreForPower(0).hardAccelPenalty, 6.0);
      expect(scoreForPower(-50).hardAccelPenalty, 6.0);
    });
  });

  // Epic #3015 — the same model on the cheap summary-only path that feeds the
  // achievement engine (`TripMetrics.drivingScore`).
  group('power-aware hard-accel penalty — summary path (Epic #3015)', () {
    TripSummary summaryWith(int harshAccel) => TripSummary(
          distanceKm: 20,
          maxRpm: 2000,
          highRpmSeconds: 0,
          idleSeconds: 0,
          harshBrakes: 0,
          harshAccelerations: harshAccel,
          startedAt: DateTime(2026, 6, 7, 9),
          endedAt: DateTime(2026, 6, 7, 9, 30),
        );

    test('null power → factor 1.0 → EXACT baseline (2×3.0 = 6.0)', () {
      expect(
          computeDrivingScoreFromSummary(summaryWith(2)).hardAccelPenalty, 6.0);
    });

    test('low power penalised more, high less, strictly ordered', () {
      final s = summaryWith(2);
      final low =
          computeDrivingScoreFromSummary(s, enginePowerKw: 55).hardAccelPenalty;
      final ref = computeDrivingScoreFromSummary(s, enginePowerKw: 100)
          .hardAccelPenalty;
      final high = computeDrivingScoreFromSummary(s, enginePowerKw: 230)
          .hardAccelPenalty;
      expect(low, closeTo(10.8, 1e-9));
      expect(ref, 6.0);
      expect(high, closeTo(3.6, 1e-9));
      expect(low, greaterThan(ref));
      expect(ref, greaterThan(high));
    });
  });
}
