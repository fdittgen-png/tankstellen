// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/features/fill_ups/api.dart';
import 'package:tankstellen/features/search/providers/all_prices_table_provider.dart';

/// #3933 — the per-fuel consumption the all-prices table turns into a
/// cost per 100 km. Measured from the user's own full-to-full windows;
/// never guessed, and never attributed when the tank ran on two fuels.
void main() {
  FillUp fill({
    required String id,
    required int day,
    required double liters,
    required double odometerKm,
    required FuelType fuelType,
    bool isFullTank = true,
    bool isCorrection = false,
  }) => FillUp(
    id: id,
    date: DateTime.utc(2026, 1, day),
    liters: liters,
    totalCost: liters * 1.8,
    odometerKm: odometerKm,
    fuelType: fuelType,
    isFullTank: isFullTank,
    isCorrection: isCorrection,
    vehicleId: 'v1',
  );

  group('perFuelConsumptionFromFills', () {
    test('a single fill yields nothing — one tank is not a measurement', () {
      final result = perFuelConsumptionFromFills([
        fill(id: '1', day: 1, liters: 40, odometerKm: 1000,
            fuelType: FuelType.e10),
      ]);

      expect(result, isEmpty);
    });

    test('one closed single-fuel window gives litres per 100 km', () {
      // 30 L over 500 km = 6,0 L/100 km.
      final result = perFuelConsumptionFromFills([
        fill(id: '1', day: 1, liters: 40, odometerKm: 1000,
            fuelType: FuelType.e85),
        fill(id: '2', day: 10, liters: 30, odometerKm: 1500,
            fuelType: FuelType.e85),
      ]);

      expect(result[FuelType.e85], closeTo(6.0, 1e-9));
    });

    test('two fuels are measured independently', () {
      final result = perFuelConsumptionFromFills([
        fill(id: '1', day: 1, liters: 40, odometerKm: 1000,
            fuelType: FuelType.e85),
        fill(id: '2', day: 5, liters: 30, odometerKm: 1500,
            fuelType: FuelType.e85),
        fill(id: '3', day: 9, liters: 35, odometerKm: 2000,
            fuelType: FuelType.e10),
        fill(id: '4', day: 14, liters: 23, odometerKm: 2500,
            fuelType: FuelType.e10),
      ]);

      // e85: 30 L / 500 km; the e85→e10 crossover window is mixed and is
      // dropped; e10: 23 L / 500 km.
      expect(result[FuelType.e85], closeTo(6.0, 1e-9));
      expect(result[FuelType.e10], closeTo(4.6, 1e-9));
    });

    test('a mixed window is dropped rather than credited to one fuel', () {
      final result = perFuelConsumptionFromFills([
        fill(id: '1', day: 1, liters: 40, odometerKm: 1000,
            fuelType: FuelType.e10),
        fill(id: '2', day: 5, liters: 20, odometerKm: 1300,
            fuelType: FuelType.e85, isFullTank: false),
        fill(id: '3', day: 9, liters: 20, odometerKm: 1500,
            fuelType: FuelType.e85),
      ]);

      expect(result, isEmpty);
    });

    test('an odometer that never moved produces no number', () {
      final result = perFuelConsumptionFromFills([
        fill(id: '1', day: 1, liters: 40, odometerKm: 1000,
            fuelType: FuelType.e10),
        fill(id: '2', day: 5, liters: 30, odometerKm: 1000,
            fuelType: FuelType.e10),
      ]);

      expect(result, isEmpty);
    });

    test('a correction entry does not change the window fuel', () {
      final result = perFuelConsumptionFromFills([
        fill(id: '1', day: 1, liters: 40, odometerKm: 1000,
            fuelType: FuelType.e10),
        fill(id: '2', day: 3, liters: 2, odometerKm: 1200,
            fuelType: FuelType.e85, isFullTank: false, isCorrection: true),
        fill(id: '3', day: 5, liters: 28, odometerKm: 1500,
            fuelType: FuelType.e10),
      ]);

      // 2 + 28 = 30 L over 500 km.
      expect(result[FuelType.e10], closeTo(6.0, 1e-9));
    });
  });

  group('FuelCostModel', () {
    test('the empty model reports no consumption and dims nothing', () {
      expect(FuelCostModel.empty.hasConsumption, isFalse);
      expect(FuelCostModel.empty.usableFuels, isEmpty);
    });
  });
}
