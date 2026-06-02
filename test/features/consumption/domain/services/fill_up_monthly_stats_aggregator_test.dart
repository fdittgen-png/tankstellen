// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/entities/consumption_stats.dart';
import 'package:tankstellen/features/consumption/domain/services/fill_up_monthly_stats_aggregator.dart';
import 'package:tankstellen/features/consumption/domain/entities/fill_up.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

/// Reuse-fidelity coverage for [FillUpMonthlyStatsAggregator] (#2698).
///
/// The aggregator must NOT re-implement consumption maths — it groups by
/// calendar month and delegates each month's slice to the canonical
/// [ConsumptionStats.fromFillUps] window walker. These tests drive the
/// REAL aggregator with recorded fill-up fixtures spanning ≥2 months and
/// assert per-month litres / spend / avg-price, plus the comparison
/// Δ/% the comparison card derives. (RED on master: the aggregator file
/// is absent there.)
FillUp _f({
  required String id,
  required DateTime date,
  required double liters,
  required double cost,
  required double odo,
  FuelType fuelType = FuelType.e10,
  bool isFullTank = true,
  bool isCorrection = false,
}) => FillUp(
  id: id,
  date: date,
  liters: liters,
  totalCost: cost,
  odometerKm: odo,
  fuelType: fuelType,
  isFullTank: isFullTank,
  isCorrection: isCorrection,
);

void main() {
  group('FillUpMonthlyStatsAggregator.byMonth', () {
    test('empty list returns empty list', () {
      expect(FillUpMonthlyStatsAggregator.byMonth(const []), isEmpty);
    });

    test('groups by calendar month, oldest first', () {
      final months = FillUpMonthlyStatsAggregator.byMonth([
        _f(
          id: 'feb',
          date: DateTime(2026, 2, 5),
          liters: 30,
          cost: 45,
          odo: 11000,
        ),
        _f(
          id: 'jan',
          date: DateTime(2026, 1, 5),
          liters: 40,
          cost: 60,
          odo: 10000,
        ),
      ]);

      expect(months.length, 2);
      // Oldest first.
      expect(months.first.month, DateTime(2026, 1));
      expect(months.last.month, DateTime(2026, 2));
    });

    test('per-month litres / spend / avg-price always present', () {
      final months = FillUpMonthlyStatsAggregator.byMonth([
        // January — single fill, no closed window → no L/100km, but
        // litres / spend / price-per-litre still computed.
        _f(
          id: 'jan',
          date: DateTime(2026, 1, 10),
          liters: 40,
          cost: 60,
          odo: 10000,
        ),
        // February — two pleins 1000 km apart → a closed window lands
        // inside the month, so L/100km materialises.
        _f(
          id: 'feb1',
          date: DateTime(2026, 2, 3),
          liters: 50,
          cost: 75,
          odo: 11000,
        ),
        _f(
          id: 'feb2',
          date: DateTime(2026, 2, 20),
          liters: 50,
          cost: 80,
          odo: 12000,
        ),
      ]);

      final jan = months[0].stats;
      final feb = months[1].stats;

      // January totals.
      expect(jan.totalLiters, closeTo(40, 0.0001));
      expect(jan.totalSpent, closeTo(60, 0.0001));
      expect(jan.avgPricePerLiter, closeTo(1.5, 0.0001));
      // Single fill → no closed plein-to-plein window → null consumption.
      expect(jan.avgConsumptionL100km, isNull);

      // February totals — both pumped fills counted.
      expect(feb.totalLiters, closeTo(100, 0.0001));
      expect(feb.totalSpent, closeTo(155, 0.0001));
      // avg price/L = 155 / 100 = 1.55.
      expect(feb.avgPricePerLiter, closeTo(1.55, 0.0001));
      // Closed window: 50 L pumped at feb2 over 1000 km = 5.0 L/100km.
      expect(feb.avgConsumptionL100km, isNotNull);
      expect(feb.avgConsumptionL100km, closeTo(5.0, 0.0001));
    });

    test('delegates to ConsumptionStats.fromFillUps per month (parity)', () {
      // The Feb slice run standalone must equal the aggregator's Feb stats
      // — proving the aggregator reuses the window walker rather than
      // re-deriving it.
      final febFills = [
        _f(
          id: 'feb1',
          date: DateTime(2026, 2, 3),
          liters: 50,
          cost: 75,
          odo: 11000,
        ),
        _f(
          id: 'feb2',
          date: DateTime(2026, 2, 20),
          liters: 50,
          cost: 80,
          odo: 12000,
        ),
      ];
      final viaAggregator = FillUpMonthlyStatsAggregator.byMonth([
        _f(
          id: 'jan',
          date: DateTime(2026, 1, 10),
          liters: 40,
          cost: 60,
          odo: 10000,
        ),
        ...febFills,
      ]).last.stats;
      final standalone = ConsumptionStats.fromFillUps(febFills);

      expect(viaAggregator.totalLiters, standalone.totalLiters);
      expect(viaAggregator.totalSpent, standalone.totalSpent);
      expect(
        viaAggregator.avgConsumptionL100km,
        standalone.avgConsumptionL100km,
      );
      expect(viaAggregator.avgPricePerLiter, standalone.avgPricePerLiter);
      expect(viaAggregator.fillUpCount, standalone.fillUpCount);
    });

    test('month-over-month delta + % the comparison card derives', () {
      final months = FillUpMonthlyStatsAggregator.byMonth([
        _f(
          id: 'jan',
          date: DateTime(2026, 1, 10),
          liters: 40,
          cost: 60,
          odo: 10000,
        ),
        _f(
          id: 'feb1',
          date: DateTime(2026, 2, 3),
          liters: 50,
          cost: 75,
          odo: 11000,
        ),
        _f(
          id: 'feb2',
          date: DateTime(2026, 2, 20),
          liters: 50,
          cost: 80,
          odo: 12000,
        ),
      ]);

      final previous = months[months.length - 2].stats; // January
      final current = months.last.stats; // February

      // Total litres: 100 vs 40 → Δ +60, % = 60/40*100 = +150 %.
      final litresDelta = current.totalLiters - previous.totalLiters;
      final litresPct =
          (current.totalLiters - previous.totalLiters) /
          previous.totalLiters *
          100;
      expect(litresDelta, closeTo(60, 0.0001));
      expect(litresPct, closeTo(150, 0.0001));

      // Avg price/L: 1.55 vs 1.50 → Δ +0.05.
      final priceDelta = current.avgPricePerLiter! - previous.avgPricePerLiter!;
      expect(priceDelta, closeTo(0.05, 0.0001));
    });
  });
}
