// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/climb_restart_detector.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';

/// #2693 C6 — pure climb detection. The climb detector recomputes
/// confident road grade with the SAME RoadGradeCalculator config the live
/// folder uses (150 m / 0.2 / 5) and attributes the extra fuel. (#2694 C8
/// adds the stop-and-go-restart detector + its tests.)
void main() {
  final start = DateTime.utc(2026);

  // 10 m/s (36 km/h), one sample every 3 s → 30 m apart, so a 150 m grade
  // window spans ~6 samples (clears the minSamplesInWindow=5 gate).
  List<TripSample> climbStream({
    required double gradeFraction,
    int count = 40,
    double? fuelRate = 8,
  }) {
    final samples = <TripSample>[];
    var altitude = 100.0;
    const stepM = 30.0;
    for (var i = 0; i < count; i++) {
      samples.add(TripSample(
        timestamp: start.add(Duration(seconds: i * 3)),
        speedKmh: 36,
        rpm: 2200,
        altitudeM: altitude,
        fuelRateLPerHour: fuelRate,
      ));
      altitude += stepM * gradeFraction; // rise per 30 m step
    }
    return samples;
  }

  group('#2693 C6 detectClimbCost', () {
    test('a confident ~6% climb yields a climbing cost + the expected grade',
        () {
      final result = detectClimbCost(climbStream(gradeFraction: 0.06));
      expect(result.climbingLiters, greaterThan(0));
      expect(result.climbSeconds, greaterThan(0));
      // Smoothing lags the raw 6 % a little; assert the right ballpark.
      expect(result.peakGradePercent, greaterThan(3.0));
      expect(result.peakGradePercent, lessThan(7.0));
    });

    test('a flat stream (zero grade) yields NO climbing cost', () {
      final result = detectClimbCost(climbStream(gradeFraction: 0.0));
      expect(result.climbingLiters, 0);
      expect(result.climbSeconds, 0);
      expect(result.peakGradePercent, 0);
    });

    test('a gentle 1% slope stays under the climb threshold → no cost', () {
      final result = detectClimbCost(climbStream(gradeFraction: 0.01));
      expect(result.climbingLiters, 0);
    });

    test('a GPS-only climb (no fuel rate) still estimates via the fallback',
        () {
      final result =
          detectClimbCost(climbStream(gradeFraction: 0.06, fuelRate: null));
      expect(result.climbingLiters, greaterThan(0));
    });

    test('fewer than two samples → none', () {
      expect(detectClimbCost(const []), ClimbCostResult.none);
    });
  });
}
