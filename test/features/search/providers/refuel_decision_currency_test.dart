// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/exchange_rate_provider.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/money.dart';
import 'package:tankstellen/core/domain/refuel_economics.dart';
import 'package:tankstellen/core/domain/refuel_profile_provider.dart';
import 'package:tankstellen/core/domain/search_result_item.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/core/time/app_clock.dart';
import 'package:tankstellen/features/search/providers/refuel_decision_provider.dart';
import 'package:tankstellen/features/search/providers/search_filters_provider.dart';

/// #4361 through the PRODUCTION provider, not a hand-built candidate
/// list: the cross-border defect lives in candidate construction, where
/// a Danish price reached a German list as a bare number.
///
/// `de-` and `shell-` are the real station-id prefixes of Germany and one
/// of Denmark's brand feeds (#753), so the currency each candidate
/// carries is resolved exactly as it is in the app.
void main() {
  final now = DateTime.utc(2026, 9, 17, 12);

  Station station(String id, double price, double dist) => Station(
        id: id,
        name: id,
        brand: 'B',
        street: 'R',
        postCode: '1',
        place: 'P',
        // Coordinates only matter for an id that carries no prefix.
        lat: 54.9,
        lng: 9.8,
        e10: price,
        dist: dist,
      );

  ProviderContainer container({
    String comparison = 'EUR',
    ExchangeRateSnapshot rates = const ExchangeRateSnapshot.empty(),
  }) =>
      ProviderContainer(overrides: [
        selectedFuelTypeProvider.overrideWith(_FixedFuel.new),
        refuelProfileProvider.overrideWithValue(
          const RefuelProfile(consumptionLPer100km: 7, litresIntended: 40),
        ),
        appClockProvider.overrideWithValue(FixedClock(now)),
        comparisonCurrencyProvider.overrideWithValue(comparison),
        exchangeRatesProvider.overrideWithValue(rates),
      ]);

  // €1.80/L in Germany against DKK 13/L in Denmark. As bare numbers the
  // Danish figure is seven times larger and would never be cheapest; at
  // 7.50 DKK = €1 it is €1.733…/L and wins.
  final items = [
    FuelStationResult(station('de-1', 1.80, 2)),
    FuelStationResult(station('shell-dk-1', 13, 3)),
  ];

  test('each candidate carries its own country currency', () {
    final c = container();
    addTearDown(c.dispose);
    final decision = c.read(refuelDecisionProvider(items));
    final byId = {
      for (final q in decision.quotes) q.candidate.stationId: q.candidate,
    };
    expect(byId['de-1']!.currencyCode, 'EUR');
    expect(byId['shell-dk-1']!.currencyCode, 'DKK');
  });

  test('with no rate the money rankings are withheld, not guessed', () {
    final c = container();
    addTearDown(c.dispose);
    final decision = c.read(refuelDecisionProvider(items));

    expect(decision.moneyRankingWithheld, isTrue);
    expect(decision.comparisonCurrency, 'EUR');
    expect(decision.cheapest?.candidate.stationId, 'de-1',
        reason: 'the one candidate that could be expressed in EUR');
    expect(decision.bestValue?.candidate.stationId, 'de-1');
    // Distance needs no rate, so the nearest is still the nearest and
    // both rows keep their native prices.
    expect(decision.closest?.candidate.stationId, 'de-1');
    expect(decision.quotes, hasLength(2));
  });

  test('with a stated fresh rate the Danish station wins on price', () {
    final c = container(
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
    addTearDown(c.dispose);
    final decision = c.read(refuelDecisionProvider(items));

    expect(decision.moneyRankingWithheld, isFalse);
    expect(decision.cheapest?.candidate.stationId, 'shell-dk-1');
    expect(decision.closest?.candidate.stationId, 'de-1',
        reason: 'the cheaper station is the farther one');
  });

  test('a stale rate does not become a winner', () {
    final c = container(
      rates: ExchangeRateSnapshot(rates: [
        ExchangeRate(
          baseCurrency: 'EUR',
          quoteCurrency: 'DKK',
          rate: 7.5,
          source: 'test-fixture',
          capturedAt: now.subtract(const Duration(days: 4)),
        ),
      ]),
    );
    addTearDown(c.dispose);
    final decision = c.read(refuelDecisionProvider(items));

    expect(decision.moneyRankingWithheld, isTrue);
    expect(decision.cheapest?.candidate.stationId, 'de-1');
  });

  test('a single-currency list needs no rate and withholds nothing', () {
    final c = container();
    addTearDown(c.dispose);
    final decision = c.read(refuelDecisionProvider([
      FuelStationResult(station('de-1', 1.80, 2)),
      FuelStationResult(station('de-2', 1.70, 3)),
    ]));

    expect(decision.moneyRankingWithheld, isFalse);
    expect(decision.cheapest?.candidate.stationId, 'de-2');
  });
}

class _FixedFuel extends SelectedFuelType {
  @override
  FuelType build() => FuelType.e10;
}
