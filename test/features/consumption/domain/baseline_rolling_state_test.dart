// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/trip_live_reading.dart';
import 'package:tankstellen/features/consumption/domain/baseline_rolling_state.dart';

/// Unit coverage for the #2513 rolling-state helper that derives the
/// stop-and-go context flag, the finite-difference accel, the confident
/// road grade, and the throttle/load signal selection the fuzzy
/// calibration path feeds into the pure [FuzzyClassifier].
void main() {
  TripLiveReading reading({
    double? speed,
    double distanceKm = 0,
    double? altitude,
    double? throttle,
    double? engineLoad,
    double? absLoad,
  }) =>
      TripLiveReading(
        speedKmh: speed,
        distanceKmSoFar: distanceKm,
        altitudeM: altitude,
        throttlePercent: throttle,
        engineLoadPercent: engineLoad,
        absLoadPercent: absLoad,
        elapsed: Duration.zero,
      );

  group('stop-and-go context', () {
    test('a steady cruise is not stop-and-go', () {
      final s = BaselineRollingState();
      final base = DateTime(2026);
      for (var i = 0; i < 10; i++) {
        s.add(reading(speed: 80), base.add(Duration(seconds: i)));
      }
      expect(s.isStopAndGoContext, isFalse);
    });

    test('repeated start/stop crossings flag stop-and-go', () {
      final s = BaselineRollingState();
      final base = DateTime(2026);
      const pattern = [30.0, 0.0, 30.0, 0.0, 30.0, 0.0];
      for (var i = 0; i < pattern.length; i++) {
        s.add(reading(speed: pattern[i]), base.add(Duration(seconds: i)));
      }
      expect(s.isStopAndGoContext, isTrue);
    });

    test('fewer than three samples never trips the flag', () {
      final s = BaselineRollingState();
      final base = DateTime(2026);
      s.add(reading(speed: 30), base);
      s.add(reading(speed: 0), base.add(const Duration(seconds: 1)));
      expect(s.isStopAndGoContext, isFalse);
    });

    test('samples older than the 30-s window are trimmed out', () {
      final s = BaselineRollingState();
      final base = DateTime(2026);
      // Old stop-and-go burst, then a long steady cruise that pushes
      // the burst out of the window.
      const burst = [30.0, 0.0, 30.0, 0.0];
      for (var i = 0; i < burst.length; i++) {
        s.add(reading(speed: burst[i]), base.add(Duration(seconds: i)));
      }
      for (var i = 0; i < 40; i++) {
        s.add(reading(speed: 90),
            base.add(Duration(seconds: 10 + i)));
      }
      expect(s.isStopAndGoContext, isFalse,
          reason: 'the stale burst must have aged out of the 30-s window');
    });
  });

  group('confident road grade', () {
    test('a steady climb in altitude over distance becomes confident', () {
      final s = BaselineRollingState();
      final base = DateTime(2026);
      var distanceKm = 0.0;
      var altitude = 100.0;
      for (var i = 0; i < 40; i++) {
        distanceKm += 0.02; // 20 m per sample
        altitude += 1.0; // ~5 % grade
        s.add(reading(speed: 50, distanceKm: distanceKm, altitude: altitude),
            base.add(Duration(seconds: i)));
      }
      expect(s.confidentGradePct, greaterThan(0));
    });

    test('no GPS altitude leaves the grade at 0 (non-confident)', () {
      final s = BaselineRollingState();
      final base = DateTime(2026);
      var distanceKm = 0.0;
      for (var i = 0; i < 40; i++) {
        distanceKm += 0.02;
        s.add(reading(speed: 50, distanceKm: distanceKm),
            base.add(Duration(seconds: i)));
      }
      expect(s.confidentGradePct, 0);
    });
  });

  group('accel', () {
    test('rising speed yields positive accel, falling negative', () {
      final s = BaselineRollingState();
      final base = DateTime(2026);
      s.add(reading(speed: 0), base);
      s.add(reading(speed: 36), base.add(const Duration(seconds: 1)));
      // 36 km/h in 1 s = 10 m/s in 1 s = 10 m/s².
      expect(s.recentAccelMps2(), greaterThan(0));

      final d = BaselineRollingState();
      d.add(reading(speed: 36), base);
      d.add(reading(speed: 0), base.add(const Duration(seconds: 1)));
      expect(d.recentAccelMps2(), lessThan(0));
    });
  });

  group('signal selection', () {
    test('throttleSignal prefers real PID 0x11, falls back to load', () {
      expect(
        BaselineRollingState.throttleSignal(
            reading(throttle: 40, engineLoad: 90)),
        40,
      );
      expect(
        BaselineRollingState.throttleSignal(reading(engineLoad: 90)),
        90,
      );
      expect(BaselineRollingState.throttleSignal(reading()), isNull);
    });

    test('loadSignal prefers absolute load, falls back to engine load, '
        'then 0', () {
      expect(
        BaselineRollingState.loadSignal(
            reading(absLoad: 88, engineLoad: 60)),
        88,
      );
      expect(BaselineRollingState.loadSignal(reading(engineLoad: 60)), 60);
      expect(BaselineRollingState.loadSignal(reading()), 0);
    });
  });

  test('reset drops the window + grade state', () {
    final s = BaselineRollingState();
    final base = DateTime(2026);
    const pattern = [30.0, 0.0, 30.0, 0.0, 30.0, 0.0];
    for (var i = 0; i < pattern.length; i++) {
      s.add(reading(speed: pattern[i]), base.add(Duration(seconds: i)));
    }
    expect(s.isStopAndGoContext, isTrue);
    s.reset();
    expect(s.isStopAndGoContext, isFalse);
    expect(s.recentAccelMps2(), 0);
  });
}
