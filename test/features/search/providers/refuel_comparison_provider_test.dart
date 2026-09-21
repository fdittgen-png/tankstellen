// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// #4363 — the shared comparison through the PRODUCTION provider: the
/// same candidate reduction and the same trip ledger every other surface
/// uses, recomputed on every input change while the selection holds.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/country/country_config.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/money.dart';
import 'package:tankstellen/core/domain/refuel_comparison_selection.dart';
import 'package:tankstellen/core/domain/refuel_economics.dart';
import 'package:tankstellen/core/domain/refuel_quantity_provider.dart';
import 'package:tankstellen/core/domain/refuel_trip_cost.dart';
import 'package:tankstellen/core/domain/tank_state_provider.dart';
import 'package:tankstellen/core/domain/travel_estimate.dart';
import 'package:tankstellen/features/search/providers/refuel_comparison_provider.dart';
import 'package:tankstellen/features/search/providers/refuel_travel_origin_provider.dart';
import 'package:tankstellen/features/search/providers/search_filters_provider.dart';
import 'package:tankstellen/features/search/providers/station_travel_estimates_provider.dart';

import 'refuel_comparison_support.dart';

void main() {
  final now = DateTime.utc(2026, 9, 18, 10);
  const origin = TravelPoint(52.5, 13.4);

  final near = fixtureStation('de-1', price: 1.80, dist: 2);
  final far = fixtureStation('de-2', price: 1.70, dist: 8);

  ProviderContainer container({
    double? quantity,
    TravelEstimateFetcher? fetcher,
    ExchangeRateSnapshot rates = const ExchangeRateSnapshot.empty(),
    bool withOrigin = true,
  }) {
    final c = ProviderContainer(
      overrides: comparisonOverrides(
        now: now,
        quantity: quantity,
        fetcher: fetcher,
        rates: rates,
      ),
    );
    addTearDown(c.dispose);
    if (withOrigin) c.read(refuelTravelOriginProvider.notifier).set(origin);
    return c;
  }

  test('an empty selection is an empty comparison', () {
    final c = container();
    expect(c.read(refuelComparisonProvider).isEmpty, isTrue);
  });

  test('each picked station is costed by the trip ledger for the SAME net '
      'refill, and the cheapest is a named baseline', () {
    final c = container(quantity: 30);
    c.read(refuelComparisonSelectionProvider.notifier)
      ..toggle(near)
      ..toggle(far);

    final result = c.read(refuelComparisonProvider);
    expect(result.entries.map((e) => e.stationId), ['de-1', 'de-2']);
    expect(result.quantityLitres, 30);
    expect(result.quantityIsChosen, isTrue);

    // Crow-flies errands at the documented 1.3 road factor, 7 L/100 km:
    // near drives 2 × 2 × 1.3 = 5.2 km → 0.364 L; far 20.8 km → 1.456 L.
    final byId = {for (final e in result.entries) e.stationId: e};
    expect(byId['de-1']!.cost!.litresDispensed, closeTo(30.364, 1e-9));
    expect(byId['de-2']!.cost!.litresDispensed, closeTo(31.456, 1e-9));
    expect(byId['de-1']!.cash!.amount, closeTo(30.364 * 1.80, 1e-9));
    expect(byId['de-2']!.cash!.amount, closeTo(31.456 * 1.70, 1e-9));
    // €53.475 vs €54.655: the dearer pump wins once the drive is paid.
    expect(result.baseline!.stationId, 'de-2');
    expect(byId['de-1']!.extraVsBaseline!.amount, closeTo(1.18, 1e-2));
    expect(byId['de-2']!.extraVsBaseline!.amount, 0);
    // The road quote is still in flight, so the row carries the
    // crow-flies figures asserted above AND says they are provisional —
    // never a routed claim it cannot stand behind.
    expect(byId['de-1']!.travel, RefuelComparisonTravel.pending);
  });

  test('changing the quantity recomputes every total and keeps the '
      'selection', () async {
    final c = container(quantity: 30);
    c.read(refuelComparisonSelectionProvider.notifier)
      ..toggle(near)
      ..toggle(far);
    final before = c.read(refuelComparisonProvider);

    await c.read(refuelQuantityProvider.notifier).set(10);

    final after = c.read(refuelComparisonProvider);
    expect(c.read(refuelComparisonSelectionProvider).map((s) => s.id),
        ['de-1', 'de-2'], reason: 'the selection is untouched');
    expect(after.quantityLitres, 10);
    expect(after.entries.first.cash!.amount,
        lessThan(before.entries.first.cash!.amount));
    // At 10 L the detour is amortised over fewer litres, and the nearer
    // dearer pump now wins — the recompute changed the ANSWER, not just
    // the numbers.
    expect(after.baseline!.stationId, 'de-1');
  });

  test('changing the fuel recomputes on the new grade', () {
    final c = container(quantity: 30);
    c.read(refuelComparisonSelectionProvider.notifier).toggle(near);
    expect(c.read(refuelComparisonProvider).entries.single.fuel, FuelType.e10);

    c.read(selectedFuelTypeProvider.notifier).state = FuelType.diesel;

    final result = c.read(refuelComparisonProvider);
    expect(result.entries.single.fuel, FuelType.diesel);
    expect(result.entries.single.blocker, RefuelTripBlocker.noPrice,
        reason: 'the fixture station sells no diesel');
    expect(c.read(refuelComparisonSelectionProvider), hasLength(1));
  });

  test('a road quote replaces the approximate errand once it is current',
      () async {
    final c = container(
      quantity: 30,
      fetcher: (context, stops) async => [
        for (final s in stops)
          StationTravelEstimate.routed(
            stationId: s.id,
            context: context,
            toStation: const TravelLeg(distanceKm: 3, durationMinutes: 5),
            fromStation: const TravelLeg(distanceKm: 4, durationMinutes: 6),
            baseline: TravelLeg.zero,
            calculatedAt: now,
          ),
      ],
    );
    c.read(refuelComparisonSelectionProvider.notifier).toggle(near);
    final sub = c.listen(refuelComparisonProvider, (_, _) {});
    addTearDown(sub.close);

    expect(c.read(refuelComparisonProvider).entries.single.travel,
        RefuelComparisonTravel.pending);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    final entry = c.read(refuelComparisonProvider).entries.single;
    expect(entry.travel, RefuelComparisonTravel.road);
    expect(entry.cost!.travelKm, 7, reason: '3 km out and 4 km back');
    expect(entry.cost!.travelIsRoad, isTrue);
  });

  test('a mixed-currency selection withholds the cheapest without a rate '
      'and names it with one (#4361)', () async {
    final danish = fixtureStation('shell-dk-1', price: 13, dist: 3);

    final withoutRate = container(quantity: 30);
    withoutRate.read(refuelComparisonSelectionProvider.notifier)
      ..toggle(near)
      ..toggle(danish);
    final withheld = withoutRate.read(refuelComparisonProvider);
    expect(withheld.moneyWithheld, isTrue);
    final dk = withheld.entries.firstWhere((e) => e.stationId == 'shell-dk-1');
    expect(dk.cash, isNull);
    expect(dk.nativeCash!.currencyCode, 'DKK');
    expect(dk.cost, isNotNull, reason: 'litres and kilometres need no rate');
    expect(withheld.baseline, isNull,
        reason: 'naming the cheapest of the rows that happened to convert '
            'would be a claim about a set the driver did not choose');

    final withRate = container(
      quantity: 30,
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
    withRate.read(refuelComparisonSelectionProvider.notifier)
      ..toggle(near)
      ..toggle(danish);
    final named = withRate.read(refuelComparisonProvider);
    expect(named.moneyWithheld, isFalse);
    final dkWithRate =
        named.entries.firstWhere((e) => e.stationId == 'shell-dk-1');
    expect(dkWithRate.nativeCash!.currencyCode, 'DKK');
    expect(dkWithRate.cash!.currencyCode, 'EUR');
    // DKK 13.00/L is €1.733 at 7.50; 30.546 L (30 net + 0.546 burned over
    // 7.8 km) is DKK 397.10 → €52.95, under de-1's €54.66. The rate is
    // what makes the two quotes rankable at all.
    expect(dkWithRate.cash!.amount, closeTo(52.95, 0.01));
    expect(named.baseline!.stationId, 'shell-dk-1',
        reason: 'with a fresh stated rate the Danish pump is nameable, and '
            'it wins');
  });

  test('a reference price stays a visible price with no drive (#4348)', () {
    final luPrefix = Countries.byCode('LU')!.stationIdPrefixes.first;
    final reference = fixtureStation('${luPrefix}centroid', price: 1.5, dist: 1);
    final c = container(quantity: 30);
    c.read(refuelComparisonSelectionProvider.notifier)
      ..toggle(reference)
      ..toggle(near);

    final result = c.read(refuelComparisonProvider);
    final ref = result.entries.firstWhere((e) => e.stationId.startsWith(luPrefix));
    expect(ref.candidate.pricePerLitre, 1.5, reason: 'the price is real');
    expect(ref.blocker, RefuelTripBlocker.notAStation);
    expect(ref.isBaseline, isFalse,
        reason: 'a stand-in point cannot be the cheapest STATION');
    expect(result.baseline!.stationId, 'de-1');
  });

  test('without an origin every distance is approximate and says so', () {
    final c = container(quantity: 30, withOrigin: false);
    c.read(refuelComparisonSelectionProvider.notifier).toggle(near);
    final result = c.read(refuelComparisonProvider);
    expect(result.originKnown, isFalse);
    expect(result.entries.single.travel, RefuelComparisonTravel.approximate);
  });

  test('an active route makes every row a stop on the journey', () async {
    final c = ProviderContainer(
        overrides:
            comparisonOverrides(now: now, quantity: 30, route: fixtureRoute()));
    addTearDown(c.dispose);
    c.read(refuelComparisonSelectionProvider.notifier).toggle(near);
    expect(c.read(refuelComparisonProvider).isJourneyStop, isTrue);
    expect(c.read(refuelComparisonProvider).originKnown, isTrue);
  });

  test('no consumption blocks every row with a named reason', () {
    final c = ProviderContainer(
        overrides: comparisonOverrides(
      now: now,
      quantity: 30,
      profile: const RefuelProfile(),
      tank: const TankState(capacityL: null, currentL: null),
    ));
    addTearDown(c.dispose);
    c.read(refuelComparisonSelectionProvider.notifier).toggle(near);
    final result = c.read(refuelComparisonProvider);
    expect(result.entries.single.blocker, RefuelTripBlocker.noConsumption);
    expect(result.baseline, isNull);
  });
}
