import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/route_search/data/strategies/eco_savings_estimator.dart';

/// Unit tests for [EcoSavingsEstimator] (epic #1612, child #1631).
///
/// The estimator is a pure calculation — no I/O, no async — so every
/// branch of `estimateLitersSaved` is exercised directly: the happy
/// path, the negative-delta clamp, and each guard (zero/negative
/// consumption, zero/negative distance).
void main() {
  group('EcoSavingsEstimator constants', () {
    test('exposes the documented EU-fleet defaults', () {
      expect(EcoSavingsEstimator.defaultConsumptionLPer100km, 7.0);
      expect(EcoSavingsEstimator.ecoEfficiencyLift, 0.07);
    });
  });

  group('EcoSavingsEstimator.estimateLitersSaved — happy path', () {
    test('equal-distance routes save the efficiency-lift fraction', () {
      // fastest: 100 km * 7 / 100 = 7.0 L
      // eco consumption: 7 / 1.07 = 6.5420... L/100km
      // eco: 100 km * 6.5420 / 100 = 6.5420 L
      // delta = 7.0 - 6.5420 = 0.4579...
      final saved = EcoSavingsEstimator.estimateLitersSaved(
        fastestDistanceKm: 100,
        ecoDistanceKm: 100,
        consumptionLPer100km: 7.0,
      );
      expect(saved, closeTo(0.4579, 0.001));
    });

    test('scales linearly with distance', () {
      final short = EcoSavingsEstimator.estimateLitersSaved(
        fastestDistanceKm: 100,
        ecoDistanceKm: 100,
        consumptionLPer100km: 7.0,
      );
      final long = EcoSavingsEstimator.estimateLitersSaved(
        fastestDistanceKm: 300,
        ecoDistanceKm: 300,
        consumptionLPer100km: 7.0,
      );
      expect(long, closeTo(short * 3, 0.001));
    });
  });

  group('EcoSavingsEstimator.estimateLitersSaved — negative-delta clamp', () {
    test('returns 0 when the eco route is so much longer it burns more', () {
      // fastest: 50 km * 7 / 100 = 3.5 L
      // eco: 200 km * 6.542 / 100 = 13.08 L  -> delta is negative
      final saved = EcoSavingsEstimator.estimateLitersSaved(
        fastestDistanceKm: 50,
        ecoDistanceKm: 200,
        consumptionLPer100km: 7.0,
      );
      expect(saved, 0.0);
    });

    test('never returns a negative value', () {
      final saved = EcoSavingsEstimator.estimateLitersSaved(
        fastestDistanceKm: 10,
        ecoDistanceKm: 1000,
        consumptionLPer100km: 9.5,
      );
      expect(saved, greaterThanOrEqualTo(0.0));
    });
  });

  group('EcoSavingsEstimator.estimateLitersSaved — guards', () {
    test('zero consumption returns 0', () {
      expect(
        EcoSavingsEstimator.estimateLitersSaved(
          fastestDistanceKm: 100,
          ecoDistanceKm: 100,
          consumptionLPer100km: 0,
        ),
        0.0,
      );
    });

    test('negative consumption returns 0', () {
      expect(
        EcoSavingsEstimator.estimateLitersSaved(
          fastestDistanceKm: 100,
          ecoDistanceKm: 100,
          consumptionLPer100km: -7.0,
        ),
        0.0,
      );
    });

    test('zero fastest distance returns 0', () {
      expect(
        EcoSavingsEstimator.estimateLitersSaved(
          fastestDistanceKm: 0,
          ecoDistanceKm: 100,
          consumptionLPer100km: 7.0,
        ),
        0.0,
      );
    });

    test('zero eco distance returns 0', () {
      expect(
        EcoSavingsEstimator.estimateLitersSaved(
          fastestDistanceKm: 100,
          ecoDistanceKm: 0,
          consumptionLPer100km: 7.0,
        ),
        0.0,
      );
    });

    test('negative distances return 0', () {
      expect(
        EcoSavingsEstimator.estimateLitersSaved(
          fastestDistanceKm: -100,
          ecoDistanceKm: 100,
          consumptionLPer100km: 7.0,
        ),
        0.0,
      );
      expect(
        EcoSavingsEstimator.estimateLitersSaved(
          fastestDistanceKm: 100,
          ecoDistanceKm: -100,
          consumptionLPer100km: 7.0,
        ),
        0.0,
      );
    });
  });
}
