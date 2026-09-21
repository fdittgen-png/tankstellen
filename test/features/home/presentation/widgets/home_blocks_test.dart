// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later
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
import 'package:tankstellen/core/utils/price_formatter.dart';
import 'package:tankstellen/core/utils/unit_formatter.dart';

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
  // #4273 — `PriceFormatter` holds its country in static state and the
  // shared harness pins none, so a currency assertion depends on whatever
  // test ran previously. Pin it here and restore the suite-wide default.
  setUp(() => PriceFormatter.setCountry('FR'));
  tearDown(() => PriceFormatter.setCountry('FR'));

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

      // #4273 — the labels above are ARB strings; they stayed green
      // through a change that altered BOTH figures, including one that
      // rendered money with no currency symbol at all. Assert the
      // rendered VALUES so a formatting regression fails here and not
      // only in the #3743 lint.
      //
      // The window walker closes one window over these two fills:
      // 42 L across 100600-100000 = 600 km for 71.40, so
      // 42/600*100 = 7.0 L/100 km and 71.40/600 = 0.119 per km.
      expect(find.text(UnitFormatter.formatDecimal(7.0)), findsOneWidget,
          reason: 'consumption renders through the locale-aware decimal '
              'formatter — a bare toStringAsFixed would print 7.0 where '
              'this locale wants 7,0');
      // `formatPerKm` deliberately omits the currency symbol — its doc
      // says "the symbol is supplied by the surrounding label" — so the
      // block renders the figure beside the ARB label "per km". What the
      // inline `toStringAsFixed(3)` got wrong here was the decimal
      // separator, not a missing symbol.
      expect(find.text(PriceFormatter.formatPerKm(0.119)), findsOneWidget,
          reason: 'cost per km renders through the 3-dp locale formatter; '
              'a bare toStringAsFixed would print 0.119 where this locale '
              'wants 0,119');
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

    // #4273 — both cases above assert ABSENCE, so nothing covered the
    // block when it does render. That is how a total printed without a
    // currency symbol shipped unnoticed.
    testWidgets('renders the total WITH its currency when the ledger is '
        'single-currency', (tester) async {
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
                currency: 'EUR',
              ),
            ],
          )),
        ],
      );

      // (1.80-1.70)*40 + (1.80-1.60)*40 = 4.00 + 8.00 = 12.00
      expect(find.text(PriceFormatter.formatTotal(12.0)), findsOneWidget,
          reason: 'the realised total renders through the currency '
              'formatter; a bare toStringAsFixed(2) printed 12.00 with no '
              'currency at all (#4273)');
      expect(find.textContaining(PriceFormatter.currency), findsWidgets);
    });
  });
}
