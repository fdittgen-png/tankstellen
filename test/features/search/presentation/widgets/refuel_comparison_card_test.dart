// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// #4363 — the comparison card, driven by the PRODUCTION provider.
///
/// Every figure asserted here is computed by the domain and formatted by
/// the shared formatters; the test states the same value independently
/// (`PriceFormatter` / `UnitFormatter` over the ledger's arithmetic) so a
/// widget that started doing its own sums would fail rather than agree
/// with itself.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/country/country_config.dart';
import 'package:tankstellen/core/domain/money.dart';
import 'package:tankstellen/core/domain/refuel_comparison_selection.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/core/domain/travel_estimate.dart';
import 'package:tankstellen/core/utils/price_formatter.dart';
import 'package:tankstellen/core/utils/unit_formatter.dart';
import 'package:tankstellen/features/search/presentation/widgets/results/refuel_comparison_card.dart';
import 'package:tankstellen/features/search/providers/station_travel_estimates_provider.dart';

import '../../../../helpers/pump_app.dart';
import '../../providers/refuel_comparison_support.dart';

void main() {
  final now = DateTime.utc(2026, 9, 18, 10);
  const origin = TravelPoint(52.5, 13.4);

  final alpha = fixtureStation('de-1',
      price: 1.80, dist: 2, name: 'Alpha Raststätte');
  final beta =
      fixtureStation('de-2', price: 1.70, dist: 8, name: 'Beta Autohof');

  // 7 L/100 km over the round trip, crow-flies × the documented 1.3 road
  // factor, for the same 30 L NET refill (#4360).
  double roundTripKm(double crowFliesKm) => 2 * crowFliesKm * 1.3;
  double dispensed(double crowFliesKm) =>
      30 + roundTripKm(crowFliesKm) * 7 / 100;
  String rowLitres(double crowFliesKm) =>
      UnitFormatter.formatVolume(dispensed(crowFliesKm));
  String rowCash(double crowFliesKm, double price) =>
      PriceFormatter.formatTotal(dispensed(crowFliesKm) * price);

  StationTravelEstimate routed(
    String id,
    TravelContext context, {
    required double out,
    required double back,
  }) =>
      StationTravelEstimate.routed(
        stationId: id,
        context: context,
        toStation: TravelLeg(distanceKm: out, durationMinutes: out),
        fromStation: TravelLeg(distanceKm: back, durationMinutes: back),
        baseline: TravelLeg.zero,
        calculatedAt: now,
      );

  late ProviderContainer container;

  Future<void> pumpCard(
    WidgetTester tester, {
    List<Station> selection = const [],
    Size size = const Size(400, 1600),
    double textScale = 1,
    Locale locale = const Locale('fr'),
    TravelEstimateFetcher? fetcher,
    double? quantity = 30,
    ExchangeRateSnapshot rates = const ExchangeRateSnapshot.empty(),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpApp(
      tester,
      MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: const SingleChildScrollView(child: RefuelComparisonCard()),
      ),
      overrides: comparisonOverrides(
        now: now,
        quantity: quantity,
        origin: origin,
        fetcher: fetcher,
        rates: rates,
        preselected: selection,
      ),
      locale: locale,
      settle: false,
    );
    container = ProviderScope.containerOf(
        tester.element(find.byType(RefuelComparisonCard)));
    await tester.pump();
  }

  testWidgets('every picked station is a named row with its litres, its '
      'cash and its round trip', (tester) async {
    await pumpCard(tester, selection: [alpha, beta]);

    expect(find.text('Alpha Raststätte'), findsOneWidget);
    expect(find.text('Beta Autohof'), findsOneWidget,
        reason: 'the row heading; the baseline is named again below it');
    expect(find.textContaining(rowLitres(2)), findsOneWidget);
    expect(find.textContaining(rowCash(2, 1.80)), findsOneWidget);
    expect(find.textContaining(rowLitres(8)), findsOneWidget);
    expect(find.textContaining(rowCash(8, 1.70)), findsOneWidget);
    // Both pump prices stay visible as their own separate fact.
    expect(find.textContaining(PriceFormatter.formatPrice(1.80)),
        findsOneWidget);
    expect(find.textContaining(PriceFormatter.formatPrice(1.70)),
        findsOneWidget);
  });

  testWidgets('the cheapest is a named baseline and the other row says '
      'what it costs over it', (tester) async {
    await pumpCard(tester, selection: [alpha, beta]);

    // €53.48 (the 8 km pump at €1.70) beats €54.66 (the 2 km pump at
    // €1.80): the dearer forecourt wins once the drive is paid for.
    expect(find.text('La moins chère pour cette quantité'), findsOneWidget);
    final extra = PriceFormatter.formatTotal(
        dispensed(2) * 1.80 - dispensed(8) * 1.70);
    expect(find.text('$extra de plus que Beta Autohof'), findsOneWidget);
  });

  testWidgets('the context row states the fuel, the quantity and the '
      "vehicle's consumption, and offers to correct them", (tester) async {
    await pumpCard(tester, selection: [alpha]);

    expect(
      find.textContaining(UnitFormatter.formatVolume(30)),
      findsWidgets,
      reason: 'the net quantity every row is priced for',
    );
    expect(
      find.textContaining(UnitFormatter.formatConsumption(7, isEv: false)),
      findsOneWidget,
    );
    expect(find.byKey(const Key('refuel_compare_edit_quantity')),
        findsOneWidget);
  });

  testWidgets('a reference price keeps its price and has no drive (#4348)',
      (tester) async {
    final lu = Countries.byCode('LU')!.stationIdPrefixes.first;
    final reference =
        fixtureStation('${lu}centroid', price: 1.5, dist: 1, name: 'Luxembourg');
    await pumpCard(tester, selection: [reference]);

    expect(find.textContaining(PriceFormatter.formatPrice(1.5)),
        findsOneWidget);
    expect(find.textContaining('La moins chère'), findsNothing);
    // No round-trip line at all: there is nowhere to drive to.
    expect(find.textContaining('aller-retour'), findsNothing);
  });

  testWidgets('a late road quote for a PREVIOUS selection cannot land in '
      'the card', (tester) async {
    // The two-station request is slow and would put Beta 40 km out and
    // 40 km back. By the time it answers, the driver has dropped Alpha
    // and the one-station request has already said 3 km out, 4 km back.
    await pumpCard(
      tester,
      selection: [alpha, beta],
      fetcher: (context, stops) async {
        if (stops.length > 1) {
          await Future<void>.delayed(const Duration(seconds: 2));
          return [routed('de-2', context, out: 40, back: 40)];
        }
        return [routed('de-2', context, out: 3, back: 4)];
      },
    );

    container.read(refuelComparisonSelectionProvider.notifier).remove('de-1');
    await tester.pump();
    await tester.pump();

    final current = PriceFormatter.formatTotal((30 + 7 * 7 / 100) * 1.70);
    final stale = PriceFormatter.formatTotal((30 + 80 * 7 / 100) * 1.70);
    expect(find.textContaining(current), findsOneWidget);

    // The obsolete answer now arrives.
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    expect(find.textContaining(current), findsOneWidget,
        reason: 'the current quote still owns the row');
    expect(find.textContaining(stale), findsNothing);
    expect(find.textContaining('Alpha Raststätte'), findsNothing);
  });

  testWidgets('a stop across the border keeps the price its own country '
      'quotes beside the converted total (#4361)', (tester) async {
    final danish =
        fixtureStation('shell-dk-1', price: 13, dist: 3, name: 'Shell Kolding');
    await pumpCard(
      tester,
      selection: [alpha, danish],
      rates: ExchangeRateSnapshot(rates: [
        ExchangeRate(
          baseCurrency: 'EUR',
          quoteCurrency: 'DKK',
          rate: 7.5,
          source: 'test-fixture',
          capturedAt: now.subtract(const Duration(hours: 1)),
        ),
      ]),
    );

    expect(
      find.textContaining(PriceFormatter.formatTotal(
          dispensed(3) * 13 / 7.5)),
      findsOneWidget,
      reason: 'the comparable total, in the comparison currency',
    );
    expect(
      find.text('${PriceFormatter.formatTotal(dispensed(3) * 13, currencyOverride: 'DKK')} à la pompe'),
      findsOneWidget,
      reason: 'the Danish krone figure is kept, not replaced',
    );
  });

  testWidgets('without a rate the cross-border row is not costed and no '
      'cheapest is named (#4361)', (tester) async {
    final danish =
        fixtureStation('shell-dk-1', price: 13, dist: 3, name: 'Shell Kolding');
    await pumpCard(tester, selection: [alpha, danish]);

    expect(find.text('Shell Kolding'), findsOneWidget);
    expect(
      find.textContaining(
          'Les prix sont dans des devises différentes'),
      findsWidgets,
      reason: 'the row says why, and the card repeats it as a caveat',
    );
    expect(find.text('La moins chère pour cette quantité'), findsNothing,
        reason: 'a withheld conversion withholds the winner too');
  });

  testWidgets('a narrow screen at double text size does not overflow',
      (tester) async {
    await pumpCard(
      tester,
      selection: [alpha, beta],
      size: const Size(320, 4000),
      textScale: 2,
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Alpha Raststätte'), findsOneWidget);
    expect(find.text('Beta Autohof'), findsOneWidget);
    expect(find.text('La moins chère pour cette quantité'), findsOneWidget);
  });

  testWidgets('it renders in French, with no English fallback in the copy '
      'this surface owns', (tester) async {
    await pumpCard(tester, selection: [alpha]);

    expect(find.text('Votre comparaison'), findsOneWidget);
    expect(find.text('1 station'), findsOneWidget);
    expect(find.text('Vider'), findsOneWidget);
    expect(find.textContaining('Your comparison'), findsNothing);
    expect(find.textContaining('Cheapest for this quantity'), findsNothing);
  });

  testWidgets('clearing the comparison empties the card', (tester) async {
    await pumpCard(tester, selection: [alpha, beta]);
    await tester.tap(find.byKey(const Key('refuel_compare_clear')));
    await tester.pump();

    expect(find.textContaining('Alpha Raststätte'), findsNothing);
    expect(find.text('Votre comparaison'), findsNothing);
  });
}
