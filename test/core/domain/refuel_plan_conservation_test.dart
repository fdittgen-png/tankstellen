// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// #4360 — plans conserve fuel and compare equal tank states.
///
/// Expected values are worked by hand beside each assertion from the
/// issue's own fixtures, independently of the planner.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/money.dart';
import 'package:tankstellen/core/domain/refuel_plan.dart';
import 'package:tankstellen/core/domain/refuel_planner.dart';

void main() {
  group('fixture B — an equal terminal state makes two totals comparable',
      () {
    // 120 km, 10 L/100 km, capacity 50 L, start 15 L, reserve 5 L, one
    // on-route station at km 50 priced €2/L.
    final set = RefuelPlanner.plan(const RefuelPlanRequest(
      routeKm: 120,
      drivingMinutes: 90,
      tankCapacityL: 50,
      startLitres: 15,
      consumptionLPer100km: 10,
      reserveLitres: 5,
      currencyCode: 'EUR',
      candidates: [
        PlanCandidate(stationId: 's', alongRouteKm: 50, pricePerLitre: 2),
      ],
    ));
    final cheapest = set.cheapest!;

    test('the plan buys 2 L, spends €4 and ends with 5 L', () {
      // arrive 15 − 5 = 10 L; need 7 L + 5 L reserve = 12 L → buy 2 L.
      expect(cheapest.stops.single.litres, closeTo(2, 1e-9));
      expect(cheapest.fuelCost, closeTo(4, 1e-9));
      expect(cheapest.endLitres, closeTo(5, 1e-9));
    });

    test('every objective lands on it, so it is ONE result with three '
        'labels (#4362)', () {
      // #4362 changed what "fastest" means. It used to be a POLICY —
      // fill the tank at the furthest reachable station — which filled
      // to 50 L here and ended 38 L richer than the cheapest plan for
      // €76 more. That was never a time optimum: the stop, its detour
      // and its overhead are identical whether the driver buys 2 L or
      // 40 L, so the two itineraries take exactly as long as each other
      // and the €76 bought inventory, not minutes.
      expect(set.distinctPlans, hasLength(1));
      expect(set.objectivesFor(cheapest), {
        RefuelObjective.lowestCost,
        RefuelObjective.shortestTime,
        RefuelObjective.leastExtraDistance,
      });
    });

    test('a fuller tank at the destination is inventory, not a loss', () {
      // The valuation rule still has to work for plans that DO end
      // differently — a driver who chose to fill up, or a no-stop
      // journey that arrives with fuel to spare. Built by hand, because
      // the planner no longer produces such a plan for this fixture.
      const filled = RefuelPlan(
        stops: [],
        fuelCost: 80,
        detourKm: 0,
        routeKm: 120,
        drivingMinutes: 90,
        consumptionLPer100km: 10,
        startLitres: 15,
        consumedLitres: 12,
        endLitres: 43,
        currencyCode: 'EUR',
      );
      expect(filled.fuelCost - cheapest.fuelCost, closeTo(76, 1e-9));
      expect(filled.endLitres - cheapest.endLitres, closeTo(38, 1e-9));
      expect(set.valuationPricePerLitre, 2);
      // Valued at the common basis down to the common reserve: equal.
      expect(set.comparableCost(cheapest), closeTo(4, 1e-9));
      expect(set.comparableCost(filled), closeTo(4, 1e-9));
      expect(set.comparableMoney(filled), const Money(4, 'EUR'));
    });
  });

  group('fixture C — no stop still consumes fuel', () {
    test('40 km at 5 L/100 km: no pump spend, 2 L consumed', () {
      final set = RefuelPlanner.plan(const RefuelPlanRequest(
        routeKm: 40,
        drivingMinutes: 35,
        tankCapacityL: 50,
        startLitres: 30,
        consumptionLPer100km: 5,
        candidates: [
          PlanCandidate(stationId: 's', alongRouteKm: 20, pricePerLitre: 1.9),
        ],
      ));
      final plan = set.cheapest!;
      expect(plan.stops, isEmpty);
      expect(plan.fuelCost, 0);
      expect(plan.consumedLitres, closeTo(2, 1e-9));
      expect(plan.endLitres, closeTo(28, 1e-9));
    });
  });

  group('the detour is fuel in the tank, not a second charge', () {
    // 300 km, 10 L/100 km, capacity 50, start 20, reserve 5. One station at
    // km 100, €2/L, with a routed extra of 10 km (5 km access, 5 km back).
    final set = RefuelPlanner.plan(const RefuelPlanRequest(
      routeKm: 300,
      drivingMinutes: 200,
      tankCapacityL: 50,
      startLitres: 20,
      consumptionLPer100km: 10,
      candidates: [
        PlanCandidate(
          stationId: 's',
          alongRouteKm: 100,
          pricePerLitre: 2,
          roadExtraKm: 10,
          roadExtraMinutes: 12,
        ),
      ],
    ));
    final plan = set.cheapest!;

    test('arrival is debited by the access leg, departure by the rejoin', () {
      // 20 − 10 (100 km) − 0.5 (5 km access) = 9.5 L on arrival.
      expect(plan.stops.single.arrivalLitres, closeTo(9.5, 1e-9));
      // Need 0.5 rejoin + 20 (200 km) + 5 reserve = 25.5 → buy 16 L.
      expect(plan.stops.single.litres, closeTo(16, 1e-9));
      expect(plan.endLitres, closeTo(5, 1e-9));
    });

    test('money is the pump cash only: €32, no detour added on top', () {
      expect(plan.fuelCost, closeTo(32, 1e-9));
      expect(plan.totalCost, closeTo(32, 1e-9));
      expect(plan.detourLitres, closeTo(1, 1e-9),
          reason: 'explained, already inside consumedLitres');
      expect(plan.consumedLitres, closeTo(31, 1e-9)); // 310 km × 10/100
    });

    test('the routed detour minutes are used, not the average speed', () {
      expect(plan.detourTimeIsApproximate, isFalse);
      expect(plan.detourMinutes, closeTo(12 + kStopOverheadMinutes, 1e-9));
    });
  });

  test('non-finite or negative inputs are refused, not planned', () {
    for (final bad in [double.nan, double.infinity, -3.0]) {
      final set = RefuelPlanner.plan(RefuelPlanRequest(
        routeKm: 100,
        drivingMinutes: 60,
        tankCapacityL: 50,
        startLitres: 20,
        consumptionLPer100km: 7,
        candidates: [
          PlanCandidate(stationId: 's', alongRouteKm: 50, pricePerLitre: bad),
        ],
      ));
      expect(set.cheapest, isNull, reason: 'price $bad');
      expect(set.gap, isNull);
    }
  });
}
