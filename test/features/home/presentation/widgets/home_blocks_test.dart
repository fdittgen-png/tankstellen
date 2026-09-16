// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #4137 — "empty states are the design, not an afterthought". A
// first-run home that shows three empty cards is worse than the search
// screen it replaced, so every block here must be ABSENT rather than
// blank when it has nothing true to say.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/features/fill_ups/api.dart';
import 'package:tankstellen/features/fill_ups/domain/services/price_baseline.dart';
import 'package:tankstellen/features/fill_ups/domain/services/savings_ledger.dart';
import 'package:tankstellen/features/home/presentation/widgets/home_blocks.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

FillUp fill(String id, int day, double odo, double litres, double cost) =>
    FillUp(
      id: id,
      date: DateTime(2026, 8, day),
      liters: litres,
      totalCost: cost,
      odometerKm: odo,
      fuelType: FuelType.e10,
    );

void main() {
  group('a fresh install shows nothing rather than empty cards', () {
    testWidgets('all three blocks are absent with no data', (tester) async {
      await pumpApp(
        tester,
        const Column(children: [
          HomeNextStopBlock(),
          HomeVehicleBlock(),
          HomeSavingsBlock(),
        ]),
        overrides: standardTestOverrides().overrides,
      );

      // Nothing rendered means nothing to mislead with. The blocks
      // collapse to zero-size rather than drawing a card with dashes.
      expect(find.byType(Card), findsNothing);
      expect(find.textContaining('per km'), findsNothing);
    });
  });

  group('the vehicle block', () {
    testWidgets('renders cost/km and consumption once fill-ups exist',
        (tester) async {
      await pumpApp(
        tester,
        const HomeVehicleBlock(),
        overrides: [
          ...standardTestOverrides().overrides,
          consumptionStatsProvider.overrideWithValue(
            ConsumptionStats.fromFillUps([
              fill('a', 1, 100000, 40, 70),
              fill('b', 15, 100600, 42, 71.4),
            ]),
          ),
        ],
      );

      expect(find.text('per km'), findsOneWidget);
      expect(find.text('L/100 km'), findsOneWidget);
      expect(find.text('Measured from your fill-ups'), findsOneWidget,
          reason: 'these are measurements, and the block says so — the '
              'provenance is why it is absent before there are fills');
    });
  });

  group('the savings block refuses to invent a number', () {
    testWidgets('absent when the ledger has no baseline', (tester) async {
      await pumpApp(
        tester,
        const HomeSavingsBlock(),
        overrides: [
          ...standardTestOverrides().overrides,
          savingsLedgerProvider
              .overrideWithValue(const SavingsLedger.unavailable()),
        ],
      );
      expect(find.textContaining("You've saved"), findsNothing,
          reason: 'below the sample count there is no baseline to measure '
              'against — trust rule 1');
    });

    testWidgets('absent when the history spans two currencies', (tester) async {
      await pumpApp(
        tester,
        const HomeSavingsBlock(),
        overrides: [
          ...standardTestOverrides().overrides,
          savingsLedgerProvider.overrideWithValue(SavingsLedger(
            baseline: const PriceBaseline(
              typicalPricePerLitre: 1.80,
              typicalLitres: 40,
              sampleCount: 6,
            ),
            entries: [
              SavingsEntry(
                fillUpId: 'a',
                date: DateTime(2026, 8, 1),
                litres: 40,
                pricePaid: 1.70,
                referencePrice: 1.80,
                currency: 'EUR',
              ),
              SavingsEntry(
                fillUpId: 'b',
                date: DateTime(2026, 8, 20),
                litres: 40,
                pricePaid: 1.60,
                referencePrice: 1.80,
                currency: 'CHF',
              ),
            ],
          )),
        ],
      );

      expect(find.textContaining("You've saved"), findsNothing,
          reason: 'a history spanning two currencies has no single total; '
              'summing them would be true in neither');
    });
  });
}
