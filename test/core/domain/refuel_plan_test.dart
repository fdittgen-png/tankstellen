// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/refuel_plan.dart';
import 'package:tankstellen/core/domain/refuel_planner.dart';

/// #4146 — planning a long trip's stops once range is a constraint.
///
/// Every expectation here is hand-checkable from the inputs: that is the
/// point of the planner being pure arithmetic over primitives (trust rule
/// 4 of `docs/specs/refuel-economics.md` — no opaque scores).
void main() {
  // A 10 L/100 km car with a 50 L tank and a 5 L reserve: 45 usable
  // litres = 450 km of range. Round numbers on purpose, so every
  // assertion below can be checked in your head.
  RefuelPlanRequest request({
    double routeKm = 740,
    double startLitres = 50,
    List<PlanCandidate> candidates = const [],
    double capacity = 50,
  }) =>
      RefuelPlanRequest(
        routeKm: routeKm,
        drivingMinutes: 457,
        tankCapacityL: capacity,
        startLitres: startLitres,
        consumptionLPer100km: 10,
        candidates: candidates,
      );

  PlanCandidate at(double km, double price, {double detour = 0}) =>
      PlanCandidate(
        stationId: 'km$km',
        alongRouteKm: km,
        pricePerLitre: price,
        detourKm: detour,
      );

  group('what it refuses to compute', () {
    test('no consumption, no plan', () {
      final set = RefuelPlanner.plan(RefuelPlanRequest(
        routeKm: 740,
        drivingMinutes: 457,
        tankCapacityL: 50,
        startLitres: 50,
        consumptionLPer100km: 0,
        candidates: [at(300, 1.7)],
      ));
      // Range is the whole constraint. Guessing it would invent the
      // answer the feature exists to give.
      expect(set.cheapest, isNull);
      expect(set.fastest, isNull);
    });

    test('no tank capacity, no plan', () {
      final set = RefuelPlanner.plan(request(capacity: 0));
      expect(set.cheapest, isNull);
    });
  });

  group('feasibility is an answer, not a crash', () {
    test('a stretch longer than a full tank names the gap', () {
      // 450 km of range, and nothing between km 100 and km 700.
      final set = RefuelPlanner.plan(
        request(candidates: [at(100, 1.70), at(700, 1.60)]),
      );

      expect(set.isFeasible, isFalse);
      expect(set.cheapest, isNull,
          reason: 'an unreachable route has no cheapest plan, only a gap');
      expect(set.gap!.fromKm, closeTo(550, 0.001),
          reason: 'km 100 + 450 km of range');
      expect(set.gap!.toKm, 700);
    });

    test('a route inside one tank needs no stop at all', () {
      final set = RefuelPlanner.plan(
        request(routeKm: 400, candidates: [at(200, 1.70)]),
      );

      expect(set.isFeasible, isTrue);
      expect(set.cheapest!.stops, isEmpty);
      expect(set.cheapest!.fuelCost, 0);
    });

    test('starting nearly empty is accounted for', () {
      // 10 L on board = 50 km of usable range, so the station at km 400
      // is out of reach even though the tank could hold enough.
      final set = RefuelPlanner.plan(
        request(startLitres: 10, candidates: [at(400, 1.60)]),
      );

      expect(set.isFeasible, isFalse);
      expect(set.gap!.fromKm, closeTo(50, 0.001));
    });
  });

  group('the greedy rule', () {
    test('buys just enough to reach a cheaper station in range', () {
      // Cheap fuel 200 km ahead: buy only what it takes to get there.
      final set = RefuelPlanner.plan(request(
        routeKm: 740,
        startLitres: 20, // 150 km usable
        candidates: [at(100, 1.80), at(300, 1.50), at(600, 1.55)],
      ));

      final plan = set.cheapest!;
      expect(plan.stops.first.candidate.stationId, 'km100.0');

      // Arrives at km 100 with 20 − 10 = 10 L. To reach km 300 it needs
      // 20 L plus the 5 L reserve = 25 L, so it buys 15 L — not a fill.
      expect(plan.stops.first.arrivalLitres, closeTo(10, 1e-9));
      expect(plan.stops.first.litres, closeTo(15, 1e-9),
          reason: 'never carry expensive fuel past a cheap station');
      expect(plan.stops.first.cost, closeTo(15 * 1.80, 1e-9));
    });

    test('fills up when nothing cheaper is in range', () {
      // Everything ahead is dearer, so top up completely here.
      final set = RefuelPlanner.plan(request(
        routeKm: 740,
        startLitres: 20,
        candidates: [at(100, 1.50), at(300, 1.80), at(600, 1.90)],
      ));

      final first = set.cheapest!.stops.first;
      expect(first.candidate.stationId, 'km100.0');
      expect(first.arrivalLitres + first.litres, closeTo(50, 1e-9),
          reason: 'a full tank of the cheapest fuel in range');
    });

    test('never drops below the reserve at any arrival', () {
      final set = RefuelPlanner.plan(request(
        startLitres: 30,
        candidates: [
          for (var km = 120.0; km < 740; km += 120) at(km, 1.60 + km / 10000),
        ],
      ));

      for (final stop in set.cheapest!.stops) {
        expect(stop.arrivalLitres, greaterThanOrEqualTo(-1e-9));
        expect(stop.arrivalLitres, lessThanOrEqualTo(50));
      }
      expect(set.cheapest!.isFeasible, isTrue);
    });
  });

  group('the three plans can disagree', () {
    test('fastest takes fewer stops than cheapest when cheap fuel is '
        'scattered', () {
      // Cheap stations early and often; one dear station far along.
      final candidates = [
        at(120, 1.50),
        at(240, 1.50),
        at(360, 1.50),
        at(430, 1.90),
      ];
      final set = RefuelPlanner.plan(
        request(routeKm: 800, startLitres: 50, candidates: candidates),
      );

      expect(set.isFeasible, isTrue);
      expect(set.fastest!.stops.length,
          lessThanOrEqualTo(set.cheapest!.stops.length),
          reason: 'fastest minimises stops; each costs '
              '${kStopOverheadMinutes.toInt()} minutes');
      expect(set.cheapest!.fuelCost,
          lessThanOrEqualTo(set.fastest!.fuelCost + 1e-9),
          reason: 'and cheapest minimises money, or it is not cheapest');
    });
  });

  group('the totals a user is shown', () {
    test('detour kilometres count both ways, and cost fuel', () {
      final set = RefuelPlanner.plan(request(
        routeKm: 500,
        startLitres: 20,
        candidates: [at(100, 1.60, detour: 3)],
      ));

      final plan = set.cheapest!;
      expect(plan.detourKm, closeTo(6, 1e-9), reason: 'off the road and back');
      // 6 km at 10 L/100 km = 0.6 L, valued at the price actually paid.
      expect(plan.detourCost, closeTo(0.6 * 1.60, 1e-6));
      expect(plan.totalCost, closeTo(plan.fuelCost + plan.detourCost, 1e-9));
    });

    test('a stop costs time even with no detour', () {
      final set = RefuelPlanner.plan(request(
        routeKm: 500,
        startLitres: 20,
        candidates: [at(100, 1.60)],
      ));

      final plan = set.cheapest!;
      expect(plan.detourKm, 0);
      expect(plan.totalMinutes,
          closeTo(plan.drivingMinutes + kStopOverheadMinutes, 1e-9));
    });

    test('cost per kilometre is the trip total over the route', () {
      final set = RefuelPlanner.plan(request(
        routeKm: 500,
        startLitres: 20,
        candidates: [at(100, 1.60)],
      ));

      final plan = set.cheapest!;
      expect(plan.costPerKm, closeTo(plan.totalCost / 500, 1e-9));
    });
  });
}
