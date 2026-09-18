// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// #4360 — plans conserve fuel and compare equal tank states.
///
/// Expected values are worked by hand beside each assertion from the
/// issue's own fixtures, independently of the planner.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/refuel_plan.dart';
import 'package:tankstellen/core/domain/refuel_planner.dart';

void main() {
  group('fixture B — different ending inventories are not savings', () {
    // 120 km, 10 L/100 km, capacity 50 L, start 15 L, reserve 5 L, one
    // on-route station at km 50 priced €2/L.
    final set = RefuelPlanner.plan(const RefuelPlanRequest(
      routeKm: 120,
      drivingMinutes: 90,
      tankCapacityL: 50,
      startLitres: 15,
      consumptionLPer100km: 10,
      reserveLitres: 5,
      candidates: [
        PlanCandidate(stationId: 's', alongRouteKm: 50, pricePerLitre: 2),
      ],
    ));
    final cheapest = set.cheapest!, fastest = set.fastest!;

    test('the cheapest plan buys 2 L, spends €4 and ends with 5 L', () {
      // arrive 15 − 5 = 10 L; need 7 L + 5 L reserve = 12 L → buy 2 L.
      expect(cheapest.stops.single.litres, closeTo(2, 1e-9));
      expect(cheapest.fuelCost, closeTo(4, 1e-9));
      expect(cheapest.endLitres, closeTo(5, 1e-9));
    });

    test('the fastest plan buys 40 L, spends €80 and ends with 43 L', () {
      // arrive 10 L, fill to 50 L, drive 70 km = 7 L → 43 L.
      expect(fastest.stops.single.litres, closeTo(40, 1e-9));
      expect(fastest.fuelCost, closeTo(80, 1e-9));
      expect(fastest.endLitres, closeTo(43, 1e-9));
    });

    test('the €76 cash gap is exactly 38 L of extra inventory at €2/L', () {
      expect(fastest.fuelCost - cheapest.fuelCost, closeTo(76, 1e-9));
      expect(fastest.endLitres - cheapest.endLitres, closeTo(38, 1e-9));
      expect(set.valuationPricePerLitre, 2);
      // Valued at the common basis down to the common reserve: equal.
      expect(set.comparableCost(cheapest), closeTo(4, 1e-9));
      expect(set.comparableCost(fastest), closeTo(4, 1e-9));
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
