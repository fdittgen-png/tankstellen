// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// #4362 — feasibility, and the three objectives.
///
/// The reference solver at the bottom is deliberately NOT the planner's
/// algorithm: it enumerates every stop subset, walks a purchase grid at
/// each stop but the last, solves the last from the terminal level, and
/// checks the tank leg by leg. It is far too slow to ship and far too
/// simple to be wrong, which is exactly what makes it a check on the
/// closed-form quantity rule rather than an echo of it. It shares no code
/// with the planner beyond the request type.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/refuel_itinerary.dart';
import 'package:tankstellen/core/domain/refuel_plan.dart';
import 'package:tankstellen/core/domain/refuel_planner.dart';

void main() {
  PlanCandidate at(
    String id,
    double km,
    double price, {
    double extraKm = 0,
    double? extraMinutes,
    double? charge,
  }) =>
      PlanCandidate(
        stationId: id,
        alongRouteKm: km,
        pricePerLitre: price,
        roadExtraKm: extraKm,
        roadExtraMinutes: extraMinutes ?? 0,
        incrementalCharge: charge,
      );

  group('feasibility is checked on the real legs', () {
    test('a station whose access leg eats the reserve is not a stop', () {
      // Start 10 L, reserve 5 L, 10 L/100 km. The station sits at route
      // km 40 behind a 15 km access leg: 40 km costs 4 L and the access
      // leg 1.5 L, so it is reached with 4.5 L — under the reserve. The
      // rejoin leg costs another 1.5 L on the way out.
      final set = RefuelPlanner.plan(RefuelPlanRequest(
        routeKm: 200,
        drivingMinutes: 120,
        tankCapacityL: 40,
        startLitres: 10,
        consumptionLPer100km: 10,
        reserveLitres: 5,
        candidates: [at('far-off', 40, 1.5, extraKm: 30)],
      ));
      expect(set.cheapest, isNull);
      expect(set.gap, isNotNull, reason: 'the journey breaks, and says where');
    });

    test('the same station on a shorter access leg IS a stop', () {
      final set = RefuelPlanner.plan(RefuelPlanRequest(
        routeKm: 200,
        drivingMinutes: 120,
        tankCapacityL: 40,
        startLitres: 10,
        consumptionLPer100km: 10,
        reserveLitres: 5,
        candidates: [at('near', 40, 1.5, extraKm: 2)],
      ));
      final plan = set.cheapest!;
      expect(plan.stops.single.arrivalLitres, closeTo(5.9, 1e-9));
      expect(plan.endLitres, closeTo(5, 1e-9));
      // start + bought − consumed = end, detours included.
      expect(plan.startLitres + plan.litresBought - plan.consumedLitres,
          closeTo(plan.endLitres, 1e-9));
    });

    test('a station at the route origin is a valid refuelling action', () {
      final set = RefuelPlanner.plan(RefuelPlanRequest(
        routeKm: 100,
        drivingMinutes: 60,
        tankCapacityL: 40,
        startLitres: 6,
        consumptionLPer100km: 10,
        reserveLitres: 5,
        candidates: [at('origin', 0, 1.5)],
      ));
      expect(set.cheapest!.stops.single.candidate.stationId, 'origin');
      expect(set.cheapest!.endLitres, closeTo(5, 1e-9));
    });

    test('a candidate beyond the destination creates no stop', () {
      final set = RefuelPlanner.plan(RefuelPlanRequest(
        routeKm: 100,
        drivingMinutes: 60,
        tankCapacityL: 40,
        startLitres: 30,
        consumptionLPer100km: 10,
        reserveLitres: 5,
        candidates: [at('past-the-end', 140, 1.0)],
      ));
      expect(set.cheapest!.stops, isEmpty);
      expect(set.cheapest!.endLitres, closeTo(20, 1e-9));
    });

    test('no priced candidate at all is still a journey when the tank '
        'covers it', () {
      final set = RefuelPlanner.plan(const RefuelPlanRequest(
        routeKm: 100,
        drivingMinutes: 60,
        tankCapacityL: 40,
        startLitres: 30,
        consumptionLPer100km: 10,
        reserveLitres: 5,
        candidates: [],
      ));
      expect(set.gap, isNull);
      expect(set.cheapest!.stops, isEmpty);
      expect(set.cheapest!.consumedLitres, closeTo(10, 1e-9),
          reason: 'zero pump spend is not zero consumption');
    });

    test('duplicate route positions do not create phantom stops', () {
      final set = RefuelPlanner.plan(RefuelPlanRequest(
        routeKm: 200,
        drivingMinutes: 120,
        tankCapacityL: 40,
        startLitres: 20,
        consumptionLPer100km: 10,
        reserveLitres: 5,
        candidates: [at('a', 100, 1.5), at('b', 100, 1.4)],
      ));
      final plan = set.cheapest!;
      expect(plan.stops, hasLength(1));
      expect(plan.stops.single.candidate.stationId, 'b');
    });

    test('an infeasible journey never returns a plan', () {
      final set = RefuelPlanner.plan(const RefuelPlanRequest(
        routeKm: 400,
        drivingMinutes: 240,
        tankCapacityL: 40,
        startLitres: 10,
        consumptionLPer100km: 10,
        reserveLitres: 5,
        candidates: [],
      ));
      expect(set.cheapest, isNull);
      expect(set.fastest, isNull);
      expect(set.leastDetour, isNull);
      expect(set.gap!.fromKm, closeTo(50, 1e-9));
    });

    test('invalid inputs are refused rather than planned', () {
      for (final request in [
        const RefuelPlanRequest(
          routeKm: 0,
          drivingMinutes: 10,
          tankCapacityL: 40,
          startLitres: 10,
          consumptionLPer100km: 10,
          candidates: [],
        ),
        const RefuelPlanRequest(
          routeKm: 100,
          drivingMinutes: 10,
          tankCapacityL: 40,
          startLitres: 10,
          consumptionLPer100km: -1,
          candidates: [],
        ),
        const RefuelPlanRequest(
          routeKm: double.nan,
          drivingMinutes: 10,
          tankCapacityL: 40,
          startLitres: 10,
          consumptionLPer100km: 10,
          candidates: [],
        ),
      ]) {
        final set = RefuelPlanner.plan(request);
        expect(set.cheapest, isNull);
        expect(set.gap, isNull, reason: 'no arithmetic is not a gap');
      }
    });
  });

  group('the three objectives disagree', () {
    // 300 km at 10 L/100 km, capacity 40 L, start 12 L, reserve 5 L.
    //
    //  cheap-detour  €1.20/L, 20 km off the road and 30 min
    //  fast-medium   €1.60/L,  6 km off the road and  4 min (a slip road)
    //  slow-short    €1.70/L,  1 km off the road and 14 min (through town)
    //
    // All three sit at km 60, the last point a 7-usable-litre tank
    // reaches, so the choice is purely which trade to make: the cheapest
    // fuel costs 20 km and half an hour; the shortest drive costs 14
    // minutes crawling; the quickest stop is neither.
    final request = RefuelPlanRequest(
      routeKm: 300,
      drivingMinutes: 180,
      tankCapacityL: 40,
      startLitres: 12,
      consumptionLPer100km: 10,
      reserveLitres: 5,
      currencyCode: 'EUR',
      candidates: [
        at('cheap-detour', 60, 1.20, extraKm: 20, extraMinutes: 30),
        at('fast-medium', 60, 1.60, extraKm: 6, extraMinutes: 4),
        at('slow-short', 60, 1.70, extraKm: 1, extraMinutes: 14),
      ],
    );
    final set = RefuelPlanner.plan(request);

    test('each objective picks a different itinerary', () {
      expect(set.cheapest!.stops.map((s) => s.candidate.stationId),
          ['cheap-detour']);
      expect(set.fastest!.stops.map((s) => s.candidate.stationId),
          ['fast-medium']);
      expect(set.leastDetour!.stops.map((s) => s.candidate.stationId),
          ['slow-short']);
      expect(set.distinctPlans, hasLength(3));
    });

    test('each is the minimum of its own measure among every feasible '
        'itinerary', () {
      final all = _feasibleItineraries(request);
      expect(set.cheapest!.totalCost,
          closeTo(all.map((i) => i.cost).reduce(_min), 1e-6));
      expect(set.fastest!.totalMinutes,
          closeTo(all.map((i) => i.minutes).reduce(_min), 1e-6));
      expect(set.leastDetour!.detourKm,
          closeTo(all.map((i) => i.extraKm).reduce(_min), 1e-6));
    });

    test('a shorter drive that takes longer does not win "fastest"', () {
      // slow-short is the shortest drive of the three and the second
      // SLOWEST: 1 km off the road, 14 minutes of it.
      expect(set.leastDetour!.detourKm, lessThan(set.fastest!.detourKm));
      expect(set.fastest!.totalMinutes,
          lessThan(set.leastDetour!.totalMinutes));
      expect(set.cheapest!.totalMinutes,
          greaterThan(set.leastDetour!.totalMinutes));
    });

    test('the objectives share one journey, vehicle and terminal state',
        () {
      for (final plan in set.distinctPlans) {
        expect(plan.routeKm, 300);
        expect(plan.startLitres, 12);
        expect(plan.endLitres, closeTo(5, 1e-6));
      }
    });
  });

  group('the objectives are not a hidden score', () {
    test('a cheaper pump loses once the detour is paid for', () {
      final set = RefuelPlanner.plan(RefuelPlanRequest(
        routeKm: 200,
        drivingMinutes: 120,
        tankCapacityL: 40,
        startLitres: 20,
        consumptionLPer100km: 10,
        reserveLitres: 5,
        candidates: [
          at('cheap-far', 80, 1.40, extraKm: 40, extraMinutes: 45),
          at('dear-near', 80, 1.45),
        ],
      ));
      expect(set.cheapest!.stops.single.candidate.stationId, 'dear-near');
    });

    test('a stop-only charge can flip the cheapest itinerary', () {
      RefuelPlanSet planWith({double? charge}) =>
          RefuelPlanner.plan(RefuelPlanRequest(
            routeKm: 200,
            drivingMinutes: 120,
            tankCapacityL: 40,
            startLitres: 10,
            consumptionLPer100km: 10,
            reserveLitres: 5,
            currencyCode: 'EUR',
            candidates: [
              at('A', 40, 2.00),
              at('B', 100, 1.50, charge: charge),
            ],
          ));
      final free = planWith();
      expect(free.cheapest!.stops.map((s) => s.candidate.stationId),
          ['A', 'B']);
      expect(free.cheapest!.totalCost, closeTo(25, 1e-9));

      final tolled = planWith(charge: 6);
      expect(tolled.cheapest!.stops.map((s) => s.candidate.stationId), ['A']);
      expect(tolled.cheapest!.totalCost, closeTo(30, 1e-9));
    });

    test('cost per kilometre is a unit conversion, not a fourth answer',
        () {
      final set = RefuelPlanner.plan(RefuelPlanRequest(
        routeKm: 200,
        drivingMinutes: 120,
        tankCapacityL: 40,
        startLitres: 10,
        consumptionLPer100km: 10,
        reserveLitres: 5,
        currencyCode: 'EUR',
        candidates: [at('A', 40, 2.0), at('B', 100, 1.5)],
      ));
      final plan = set.cheapest!;
      expect(plan.costPerKm, closeTo(plan.totalCost / 200, 1e-12));
    });
  });

  group('the search states its own bounds', () {
    test('a small candidate set is searched exhaustively', () {
      final set = RefuelPlanner.plan(RefuelPlanRequest(
        routeKm: 200,
        drivingMinutes: 120,
        tankCapacityL: 40,
        startLitres: 20,
        consumptionLPer100km: 10,
        reserveLitres: 5,
        candidates: [at('a', 50, 1.5), at('b', 120, 1.4)],
      ));
      expect(set.searchWasBounded, isFalse);
    });

    test('a large candidate set is bounded, says so, and still plans', () {
      final many = [
        for (var i = 0; i < 40; i++)
          at('s$i', 10.0 + i * 5, 1.9 - i * 0.01),
      ];
      final stopwatch = Stopwatch()..start();
      final set = RefuelPlanner.plan(RefuelPlanRequest(
        routeKm: 300,
        drivingMinutes: 180,
        tankCapacityL: 40,
        startLitres: 12,
        consumptionLPer100km: 10,
        reserveLitres: 5,
        candidates: many,
      ));
      final elapsed = (stopwatch..stop()).elapsed;
      expect(set.searchWasBounded, isTrue,
          reason: 'the claim is the best FOUND, never complete coverage');
      expect(set.cheapest, isNotNull);
      expect(elapsed.inSeconds, lessThan(2),
          reason: 'the documented work limit keeps this off the UI thread');
    });
  });

  group("the driver's limits apply to every objective", () {
    test('a detour past the stated limit is never recommended', () {
      final set = RefuelPlanner.plan(RefuelPlanRequest(
        routeKm: 200,
        drivingMinutes: 120,
        tankCapacityL: 40,
        startLitres: 20,
        consumptionLPer100km: 10,
        reserveLitres: 5,
        limits: const TravelLimits(maxExtraKm: 5),
        candidates: [
          at('over-limit', 60, 1.0, extraKm: 30, extraMinutes: 40),
          at('within', 60, 1.8, extraKm: 4, extraMinutes: 5),
        ],
      ));
      for (final plan in set.distinctPlans) {
        expect(plan.stops.map((s) => s.candidate.stationId),
            isNot(contains('over-limit')));
      }
    });
  });
}

double _min(double a, double b) => a < b ? a : b;

/// One itinerary the reference solver found feasible.
typedef _Reference = ({double cost, double minutes, double extraKm});

/// Independent brute force: every stop subset, every purchase at all but
/// the LAST stop on a 0.25 L grid, and the last quantity solved from the
/// terminal-level requirement (a grid cannot land on 23.2 L, and an
/// itinerary that ends anywhere else is not comparable anyway). The tank
/// is checked leg by leg. Exponential and deliberately naive — it shares
/// no code with the planner beyond the request type.
List<_Reference> _feasibleItineraries(RefuelPlanRequest r) {
  const step = 0.25;
  final sites = [
    for (final c in r.candidates)
      if (c.alongRouteKm >= 0 && c.alongRouteKm <= r.routeKm) c,
  ]..sort((a, b) => a.alongRouteKm.compareTo(b.alongRouteKm));
  final out = <_Reference>[];

  void walk(List<PlanCandidate> chosen, int from) {
    _evaluate(r, chosen, step, out);
    for (var i = from; i < sites.length; i++) {
      walk([...chosen, sites[i]], i + 1);
    }
  }

  walk(const [], 0);
  return out;
}

void _evaluate(
  RefuelPlanRequest r,
  List<PlanCandidate> stops,
  double step,
  List<_Reference> out,
) {
  if (stops.isEmpty) {
    final end = r.startLitres - r.litresFor(r.routeKm);
    if (end >= r.reserveLitres - 1e-9) {
      out.add((cost: 0, minutes: r.drivingMinutes, extraKm: 0));
    }
    return;
  }
  final grid = (r.tankCapacityL / step).round() + 1;
  final free = stops.length - 1;
  final quantities = List<int>.filled(free, 0);

  bool next() {
    for (var i = free - 1; i >= 0; i--) {
      if (++quantities[i] < grid) return true;
      quantities[i] = 0;
    }
    return false;
  }

  do {
    var litres = r.startLitres;
    var position = 0.0;
    var cost = 0.0;
    var minutes = r.drivingMinutes;
    var extraKm = 0.0;
    var ok = true;
    for (var i = 0; i < stops.length && ok; i++) {
      final stop = stops[i];
      final half = r.litresFor(stop.extraKm / 2);
      final arrival =
          litres - r.litresFor(stop.alongRouteKm - position) - half;
      if (arrival < r.reserveLitres - 1e-9) ok = false;
      // The last stop buys exactly what reaches the terminal level.
      final buy = i == free
          ? r.reserveLitres +
              half +
              r.litresFor(r.routeKm - stop.alongRouteKm) -
              arrival
          : quantities[i] * step;
      if (buy < -1e-9) ok = false;
      if (arrival + buy > r.tankCapacityL + 1e-9) ok = false;
      cost += buy * stop.pricePerLitre + (stop.incrementalCharge ?? 0);
      minutes += (stop.roadExtraMinutes ?? 0) + kStopOverheadMinutes;
      extraKm += stop.extraKm;
      litres = arrival + buy - half;
      position = stop.alongRouteKm;
    }
    if (!ok) continue;
    final end = litres - r.litresFor(r.routeKm - position);
    if ((end - r.reserveLitres).abs() > 1e-6) continue;
    if (r.limits.exceededByKm(extraKm)) continue;
    if (r.limits.exceededByMinutes(minutes - r.drivingMinutes)) continue;
    out.add((cost: cost, minutes: minutes, extraKm: extraKm));
  } while (free > 0 && next());
}
