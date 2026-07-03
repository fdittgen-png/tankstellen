// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/instant_consumption_ema.dart';

/// #3431 (epic #3416) — EMA step response + idle guard for the true
/// instantaneous consumption signal.
void main() {
  final t0 = DateTime.utc(2026, 7, 1, 12);

  group('InstantConsumptionEma — step response (τ = 2.5 s)', () {
    test('first measured tick seeds the EMA at the raw value', () {
      final ema = InstantConsumptionEma();
      final out = ema.update(now: t0, fuelRateLPerHour: 6.0, speedKmh: 60.0);
      expect(out, isNotNull);
      expect(out!.lPerHour, 6.0);
      expect(out.lPer100Km, closeTo(10.0, 1e-9));
      expect(out.isIdle, isFalse);
    });

    test('a rate step reaches ~63% after one τ and ~95% after three', () {
      final ema = InstantConsumptionEma();
      // Seed at 0 L/h, then step the true rate to 10 L/h.
      ema.update(now: t0, fuelRateLPerHour: 0.0, speedKmh: 60.0);

      final afterOneTau = ema.update(
        now: t0.add(const Duration(milliseconds: 2500)),
        fuelRateLPerHour: 10.0,
        speedKmh: 60.0,
      )!;
      // 1 − e^(−1) ≈ 0.632.
      expect(afterOneTau.lPerHour, closeTo(6.32, 0.02));

      ema.update(
        now: t0.add(const Duration(milliseconds: 5000)),
        fuelRateLPerHour: 10.0,
        speedKmh: 60.0,
      );
      final afterThreeTau = ema.update(
        now: t0.add(const Duration(milliseconds: 7500)),
        fuelRateLPerHour: 10.0,
        speedKmh: 60.0,
      )!;
      // 1 − e^(−3) ≈ 0.950.
      expect(afterThreeTau.lPerHour, closeTo(9.50, 0.02));
    });

    test('smoothing damps a single-tick spike instead of jumping', () {
      final ema = InstantConsumptionEma();
      ema.update(now: t0, fuelRateLPerHour: 5.0, speedKmh: 60.0);
      final spiked = ema.update(
        now: t0.add(const Duration(milliseconds: 250)),
        fuelRateLPerHour: 20.0,
        speedKmh: 60.0,
      )!;
      // 250 ms tick vs τ 2.5 s → α ≈ 0.095: nowhere near the raw 20.
      expect(spiked.lPerHour, lessThan(7.0));
      expect(spiked.lPerHour, greaterThan(5.0));
    });

    test('a long PID dropout effectively re-seeds (α → 1)', () {
      final ema = InstantConsumptionEma();
      ema.update(now: t0, fuelRateLPerHour: 12.0, speedKmh: 100.0);
      // 60 s with no measured tick, then a fresh low reading.
      final resumed = ema.update(
        now: t0.add(const Duration(seconds: 60)),
        fuelRateLPerHour: 4.0,
        speedKmh: 50.0,
      )!;
      expect(resumed.lPerHour, closeTo(4.0, 0.01));
    });

    test('null fuel rate returns null and leaves state untouched', () {
      final ema = InstantConsumptionEma();
      ema.update(now: t0, fuelRateLPerHour: 6.0, speedKmh: 60.0);
      final gap = ema.update(
        now: t0.add(const Duration(milliseconds: 250)),
        fuelRateLPerHour: null,
        speedKmh: 60.0,
      );
      expect(gap, isNull);
      expect(ema.smoothedLPerHour, 6.0);
    });

    test('non-increasing clock keeps the previous EMA', () {
      final ema = InstantConsumptionEma();
      ema.update(now: t0, fuelRateLPerHour: 6.0, speedKmh: 60.0);
      final dup = ema.update(
        now: t0, // duplicate timestamp
        fuelRateLPerHour: 60.0,
        speedKmh: 60.0,
      )!;
      expect(dup.lPerHour, 6.0);
    });
  });

  group('InstantConsumptionEma — idle guard', () {
    test('below 5 km/h flips to idle mode: L/h only, no L/100 km', () {
      final ema = InstantConsumptionEma();
      final out = ema.update(now: t0, fuelRateLPerHour: 0.8, speedKmh: 3.0)!;
      expect(out.isIdle, isTrue);
      expect(out.lPer100Km, isNull);
      expect(out.lPerHour, 0.8);
    });

    test('unknown speed is treated as idle (never divides by null)', () {
      final ema = InstantConsumptionEma();
      final out = ema.update(now: t0, fuelRateLPerHour: 0.8, speedKmh: null)!;
      expect(out.isIdle, isTrue);
      expect(out.lPer100Km, isNull);
    });

    test('crossing the threshold restores the per-distance figure', () {
      final ema = InstantConsumptionEma();
      ema.update(now: t0, fuelRateLPerHour: 0.8, speedKmh: 2.0);
      final moving = ema.update(
        now: t0.add(const Duration(seconds: 10)),
        fuelRateLPerHour: 6.0,
        speedKmh: 50.0,
      )!;
      expect(moving.isIdle, isFalse);
      expect(moving.lPer100Km, isNotNull);
      // L/100 = smoothed rate / 50 × 100.
      expect(moving.lPer100Km, closeTo(moving.lPerHour / 50.0 * 100.0, 1e-9));
    });

    test('reset drops the state so the next tick re-seeds', () {
      final ema = InstantConsumptionEma();
      ema.update(now: t0, fuelRateLPerHour: 12.0, speedKmh: 80.0);
      ema.reset();
      expect(ema.smoothedLPerHour, isNull);
      final out = ema.update(
        now: t0.add(const Duration(milliseconds: 250)),
        fuelRateLPerHour: 4.0,
        speedKmh: 80.0,
      )!;
      expect(out.lPerHour, 4.0);
    });
  });
}
