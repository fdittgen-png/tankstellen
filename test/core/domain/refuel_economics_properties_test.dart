// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// Property-based tests for the economics (#4158, epic #4155).
///
/// The ranking code's correctness is expressible as LAWS rather than
/// examples, and #4088 is the cautionary tale: `compareByPriceDistance`
/// ranked by `price ÷ distance` — a quantity with no economic meaning
/// that is monotonically IMPROVED by driving further, so at equal price
/// it preferred the farther station. Example-based tests passed for
/// months. A monotonicity property fails on the first generated case.
///
/// Each property below names the docstring sentence or issue it
/// enforces, because a law nobody can trace back to a claim is a law
/// nobody will maintain.
///
/// **Generators produce REALISTIC inputs** — prices 0.5–3.0 €/L,
/// distances 0–200 km, consumption 3–25 L/100 km. A generator emitting
/// NaN prices tests the guard clauses, not the economics; those are
/// covered separately in `refuel_economics_test.dart`.
library;

import 'package:flutter_test/flutter_test.dart';
// `show` deliberately: glados re-exports `package:test`, which collides
// with flutter_test's `test` / `group` / `expect`. Only the generator
// machinery is wanted here.
import 'package:glados/glados.dart'
    show Glados3, Generator, any, DoubleAnys, GeneratorUtils;
import 'package:tankstellen/core/domain/refuel_economics.dart';
import 'package:tankstellen/core/domain/refuel_plan.dart';
import 'package:tankstellen/core/domain/refuel_planner.dart';

/// glados runs 100 cases per property by default, and that is the right
/// order of magnitude here: these are cheap pure functions, the file
/// runs in well under a second, and the laws are low-dimensional enough
/// that 100 samples explores them properly. Left at the default rather
/// than restated as a constant nobody would keep in sync.
///
/// Note glados caps at [Glados3] — three generators. Where a law has a
/// fourth free variable it is FIXED at a representative value and the
/// variable gets its own property, which is clearer than a tuple
/// generator nobody can read a counterexample out of.

/// Realistic pump prices, in €/L.
Generator<double> get price =>
    any.doubleInRange(0.5, 3.0).map((d) => (d * 1000).round() / 1000);

/// Realistic one-way distances, in km.
Generator<double> get distanceKm =>
    any.doubleInRange(0, 200).map((d) => (d * 10).round() / 10);

/// Realistic consumption, in L/100 km.
Generator<double> get consumption =>
    any.doubleInRange(3, 25).map((d) => (d * 10).round() / 10);

/// Realistic fill volumes, in litres.
Generator<double> get litres =>
    any.doubleInRange(5, 90).map((d) => (d * 10).round() / 10);

void main() {
  RefuelProfile profileOf(double c, double q) =>
      RefuelProfile(consumptionLPer100km: c, litresIntended: q);

  RefuelCandidate candidate(String id, double p, double km) =>
      RefuelCandidate(stationId: id, oneWayKm: km, pricePerLitre: p);

  double? effective(double p, double km, double c, double q) {
    final cand = candidate('s', p, km);
    final prof = profileOf(c, q);
    return RefuelQuote(
      candidate: cand,
      cost: RefuelEconomics.cost(cand, prof),
    ).effectivePricePerLitre;
  }

  group('effective price per litre (#4088)', () {
    Glados3(price, distanceKm, consumption).test(
      'is monotonically WORSENED by distance — the law #4088 violated',
      (p, km, c) {
        const q = 40.0;
        // `price ÷ distance` IMPROVED with distance, so at equal price
        // it ranked the farther station first. A real cost cannot.
        final near = effective(p, km, c, q);
        final far = effective(p, km + 1, c, q);
        expect(near, isNotNull);
        expect(far, isNotNull);
        expect(far!, greaterThanOrEqualTo(near!),
            reason: 'driving further got CHEAPER: $km km → $near, '
                '${km + 1} km → $far');
      },
    );

    Glados3(price, consumption, litres).test(
      'at zero distance equals the pump price — no detour, no penalty',
      (p, c, q) {
        expect(effective(p, 0, c, q), closeTo(p, 1e-9));
      },
    );

    Glados3(price, distanceKm, consumption).test(
      'is never below the pump price — a detour cannot pay you',
      (p, km, c) {
        expect(effective(p, km, c, 40)!, greaterThanOrEqualTo(p - 1e-9));
      },
    );

    Glados3(price, consumption, litres).test(
      'holds for ANY fill volume too — Q is the fourth variable the '
      'distance laws fix',
      (p, c, q) {
        expect(effective(p, 12, c, q)!, greaterThanOrEqualTo(p - 1e-9));
        expect(effective(p, 12, c, q)!,
            greaterThanOrEqualTo(effective(p, 0, c, q)! - 1e-9));
      },
    );
  });

  group('what the quantity Q actually does (#4158 corrected the doc)', () {
    // `refuel_economics.dart` used to claim Q "moves the effective price
    // by cents, never the sign of a comparison". The FIRST run of this
    // property disproved it and shrank to a three-number counterexample:
    //
    //   a €1.47/L at 0.7 km, b €1.40/L at 7.7 km, 7 L/100 km
    //   Q=20 → a wins; Q=80 → b wins
    //
    // The code was right — effective = p + detourCost/Q, so buying more
    // litres amortises the detour and a cheaper-but-farther station
    // genuinely becomes worth the drive. The DOCSTRING was wrong, and is
    // corrected. These are the two laws that actually hold.

    Glados3(price, price, distanceKm).test(
      'at EQUAL distance, Q never reorders two stations',
      (pA, pB, km) {
        // Here effective is proportional to the pump price, so the
        // ordering cannot depend on Q.
        const c = 7.0;
        int order(double q) {
          final prof = profileOf(c, q);
          final a = candidate('a', pA, km);
          final b = candidate('b', pB, km);
          final ea = RefuelQuote(
                  candidate: a, cost: RefuelEconomics.cost(a, prof))
              .effectivePricePerLitre!;
          final eb = RefuelQuote(
                  candidate: b, cost: RefuelEconomics.cost(b, prof))
              .effectivePricePerLitre!;
          if ((ea - eb).abs() < 1e-9) return 0;
          return ea < eb ? -1 : 1;
        }

        expect(order(20), order(80),
            reason: 'two stations the same distance away changed places '
                'when the fill volume changed');
      },
    );

    Glados3(price, distanceKm, consumption).test(
      'raising Q moves the effective price TOWARD the pump price',
      (p, km, c) {
        // The detour cost is independent of Q, so dividing it by more
        // litres can only shrink the penalty — never grow it, and never
        // overshoot below the pump price.
        final small = effective(p, km, c, 20)!;
        final large = effective(p, km, c, 80)!;
        expect(large, lessThanOrEqualTo(small + 1e-9));
        expect(large, greaterThanOrEqualTo(p - 1e-9));
      },
    );

    Glados3(price, distanceKm, consumption).test(
      'and Q is therefore a real input, not a harmless default',
      (p, km, c) {
        // Stated as a law so nobody re-asserts the old claim: where
        // there IS a detour, the effective price genuinely differs
        // between a small and a large fill.
        if (km < 1) return; // no detour, nothing to amortise
        expect(effective(p, km, c, 20)!,
            greaterThan(effective(p, km, c, 80)!));
      },
    );
  });

  group('cost is refused rather than invented (spec §4.1)', () {
    Glados3(distanceKm, consumption, litres).test(
      'a zero or negative price never produces a cost',
      (km, c, q) {
        final prof = profileOf(c, q);
        expect(RefuelEconomics.cost(candidate('z', 0, km), prof), isNull);
        expect(RefuelEconomics.cost(candidate('n', -1, km), prof), isNull);
      },
    );

    Glados3(price, distanceKm, litres).test(
      'no consumption means no cost — never a default',
      (p, km, q) {
        final prof = RefuelProfile(litresIntended: q);
        expect(RefuelEconomics.cost(candidate('s', p, km), prof), isNull);
      },
    );
  });

  group('adding a worse option never changes the winner', () {
    Glados3(price, price, distanceKm).test(
      'a MORE expensive station at the same distance never takes the lead',
      (pA, pB, km) {
        const c = 7.0;
        final dearer = pA > pB ? pA : pB;
        final cheaper = pA > pB ? pB : pA;
        final prof = profileOf(c, 40);

        final withoutIt = RefuelEconomics.decide(
            [candidate('cheap', cheaper, km)], prof);
        final withIt = RefuelEconomics.decide([
          candidate('cheap', cheaper, km),
          candidate('dear', dearer + 0.01, km),
        ], prof);

        expect(withIt.cheapest?.candidate.stationId,
            withoutIt.cheapest?.candidate.stationId);
      },
    );
  });

  group('a plan never dips below the reserve (#4146)', () {
    Glados3(consumption, price, price).test(
      'every stop arrives with at least the reserve in the tank',
      (c, pA, pB) {
        final plans = RefuelPlanner.plan(RefuelPlanRequest(
          routeKm: 600,
          drivingMinutes: 360,
          tankCapacityL: 55,
          startLitres: 50,
          consumptionLPer100km: c,
          candidates: [
            PlanCandidate(
                stationId: 'a', alongRouteKm: 120, pricePerLitre: pA),
            PlanCandidate(
                stationId: 'b', alongRouteKm: 330, pricePerLitre: pB),
            PlanCandidate(
                stationId: 'c', alongRouteKm: 480, pricePerLitre: pA),
          ],
        ));
        final plan = plans.cheapest;
        if (plan == null) return; // infeasible is a valid answer
        for (final stop in plan.stops) {
          expect(stop.arrivalLitres, greaterThanOrEqualTo(-1e-6),
              reason: 'the tank went negative before ${stop.candidate.stationId}');
        }
      },
    );

    // #4360 — compared at the SAME terminal state. Raw pump cash compares
    // a plan ending near the reserve with one ending on a full tank; the
    // comparable cost values the difference at the set's one basis.
    Glados3(consumption, price, price).test(
      'the cheapest plan never costs more than the fastest one',
      (c, pA, pB) {
        final plans = RefuelPlanner.plan(RefuelPlanRequest(
          routeKm: 600,
          drivingMinutes: 360,
          tankCapacityL: 55,
          startLitres: 50,
          consumptionLPer100km: c,
          candidates: [
            PlanCandidate(
                stationId: 'a', alongRouteKm: 120, pricePerLitre: pA),
            PlanCandidate(
                stationId: 'b', alongRouteKm: 330, pricePerLitre: pB),
            PlanCandidate(
                stationId: 'c', alongRouteKm: 480, pricePerLitre: pA),
          ],
        ));
        final cheap = plans.cheapest, fast = plans.fastest;
        if (cheap == null || fast == null) return;
        expect(plans.comparableCost(cheap)!,
            lessThanOrEqualTo(plans.comparableCost(fast)! + 1e-6),
            reason: 'the "cheapest" plan cost more than the fastest one');
      },
    );
  });
}
