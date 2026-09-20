// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/money_tally.dart';
import 'package:tankstellen/features/fill_ups/domain/entities/consumption_stats.dart';
import 'package:tankstellen/features/fill_ups/domain/entities/fill_up.dart';
import 'package:tankstellen/core/utils/price_formatter.dart';

/// #4364 — the correction reaching the NAMED canonical aggregation path
/// (acceptance box 10): `ConsumptionStats.fromFillUps` is what the
/// consumption screen, the Fuel tab card, the monthly charts and the
/// home cost block all read.
FillUp _f({
  required String id,
  required DateTime date,
  required double liters,
  required double cost,
  required double odo,
  String? currency,
  FuelType fuelType = FuelType.e10,
  bool isFullTank = true,
}) =>
    FillUp(
      id: id,
      date: date,
      liters: liters,
      totalCost: cost,
      odometerKm: odo,
      fuelType: fuelType,
      isFullTank: isFullTank,
      currency: currency,
    );

void main() {
  group('currency segregation (box 1 + 2)', () {
    test('€30 and DKK 225 do not become 255 in the headline total', () {
      final stats = ConsumptionStats.fromFillUps([
        _f(id: '1', date: DateTime(2026, 1, 1), liters: 20, cost: 30, odo: 1000, currency: 'EUR'),
        _f(id: '2', date: DateTime(2026, 1, 20), liters: 30, cost: 225, odo: 1500, currency: 'DKK'),
      ]);

      expect(stats.totalSpent, isNull, reason: 'no single denomination');
      expect(stats.spend.amountIn('EUR'), 30);
      expect(stats.spend.amountIn('DKK'), 225);
      expect(stats.avgPricePerLiter, isNull);
      expect(stats.avgCostPerKm, isNull);
      // The quantities survive: only the money is withheld.
      expect(stats.totalLiters, 50);
      expect(stats.totalDistanceKm, 500);
    });

    test('a single-currency history behaves exactly as before', () {
      final stats = ConsumptionStats.fromFillUps([
        _f(id: '1', date: DateTime(2026, 1, 1), liters: 20, cost: 30, odo: 1000, currency: 'EUR'),
        _f(id: '2', date: DateTime(2026, 1, 20), liters: 30, cost: 45, odo: 1500, currency: 'EUR'),
      ]);

      expect(stats.totalSpent, 75);
      expect(stats.avgPricePerLiter, closeTo(1.5, 1e-9));
      expect(stats.avgCostPerKm, closeTo(45 / 500, 1e-9));
      expect(stats.spend.soleCurrency, 'EUR');
    });

    test('unknown-currency fills keep their quantities and their own bucket',
        () {
      final stats = ConsumptionStats.fromFillUps([
        _f(id: '1', date: DateTime(2026, 1, 1), liters: 20, cost: 30, odo: 1000),
        _f(id: '2', date: DateTime(2026, 1, 20), liters: 30, cost: 45, odo: 1500),
      ]);

      expect(stats.spend.currencies, [kUnknownCurrency]);
      expect(stats.spend.hasUnknownCurrency, isTrue);
      expect(stats.spend.soleMoney, isNull, reason: 'cannot be named');
      expect(stats.totalLiters, 50);
    });

    test('unknown never merges into a named currency', () {
      final stats = ConsumptionStats.fromFillUps([
        _f(id: '1', date: DateTime(2026, 1, 1), liters: 20, cost: 30, odo: 1000, currency: 'EUR'),
        _f(id: '2', date: DateTime(2026, 1, 20), liters: 30, cost: 45, odo: 1500),
      ]);

      expect(stats.totalSpent, isNull);
      expect(stats.spend.amountIn('EUR'), 30);
      expect(stats.spend.byCurrency[kUnknownCurrency], 45);
    });

    test('changing the active country does not relabel historical money', () {
      final fills = [
        _f(id: '1', date: DateTime(2026, 1, 1), liters: 20, cost: 30, odo: 1000),
        _f(id: '2', date: DateTime(2026, 1, 20), liters: 30, cost: 45, odo: 1500),
      ];
      final before = ConsumptionStats.fromFillUps(fills);

      // Whatever the app's active currency happens to be, the aggregation
      // must not consult it: the same fills produce the same buckets.
      PriceFormatter.setCountry('DK');
      addTearDown(() => PriceFormatter.setCountry('DE'));
      expect(PriceFormatter.currencyCode, 'DKK');
      final after = ConsumptionStats.fromFillUps(fills);

      expect(after.spend, before.spend);
      expect(after.spend.currencies, [kUnknownCurrency]);
      expect(after.spend.currencies, isNot(contains('DKK')));
    });
  });

  group('missing costs (box 6)', () {
    test('an unpriced fill does not shrink the €/km numerator', () {
      // Window 1: 45.00 over 500 km. Window 2: no price at all.
      // Summing 45 over 1000 km would halve the cost per km and
      // manufacture a cheaper vehicle out of missing data.
      final stats = ConsumptionStats.fromFillUps([
        _f(id: '1', date: DateTime(2026, 1, 1), liters: 20, cost: 30, odo: 1000, currency: 'EUR'),
        _f(id: '2', date: DateTime(2026, 1, 20), liters: 30, cost: 45, odo: 1500, currency: 'EUR'),
        _f(id: '3', date: DateTime(2026, 2, 10), liters: 30, cost: 0, odo: 2000, currency: 'EUR'),
      ]);

      expect(stats.unpricedFillCount, 1);
      expect(stats.unpricedClosedWindowFillCount, 1);
      expect(stats.avgCostPerKm, isNull);
      expect(stats.avgCostPerKm, isNot(0),
          reason: 'absent, never a cheaper number');
      // Distance and litres are untouched — the observation survives.
      expect(stats.totalDistanceKm, 1000);
      expect(stats.avgConsumptionL100km, closeTo(60 / 1000 * 100, 1e-9));
    });

    test('price per litre uses only the litres that carried a price', () {
      final stats = ConsumptionStats.fromFillUps([
        _f(id: '1', date: DateTime(2026, 1, 1), liters: 20, cost: 30, odo: 1000, currency: 'EUR'),
        _f(id: '2', date: DateTime(2026, 1, 20), liters: 30, cost: 45, odo: 1500, currency: 'EUR'),
        _f(id: '3', date: DateTime(2026, 2, 10), liters: 30, cost: 0, odo: 2000, currency: 'EUR'),
      ]);

      expect(stats.pricedLiters, 50);
      expect(stats.totalLiters, 80);
      expect(stats.avgPricePerLiter, closeTo(75 / 50, 1e-9));
    });
  });

  test('closed windows are counted so a comparison can show its sample size',
      () {
    final stats = ConsumptionStats.fromFillUps([
      _f(id: '1', date: DateTime(2026, 1, 1), liters: 20, cost: 30, odo: 1000, currency: 'EUR'),
      _f(id: '2', date: DateTime(2026, 1, 20), liters: 30, cost: 45, odo: 1500, currency: 'EUR'),
      _f(id: '3', date: DateTime(2026, 2, 10), liters: 30, cost: 45, odo: 2000, currency: 'EUR'),
    ]);

    expect(stats.closedWindowCount, 2);
  });
}
