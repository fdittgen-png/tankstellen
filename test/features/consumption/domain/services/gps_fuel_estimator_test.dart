// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/gps_driving_features.dart';
import 'package:tankstellen/features/consumption/domain/services/gps_fuel_estimator.dart';
import 'package:tankstellen/core/domain/gps_calibration_matrix.dart';

GpsDrivingFeatures _features({
  required double distanceKm,
  required double totalSeconds,
  double idleSeconds = 0,
  double highSpeedSeconds = 0,
  int accelEvents = 0,
}) =>
    GpsDrivingFeatures(
      idleSeconds: idleSeconds,
      lowSpeedSeconds: 0,
      cruiseSeconds: totalSeconds - idleSeconds - highSpeedSeconds,
      highSpeedSeconds: highSpeedSeconds,
      accelEvents: accelEvents,
      brakeEvents: 0,
      maxAccelG: 0,
      meanSpeedKmh: distanceKm / (totalSeconds / 3600.0),
      distanceKm: distanceKm,
      totalSeconds: totalSeconds,
      gradeClimbMeters: 0,
      gradeDescentMeters: 0,
      cornerLoadIntegral: 0,
    );

void main() {
  group('GpsFuelEstimator.estimate', () {
    test('null on zero-distance features', () {
      final f = _features(distanceKm: 0, totalSeconds: 300);
      final r = GpsFuelEstimator.estimate(
        matrix: GpsCalibrationMatrix.coldStart(),
        features: f,
      );
      expect(r, isNull);
    });

    test('pure cruise returns ~baseline L/100 km', () {
      // All cruise — every share-coefficient is zero.
      final f = _features(distanceKm: 100, totalSeconds: 4500); // 80 km/h cruise
      final m = GpsCalibrationMatrix.coldStart(wltp: 6.0);
      final r = GpsFuelEstimator.estimate(matrix: m, features: f)!;
      expect(r.lPer100Km, closeTo(6.0, 0.01));
      expect(r.litersConsumed, closeTo(6.0, 0.01));
    });

    test('idle share bumps L/100 km via idleCost', () {
      // 50 % idle, 50 % cruise over a 100 km / 2 h trajet.
      final f = _features(
        distanceKm: 100,
        totalSeconds: 7200,
        idleSeconds: 3600,
      );
      final m = GpsCalibrationMatrix.coldStart(wltp: 6.0);
      // Default idleCost = 1.2 → +0.6 L/100 km.
      final r = GpsFuelEstimator.estimate(matrix: m, features: f)!;
      expect(r.lPer100Km, closeTo(6.6, 0.05));
    });

    test('clamps to [minLPer100Km, maxLPer100Km] for degenerate matrix', () {
      // Negative baseline (impossible in practice — clamping at the
      // entity level prevents this — but the estimator stays defensive).
      const m = GpsCalibrationMatrix(
        baseline: 0.0,
        idleCost: 0,
        highSpeedPenalty: 0,
        accelEventCost: 0,
      );
      final f = _features(distanceKm: 10, totalSeconds: 600);
      final r = GpsFuelEstimator.estimate(matrix: m, features: f)!;
      expect(r.lPer100Km, GpsFuelEstimator.minLPer100Km);
    });

    test('liters = lPer100Km × distanceKm / 100', () {
      final f = _features(distanceKm: 50, totalSeconds: 2250); // 80 km/h
      final m = GpsCalibrationMatrix.coldStart(wltp: 8.0);
      final r = GpsFuelEstimator.estimate(matrix: m, features: f)!;
      expect(r.litersConsumed, closeTo(8.0 * 50 / 100, 0.01)); // 4 L
    });
  });
}
