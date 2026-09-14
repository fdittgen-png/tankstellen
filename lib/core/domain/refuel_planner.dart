// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// The greedy optimal refuelling policy (#4146, Epic #4132).
///
/// Split from `refuel_plan.dart` when that file reached the 400-line cap.
/// A real seam rather than a length dodge: "what a plan IS" and "how one
/// is computed" are different concerns, and the types are consumed by
/// callers that never run the planner. `refuel_economics.dart` is split
/// the same way — value types, then an `abstract final` computer.
///
/// ## The rule
///
/// For minimum fuel cost with a tank of fixed capacity the greedy policy
/// is provably optimal, and it is the whole algorithm:
///
/// > At each stop, look ahead at every station reachable on a full tank.
/// > If a cheaper one is reachable, buy **just enough** to get there.
/// > Otherwise fill up, and drive to the cheapest station in range.
///
/// The intuition: you never want to carry expensive fuel past a cheap
/// station, and you never want to arrive at a cheap station with a full
/// tank you paid more for.
library;

import 'dart:math' as math;

import 'refuel_plan.dart';

abstract final class RefuelPlanner {
  /// Plan [request] three ways.
  ///
  /// Returns an empty set when the inputs cannot support arithmetic —
  /// the caller says what is missing rather than showing a guess.
  static RefuelPlanSet plan(RefuelPlanRequest request) {
    if (!request.isComputable) return const RefuelPlanSet();

    final sorted = [...request.candidates]
      ..sort((a, b) => a.alongRouteKm.compareTo(b.alongRouteKm));

    final gap = _firstGap(request, sorted);
    if (gap != null) return RefuelPlanSet(gap: gap);

    return RefuelPlanSet(
      cheapest: _cheapest(request, sorted),
      fastest: _fastest(request, sorted),
    );
  }

  /// The first stretch the driver cannot cross, or null.
  ///
  /// Checked before any planning, because an infeasible route has no
  /// cheapest plan — only a gap to name.
  static RefuelPlanGap? _firstGap(
    RefuelPlanRequest r,
    List<PlanCandidate> sorted,
  ) {
    // From the start, on what is in the tank now.
    var reachable = r.kmFor(math.max(0, r.startLitres - r.reserveLitres));
    var at = 0.0;
    for (final c in sorted) {
      if (c.alongRouteKm <= at) continue;
      if (c.alongRouteKm > at + reachable) {
        return RefuelPlanGap(fromKm: at + reachable, toKm: c.alongRouteKm);
      }
      at = c.alongRouteKm;
      reachable = r.fullRangeKm;
    }
    if (r.routeKm > at + reachable) {
      return RefuelPlanGap(fromKm: at + reachable, toKm: r.routeKm);
    }
    return null;
  }

  /// The greedy optimal policy for minimum fuel cost (see the library
  /// doc). Buys just enough to reach a cheaper station when one is in
  /// range; fills up otherwise.
  static RefuelPlan _cheapest(RefuelPlanRequest r, List<PlanCandidate> sorted) {
    final stops = <PlannedStop>[];
    var position = 0.0;
    var litres = r.startLitres;
    var cost = 0.0;
    var detour = 0.0;

    while (true) {
      final remaining = r.routeKm - position;
      if (litres - r.reserveLitres >= r.litresFor(remaining)) break;

      final reach = position + r.kmFor(litres - r.reserveLitres);
      final inRange = [
        for (final c in sorted)
          if (c.alongRouteKm > position && c.alongRouteKm <= reach) c,
      ];
      if (inRange.isEmpty) break; // _firstGap already ruled this out

      // The first strictly cheaper station in range, if any.
      final here = inRange.first;
      PlanCandidate? cheaperAhead;
      for (final c in inRange) {
        if (c.pricePerLitre < here.pricePerLitre) {
          cheaperAhead = c;
          break;
        }
      }

      // Stop at the cheapest station in range; ties keep the nearest so
      // the plan does not send the driver past one forecourt to an
      // identical one.
      var stop = here;
      for (final c in inRange) {
        if (c.pricePerLitre < stop.pricePerLitre) stop = c;
      }
      if (cheaperAhead != null && cheaperAhead.stationId != stop.stationId) {
        stop = cheaperAhead;
      }

      final arrival = litres - r.litresFor(stop.alongRouteKm - position);

      // How far must this tank reach? To the next cheaper station if one
      // is in range from HERE, else as far as the tank allows.
      final onwardReach = stop.alongRouteKm + r.fullRangeKm;
      PlanCandidate? nextCheaper;
      for (final c in sorted) {
        if (c.alongRouteKm <= stop.alongRouteKm) continue;
        if (c.alongRouteKm > onwardReach) break;
        if (c.pricePerLitre < stop.pricePerLitre) {
          nextCheaper = c;
          break;
        }
      }

      final targetKm = nextCheaper != null
          ? math.min(nextCheaper.alongRouteKm, r.routeKm)
          : math.min(onwardReach, r.routeKm);
      final needed =
          r.litresFor(targetKm - stop.alongRouteKm) + r.reserveLitres;
      final buy =
          math.max(0.0, math.min(r.tankCapacityL, needed) - arrival);

      stops.add(PlannedStop(
        candidate: stop,
        litres: buy,
        cost: buy * stop.pricePerLitre,
        arrivalLitres: arrival,
      ));
      cost += buy * stop.pricePerLitre;
      detour += stop.detourKm * 2; // off the route and back on
      litres = arrival + buy;
      position = stop.alongRouteKm;
    }

    return RefuelPlan(
      stops: stops,
      fuelCost: cost,
      detourKm: detour,
      routeKm: r.routeKm,
      drivingMinutes: r.drivingMinutes,
      consumptionLPer100km: r.consumptionLPer100km,
    );
  }

  /// Fewest stops, and among equal-length plans the smallest detour.
  ///
  /// Drive time over the route itself is fixed, so minimising time means
  /// minimising stops (each costs [kStopOverheadMinutes]) and the
  /// kilometres spent leaving the road.
  static RefuelPlan _fastest(RefuelPlanRequest r, List<PlanCandidate> sorted) {
    final stops = <PlannedStop>[];
    var position = 0.0;
    var litres = r.startLitres;
    var cost = 0.0;
    var detour = 0.0;

    while (true) {
      final remaining = r.routeKm - position;
      if (litres - r.reserveLitres >= r.litresFor(remaining)) break;

      final reach = position + r.kmFor(litres - r.reserveLitres);
      final inRange = [
        for (final c in sorted)
          if (c.alongRouteKm > position && c.alongRouteKm <= reach) c,
      ];
      if (inRange.isEmpty) break;

      // Go as far as possible — that is what makes the stop count
      // minimal. Among the farthest few, prefer the smaller detour.
      final farthest = inRange.last.alongRouteKm;
      var stop = inRange.last;
      for (final c in inRange) {
        // Within the last 10 % of reachable distance, a shorter detour
        // wins: arriving 20 km earlier is not worth 8 km off the road.
        if (c.alongRouteKm >= farthest - r.fullRangeKm * 0.1 &&
            c.detourKm < stop.detourKm) {
          stop = c;
        }
      }

      final arrival = litres - r.litresFor(stop.alongRouteKm - position);
      // Fill up: a fastest plan never returns for a second short stop.
      final buy = r.tankCapacityL - arrival;

      stops.add(PlannedStop(
        candidate: stop,
        litres: buy,
        cost: buy * stop.pricePerLitre,
        arrivalLitres: arrival,
      ));
      cost += buy * stop.pricePerLitre;
      detour += stop.detourKm * 2;
      litres = arrival + buy;
      position = stop.alongRouteKm;
    }

    return RefuelPlan(
      stops: stops,
      fuelCost: cost,
      detourKm: detour,
      routeKm: r.routeKm,
      drivingMinutes: r.drivingMinutes,
      consumptionLPer100km: r.consumptionLPer100km,
    );
  }
}
