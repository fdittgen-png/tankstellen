import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/services/trip_consumption_reliability.dart';

/// Pure-predicate tests for the #2835 consumption reliability gates.
///
/// These thresholds are shared by the live recorder and the monthly
/// re-integration aggregator, so they get their own focused tests in
/// addition to the through-the-recorder integration coverage.
void main() {
  group('isDistanceReliableForRatio (#2835 tiny-distance gate)', () {
    test('rejects a sub-floor distance (the 0.4 km blow-up case)', () {
      expect(isDistanceReliableForRatio(0.4), isFalse);
    });

    test('accepts a distance at the floor', () {
      expect(
        isDistanceReliableForRatio(kMinReliableConsumptionDistanceKm),
        isTrue,
      );
    });

    test('accepts a comfortably-long trip', () {
      expect(isDistanceReliableForRatio(58.8), isTrue);
    });
  });

  group('isFuelCadenceReliable (#2835 sparse-cadence gate)', () {
    test('rejects when no interval contributed litres', () {
      expect(
        isFuelCadenceReliable(fuelIntervalCount: 0, fuelIntegratedSeconds: 0),
        isFalse,
      );
    });

    test('rejects a ~1/min mean interval (the field-backup sparse trip)', () {
      // 70 intervals of 60 s each — mean 60 s, beyond the 30 s ceiling.
      expect(
        isFuelCadenceReliable(
          fuelIntervalCount: 70,
          fuelIntegratedSeconds: 70 * 60,
        ),
        isFalse,
      );
    });

    test('accepts a dense 1 Hz cadence', () {
      expect(
        isFuelCadenceReliable(
          fuelIntervalCount: 300,
          fuelIntegratedSeconds: 300,
        ),
        isTrue,
      );
    });

    test('accepts exactly the cadence ceiling', () {
      expect(
        isFuelCadenceReliable(
          fuelIntervalCount: 10,
          fuelIntegratedSeconds: 10 * kMaxReliableFuelIntervalSeconds,
        ),
        isTrue,
      );
    });
  });

  group('isTripConsumptionReliable (both gates ANDed)', () {
    test('true only when distance AND cadence both pass', () {
      expect(
        isTripConsumptionReliable(
          distanceKm: 50,
          fuelIntervalCount: 300,
          fuelIntegratedSeconds: 300,
        ),
        isTrue,
      );
    });

    test('false when distance is tiny even if cadence is dense', () {
      expect(
        isTripConsumptionReliable(
          distanceKm: 0.4,
          fuelIntervalCount: 100,
          fuelIntegratedSeconds: 100,
        ),
        isFalse,
      );
    });

    test('false when cadence is sparse even over a long distance', () {
      expect(
        isTripConsumptionReliable(
          distanceKm: 58.8,
          fuelIntervalCount: 60,
          fuelIntegratedSeconds: 60 * 60,
        ),
        isFalse,
      );
    });
  });
}
