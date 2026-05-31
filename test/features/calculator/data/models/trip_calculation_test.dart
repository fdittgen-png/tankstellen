// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

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

  group('TripCalculation.costPerKm', () {
    test('is totalCost / distance for a normal trip', () {
      const calc = TripCalculation(
        distanceKm: 200,
        consumptionPer100Km: 6,
        pricePerLiter: 1.5,
      );
      // 200 * 6 / 100 = 12 L; 12 * 1.5 = 18 €; / 200 km = 0.09 €/km.
      expect(calc.costPerKm, closeTo(0.09, 1e-9));
    });

    test('guards a zero distance — returns 0, not NaN/Infinity', () {
      const calc = TripCalculation(
        distanceKm: 0,
        consumptionPer100Km: 7,
        pricePerLiter: 1.9,
      );
      expect(calc.costPerKm, 0);
      expect(calc.costPerKm.isFinite, isTrue);
    });
  });

  group('TripCalculation round-trip', () {
    const calc = TripCalculation(
      distanceKm: 100,
      consumptionPer100Km: 7,
      pricePerLiter: 2,
    );

    test('roundTripCost doubles the one-way total', () {
      expect(calc.roundTripCost, closeTo(2 * calc.totalCost, 1e-9));
      expect(calc.roundTripLiters, closeTo(2 * calc.totalLiters, 1e-9));
    });

    test('effectiveCost honours the round-trip flag', () {
      expect(calc.effectiveCost(roundTrip: false), calc.totalCost);
      expect(calc.effectiveCost(roundTrip: true), calc.roundTripCost);
    });

    test('does not mutate the input distance', () {
      // The one-way distance the caller passed in is untouched.
      expect(calc.distanceKm, 100);
    });
  });

  group('TripCalculation.monthlyCost', () {
    const calc = TripCalculation(
      distanceKm: 100,
      consumptionPer100Km: 7,
      pricePerLiter: 2,
    );

    test('multiplies the effective cost by trips/month', () {
      // one-way 14 €, ×20 = 280 €.
      expect(
        calc.monthlyCost(roundTrip: false, tripsPerMonth: 20),
        closeTo(280, 1e-9),
      );
      // round-trip 28 €, ×20 = 560 €.
      expect(
        calc.monthlyCost(roundTrip: true, tripsPerMonth: 20),
        closeTo(560, 1e-9),
      );
    });

    test('returns 0 when trips/month is null or non-positive', () {
      expect(calc.monthlyCost(roundTrip: false, tripsPerMonth: null), 0);
      expect(calc.monthlyCost(roundTrip: false, tripsPerMonth: 0), 0);
      expect(calc.monthlyCost(roundTrip: false, tripsPerMonth: -3), 0);
    });
  });
}
