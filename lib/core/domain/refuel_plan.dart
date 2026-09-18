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

import 'money.dart';

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
    this.nativePrice,
    this.countryCode,
    this.detourKm = 0,
    this.roadExtraKm,
    this.roadExtraMinutes,
  });

  final String stationId;

  /// Distance from the start ALONG the route. The planner needs
  /// positions on a line; the caller projects stations onto the polyline.
  final double alongRouteKm;

  /// Price of the fuel actually being bought, ALREADY EXPRESSED in
  /// [RefuelPlanRequest.currencyCode] (#4361).
  ///
  /// Normalisation happens before planning, in the layer that holds the
  /// rate snapshot, for one reason: a candidate whose price cannot be
  /// converted at a stated, fresh rate must not reach the planner at all
  /// — there is no honest way for an optimiser to rank a number whose
  /// currency it does not know, and "drop it silently" and "convert it at
  /// 1:1" are both wrong. See `refuel_plan_provider.dart`.
  final double pricePerLitre;

  /// The pump price as the country quotes it, kept for display and for
  /// the explanation of a converted total. Null when the caller stated
  /// no currency.
  final Money? nativePrice;

  /// The SELLING country, so a plan can make a border crossing visible
  /// and attribute a coverage or setup caveat to the right side of it.
  final String? countryCode;

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
    this.startLitres = 0,
    this.consumedLitres = 0,
    this.endLitres = 0,
    this.currencyCode,
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
        approximateDetourKm = 0,
        startLitres = 0,
        consumedLitres = 0,
        endLitres = 0,
        currencyCode = null;

  final List<PlannedStop> stops;

  /// The one currency every figure in this plan is denominated in
  /// (#4361). Null only when the caller stated none.
  final String? currencyCode;

  /// Cash paid at the pumps — every purchased litre counted once,
  /// including the litres the detours burn (#4360).
  final double fuelCost;

  /// The tank at the start of the route.
  final double startLitres;

  /// Fuel burned over the whole journey: the route, every access leg and
  /// every rejoin leg. Non-zero even for a plan with no stop (#4360
  /// fixture C) — zero pump spend is not zero consumption.
  final double consumedLitres;

  /// The tank at the destination: `start + bought − consumed`. Two plans
  /// that end with different amounts are not comparable on cash alone —
  /// see [RefuelPlanSet.comparableCost].
  final double endLitres;

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

  /// Litres the detours burn — already inside [consumedLitres] and paid
  /// for inside [fuelCost]. An explanation, never a second charge.
  double get detourLitres => detourKm * consumptionLPer100km / 100;

  /// Litres bought across all stops.
  double get litresBought => stops.fold<double>(0, (s, x) => s + x.litres);

  /// Cash at the pumps (#4360). It used to add a separately valued
  /// detour cost on top — which, once the detour fuel is conserved in
  /// the tank and bought at a pump, counted those litres twice.
  double get totalCost => fuelCost;

  /// [totalCost] with its currency attached — the form a surface may
  /// render or compare (#4361). Null when no currency was stated.
  Money? get totalMoney {
    final code = currencyCode;
    return code == null ? null : Money(totalCost, code);
  }

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

  /// Pump cash per kilometre of the ROUTE (#4360 rule 8).
  ///
  /// The denominator is the journey both plans share, never the plan's
  /// own detour kilometres — dividing by a longer drive would reward
  /// driving further. On that common denominator it orders plans exactly
  /// as the totals do, so it is a unit conversion, not a third optimum.
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
    this.currencyCode,
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

  /// The currency every [PlanCandidate.pricePerLitre] is already
  /// expressed in (#4361). Null for a caller that states none.
  final String? currencyCode;

  /// Whether the arithmetic can run at all.
  ///
  /// No consumption and no capacity are BOTH hard stops, not defaults:
  /// range is the entire constraint this feature exists to respect, and
  /// guessing it would silently invent the answer (spec §4.1).
  bool get isComputable =>
      [routeKm, drivingMinutes, tankCapacityL, startLitres,
        consumptionLPer100km, reserveLitres].every((v) => v.isFinite) &&
      candidates.every((c) =>
          c.alongRouteKm.isFinite &&
          c.alongRouteKm >= 0 &&
          c.pricePerLitre.isFinite &&
          c.pricePerLitre > 0 &&
          c.extraKm.isFinite &&
          c.extraKm >= 0) &&
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
  const RefuelPlanSet({
    this.cheapest,
    this.fastest,
    this.gap,
    this.reserveLitres = kDefaultReserveLitres,
    this.valuationPricePerLitre,
    this.currencyCode,
  });

  /// Minimum total money.
  final RefuelPlan? cheapest;

  /// Minimum total time — fewest stops, smallest detours.
  final RefuelPlan? fastest;

  /// Set when the route cannot be driven at all; then both plans are null.
  final RefuelPlanGap? gap;

  bool get isFeasible => gap == null;

  /// The reserve both plans are compared at — the common target terminal
  /// fuel state (#4360 rule 3).
  final double reserveLitres;

  /// The ONE price every plan's leftover fuel is valued at: the lowest
  /// pump price among this route's candidates. Documented, common, and
  /// conservative — surplus fuel is credited at the least it could have
  /// been bought for on this journey, never at what a plan happened to
  /// pay. Null when there were no candidates.
  final double? valuationPricePerLitre;

  /// The currency [valuationPricePerLitre] and every plan total are in
  /// (#4361).
  final String? currencyCode;

  /// [plan]'s pump cash with its fuel above the reserve at the destination
  /// valued back at [valuationPricePerLitre] — the figure two plans with
  /// different terminal inventories CAN be compared on (#4360 fixture
  /// B: €4 ending at 5 L and €80 ending at 43 L are both €4 here).
  ///
  /// Null without a valuation basis: then only equal end states compare.
  double? comparableCost(RefuelPlan plan) {
    final basis = valuationPricePerLitre;
    if (basis == null) return null;
    return plan.fuelCost - (plan.endLitres - reserveLitres) * basis;
  }

  /// [comparableCost] with its currency attached (#4361).
  Money? comparableMoney(RefuelPlan plan) {
    final code = currencyCode;
    final value = comparableCost(plan);
    return code == null || value == null ? null : Money(value, code);
  }
}
