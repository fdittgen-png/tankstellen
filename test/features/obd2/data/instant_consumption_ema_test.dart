// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/domain/instant_consumption_ema.dart';

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

    test('null fuel rate leaves the EMA state untouched', () {
      // #3845 changed what a gap RETURNS (see the hold group below), but
      // not what it stores: a tick with no fuel rate must never fold a
      // fabricated value into the average.
      final ema = InstantConsumptionEma();
      ema.update(now: t0, fuelRateLPerHour: 6.0, speedKmh: 60.0);
      ema.update(
        now: t0.add(const Duration(milliseconds: 250)),
        fuelRateLPerHour: null,
        speedKmh: 60.0,
      );
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

    test('a gap AT STANDSTILL is the one case that stays blank', () {
      // The user's requirement, verbatim: the figure "must only be unset
      // if the car stands still".
      final ema = InstantConsumptionEma();
      ema.update(now: t0, fuelRateLPerHour: 6.0, speedKmh: 60.0);
      final stopped = ema.update(
        now: t0.add(const Duration(milliseconds: 250)),
        fuelRateLPerHour: null,
        speedKmh: 0.0,
      );
      expect(stopped, isNull);
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

  group('#3845 the figure holds across a fuel-rate gap while moving', () {
    // Field data from the reporting drive: emit runs at 4 Hz (250 ms) and
    // `signalCoverage.fuelRate` was 0.209 — roughly four ticks in five
    // carry NO fuel rate, so returning null on every gap blanked the
    // headline for most of the drive. Mean gap at that coverage is
    // ~1.2 s, which the 2 s window covers; a genuine dropout still
    // blanks, which is what keeps a stale number off the screen.
    test('a gap while moving holds the last smoothed value', () {
      final ema = InstantConsumptionEma();
      ema.update(now: t0, fuelRateLPerHour: 6.0, speedKmh: 60.0);
      final held = ema.update(
        now: t0.add(const Duration(milliseconds: 250)),
        fuelRateLPerHour: null,
        speedKmh: 60.0,
      );
      expect(held, isNotNull, reason: 'this is the blanking the user saw');
      expect(held!.lPerHour, 6.0);
      expect(held.lPer100Km, closeTo(10.0, 1e-9));
      expect(held.isIdle, isFalse);
    });

    test('four gap ticks in a row all answer — the 4:1 field pattern', () {
      final ema = InstantConsumptionEma();
      ema.update(now: t0, fuelRateLPerHour: 6.0, speedKmh: 60.0);
      for (var i = 1; i <= 4; i++) {
        final out = ema.update(
          now: t0.add(Duration(milliseconds: 250 * i)),
          fuelRateLPerHour: null,
          speedKmh: 60.0,
        );
        expect(out, isNotNull, reason: 'blanked on gap tick $i of 4');
      }
    });

    test('the held figure tracks the CURRENT speed, not the stored one', () {
      // Holding the rate is defensible; replaying a whole L/100 km figure
      // through an acceleration is not — 6 L/h at 60 km/h is 10 L/100 km,
      // the same rate at 120 km/h is 5.
      final ema = InstantConsumptionEma();
      ema.update(now: t0, fuelRateLPerHour: 6.0, speedKmh: 60.0);
      final held = ema.update(
        now: t0.add(const Duration(milliseconds: 250)),
        fuelRateLPerHour: null,
        speedKmh: 120.0,
      )!;
      expect(held.lPerHour, 6.0);
      expect(held.lPer100Km, closeTo(5.0, 1e-9));
    });

    test('past the 2 s window the value is stale and blanks again', () {
      final ema = InstantConsumptionEma();
      ema.update(now: t0, fuelRateLPerHour: 6.0, speedKmh: 60.0);
      expect(
        ema.update(
          now: t0.add(const Duration(milliseconds: 2000)),
          fuelRateLPerHour: null,
          speedKmh: 60.0,
        ),
        isNotNull,
        reason: 'exactly at the window the value is still fresh',
      );
      expect(
        ema.update(
          now: t0.add(const Duration(milliseconds: 2001)),
          fuelRateLPerHour: null,
          speedKmh: 60.0,
        ),
        isNull,
        reason: 'one ms past the window it is a stale number on a live '
            'screen — the anti-staleness guarantee #3431 shipped',
      );
    });

    test('the window measures from the last MEASURED tick, not the last '
        'held answer', () {
      // Otherwise a chain of held answers would keep re-arming the window
      // and pin one value on screen for the whole drive.
      final ema = InstantConsumptionEma();
      ema.update(now: t0, fuelRateLPerHour: 6.0, speedKmh: 60.0);
      for (var i = 1; i <= 8; i++) {
        ema.update(
          now: t0.add(Duration(milliseconds: 250 * i)),
          fuelRateLPerHour: null,
          speedKmh: 60.0,
        );
      }
      expect(
        ema.update(
          now: t0.add(const Duration(milliseconds: 2250)),
          fuelRateLPerHour: null,
          speedKmh: 60.0,
        ),
        isNull,
      );
    });

    test('nothing is held before the first measured tick', () {
      final ema = InstantConsumptionEma();
      expect(
        ema.update(now: t0, fuelRateLPerHour: null, speedKmh: 60.0),
        isNull,
      );
    });

    test('a negative fuel rate is treated as a gap, not folded in', () {
      final ema = InstantConsumptionEma();
      ema.update(now: t0, fuelRateLPerHour: 6.0, speedKmh: 60.0);
      final held = ema.update(
        now: t0.add(const Duration(milliseconds: 250)),
        fuelRateLPerHour: -3.0,
        speedKmh: 60.0,
      )!;
      expect(held.lPerHour, 6.0);
      expect(ema.smoothedLPerHour, 6.0);
    });

    test('a backwards clock during a gap blanks rather than answers', () {
      final ema = InstantConsumptionEma();
      ema.update(now: t0, fuelRateLPerHour: 6.0, speedKmh: 60.0);
      expect(
        ema.update(
          now: t0.subtract(const Duration(seconds: 1)),
          fuelRateLPerHour: null,
          speedKmh: 60.0,
        ),
        isNull,
      );
    });

    test('the window is configurable and 2 s by default', () {
      expect(InstantConsumptionEma().holdWindow, const Duration(seconds: 2));
      final wide = InstantConsumptionEma(holdWindow: const Duration(seconds: 6));
      wide.update(now: t0, fuelRateLPerHour: 6.0, speedKmh: 60.0);
      expect(
        wide.update(
          now: t0.add(const Duration(seconds: 5)),
          fuelRateLPerHour: null,
          speedKmh: 60.0,
        ),
        isNotNull,
      );
    });
  });
}
