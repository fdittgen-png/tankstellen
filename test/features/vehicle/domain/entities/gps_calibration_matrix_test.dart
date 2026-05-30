// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/vehicle/domain/entities/gps_calibration_matrix.dart';

void main() {
  group('GpsCalibrationMatrix.coldStart', () {
    test('uses the WLTP value when present and in-bounds', () {
      final m = GpsCalibrationMatrix.coldStart(wltp: 5.4);
      expect(m.baseline, closeTo(5.4, 0.0001));
      expect(m.idleCost,
          GpsCalibrationMatrix.defaultIdleCost);
      expect(m.highSpeedPenalty,
          GpsCalibrationMatrix.defaultHighSpeedPenalty);
      expect(m.accelEventCost,
          GpsCalibrationMatrix.defaultAccelEventCost);
      expect(m.fillUpReconciliationCount, 0);
      expect(m.lastReconciledAt, isNull);
    });

    test('falls back to the population median when WLTP is null', () {
      final m = GpsCalibrationMatrix.coldStart();
      expect(m.baseline,
          GpsCalibrationMatrix.defaultBaselineLPer100Km);
    });

    test('clamps obviously-bogus WLTP values back to the population median',
        () {
      // 0.5 L/100 km is implausible (sub-Prius) — out of bounds.
      final low = GpsCalibrationMatrix.coldStart(wltp: 0.5);
      expect(low.baseline,
          GpsCalibrationMatrix.defaultBaselineLPer100Km);
      // 22 L/100 km is implausible (heavy commercial truck) — out of bounds.
      final high = GpsCalibrationMatrix.coldStart(wltp: 22);
      expect(high.baseline,
          GpsCalibrationMatrix.defaultBaselineLPer100Km);
    });
  });

  group('GpsCalibrationMatrix.clamped', () {
    test('passes through values already inside the bounds', () {
      const m = GpsCalibrationMatrix(
        baseline: 6.0,
        idleCost: 1.0,
        highSpeedPenalty: 1.5,
        accelEventCost: 0.4,
      );
      final c = m.clamped();
      expect(c.baseline, 6.0);
      expect(c.idleCost, 1.0);
      expect(c.highSpeedPenalty, 1.5);
      expect(c.accelEventCost, 0.4);
    });

    test('clamps each coefficient to its per-field bounds', () {
      const m = GpsCalibrationMatrix(
        baseline: 50.0, // way over
        idleCost: -1.0, // below min
        highSpeedPenalty: 100.0, // way over
        accelEventCost: -5.0, // below min
      );
      final c = m.clamped();
      expect(c.baseline, GpsCalibrationMatrix.baselineMax);
      expect(c.idleCost, GpsCalibrationMatrix.idleCostMin);
      expect(c.highSpeedPenalty,
          GpsCalibrationMatrix.highSpeedPenaltyMax);
      expect(c.accelEventCost,
          GpsCalibrationMatrix.accelEventCostMin);
    });
  });

  group('GpsCalibrationMatrix.maturity', () {
    test('cold when fewer than 3 reconciliations', () {
      const m = GpsCalibrationMatrix(fillUpReconciliationCount: 2);
      expect(m.maturity, GpsCalibrationMaturity.cold);
    });

    test('warming with 3–7 reconciliations and variance ≤ 1.5', () {
      const m = GpsCalibrationMatrix(
        fillUpReconciliationCount: 5,
        residualVariance: 1.0,
      );
      expect(m.maturity, GpsCalibrationMaturity.warming);
    });

    test('converged at 8+ reconciliations and variance ≤ 0.5', () {
      const m = GpsCalibrationMatrix(
        fillUpReconciliationCount: 9,
        residualVariance: 0.3,
      );
      expect(m.maturity, GpsCalibrationMaturity.converged);
    });

    test('a high variance keeps the matrix cold even with many reconciliations',
        () {
      const m = GpsCalibrationMatrix(
        fillUpReconciliationCount: 10,
        residualVariance: 2.5, // > 1.5
      );
      expect(m.maturity, GpsCalibrationMaturity.cold);
    });
  });

  group('GpsCalibrationMatrix.isExpanded7Coef', () {
    test('false in the lean default state', () {
      const m = GpsCalibrationMatrix();
      expect(m.isExpanded7Coef, isFalse);
    });

    test('true only when all three expansion slots are populated', () {
      const partial = GpsCalibrationMatrix(brakeEventCost: 0.1);
      expect(partial.isExpanded7Coef, isFalse);

      const full = GpsCalibrationMatrix(
        brakeEventCost: 0.1,
        gradeClimbCost: 0.05,
        cornerLoadCost: 0.02,
      );
      expect(full.isExpanded7Coef, isTrue);
    });
  });

  group('GpsCalibrationMatrix JSON round-trip', () {
    test('serialises + deserialises identically', () {
      const m = GpsCalibrationMatrix(
        baseline: 5.8,
        idleCost: 1.4,
        highSpeedPenalty: 2.2,
        accelEventCost: 0.6,
        fillUpReconciliationCount: 4,
        residualVariance: 0.8,
        physicsScale: 1.12,
      );
      final json = m.toJson();
      final decoded = GpsCalibrationMatrix.fromJson(json);
      expect(decoded.baseline, m.baseline);
      expect(decoded.idleCost, m.idleCost);
      expect(decoded.highSpeedPenalty, m.highSpeedPenalty);
      expect(decoded.accelEventCost, m.accelEventCost);
      expect(decoded.fillUpReconciliationCount,
          m.fillUpReconciliationCount);
      expect(decoded.residualVariance, m.residualVariance);
      expect(decoded.physicsScale, m.physicsScale);
    });
  });

  group('GpsCalibrationMatrix.physicsScale', () {
    test('defaults to 1.0 on a freshly-constructed matrix', () {
      const m = GpsCalibrationMatrix();
      expect(m.physicsScale, 1.0);
    });

    test('cold-start seeds physicsScale to the 1.0 default', () {
      final m = GpsCalibrationMatrix.coldStart(wltp: 6.0);
      expect(m.physicsScale, 1.0);
    });

    test('survives a JSON round-trip', () {
      const m = GpsCalibrationMatrix(physicsScale: 0.93);
      final decoded = GpsCalibrationMatrix.fromJson(m.toJson());
      expect(decoded.physicsScale, 0.93);
    });

    test('legacy blob without physicsScale deserialises to the 1.0 default',
        () {
      // A pre-#2388 Hive payload simply omits the field — freezed's
      // @Default(1.0) must fill it in (free migration, no data loss).
      final legacy = <String, dynamic>{
        'baseline': 6.5,
        'idleCost': 1.2,
        'highSpeedPenalty': 2.0,
        'accelEventCost': 0.5,
        'fillUpReconciliationCount': 3,
        'residualVariance': 0.4,
      };
      final decoded = GpsCalibrationMatrix.fromJson(legacy);
      expect(decoded.physicsScale, 1.0);
      // The rest of the legacy payload still maps across cleanly.
      expect(decoded.baseline, 6.5);
      expect(decoded.fillUpReconciliationCount, 3);
    });
  });
}
