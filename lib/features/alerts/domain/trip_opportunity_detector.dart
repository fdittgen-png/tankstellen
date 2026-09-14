// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Trip- and tank-aware opportunities (#4153, epic #4148).
///
/// The alert a driver actually wants is not "a station is cheap". It is
/// *"best fuel stop in 18 km — save about €3.80"*, and the one that
/// prevents a pointless interruption is the silence when 280 km of range
/// covers the 40 km left to go.
///
/// **Assembly, not analytics.** `RefuelPlanner` (#4146) already answers
/// the hard parts — whether the trip needs a stop, where, how much to
/// buy, and whether the route is feasible at all. Nothing here
/// recomputes range or re-derives a stop; it plans once and reports what
/// the plan says.
///
/// Pure over primitives and the clock is a parameter, so the whole thing
/// runs in the background isolate it will actually execute in.
library;

import 'package:meta/meta.dart';

import '../../../core/domain/data_value.dart';
import '../../../core/domain/refuel_plan.dart';
import '../../../core/domain/refuel_planner.dart';
import '../../../core/services/provider_capability.dart';
import 'opportunity.dart';
import 'opportunity_detectors.dart';

/// Why no trip opportunity could be produced.
///
/// Named so the in-app surface can say what is missing, which is the
/// acceptance criterion: "no tank level or no consumption → no fire,
/// with the reason available".
enum TripOpportunityBlocker {
  /// Not driving anywhere. Speculating about a route the user is not on
  /// is how an app becomes noise.
  noTrip,

  /// The tank level is unknown. NOT "the tank is empty" — the whole
  /// point of the distinction, see [TripContext.tankLitres].
  noTankLevel,

  /// No measured consumption, so range cannot be derived.
  noConsumption,

  /// No tank capacity on the vehicle.
  noTankCapacity,

  /// No station ahead has a price for the fuel being burned.
  noPricedStations,

  /// The trip needs no stop. This is a blocker in the sense that
  /// nothing fires — and it is the CORRECT output, not a failure.
  noStopNeeded,

  /// A stop is needed but it is not close enough yet to be worth
  /// interrupting for. See [leadDistanceKm].
  tooEarlyToSay,
}

/// How many minutes of driving ahead of a stop the driver wants to know.
///
/// Eight minutes. An alert about a stop 18 km ahead is useful at 20 km
/// and useless at 2 km, and the distance that buys eight minutes depends
/// entirely on speed: 16 km on a motorway, under 7 km in town. A fixed
/// distance would be early in traffic and late at 130 km/h, which is the
/// one direction that matters.
const int kStopLeadMinutes = 8;

/// Floor and ceiling on the lead distance.
///
/// The floor keeps a crawling driver from being told about a stop they
/// have already passed; the ceiling keeps a motorway driver from being
/// warned about something twenty minutes away that a cheaper station may
/// yet precede.
const double kMinStopLeadKm = 3;
const double kMaxStopLeadKm = 25;

/// Everything the detectors need about the drive in progress.
@immutable
class TripContext {
  const TripContext({
    required this.remainingRouteKm,
    required this.remainingMinutes,
    required this.tankLitres,
    required this.candidatesAhead,
    this.tankCapacityL,
    this.consumptionLPer100km,
    this.speedKmh,
  });

  /// Distance still to drive.
  final double remainingRouteKm;

  /// Time still to drive, as the route service estimated it.
  final double remainingMinutes;

  /// How much fuel is in the tank, and how well that is known.
  ///
  /// A `DataValue`, and this is the third place in this epic where the
  /// distinction decides correctness. "We do not know how full the tank
  /// is" and "the tank is nearly empty" are opposite claims, and a
  /// `double?` reading null as zero would turn the first into the second
  /// — an alert telling a driver with a full tank to refuel immediately.
  /// Unknown BLOCKS here rather than standing a gate down, because
  /// "you need fuel" is a claim, not a guess.
  final DataValue<double> tankLitres;

  /// Stations ahead on the route, already projected onto the polyline.
  final List<PlanCandidate> candidatesAhead;

  final double? tankCapacityL;
  final double? consumptionLPer100km;

  /// Current speed, for the lead distance. Null falls back to the
  /// route's own average.
  final double? speedKmh;

  /// How far ahead a stop must be to be worth saying now.
  double get leadDistanceKm {
    final speed = speedKmh ??
        (remainingMinutes > 0
            ? remainingRouteKm / (remainingMinutes / 60)
            : 0);
    final raw = speed * kStopLeadMinutes / 60;
    return raw.clamp(kMinStopLeadKm, kMaxStopLeadKm);
  }
}

/// What one evaluation produced.
@immutable
class TripOpportunityResult {
  const TripOpportunityResult.blocked(TripOpportunityBlocker this.blocker)
      : opportunity = null,
        plans = null;

  const TripOpportunityResult.found(
    Opportunity this.opportunity,
    RefuelPlanSet this.plans,
  ) : blocker = null;

  /// Why nothing fired, or null when something did.
  final TripOpportunityBlocker? blocker;

  /// The one opportunity worth raising, or null.
  final Opportunity? opportunity;

  /// The plan it came from, so a surface can show the stops behind the
  /// claim rather than asking the user to take it on faith.
  final RefuelPlanSet? plans;
}

/// The trip detectors. One entry point, no state.
abstract final class TripOpportunityDetector {
  /// Evaluate [trip] once.
  ///
  /// Produces at most ONE opportunity. Which one it is follows from the
  /// plan rather than from a preference: an unreachable next station is
  /// the most urgent thing the app can say, a needed stop is next, and a
  /// cheaper stop further along only matters once a stop is happening
  /// anyway.
  static TripOpportunityResult detect({
    required TripContext trip,
    required DataValue<Duration> priceAge,
    required DataConfidence confidence,
    required DateTime now,
  }) {
    if (trip.remainingRouteKm <= 0) {
      return const TripOpportunityResult.blocked(TripOpportunityBlocker.noTrip);
    }
    final litres = trip.tankLitres;
    if (litres is! Measured<double>) {
      return const TripOpportunityResult.blocked(
          TripOpportunityBlocker.noTankLevel);
    }
    final capacity = trip.tankCapacityL;
    if (capacity == null || capacity <= 0) {
      return const TripOpportunityResult.blocked(
          TripOpportunityBlocker.noTankCapacity);
    }
    final consumption = trip.consumptionLPer100km;
    if (consumption == null || consumption <= 0) {
      return const TripOpportunityResult.blocked(
          TripOpportunityBlocker.noConsumption);
    }
    if (trip.candidatesAhead.isEmpty) {
      return const TripOpportunityResult.blocked(
          TripOpportunityBlocker.noPricedStations);
    }

    final plans = RefuelPlanner.plan(RefuelPlanRequest(
      routeKm: trip.remainingRouteKm,
      drivingMinutes: trip.remainingMinutes,
      tankCapacityL: capacity,
      startLitres: litres.value,
      consumptionLPer100km: consumption,
      candidates: trip.candidatesAhead,
    ));

    // An unreachable next station is the one thing worth interrupting
    // for regardless of price: the driver runs dry otherwise.
    final gap = plans.gap;
    if (gap != null) {
      return TripOpportunityResult.found(
        _refuelSoon(trip, plans, null, priceAge, confidence, now,
            atKm: gap.fromKm),
        plans,
      );
    }

    final cheapest = plans.cheapest;
    if (cheapest == null || cheapest.stops.isEmpty) {
      // The tank covers the trip. Silence is the correct output — an
      // alert saying "no action needed" is an interruption that says
      // nothing.
      return const TripOpportunityResult.blocked(
          TripOpportunityBlocker.noStopNeeded);
    }

    final first = cheapest.stops.first;
    if (first.candidate.alongRouteKm > trip.leadDistanceKm) {
      return const TripOpportunityResult.blocked(
          TripOpportunityBlocker.tooEarlyToSay);
    }

    // A stop is needed and it is close. Is the CHEAPEST plan's stop a
    // different one from the first station the driver will pass? If so
    // the money is the difference between the two plans, which is
    // reproducible from the stops each one shows.
    final fastest = plans.fastest;
    // The money is the difference between the two plans, decomposed the
    // way trust rule 4 requires: gross at the pumps, detour as the extra
    // driving the cheaper plan asks for.
    //
    // NOT `fastest.totalCost - cheapest.totalCost` as the gross —
    // `totalCost` already includes each plan's own detour cost, so
    // handing that in as `gross` and a detour beside it would subtract
    // the driving twice. Decomposed like this, `net` comes out exactly
    // equal to the difference of the two totals, which is the figure a
    // user could check against the two plans on screen.
    final money = (fastest != null && fastest.totalCost > cheapest.totalCost)
        ? Money(
            gross: fastest.fuelCost - cheapest.fuelCost,
            detour: cheapest.detourCost - fastest.detourCost,
          )
        : null;

    return TripOpportunityResult.found(
      _refuelSoon(trip, plans, money, priceAge, confidence, now,
          atKm: first.candidate.alongRouteKm),
      plans,
    );
  }

  static Opportunity _refuelSoon(
    TripContext trip,
    RefuelPlanSet plans,
    Money? money,
    DataValue<Duration> priceAge,
    DataConfidence confidence,
    DateTime now, {
    required double atKm,
  }) {
    final stop = plans.cheapest?.stops.firstOrNull;
    return Opportunity(
      kind: OpportunityKind.refuelSoon,
      stationId: stop?.candidate.stationId,
      fuelType: '',
      currentPrice: stop?.candidate.pricePerLitre ?? 0,
      reference: OpportunityReference.cheapestOnRoute,
      referencePrice: null,
      grossSaving: money?.gross,
      detourCost: money?.detour,
      netSaving: money?.net,
      // How far ahead the stop is — the number the alert is ABOUT.
      distanceKm: atKm,
      priceAge: priceAge,
      confidence: confidence,
      detectedAt: now,
      // A trip opportunity dies with the trip's own geometry: once the
      // driver has covered the lead distance the advice is either taken
      // or moot, and re-raising it as they close in is the "one decision
      // per opportunity" rule the issue asks for.
      expiresAt: now.add(const Duration(minutes: kStopLeadMinutes)),
    );
  }
}
