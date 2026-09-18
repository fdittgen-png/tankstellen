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
/// ## Fuel is conserved on every leg (#4360)
///
/// A stop is three legs, not a point on the route: the drive along the
/// route to the exit, the ACCESS leg to the forecourt, and the REJOIN leg
/// back. The routed extra of a stop (#4359, else the approximate
/// out-and-back deviation) is split evenly between access and rejoin —
/// the router reports the pair, not the split:
///
/// ```
/// arrival   = previous departure − along-route litres − access litres ≥ reserve
/// departure = arrival + bought                                         ≤ capacity
/// on route  = departure − rejoin litres
/// end       = on route − litres to the destination
/// ```
///
/// Detour fuel therefore comes out of the tank and is bought at the pump
/// like every other litre — it is never added to the money a second time.
library;

import 'dart:math' as math;

import 'refuel_plan.dart';

abstract final class RefuelPlanner {
  /// Plan [request] two ways.
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
      reserveLitres: request.reserveLitres,
      currencyCode: request.currencyCode,
      valuationPricePerLitre: sorted.isEmpty
          ? null
          : sorted.map((c) => c.pricePerLitre).reduce(math.min),
    );
  }

  /// The first stretch the driver cannot cross, or null.
  ///
  /// Checked before any planning, because an infeasible route has no
  /// cheapest plan — only a gap to name. Each hop goes to the reachable
  /// station whose full tank reaches furthest, access and rejoin legs
  /// included, so a far-off station is not counted as a bridge its own
  /// detour cannot pay for.
  static RefuelPlanGap? _firstGap(
    RefuelPlanRequest r,
    List<PlanCandidate> sorted,
  ) {
    const eps = 1e-9;
    var at = 0.0;
    var available = r.startLitres - r.reserveLitres;
    while (true) {
      if (r.litresFor(r.routeKm - at) <= available + eps) return null;
      PlanCandidate? best;
      var bestFrontier = double.negativeInfinity;
      for (final c in sorted) {
        if (c.alongRouteKm <= at) continue;
        final need = r.litresFor(c.alongRouteKm - at) + _half(r, c);
        if (need > available + eps) continue;
        final frontier = c.alongRouteKm +
            r.kmFor(r.tankCapacityL - r.reserveLitres - _half(r, c));
        if (frontier > bestFrontier) {
          best = c;
          bestFrontier = frontier;
        }
      }
      if (best == null) {
        final next = sorted.where((c) => c.alongRouteKm > at).firstOrNull;
        return RefuelPlanGap(
          fromKm: at + r.kmFor(math.max(0, available)),
          toKm: next?.alongRouteKm ?? r.routeKm,
        );
      }
      at = best.alongRouteKm;
      available = r.tankCapacityL - r.reserveLitres - _half(r, best);
    }
  }

  /// Litres of ONE of a stop's two detour legs (access or rejoin).
  static double _half(RefuelPlanRequest r, PlanCandidate c) =>
      r.litresFor(c.extraKm / 2);

  /// The greedy optimal policy for minimum fuel cost (see the library
  /// doc). Buys just enough to reach a cheaper station when one is in
  /// range; fills up otherwise.
  static RefuelPlan _cheapest(RefuelPlanRequest r, List<PlanCandidate> sorted) {
    final ledger = _Ledger(r);

    while (!ledger.coversTheRest) {
      final inRange = ledger.inRange(sorted);
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

      // How far must this tank reach after the rejoin? To the next cheaper
      // station (its access leg included) if one is in range from HERE,
      // else to the destination or as far as a full tank allows.
      final rejoin = _half(r, stop);
      final onwardReach = stop.alongRouteKm +
          r.kmFor(r.tankCapacityL - r.reserveLitres - rejoin);
      PlanCandidate? nextCheaper;
      for (final c in sorted) {
        if (c.alongRouteKm <= stop.alongRouteKm) continue;
        if (c.alongRouteKm > onwardReach) break;
        if (c.pricePerLitre < stop.pricePerLitre) {
          nextCheaper = c;
          break;
        }
      }

      final double neededAtDeparture;
      if (nextCheaper != null) {
        neededAtDeparture = rejoin +
            r.litresFor(nextCheaper.alongRouteKm - stop.alongRouteKm) +
            _half(r, nextCheaper) +
            r.reserveLitres;
      } else {
        final targetKm = math.min(onwardReach, r.routeKm);
        neededAtDeparture = rejoin +
            r.litresFor(targetKm - stop.alongRouteKm) +
            r.reserveLitres;
      }
      ledger.stopAt(stop, (arrival) => math.max(0.0,
          math.min(r.tankCapacityL, neededAtDeparture) - arrival));
    }

    return ledger.finish();
  }

  /// Fewest stops, and among equal-length plans the smallest detour.
  ///
  /// Drive time over the route itself is fixed, so minimising time means
  /// minimising stops (each costs [kStopOverheadMinutes]) and the
  /// kilometres spent leaving the road.
  static RefuelPlan _fastest(RefuelPlanRequest r, List<PlanCandidate> sorted) {
    final ledger = _Ledger(r);

    while (!ledger.coversTheRest) {
      final inRange = ledger.inRange(sorted);
      if (inRange.isEmpty) break;

      // Go as far as possible — that is what makes the stop count
      // minimal. Among the farthest few, prefer the smaller detour.
      final farthest = inRange.last.alongRouteKm;
      var stop = inRange.last;
      for (final c in inRange) {
        // Within the last 10 % of reachable distance, a shorter detour
        // wins: arriving 20 km earlier is not worth 8 km off the road.
        if (c.alongRouteKm >= farthest - r.fullRangeKm * 0.1 &&
            c.extraKm < stop.extraKm) {
          stop = c;
        }
      }

      // Fill up: a fastest plan never returns for a second short stop.
      ledger.stopAt(stop, (arrival) => r.tankCapacityL - arrival);
    }

    return ledger.finish();
  }
}

/// The running tank and money of one plan — the conservation rule in
/// one place, so the two policies cannot book fuel differently.
class _Ledger {
  _Ledger(this.r) : litres = r.startLitres;

  final RefuelPlanRequest r;
  final stops = <PlannedStop>[];
  double position = 0;
  double litres;
  double cash = 0;
  double consumed = 0;
  double detourKm = 0;
  double roadMinutes = 0;
  double approxKm = 0;

  /// The tank covers the rest of the route, down to the reserve.
  bool get coversTheRest =>
      litres - r.reserveLitres >= r.litresFor(r.routeKm - position) - 1e-9;

  /// Stations ahead whose along-route drive AND access leg arrive with
  /// at least the reserve.
  List<PlanCandidate> inRange(List<PlanCandidate> sorted) => [
        for (final c in sorted)
          if (c.alongRouteKm > position &&
              litres -
                      r.litresFor(c.alongRouteKm - position) -
                      RefuelPlanner._half(r, c) >=
                  r.reserveLitres - 1e-9)
            c,
      ];

  void stopAt(PlanCandidate stop, double Function(double arrival) buyFor) {
    final along = r.litresFor(stop.alongRouteKm - position);
    final half = RefuelPlanner._half(r, stop);
    final arrival = litres - along - half;
    final buy = buyFor(arrival);
    stops.add(PlannedStop(
      candidate: stop,
      litres: buy,
      cost: buy * stop.pricePerLitre,
      arrivalLitres: arrival,
    ));
    cash += buy * stop.pricePerLitre;
    consumed += along + 2 * half;
    detourKm += stop.extraKm;
    final routed = stop.roadExtraMinutes;
    if (routed != null) {
      roadMinutes += routed;
    } else {
      approxKm += stop.extraKm;
    }
    litres = arrival + buy - half;
    position = stop.alongRouteKm;
  }

  RefuelPlan finish() {
    final last = r.litresFor(r.routeKm - position);
    return RefuelPlan(
      stops: stops,
      fuelCost: cash,
      detourKm: detourKm,
      roadDetourMinutes: roadMinutes,
      approximateDetourKm: approxKm,
      routeKm: r.routeKm,
      drivingMinutes: r.drivingMinutes,
      consumptionLPer100km: r.consumptionLPer100km,
      startLitres: r.startLitres,
      consumedLitres: consumed + last,
      endLitres: litres - last,
      currencyCode: r.currencyCode,
    );
  }
}
