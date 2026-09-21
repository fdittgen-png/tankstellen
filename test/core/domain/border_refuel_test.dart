// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/border_refuel.dart';
import 'package:tankstellen/core/domain/data_value.dart';
import 'package:tankstellen/core/domain/money.dart';
import 'package:tankstellen/core/domain/refuel_itinerary.dart';
import 'package:tankstellen/core/domain/refuel_ledger.dart';
import 'package:tankstellen/core/domain/refuel_quantities.dart';

/// #4361 — the before/after-a-border comparison, and the arithmetic it
/// has to reproduce by hand.
///
/// The fixture is the one in the issue: 200 km at 10 L/100 km, start
/// 10 L, reserve 5 L, capacity 40 L; station A at km 40 before the
/// crossing at €2/L, station B at km 100 after it at €1.50/L, no detours
/// and no fees unless a case adds one.
void main() {
  final now = DateTime.utc(2026, 9, 17, 9);

  ItineraryInput baseline({
    ExchangeRateSnapshot rates = const ExchangeRateSnapshot.empty(),
    List<Money> sharedCharges = const [],
    TravelLimits limits = TravelLimits.none,
    String currency = 'EUR',
  }) =>
      ItineraryInput(
        routeKm: 200,
        drivingMinutes: 120,
        consumptionLPer100km: 10,
        startLitres: 10,
        capacityL: 40,
        reserveLitres: 5,
        comparisonCurrency: currency,
        rates: rates,
        sharedCharges: sharedCharges,
        limits: limits,
        now: now,
      );

  ItineraryStop site(
    String id,
    double km,
    Money price, {
    String? country,
    Money? fee,
    double extraKm = 0,
    double? extraMinutes,
  }) =>
      ItineraryStop(
        stopId: id,
        alongRouteKm: km,
        pricePerLitre: price,
        litresToBuy: 0,
        countryCode: country,
        incrementalCharge: fee,
        extraKm: extraKm,
        extraMinutes: extraMinutes,
      );

  const crossing = BorderCrossing(
    alongRouteKm: 70,
    fromCountry: 'DE',
    toCountry: 'DK',
  );

  List<BorderStrategy> strategies({
    List<ItineraryStop>? sites,
    ItineraryInput? input,
    BorderCrossing cross = crossing,
  }) =>
      crossBorderStrategies(
        baseline: input ?? baseline(),
        sites: sites ??
            [
              site('A', 40, const Money(2, 'EUR'), country: 'DE'),
              site('B', 100, const Money(1.5, 'EUR'), country: 'DK'),
            ],
        crossing: cross,
        targetEndLitres: 5,
      );

  BorderStrategy pick(List<BorderStrategy> all, BorderStrategyKind kind) =>
      all.firstWhere((s) => s.kind == kind);

  group('the worked cross-border example', () {
    test('5 L at A then 10 L at B costs €25 and ends at the reserve', () {
      final bridge =
          pick(strategies(), BorderStrategyKind.bridgeThenCheaper);
      expect(bridge.isFeasible, isTrue);
      expect(bridge.stops.map((s) => s.stopId), ['A', 'B']);
      expect(bridge.stops[0].litresToBuy, closeTo(5, 1e-9));
      expect(bridge.stops[1].litresToBuy, closeTo(10, 1e-9));
      expect(bridge.outcome.total, isNotNull);
      expect(bridge.outcome.total!.amount, closeTo(25, 1e-9));
      expect(bridge.outcome.total!.currencyCode, 'EUR');
      expect(bridge.outcome.endLitres, closeTo(5, 1e-9));
      expect(bridge.outcome.stops[1].arrivalLitres, closeTo(5, 1e-9),
          reason: 'it arrives at B exactly on the reserve');
      expect(bridge.buysAcrossBorder, isTrue);
    });

    test('buying all 15 L at A costs €30 for the same final tank', () {
      final before = pick(strategies(), BorderStrategyKind.beforeCrossing);
      expect(before.isFeasible, isTrue);
      expect(before.stops.single.litresToBuy, closeTo(15, 1e-9));
      expect(before.outcome.total!.amount, closeTo(30, 1e-9));
      expect(before.outcome.endLitres, closeTo(5, 1e-9),
          reason: 'the terminal state is what makes €25 and €30 comparable');
    });

    test('skipping A is infeasible — 5 usable litres do not reach B', () {
      final after = pick(strategies(), BorderStrategyKind.afterCrossing);
      expect(after.isFeasible, isFalse);
      expect(after.outcome.blockers, contains(ItineraryBlocker.belowReserve));
    });

    test('driving through without stopping cannot reach the destination',
        () {
      final through = pick(strategies(), BorderStrategyKind.noStop);
      expect(through.isFeasible, isFalse);
      expect(through.stops, isEmpty);
    });
  });

  group('charges', () {
    test('a €6 fee incurred only at B turns €25 into €31, so A wins', () {
      final all = strategies(sites: [
        site('A', 40, const Money(2, 'EUR'), country: 'DE'),
        site('B', 100, const Money(1.5, 'EUR'),
            country: 'DK', fee: const Money(6, 'EUR')),
      ]);
      final bridge = pick(all, BorderStrategyKind.bridgeThenCheaper);
      final before = pick(all, BorderStrategyKind.beforeCrossing);
      expect(bridge.outcome.pumpCash!.amount, closeTo(25, 1e-9));
      expect(bridge.outcome.charges!.amount, closeTo(6, 1e-9));
      expect(bridge.outcome.total!.amount, closeTo(31, 1e-9));
      expect(before.outcome.total!.amount, closeTo(30, 1e-9));
      expect(before.outcome.total!.amount,
          lessThan(bridge.outcome.total!.amount));
    });

    test('a charge both itineraries pay is counted once in each and does '
        'not move the difference', () {
      const toll = BorderCrossing(
        alongRouteKm: 70,
        fromCountry: 'DE',
        toCountry: 'DK',
        charge: Money(9, 'EUR'),
      );
      final all = strategies(cross: toll);
      final bridge = pick(all, BorderStrategyKind.bridgeThenCheaper);
      final before = pick(all, BorderStrategyKind.beforeCrossing);
      expect(bridge.outcome.total!.amount, closeTo(34, 1e-9));
      expect(before.outcome.total!.amount, closeTo(39, 1e-9));
      expect(before.outcome.total!.amount - bridge.outcome.total!.amount,
          closeTo(5, 1e-9), reason: 'the same €5 difference as without it');
    });

    test('an unknown border delay cannot become a fastest-border claim',
        () {
      expect(crossing.delayUnknown, isTrue);
      expect(crossing.charge, isNull,
          reason: 'unknown is not free, and null says so');
      const known = BorderCrossing(
        alongRouteKm: 70,
        fromCountry: 'DE',
        toCountry: 'DK',
        delayMinutes: DataValue.estimated(20, basis: DataBasis.derived),
      );
      expect(known.delayUnknown, isFalse);
    });
  });

  group('currency', () {
    test('a Danish price with no rate withholds the total and keeps the '
        'native amounts', () {
      final all = strategies(sites: [
        site('A', 40, const Money(2, 'EUR'), country: 'DE'),
        site('B', 100, const Money(11, 'DKK'), country: 'DK'),
      ]);
      final bridge = pick(all, BorderStrategyKind.bridgeThenCheaper);
      expect(bridge.outcome.total, isNull);
      expect(bridge.outcome.blockers,
          contains(ItineraryBlocker.currencyNotComparable));
      expect(
        bridge.outcome.nativePumpCash.map((m) => m.currencyCode),
        containsAll(<String>['EUR', 'DKK']),
      );
      // Distance and time survive an FX failure untouched.
      expect(bridge.outcome.endLitres, closeTo(5, 1e-9));
      expect(bridge.outcome.extraKm, 0);
    });

    test('a stated rate makes the same comparison work', () {
      final rates = ExchangeRateSnapshot(rates: [
        ExchangeRate(
          baseCurrency: 'EUR',
          quoteCurrency: 'DKK',
          rate: 7.5,
          source: 'test-fixture',
          capturedAt: now.subtract(const Duration(hours: 2)),
        ),
      ]);
      final all = strategies(
        input: baseline(rates: rates),
        sites: [
          site('A', 40, const Money(2, 'EUR'), country: 'DE'),
          // 11.25 DKK = €1.50 at the stated rate.
          site('B', 100, const Money(11.25, 'DKK'), country: 'DK'),
        ],
      );
      final bridge = pick(all, BorderStrategyKind.bridgeThenCheaper);
      expect(bridge.outcome.total!.amount, closeTo(25, 1e-9));
      expect(bridge.outcome.nativePumpCash.length, 2,
          reason: 'the native quotes stay in the explanation');
    });

    test('same-currency comparison never touches the rate table', () {
      final all = strategies(input: baseline());
      expect(pick(all, BorderStrategyKind.bridgeThenCheaper).outcome.total,
          isNotNull);
    });
  });

  group("the driver's own limits", () {
    test('a detour past the extra-km limit is blocked, not silently taken',
        () {
      final all = strategies(
        input: baseline(limits: const TravelLimits(maxExtraKm: 5)),
        sites: [
          site('A', 40, const Money(2, 'EUR'), country: 'DE', extraKm: 8,
              extraMinutes: 9),
          site('B', 100, const Money(1.5, 'EUR'), country: 'DK'),
        ],
      );
      final bridge = pick(all, BorderStrategyKind.bridgeThenCheaper);
      expect(bridge.outcome.blockers,
          contains(ItineraryBlocker.exceedsExtraDistanceLimit));
    });

    test('a detour past the extra-minutes limit is blocked too', () {
      final all = strategies(
        input: baseline(limits: const TravelLimits(maxExtraMinutes: 5)),
        sites: [
          site('A', 40, const Money(2, 'EUR'), country: 'DE', extraKm: 2,
              extraMinutes: 12),
          site('B', 100, const Money(1.5, 'EUR'), country: 'DK'),
        ],
      );
      final bridge = pick(all, BorderStrategyKind.bridgeThenCheaper);
      expect(bridge.outcome.blockers,
          contains(ItineraryBlocker.exceedsExtraTimeLimit));
    });

    test('an unrouted detour times at the route average and says so', () {
      final outcome = evaluateItinerary(ItineraryInput(
        routeKm: 200,
        drivingMinutes: 120,
        consumptionLPer100km: 10,
        startLitres: 30,
        capacityL: 40,
        reserveLitres: 5,
        comparisonCurrency: 'EUR',
        now: now,
        stops: [
          site('A', 40, const Money(2, 'EUR'), extraKm: 10).withLitres(5),
        ],
      ));
      expect(outcome.extraTimeIsApproximate, isTrue);
      expect(outcome.extraMinutes, closeTo(6, 1e-9));
    });
  });

  group('country evidence', () {
    test('a missing country setup is its own state, not "no stations"', () {
      const missing = BorderCrossing(
        alongRouteKm: 70,
        fromCountry: 'FR',
        toCountry: 'ES',
        destinationStatus: BorderCountryStatus.setupMissing,
      );
      expect(missing.destinationEvidenceComplete, isFalse);
      expect(missing.destinationStatus, BorderCountryStatus.setupMissing);
      // …and is distinguishable from the other three absences.
      expect(
        {
          BorderCountryStatus.setupMissing,
          BorderCountryStatus.unsupported,
          BorderCountryStatus.partialCoverage,
          BorderCountryStatus.providerUnavailable,
        }.length,
        4,
      );
    });

    test('each stop keeps its own country and native currency (FR→ES)', () {
      final all = strategies(
        cross: const BorderCrossing(
            alongRouteKm: 70, fromCountry: 'FR', toCountry: 'ES'),
        sites: [
          site('fr-1', 40, const Money(1.9, 'EUR'), country: 'FR'),
          site('es-1', 100, const Money(1.6, 'EUR'), country: 'ES'),
        ],
      );
      final bridge = pick(all, BorderStrategyKind.bridgeThenCheaper);
      expect(bridge.stops.map((s) => s.countryCode), ['FR', 'ES']);
      expect(bridge.stops.map((s) => s.pricePerLitre.currencyCode),
          ['EUR', 'EUR']);
    });
  });

  group('the quantity rule is independent of the border', () {
    test('it buys nothing when the tank already covers the journey', () {
      // Fuel aboard cannot be sold, so an itinerary that already ends
      // above the target ends above it. That is a real asymmetry, and
      // #4360's valuation rule — not a negative purchase — is what makes
      // such an itinerary comparable with one that stops.
      final stops = assignPurchaseQuantities(
        ItineraryInput(
          routeKm: 100,
          consumptionLPer100km: 10,
          startLitres: 20,
          capacityL: 40,
          reserveLitres: 5,
          comparisonCurrency: 'EUR',
          now: now,
        ),
        [site('A', 40, const Money(2, 'EUR'))],
        targetEndLitres: 5,
      );
      expect(stops.single.litresToBuy, 0);
    });

    test('a stop at the origin is a valid stop', () {
      final outcome = evaluateItinerary(ItineraryInput(
        routeKm: 100,
        consumptionLPer100km: 10,
        startLitres: 6,
        capacityL: 40,
        reserveLitres: 5,
        comparisonCurrency: 'EUR',
        now: now,
        stops: [site('origin', 0, const Money(1.5, 'EUR')).withLitres(9)],
      ));
      expect(outcome.isFeasible, isTrue);
      expect(outcome.endLitres, closeTo(5, 1e-9));
    });
  });
}
