// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/utils/price_formatter.dart';
import 'package:tankstellen/features/fill_ups/domain/entities/consumption_stats.dart';
import 'package:tankstellen/features/fill_ups/domain/entities/fill_up.dart';
import 'package:tankstellen/features/fill_ups/domain/services/fill_up_monthly_stats_aggregator.dart';
import 'package:tankstellen/features/fill_ups/domain/services/price_baseline.dart';
import 'package:tankstellen/features/fill_ups/domain/services/savings_ledger.dart';
import 'package:tankstellen/features/fill_ups/presentation/widgets/consumption_stats_card.dart';
import 'package:tankstellen/features/fill_ups/presentation/widgets/monthly_fuel_comparison_card.dart';
import 'package:tankstellen/features/fill_ups/presentation/widgets/savings_card.dart';
import 'package:tankstellen/features/fill_ups/presentation/widgets/spend_withheld_notice.dart';
import 'package:tankstellen/features/fill_ups/providers/savings_provider.dart';

import '../../../../helpers/pump_app.dart';

/// #4406 / #4437 F — a withheld money total says WHY, and every money
/// figure is printed in its own currency.
void main() {
  tearDown(() => PriceFormatter.setCountry('FR'));

  FillUp fill(String id, int day, double odo,
          {double cost = 70, String? currency = 'EUR'}) =>
      FillUp(
        id: id,
        date: DateTime(2026, 9, day),
        liters: 40,
        totalCost: cost,
        odometerKm: odo,
        fuelType: FuelType.e5,
        currency: currency,
      );

  group('SpendWithheldNotice', () {
    testWidgets('mixed currencies: names them instead of a bare dash',
        (tester) async {
      final stats = ConsumptionStats.fromFillUps([
        fill('a', 1, 10000),
        fill('b', 10, 10500, cost: 51.73, currency: 'CHF'),
      ]);
      await pumpApp(tester, ConsumptionStatsCard(stats: stats));
      expect(find.byKey(const Key('spend_withheld_notice')), findsOneWidget);
      expect(find.textContaining('CHF, EUR'), findsOneWidget);
      expect(find.textContaining('Add what your card charged'),
          findsOneWidget);
    });

    testWidgets('unknown currencies: states how many fills lack one',
        (tester) async {
      final stats = ConsumptionStats.fromFillUps([
        fill('a', 1, 10000, currency: null),
        fill('b', 5, 10300, currency: null),
        fill('c', 10, 10600),
      ]);
      await pumpApp(tester, SpendWithheldNotice(stats: stats));
      expect(find.textContaining('2 fill-ups have no recorded currency'),
          findsOneWidget);
    });

    testWidgets('a single-currency history shows its total and no notice',
        (tester) async {
      PriceFormatter.setCountry('FR');
      final stats = ConsumptionStats.fromFillUps([
        fill('a', 1, 10000),
        fill('b', 10, 10500),
      ]);
      await pumpApp(tester, ConsumptionStatsCard(stats: stats));
      expect(find.byKey(const Key('spend_withheld_notice')), findsNothing);
      expect(find.text(PriceFormatter.formatTotal(140)), findsOneWidget);
    });

    test('a sole foreign history totals in ITS currency', () {
      PriceFormatter.setCountry('DE');
      final stats = ConsumptionStats.fromFillUps([
        fill('a', 1, 10000, cost: 51.73, currency: 'CHF'),
      ]);
      expect(formatTotalSpent(stats), '51,73 CHF');
    });
  });

  group('MonthlyFuelComparisonCard (#4437 / #4406)', () {
    testWidgets('a CHF month is never compared against a EUR month',
        (tester) async {
      PriceFormatter.setCountry('DE');
      final months = FillUpMonthlyStatsAggregator.byMonth([
        FillUp(
          id: 'aug',
          date: DateTime(2026, 8, 10),
          liters: 40,
          totalCost: 70,
          odometerKm: 10000,
          fuelType: FuelType.e5,
          currency: 'EUR',
        ),
        FillUp(
          id: 'sep',
          date: DateTime(2026, 9, 20),
          liters: 25.61,
          totalCost: 51.73,
          odometerKm: 10500,
          fuelType: FuelType.e5,
          currency: 'CHF',
        ),
      ]);
      await pumpApp(tester, MonthlyFuelComparisonCard(months: months));
      expect(find.text('51,73 CHF'), findsOneWidget);
      // The EUR previous-month spend is withheld rather than set beside
      // a CHF figure with a trend arrow.
      expect(find.textContaining('70,00'), findsNothing);
    });

    testWidgets('a month with mixed currencies says why its spend is blank',
        (tester) async {
      final months = FillUpMonthlyStatsAggregator.byMonth([
        fill('a', 1, 10000),
        fill('b', 10, 10500, cost: 51.73, currency: 'CHF'),
      ]);
      await pumpApp(tester, MonthlyFuelComparisonCard(months: months));
      expect(find.byKey(const Key('spend_withheld_notice')), findsOneWidget);
    });
  });

  group('SavingsCard per-currency lines (#4437 A)', () {
    SavingsEntry entry(double amount, String currency) => SavingsEntry(
          fillUpId: 'f$currency',
          date: DateTime.utc(2026, 9, 1),
          litres: 50,
          pricePaid: 1.70 - amount / 50,
          referencePrice: 1.70,
          currency: currency,
        );

    testWidgets('a DKK saving reads 12,30 DKK — never "DKK 12,300 €"',
        (tester) async {
      PriceFormatter.setCountry('DE');
      await pumpApp(
        tester,
        const SavingsCard(),
        overrides: [
          savingsLedgerProvider.overrideWithValue(SavingsLedger(
            entries: [entry(12.30, 'DKK'), entry(5, 'EUR')],
            baseline: const PriceBaseline(
              typicalPricePerLitre: 1.70,
              typicalLitres: 45,
              sampleCount: 6,
            ),
          )),
        ],
      );
      expect(find.text('12,30 DKK'), findsOneWidget);
      expect(find.text('5,00 €'), findsOneWidget);
      expect(find.textContaining('DKK 12'), findsNothing);
    });
  });
}
