// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Planning a long trip's refuelling stops (#4146, Epic #4132).
///
/// `best_stops.dart` answers "which station is cheapest in each segment".
/// A driver crossing 740 km asks something else: **given what is in my
/// tank, where do I have to stop, and of those trips which is cheapest?**
/// Range is a constraint, and once it is, the problem has an optimal
/// solution rather than a heuristic.
///
/// Pure Dart over primitives — no Flutter, no feature imports, no station
/// type — for the same reason as `refuel_economics.dart`: a plan the user
/// cannot check is worse than no plan, and this layer has to be
/// reproducible by hand.
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

import 'package:meta/meta.dart';

/// Litres kept in the tank as a buffer. A plan that runs the tank to zero
/// is arithmetic, not advice — the driver has no margin for a closed
/// forecourt, a queue, or a consumption figure that was 8 % optimistic.
const double kDefaultReserveLitres = 5;

/// Minutes a stop costs beyond the driving: pulling off, queueing,
/// paying, rejoining. Used only by the fastest plan, where it is what
/// makes one big stop beat two small ones.
const double kStopOverheadMinutes = 10;

/// A station the plan may stop at, reduced to what planning needs.
@immutable
class PlanCandidate {
  const PlanCandidate({
    required this.stationId,
    required this.alongRouteKm,
    required this.pricePerLitre,
    this.detourKm = 0,
  });

  final String stationId;

  /// Distance from the start ALONG the route. The planner needs
  /// positions on a line; the caller projects stations onto the polyline.
  final double alongRouteKm;

  /// Price of the fuel actually being bought.
  final double pricePerLitre;

  /// Extra kilometres to leave the route and rejoin it. One-way
  /// deviation — the caller doubles it if the station is an errand rather
  /// than en route, exactly as `RefuelProfile.tripFactor` does.
  final double detourKm;
}

/// One stop in a finished plan.
@immutable
class PlannedStop {
  const PlannedStop({
    required this.candidate,
    required this.litres,
    required this.cost,
    required this.arrivalLitres,
  });

  final PlanCandidate candidate;

  /// Litres to buy here. "Just enough to reach a cheaper station" is a
  /// real instruction, so this is not always a full tank.
  final double litres;

  /// What those litres cost, at this station's price.
  final double cost;

  /// Litres left on arrival — the number that proves the plan never
  /// dropped below the reserve.
  final double arrivalLitres;
}

/// Why a route cannot be driven with the given range.
@immutable
class RefuelPlanGap {
  const RefuelPlanGap({required this.fromKm, required this.toKm});

  /// Last reachable point, and the next station beyond it.
  final double fromKm;
  final double toKm;
}

/// A finished plan, or the reason there is none.
@immutable
class RefuelPlan {
  const RefuelPlan({
    required this.stops,
    required this.fuelCost,
    required this.detourKm,
    required this.routeKm,
    required this.drivingMinutes,
    required this.consumptionLPer100km,
    this.gap,
  });

  /// Infeasible: the driver cannot cross [gap] on a full tank.
  const RefuelPlan.infeasible(RefuelPlanGap this.gap)
      : stops = const [],
        fuelCost = 0,
        detourKm = 0,
        routeKm = 0,
        drivingMinutes = 0,
        consumptionLPer100km = 0;

  final List<PlannedStop> stops;

  /// Money spent at the pumps.
  final double fuelCost;

  /// Extra kilometres driven to reach the stops.
  final double detourKm;

  final double routeKm;
  final double drivingMinutes;
  final double consumptionLPer100km;

  /// Non-null when no plan exists. Every other field is then meaningless
  /// and the UI must say what is missing rather than show a total.
  final RefuelPlanGap? gap;

  bool get isFeasible => gap == null;

  /// Fuel burned covering the detours, valued at what it cost to buy.
  ///
  /// Weighted by the plan's own average price, so this is reproducible
  /// from the stops shown rather than from a rate nobody can see.
  double get detourCost {
    if (stops.isEmpty || detourKm <= 0) return 0;
    final litres = stops.fold<double>(0, (s, x) => s + x.litres);
    if (litres <= 0) return 0;
    final avgPrice = fuelCost / litres;
    return detourKm * consumptionLPer100km / 100 * avgPrice;
  }

  /// What the trip costs in money: pumps plus the driving the detours add.
  double get totalCost => fuelCost + detourCost;

  /// Minutes the detours add, plus the fixed cost of stopping at all.
  double get detourMinutes =>
      _detourDrivingMinutes + stops.length * kStopOverheadMinutes;

  double get _detourDrivingMinutes {
    if (routeKm <= 0 || detourKm <= 0) return 0;
    // Detour kilometres are assumed to run at the route's own average
    // speed. Off-motorway they are usually slower, which makes this an
    // UNDER-estimate — the honest direction for a number that talks
    // someone into a detour.
    return detourKm * (drivingMinutes / routeKm);
  }

  double get totalMinutes => drivingMinutes + detourMinutes;

  /// The trip's cost per kilometre — the figure that compares two plans
  /// of different shapes.
  double? get costPerKm => routeKm <= 0 ? null : totalCost / routeKm;
}

/// Inputs a plan is computed from.
@immutable
class RefuelPlanRequest {
  const RefuelPlanRequest({
    required this.routeKm,
    required this.drivingMinutes,
    required this.tankCapacityL,
    required this.startLitres,
    required this.consumptionLPer100km,
    required this.candidates,
    this.reserveLitres = kDefaultReserveLitres,
  });

  final double routeKm;
  final double drivingMinutes;
  final double tankCapacityL;
  final double startLitres;
  final double consumptionLPer100km;

  /// Stops available, in any order — the planner sorts by position.
  final List<PlanCandidate> candidates;

  /// Litres the plan refuses to dip below.
  final double reserveLitres;

  /// Whether the arithmetic can run at all.
  ///
  /// No consumption and no capacity are BOTH hard stops, not defaults:
  /// range is the entire constraint this feature exists to respect, and
  /// guessing it would silently invent the answer (spec §4.1).
  bool get isComputable =>
      routeKm > 0 &&
      tankCapacityL > 0 &&
      consumptionLPer100km > 0 &&
      startLitres >= 0 &&
      reserveLitres >= 0 &&
      tankCapacityL > reserveLitres;

  /// Litres to cover [km].
  double litresFor(double km) => km * consumptionLPer100km / 100;

  /// Kilometres [litres] covers.
  double kmFor(double litres) =>
      consumptionLPer100km <= 0 ? 0 : litres / consumptionLPer100km * 100;

  /// Range on a full tank, down to the reserve.
  double get fullRangeKm => kmFor(tankCapacityL - reserveLitres);
}

/// The three plans a long trip has (#4146).
///
/// Three, for the same reason `refuel_economics.dart` ranks three ways:
/// the question genuinely has three answers and the app does not get to
/// pick for the driver. Any of them may be null when it cannot be
/// computed honestly.
@immutable
class RefuelPlanSet {
  const RefuelPlanSet({this.cheapest, this.fastest, this.gap});

  /// Minimum total money.
  final RefuelPlan? cheapest;

  /// Minimum total time — fewest stops, smallest detours.
  final RefuelPlan? fastest;

  /// Set when the route cannot be driven at all; then both plans are null.
  final RefuelPlanGap? gap;

  bool get isFeasible => gap == null;
}

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
