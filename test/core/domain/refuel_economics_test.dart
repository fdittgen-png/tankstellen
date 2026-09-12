// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/refuel_economics.dart';

/// #4089 — the decision model of `docs/specs/refuel-economics.md`.
///
/// The spec's §4 trust rules are the point of this file: a recommendation
/// the user cannot reproduce is worse than none. Each rule has a group.
void main() {
  // The spec's worked example, so the documented arithmetic and the code
  // can never drift apart silently.
  const specCandidate = RefuelCandidate(
    stationId: 'spec',
    oneWayKm: 7.2,
    pricePerLitre: 0.829,
  );
  const specProfile = RefuelProfile(
    consumptionLPer100km: 7,
    litresIntended: 40,
  );

  group('the worked example in the spec', () {
    test('reproduces every line of §2 to the cent', () {
      final cost = RefuelEconomics.cost(specCandidate, specProfile)!;
      // 7.2 km × 2 (there and back) × 1.3 (crow-flies) = 18.72 km
      expect(cost.travelKm, closeTo(18.72, 0.001));
      expect(cost.detourLitres, closeTo(1.3104, 0.0001));
      expect(cost.detourCost, closeTo(1.086, 0.001));
      expect(cost.purchaseCost, closeTo(33.16, 0.001));
      expect(cost.totalCost, closeTo(34.246, 0.001));
      final quote = RefuelQuote(candidate: specCandidate, cost: cost);
      expect(quote.effectivePricePerLitre, closeTo(0.856, 0.001));
    });

    test('the closed form matches the step-by-step arithmetic', () {
      final quote = RefuelQuote(
        candidate: specCandidate,
        cost: RefuelEconomics.cost(specCandidate, specProfile),
      );
      // P · (1 + k·D·C / (100·Q)), with D already road-corrected.
      const closed = 0.829 * (1 + 2 * 7.2 * 1.3 * 7 / (100 * 40));
      expect(quote.effectivePricePerLitre, closeTo(closed, 1e-9));
    });
  });

  group('tank capacity is NOT part of the model (spec §2)', () {
    test('the detour costs the same whatever the tank holds', () {
      // The old proposal divided by tank capacity. Two identical
      // refuels differing only in the vehicle's tank must cost the same,
      // because the fuel burned getting there is the same fuel.
      final small = RefuelEconomics.cost(specCandidate,
          const RefuelProfile(consumptionLPer100km: 7, litresIntended: 40))!;
      final large = RefuelEconomics.cost(specCandidate,
          const RefuelProfile(consumptionLPer100km: 7, litresIntended: 40))!;
      expect(small.detourCost, large.detourCost);
    });

    test('buying more spreads the SAME detour cost over more litres', () {
      double effective(double litres) => RefuelQuote(
            candidate: specCandidate,
            cost: RefuelEconomics.cost(
              specCandidate,
              RefuelProfile(
                  consumptionLPer100km: 7, litresIntended: litres),
            ),
          ).effectivePricePerLitre!;
      expect(effective(20), greaterThan(effective(40)));
      expect(effective(40), greaterThan(effective(60)));
      // …and never below the pump price, however much you buy.
      expect(effective(500), greaterThan(0.829));
    });
  });

  group('the property the old comparator violated (#4088)', () {
    test('at equal price, nearer ALWAYS ranks better', () {
      const near = RefuelCandidate(
          stationId: 'near', oneWayKm: 2, pricePerLitre: 1);
      const far =
          RefuelCandidate(stationId: 'far', oneWayKm: 10, pricePerLitre: 1);
      final decision = RefuelEconomics.decide(
          [far, near], const RefuelProfile(consumptionLPer100km: 7));
      expect(decision.bestValue!.candidate.stationId, 'near',
          reason: 'price ÷ distance ranked "far" first — the #4088 defect');
    });

    test('distance monotonically worsens the effective price', () {
      double effectiveAt(double km) => RefuelQuote(
            candidate: RefuelCandidate(
                stationId: 's', oneWayKm: km, pricePerLitre: 1),
            cost: RefuelEconomics.cost(
              RefuelCandidate(
                  stationId: 's', oneWayKm: km, pricePerLitre: 1),
              const RefuelProfile(consumptionLPer100km: 7),
            ),
          ).effectivePricePerLitre!;
      var previous = effectiveAt(0);
      for (final km in [1.0, 5.0, 10.0, 50.0]) {
        final now = effectiveAt(km);
        expect(now, greaterThan(previous));
        previous = now;
      }
    });
  });

  group('three rankings, never one best (spec §3)', () {
    const cheapFar =
        RefuelCandidate(stationId: 'cheap', oneWayKm: 7.2, pricePerLitre: 0.829);
    const middle =
        RefuelCandidate(stationId: 'mid', oneWayKm: 3.8, pricePerLitre: 0.839);
    const nearDear =
        RefuelCandidate(stationId: 'near', oneWayKm: 2.5, pricePerLitre: 0.899);

    final decision = RefuelEconomics.decide(
      [cheapFar, middle, nearDear],
      const RefuelProfile(consumptionLPer100km: 7, litresIntended: 40),
    );

    test('each question gets its own answer', () {
      expect(decision.cheapest!.candidate.stationId, 'cheap');
      expect(decision.closest!.candidate.stationId, 'near');
      expect(decision.bestValue!.candidate.stationId, 'mid',
          reason: 'the screenshot case: neither the cheapest nor the '
              'closest is the best buy');
    });

    test('a station holding several titles is reported once', () {
      const only =
          RefuelCandidate(stationId: 'only', oneWayKm: 1, pricePerLitre: 1);
      final one = RefuelEconomics.decide(
          [only], const RefuelProfile(consumptionLPer100km: 7));
      expect(one.rankingsFor('only'), {
        RefuelRanking.cheapest,
        RefuelRanking.closest,
        RefuelRanking.bestValue,
      });
      expect(one.distinctPicks, hasLength(1),
          reason: 'the header must not print the same station three times');
    });

    test('distinctPicks leads with best value', () {
      expect(decision.distinctPicks.map((q) => q.candidate.stationId),
          ['mid', 'cheap', 'near']);
    });
  });

  group('spec §4.1 — no consumption, no Best Value', () {
    test('the ranking is withheld, not defaulted', () {
      final decision = RefuelEconomics.decide(
        const [
          RefuelCandidate(stationId: 'a', oneWayKm: 2, pricePerLitre: 1),
          RefuelCandidate(stationId: 'b', oneWayKm: 9, pricePerLitre: 0.9),
        ],
        const RefuelProfile(), // no consumption
      );
      expect(decision.bestValue, isNull);
      expect(decision.valueRankingAvailable, isFalse,
          reason: 'the UI must state the reason, never invent a number');
      // Price and distance need no model, so they still answer.
      expect(decision.cheapest!.candidate.stationId, 'b');
      expect(decision.closest!.candidate.stationId, 'a');
    });

    test('a zero or negative consumption is treated as unknown', () {
      for (final c in [0.0, -7.0]) {
        expect(
          RefuelEconomics.decide(
            const [
              RefuelCandidate(stationId: 'a', oneWayKm: 2, pricePerLitre: 1)
            ],
            RefuelProfile(consumptionLPer100km: c),
          ).valueRankingAvailable,
          isFalse,
          reason: 'consumption $c',
        );
      }
    });
  });

  group('spec §4.3 — no price, no economic rank', () {
    test('an unpriced station can be closest but never cheapest or best', () {
      const unpriced = RefuelCandidate(stationId: 'unpriced', oneWayKm: 0.5);
      const priced =
          RefuelCandidate(stationId: 'priced', oneWayKm: 9, pricePerLitre: 1);
      final decision = RefuelEconomics.decide([unpriced, priced],
          const RefuelProfile(consumptionLPer100km: 7));
      expect(decision.closest!.candidate.stationId, 'unpriced');
      expect(decision.cheapest!.candidate.stationId, 'priced');
      expect(decision.bestValue!.candidate.stationId, 'priced');
      expect(decision.rankingsFor('unpriced'), {RefuelRanking.closest});
    });

    test('no candidate at all yields no answers rather than throwing', () {
      final empty = RefuelEconomics.decide(
          const [], const RefuelProfile(consumptionLPer100km: 7));
      expect(empty.cheapest, isNull);
      expect(empty.closest, isNull);
      expect(empty.bestValue, isNull);
      expect(empty.distinctPicks, isEmpty);
    });
  });

  group('spec §4.4 — every claim is reproducible', () {
    const cheapFar =
        RefuelCandidate(stationId: 'cheap', oneWayKm: 7.2, pricePerLitre: 0.829);
    const nearDear =
        RefuelCandidate(stationId: 'near', oneWayKm: 2.5, pricePerLitre: 0.899);
    final decision = RefuelEconomics.decide([cheapFar, nearDear],
        const RefuelProfile(consumptionLPer100km: 7, litresIntended: 40));

    test('a stated saving is the difference of two total costs', () {
      final cheap = decision.cheapest!;
      final near = decision.closest!;
      final saving = decision.savings(cheap, near)!;
      expect(saving, closeTo(near.cost!.totalCost - cheap.cost!.totalCost, 1e-9));
      expect(saving, greaterThan(0),
          reason: '7 cents a litre over 40 L outruns 9.4 km of detour');
    });

    test('extra driving is declared, and never as a negative', () {
      expect(decision.extraTravelKm(decision.cheapest!, decision.closest!),
          closeTo(18.72 - 6.5, 0.001));
      expect(decision.extraTravelKm(decision.closest!, decision.cheapest!), 0);
    });

    test('the break-even quantity is the honest "worth it from" figure', () {
      // A small price edge over a long detour: cheap only at volume.
      const marginal = RefuelCandidate(
          stationId: 'marginal', oneWayKm: 20, pricePerLitre: 0.895);
      final d = RefuelEconomics.decide([marginal, nearDear],
          const RefuelProfile(consumptionLPer100km: 7, litresIntended: 40));
      final q = d.breakEvenLitres(d.cheapest!, d.closest!)!;
      expect(q, greaterThan(0));

      // At exactly Q* the two refuels cost the same; either side of it
      // the winner flips. That is what makes the number honest.
      RefuelDecision at(double litres) => RefuelEconomics.decide(
            [marginal, nearDear],
            RefuelProfile(consumptionLPer100km: 7, litresIntended: litres),
          );
      final below = at(q * 0.5);
      final above = at(q * 2);
      expect(below.bestValue!.candidate.stationId, 'near');
      expect(above.bestValue!.candidate.stationId, 'marginal');
      final tie = at(q);
      expect(
        tie.savings(
            tie.quotes.firstWhere((x) => x.candidate.stationId == 'marginal'),
            tie.quotes.firstWhere((x) => x.candidate.stationId == 'near'))!,
        closeTo(0, 1e-9),
      );
    });

    test('break-even is null when the question does not arise', () {
      // Cheaper AND nearer: wins at any quantity, nothing to justify.
      const dominant =
          RefuelCandidate(stationId: 'dom', oneWayKm: 1, pricePerLitre: 0.8);
      final d = RefuelEconomics.decide([dominant, nearDear],
          const RefuelProfile(consumptionLPer100km: 7, litresIntended: 40));
      expect(d.breakEvenLitres(d.cheapest!, d.closest!), isNull);
      // And null for the dearer side, which has nothing to break even on.
      expect(d.breakEvenLitres(d.closest!, d.cheapest!), isNull);
    });
  });

  group('spec §4.5 — distances are honest', () {
    test('a crow-flies distance is corrected; a road distance is not', () {
      const crow =
          RefuelCandidate(stationId: 'crow', oneWayKm: 10, pricePerLitre: 1);
      const road = RefuelCandidate(
          stationId: 'road',
          oneWayKm: 10,
          pricePerLitre: 1,
          isRoadDistance: true);
      const profile = RefuelProfile(consumptionLPer100km: 7);
      expect(RefuelEconomics.cost(crow, profile)!.travelKm, closeTo(26, 1e-9));
      expect(RefuelEconomics.cost(road, profile)!.travelKm, closeTo(20, 1e-9));
    });

    test('en route counts the deviation once, not there and back', () {
      const c = RefuelCandidate(
          stationId: 's',
          oneWayKm: 4,
          pricePerLitre: 1,
          isRoadDistance: true);
      final errand = RefuelEconomics.cost(
          c, const RefuelProfile(consumptionLPer100km: 7))!;
      final enRoute = RefuelEconomics.cost(
        c,
        const RefuelProfile(
            consumptionLPer100km: 7, tripFactor: kEnRouteTripFactor),
      )!;
      expect(enRoute.travelKm, closeTo(errand.travelKm / 2, 1e-9));
      expect(enRoute.detourCost, lessThan(errand.detourCost));
    });
  });

  group('the default quantity is measured, not asked (spec §2)', () {
    test('the median ignores a splash-and-dash and a jerrycan', () {
      expect(RefuelEconomics.medianLitres([8, 38, 40, 41, 200]), 40);
    });

    test('an even history averages the two middle fills', () {
      expect(RefuelEconomics.medianLitres([30, 40, 42, 44]), 41);
    });

    test('no history yields null so the caller can fall back', () {
      expect(RefuelEconomics.medianLitres(const []), isNull);
      expect(RefuelEconomics.medianLitres([0, -5]), isNull,
          reason: 'a zero or negative volume is not a fill-up');
    });

    test('the fallback is a sane tankful', () {
      expect(kDefaultRefuelLitres, 40);
      expect(const RefuelProfile().litresIntended, kDefaultRefuelLitres);
    });
  });

  group('stability', () {
    test('a tie breaks on the station id, so the order never reshuffles', () {
      const a = RefuelCandidate(stationId: 'a', oneWayKm: 5, pricePerLitre: 1);
      const b = RefuelCandidate(stationId: 'b', oneWayKm: 5, pricePerLitre: 1);
      for (final order in [
        [a, b],
        [b, a]
      ]) {
        final d = RefuelEconomics.decide(
            order, const RefuelProfile(consumptionLPer100km: 7));
        expect(d.bestValue!.candidate.stationId, 'a');
        expect(d.cheapest!.candidate.stationId, 'a');
        expect(d.closest!.candidate.stationId, 'a');
      }
    });
  });
}
