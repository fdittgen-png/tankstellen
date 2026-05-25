// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/gps_driving_features.dart';
import 'package:tankstellen/features/consumption/domain/services/gps_matrix_reconciler.dart';
import 'package:tankstellen/features/vehicle/domain/entities/gps_calibration_matrix.dart';

GpsDrivingFeatures _features({
  required double distanceKm,
  double totalSeconds = 3600,
}) =>
    GpsDrivingFeatures(
      idleSeconds: 0,
      lowSpeedSeconds: 0,
      cruiseSeconds: totalSeconds,
      highSpeedSeconds: 0,
      accelEvents: 0,
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
  group('GpsMatrixReconciler.reconcile', () {
    test('null on empty trajets', () {
      final r = GpsMatrixReconciler.reconcile(
        matrix: GpsCalibrationMatrix.coldStart(),
        trajets: const [],
        actualLitersBurned: 5,
        totalDistanceKm: 100,
        recentResiduals: const [],
      );
      expect(r, isNull);
    });

    test('null on zero distance', () {
      final r = GpsMatrixReconciler.reconcile(
        matrix: GpsCalibrationMatrix.coldStart(),
        trajets: [_features(distanceKm: 10)],
        actualLitersBurned: 5,
        totalDistanceKm: 0,
        recentResiduals: const [],
      );
      expect(r, isNull);
    });

    test('over-predicting matrix steps baseline DOWN toward the truth', () {
      // Cold start baseline = 6.5; actual L/100 = 5.0 → matrix
      // over-predicts. Baseline should shift down toward 5.0 but not
      // jump there in one step.
      const matrix = GpsCalibrationMatrix(baseline: 6.5);
      final trajets = [_features(distanceKm: 100)];
      final r = GpsMatrixReconciler.reconcile(
        matrix: matrix,
        trajets: trajets,
        actualLitersBurned: 5.0, // 5.0 L over 100 km = 5.0 L/100
        totalDistanceKm: 100,
        recentResiduals: const [],
      )!;
      // After one EWMA step with alpha=0.3:
      //   newBaseline = 6.5 × (1 + 0.3 × (5/6.5 − 1)) = 6.5 × 0.93 ≈ 6.05
      expect(r.baseline, lessThan(6.5));
      expect(r.baseline, greaterThan(5.5));
    });

    test('under-predicting matrix steps baseline UP toward the truth', () {
      const matrix = GpsCalibrationMatrix(baseline: 5.0);
      final trajets = [_features(distanceKm: 100)];
      final r = GpsMatrixReconciler.reconcile(
        matrix: matrix,
        trajets: trajets,
        actualLitersBurned: 8.0, // 8.0 L/100
        totalDistanceKm: 100,
        recentResiduals: const [],
      )!;
      expect(r.baseline, greaterThan(5.0));
      expect(r.baseline, lessThan(8.0));
    });

    test('bookkeeping — count increments, lastReconciledAt stamped', () {
      const matrix = GpsCalibrationMatrix(
        baseline: 6.5,
        fillUpReconciliationCount: 4,
      );
      final r = GpsMatrixReconciler.reconcile(
        matrix: matrix,
        trajets: [_features(distanceKm: 100)],
        actualLitersBurned: 6.0,
        totalDistanceKm: 100,
        recentResiduals: const [],
        now: DateTime.utc(2026, 5, 25, 18),
      )!;
      expect(r.fillUpReconciliationCount, 5);
      expect(r.lastReconciledAt, DateTime.utc(2026, 5, 25, 18));
    });

    test('clamps baseline to GpsCalibrationMatrix bounds', () {
      // Wild divergence — actual 50 L/100 km on a baseline of 6 →
      // ratio = 50/6 ≈ 8.3, baseline jumps to ~6 × (1 + 0.3 × 7.3)
      // = ~19 L/100 km, which then clamps to baselineMax = 15.
      const matrix = GpsCalibrationMatrix(baseline: 6.0);
      final r = GpsMatrixReconciler.reconcile(
        matrix: matrix,
        trajets: [_features(distanceKm: 100)],
        actualLitersBurned: 50.0,
        totalDistanceKm: 100,
        recentResiduals: const [],
      )!;
      expect(r.baseline, lessThanOrEqualTo(GpsCalibrationMatrix.baselineMax));
    });

    test('converges across multiple fill-ups (#2083 monotone narrowing)',
        () {
      // Synthetic: real consumption is 7.0 L/100 km. Matrix starts
      // at 5.0 (under-predicting). Apply 5 successive fill-ups; the
      // predicted-vs-actual gap should narrow monotonically.
      const truth = 7.0;
      var matrix = const GpsCalibrationMatrix(baseline: 5.0);
      final gaps = <double>[];
      for (var i = 0; i < 5; i++) {
        final predicted = matrix.baseline;
        gaps.add((truth - predicted).abs());
        matrix = GpsMatrixReconciler.reconcile(
          matrix: matrix,
          trajets: [_features(distanceKm: 100)],
          actualLitersBurned: truth, // L per 100 km
          totalDistanceKm: 100,
          recentResiduals: const [],
        )!;
      }
      // Each gap should be strictly smaller than the previous.
      for (var i = 1; i < gaps.length; i++) {
        expect(gaps[i], lessThan(gaps[i - 1]),
            reason: 'gap[$i]=${gaps[i]} not narrower than gap[${i - 1}]=${gaps[i - 1]}');
      }
      // After 5 iterations, the matrix should be within 10 % of truth.
      expect((truth - matrix.baseline).abs() / truth, lessThan(0.10));
    });
  });
}
