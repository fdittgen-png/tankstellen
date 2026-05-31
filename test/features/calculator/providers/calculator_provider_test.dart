// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/calculator/data/models/trip_calculation.dart';
import 'package:tankstellen/features/calculator/providers/calculator_provider.dart';

void main() {
  group('TripCalculation', () {
    test('calculates 100km at 7L/100km at 1.90 EUR = 13.30 EUR', () {
      const calc = TripCalculation(
        distanceKm: 100,
        consumptionPer100Km: 7,
        pricePerLiter: 1.90,
      );

      expect(calc.totalLiters, 7.0);
      expect(calc.totalCost, closeTo(13.30, 0.001));
    });

    test('zero distance yields zero cost', () {
      const calc = TripCalculation(
        distanceKm: 0,
        consumptionPer100Km: 7,
        pricePerLiter: 1.90,
      );

      expect(calc.totalLiters, 0.0);
      expect(calc.totalCost, 0.0);
    });

    test('totalLiters getter computes correctly for 250km at 8.5L/100km', () {
      const calc = TripCalculation(
        distanceKm: 250,
        consumptionPer100Km: 8.5,
        pricePerLiter: 1.75,
      );

      expect(calc.totalLiters, closeTo(21.25, 0.001));
      expect(calc.totalCost, closeTo(37.1875, 0.001));
    });
  });

  group('Calculator notifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('setDistance updates state and recalculates', () {
      final notifier = container.read(calculatorProvider.notifier);

      notifier.setDistance(100);
      notifier.setConsumption(7);
      notifier.setPrice(1.90);

      final state = container.read(calculatorProvider);
      expect(state.hasInput, true);
      expect(state.calculation.totalCost, closeTo(13.30, 0.001));
    });

    test('reset returns to default state', () {
      final notifier = container.read(calculatorProvider.notifier);

      notifier.setDistance(200);
      notifier.setPrice(1.80);
      notifier.setRoundTrip(true);
      notifier.setTripsPerMonth(20);
      notifier.reset();

      final state = container.read(calculatorProvider);
      expect(state.distanceKm, 0);
      expect(state.consumptionPer100Km, 7.0);
      expect(state.pricePerLiter, 0);
      expect(state.roundTrip, false);
      expect(state.tripsPerMonth, isNull);
      expect(state.hasInput, false);
    });

    test('setRoundTrip flips the flag without touching distance', () {
      final notifier = container.read(calculatorProvider.notifier);
      notifier.setDistance(150);
      notifier.setRoundTrip(true);

      final state = container.read(calculatorProvider);
      expect(state.roundTrip, true);
      expect(state.distanceKm, 150);
    });

    test('setTripsPerMonth stores positive, clears on null/zero', () {
      final notifier = container.read(calculatorProvider.notifier);

      notifier.setTripsPerMonth(12);
      expect(container.read(calculatorProvider).tripsPerMonth, 12);

      notifier.setTripsPerMonth(0);
      expect(container.read(calculatorProvider).tripsPerMonth, isNull);

      notifier.setTripsPerMonth(8);
      notifier.setTripsPerMonth(null);
      expect(container.read(calculatorProvider).tripsPerMonth, isNull);
    });

    test('copyWith leaves tripsPerMonth untouched when not passed', () {
      const state = CalculatorState(tripsPerMonth: 15);
      final next = state.copyWith(distanceKm: 50);
      expect(next.tripsPerMonth, 15);
      expect(next.distanceKm, 50);
    });
  });
}
