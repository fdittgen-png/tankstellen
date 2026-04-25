import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/calculator/data/models/trip_calculation.dart';

void main() {
  group('TripCalculation.totalLiters', () {
    test('computes liters for a typical trip (500 km @ 6.5 L/100km)', () {
      const calc = TripCalculation(
        distanceKm: 500,
        consumptionPer100Km: 6.5,
        pricePerLiter: 1.85,
      );
      // 500 * 6.5 / 100 = 32.5 L
      expect(calc.totalLiters, closeTo(32.5, 1e-9));
    });

    test('returns zero when distance is zero', () {
      const calc = TripCalculation(
        distanceKm: 0,
        consumptionPer100Km: 7.0,
        pricePerLiter: 1.75,
      );
      expect(calc.totalLiters, 0);
    });

    test('returns zero when consumption is zero', () {
      const calc = TripCalculation(
        distanceKm: 250,
        consumptionPer100Km: 0,
        pricePerLiter: 1.50,
      );
      expect(calc.totalLiters, 0);
    });

    test('is independent of pricePerLiter', () {
      const cheap = TripCalculation(
        distanceKm: 100,
        consumptionPer100Km: 8,
        pricePerLiter: 0,
      );
      const expensive = TripCalculation(
        distanceKm: 100,
        consumptionPer100Km: 8,
        pricePerLiter: 99.99,
      );
      expect(cheap.totalLiters, expensive.totalLiters);
      expect(cheap.totalLiters, closeTo(8, 1e-9));
    });
  });

  group('TripCalculation.totalCost', () {
    test('computes cost for a typical trip (500 km @ 6.5 L/100km @ 1.85)', () {
      const calc = TripCalculation(
        distanceKm: 500,
        consumptionPer100Km: 6.5,
        pricePerLiter: 1.85,
      );
      // 32.5 L * 1.85 = 60.125
      expect(calc.totalCost, closeTo(60.125, 1e-9));
      expect(calc.totalCost, closeTo(calc.totalLiters * 1.85, 1e-9));
    });

    test('returns zero when distance is zero', () {
      const calc = TripCalculation(
        distanceKm: 0,
        consumptionPer100Km: 7.0,
        pricePerLiter: 1.75,
      );
      expect(calc.totalCost, 0);
    });

    test('returns zero when consumption is zero', () {
      const calc = TripCalculation(
        distanceKm: 300,
        consumptionPer100Km: 0,
        pricePerLiter: 2.10,
      );
      expect(calc.totalCost, 0);
    });

    test('returns zero when pricePerLiter is zero', () {
      const calc = TripCalculation(
        distanceKm: 400,
        consumptionPer100Km: 5.5,
        pricePerLiter: 0,
      );
      expect(calc.totalCost, 0);
      // Sanity: liters are still computed.
      expect(calc.totalLiters, closeTo(22, 1e-9));
    });

    test('scales linearly with price', () {
      const a = TripCalculation(
        distanceKm: 100,
        consumptionPer100Km: 10,
        pricePerLiter: 1,
      );
      const b = TripCalculation(
        distanceKm: 100,
        consumptionPer100Km: 10,
        pricePerLiter: 2,
      );
      expect(b.totalCost, closeTo(2 * a.totalCost, 1e-9));
    });
  });
}
