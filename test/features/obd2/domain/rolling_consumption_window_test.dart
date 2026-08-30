// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3883 — the rolling-window consumption is ∫fuelRate·dt ÷ ∫speed·dt over
// the last N seconds: steady inputs give the exact per-distance figure,
// a standstill flips to L/h, sparse fuel ticks are held for ≤ 2 s, a link
// gap resets, and the window length can change between reads.
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/domain/rolling_consumption_window.dart';

final _t0 = DateTime(2026, 8, 30, 10);

void main() {
  test('steady 6 L/h at 60 km/h over 5 s reads 10.0 L/100 km', () {
    final w = RollingConsumptionWindow();
    for (var i = 0; i <= 10; i++) {
      w.add(
          now: _t0.add(Duration(seconds: i)),
          fuelRateLPerHour: 6.0,
          speedKmh: 60.0);
    }
    final r = w.read(const Duration(seconds: 5))!;
    expect(r.lPer100Km, closeTo(10.0, 1e-9));
    expect(r.lPerHour, closeTo(6.0, 1e-9));
    expect(r.isIdle, isFalse);
    expect(r.span.inSeconds, 5);
  });

  test('the window integrates — a recent change is weighted by its time', () {
    final w = RollingConsumptionWindow();
    // 5 s at 6 L/h @ 60 km/h (10 L/100), then 5 s at 12 L/h @ 60 (20 L/100).
    for (var i = 0; i <= 10; i++) {
      w.add(
          now: _t0.add(Duration(seconds: i)),
          fuelRateLPerHour: i <= 5 ? 6.0 : 12.0,
          speedKmh: 60.0);
    }
    expect(w.read(const Duration(seconds: 10))!.lPer100Km, closeTo(15.0, 1e-9));
    expect(w.read(const Duration(seconds: 5))!.lPer100Km, closeTo(20.0, 1e-9));
    expect(w.read(const Duration(seconds: 3))!.lPer100Km, closeTo(20.0, 1e-9));
  });

  test('standstill → idle: L/h only', () {
    final w = RollingConsumptionWindow();
    for (var i = 0; i <= 5; i++) {
      w.add(
          now: _t0.add(Duration(seconds: i)),
          fuelRateLPerHour: 0.8,
          speedKmh: 0.0);
    }
    final r = w.read(const Duration(seconds: 5))!;
    expect(r.isIdle, isTrue);
    expect(r.lPer100Km, isNull);
    expect(r.lPerHour, closeTo(0.8, 1e-9));
  });

  test('sparse fuel ticks: the last rate is held for 2 s, then the '
      'window goes stale', () {
    final w = RollingConsumptionWindow();
    // Rates on ticks 0..2, none on 3..4 (held: ≤ 2 s old) → every tick
    // in the 5 s window carries litres.
    for (var i = 0; i <= 4; i++) {
      w.add(
          now: _t0.add(Duration(seconds: i)),
          fuelRateLPerHour: i <= 2 ? 6.0 : null,
          speedKmh: 60.0);
    }
    final held = w.read(const Duration(seconds: 5))!;
    expect(held.lPer100Km, closeTo(10.0, 1e-9));
    expect(held.lPerHour, closeTo(6.0, 1e-9));
    for (var i = 5; i <= 10; i++) {
      w.add(
          now: _t0.add(Duration(seconds: i)),
          fuelRateLPerHour: null,
          speedKmh: 60.0);
    }
    expect(w.read(const Duration(seconds: 5)), isNull,
        reason: 'no fuel rate within the hold in the last 5 s');
  });

  test('a gap longer than 5 s resets the window', () {
    final w = RollingConsumptionWindow();
    w.add(now: _t0, fuelRateLPerHour: 6.0, speedKmh: 60.0);
    w.add(now: _t0.add(const Duration(seconds: 1)), fuelRateLPerHour: 6.0, speedKmh: 60.0);
    w.add(now: _t0.add(const Duration(seconds: 30)), fuelRateLPerHour: 6.0, speedKmh: 60.0);
    expect(w.tickCount, 0);
    expect(w.read(const Duration(seconds: 5)), isNull);
  });

  test('the buffer keeps at most maxWindow', () {
    final w = RollingConsumptionWindow(maxWindow: const Duration(seconds: 30));
    for (var i = 0; i <= 100; i++) {
      w.add(
          now: _t0.add(Duration(seconds: i)),
          fuelRateLPerHour: 6.0,
          speedKmh: 60.0);
    }
    expect(w.tickCount, lessThanOrEqualTo(31));
    expect(w.read(const Duration(seconds: 60))!.span.inSeconds, 30);
  });
}
