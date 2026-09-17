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
/// The algorithm that fills these in lives in `refuel_planner.dart`.
library;

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
    this.roadExtraKm,
    this.roadExtraMinutes,
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

  /// The routed extra of leaving the journey for this station and
  /// rejoining it (#4359): origin → station → destination minus origin →
  /// destination, both under the same constraints. When present it
  /// replaces the approximate `2 × detourKm` (a distance to the nearest
  /// sampled route vertex, not an exit/rejoin itinerary).
  final double? roadExtraKm;

  /// The routed extra DRIVING minutes, stop overhead excluded. Null when
  /// unknown — the plan then states its detour time as approximate.
  final double? roadExtraMinutes;

  /// Extra kilometres a stop here adds: routed when known, else the
  /// approximate out-and-back deviation.
  double get extraKm => roadExtraKm ?? detourKm * 2;
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
    this.roadDetourMinutes = 0,
    this.approximateDetourKm = 0,
  });

  /// Infeasible: the driver cannot cross [gap] on a full tank.
  const RefuelPlan.infeasible(RefuelPlanGap this.gap)
      : stops = const [],
        fuelCost = 0,
        detourKm = 0,
        routeKm = 0,
        drivingMinutes = 0,
        consumptionLPer100km = 0,
        roadDetourMinutes = 0,
        approximateDetourKm = 0;

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

  /// Routed extra driving minutes of the stops that have them (#4359).
  final double roadDetourMinutes;

  /// Detour kilometres with NO routed duration — timed at the route's
  /// average speed, an approximation the UI must present as one.
  final double approximateDetourKm;

  /// Whether any stop's detour time is approximate rather than routed.
  bool get detourTimeIsApproximate => approximateDetourKm > 0;

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
    // #4359 — routed stops contribute their own routed minutes. Only the
    // remainder is timed at the route's average speed, which off the
    // motorway UNDER-estimates a local-road detour; it is flagged by
    // [detourTimeIsApproximate] rather than passed off as routed.
    if (routeKm <= 0 || approximateDetourKm <= 0) return roadDetourMinutes;
    return roadDetourMinutes + approximateDetourKm * (drivingMinutes / routeKm);
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
