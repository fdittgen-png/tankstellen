// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/exchange_rate_provider.dart';
import '../../../core/domain/refuel_plan.dart';
import '../../../core/domain/refuel_planner.dart';
import '../../../core/domain/refuel_profile_provider.dart';
import '../../../core/domain/travel_estimate.dart';
import '../../../core/time/app_clock.dart';
import '../../../core/domain/tank_state_provider.dart';
import '../../../core/domain/vehicle_trip_basis.dart';
import '../../../core/utils/route_projection.dart';
import '../../route_search/api.dart';
import 'ignored_stations_provider.dart';
import 'refuel_plan_candidates.dart';
import 'search_provider.dart';
import 'station_travel_estimates_provider.dart';

/// Why a trip cannot be planned, in terms the UI can explain (#4146).
///
/// Each of these is a MISSING INPUT, never a guess: range is the whole
/// constraint the planner exists to respect, so a default would invent
/// the answer (economics spec §4.1).
enum RefuelPlanBlocker {
  noRoute,
  noConsumption,
  noTankCapacity,
  noTankLevel,
  noPricedStations,

  /// Every priced station on this route quotes a currency the plan
  /// cannot express in the driver's own, at a stated and fresh rate
  /// (#4361). The prices are real and stay on screen; what is missing is
  /// a comparison, and inventing a 1:1 rate would manufacture a winner.
  noComparableCurrency,
}

/// A plan, or the reason there is none — with what was left out of the
/// candidate set and why (#4362).
class RefuelPlanState {
  const RefuelPlanState.ready(this.plans, {this.candidates = PlanCandidateSet.empty})
      : blocker = null;
  const RefuelPlanState.blocked(this.blocker,
      {this.candidates = PlanCandidateSet.empty})
      : plans = null;

  final RefuelPlanSet? plans;
  final RefuelPlanBlocker? blocker;

  /// The allowed stops and the stations excluded from them. A gap is only
  /// as meaningful as the set it was computed over, so the exclusions
  /// travel with the answer rather than being reconstructed by the UI.
  final PlanCandidateSet candidates;

  bool get isReady => plans != null;

  /// True when the evidence behind this answer is partial: a source that
  /// lists only some of its country's stations, or a station the driver
  /// hid. "This candidate graph has a gap" is not "no usable station
  /// exists on the road", and the surface must not conflate them.
  bool get evidenceIncomplete =>
      candidates.coverageIncomplete ||
      candidates.exclusions.values
          .contains(PlanCandidateExclusion.ignoredByUser);
}

/// Plan the active route's refuelling stops.
///
/// Assembles what the app already knows — the route and its stations, the
/// measured consumption (`refuelProfileProvider`), and the tank
/// (`tankStateProvider`) — and hands it to [RefuelPlanner]. Nothing is
/// computed here; this provider's whole job is to say what is missing
/// when something is.
final refuelPlanProvider = Provider<RefuelPlanState>((ref) {
  final result = ref.watch(routeSearchStateProvider).value;
  if (result == null || result.route.geometry.isEmpty) {
    return const RefuelPlanState.blocked(RefuelPlanBlocker.noRoute);
  }

  final profile = ref.watch(refuelProfileProvider);
  final consumption = profile.consumptionLPer100km;
  if (consumption == null || consumption <= 0) {
    return const RefuelPlanState.blocked(RefuelPlanBlocker.noConsumption);
  }

  final tank = ref.watch(tankStateProvider);
  if ((tank.capacityL ?? 0) <= 0) {
    return const RefuelPlanState.blocked(RefuelPlanBlocker.noTankCapacity);
  }
  final startLitres = tank.currentL;
  if (startLitres == null) {
    return const RefuelPlanState.blocked(RefuelPlanBlocker.noTankLevel);
  }

  final fuelType = ref.watch(selectedFuelTypeProvider);
  final projection = RouteProjection(result.route.geometry);
  // #4361 — one currency for the whole plan, reached by a stated rate or
  // not reached at all.
  final currency = ref.watch(comparisonCurrencyProvider);
  final rates = ref.watch(exchangeRatesProvider);
  final now = ref.watch(appClockProvider).now();

  final geometry = result.route.geometry;
  // #4362 — the plan is built from the ROUTE RESULT, never from the
  // filtered, sorted list the view renders. Hard exclusions are applied
  // here and recorded; soft display filters do not reach this far.
  final set = buildPlanCandidates(
    stations: result.stations,
    profileFuelByCountry: result.profileFuelByCountry,
    fuelType: fuelType,
    projection: projection,
    ignoredStationIds: ref.watch(ignoredStationsProvider).toSet(),
    currency: currency,
    rates: rates,
    now: now,
  );

  // #4359 — the exit/rejoin cost of each stop, routed as origin → station
  // → destination against origin → destination in ONE budgeted request,
  // nearest-to-route first.
  final context = TravelContext(
    origin: TravelPoint(geometry.first.latitude, geometry.first.longitude),
    destination: TravelPoint(geometry.last.latitude, geometry.last.longitude),
    purpose: TravelPurpose.stopOnJourney,
    // A recomputed route with the same endpoints is still a new journey.
    routeRevision: Object.hash(geometry.length, result.route.distanceKm),
  );
  final request = TravelQuoteRequest.budgeted(context, set.travelStops);
  final estimates = ref.watch(stationTravelEstimatesProvider(request));

  // #4367 — the request is assembled by the ONE builder the
  // multi-vehicle comparison also uses, so the same inputs cannot give
  // two answers on the two surfaces. The polyline's own length, not the
  // routing service's reported distance: positions and total must come
  // from one measurement or a stop can land past the end of the route.
  final planRequest = tripPlanRequestFor(
    VehicleTripJourney(
      routeKm: projection.totalKm,
      drivingMinutes: result.route.durationMinutes,
      currencyCode: currency,
      departAt: now,
    ),
    VehicleTripBasis(
      vehicleId: '',
      vehicleName: '',
      fuel: fuelType,
      capacityL: tank.capacityL,
      startLitres: startLitres,
      consumptionLPer100km: consumption,
    ),
    withRoadEstimates(
      set.candidates,
      (id) => actionableTravelEstimate(estimates, request, id, now),
    ),
  );
  final plans = planRequest == null
      ? const RefuelPlanSet()
      : RefuelPlanner.plan(planRequest);

  // An empty candidate set is not automatically a blocker: a tank that
  // already covers the journey is a real answer, and #4362 requires it
  // even when no priced station came back at all.
  //
  // Nor is it a GAP. A gap is a claim about the road — "you cannot cross
  // this stretch" — and it may only be made over a candidate set that
  // actually held stations. With none, what is missing is evidence, and
  // the blocker says so instead.
  if (plans.cheapest == null &&
      (set.candidates.isEmpty || plans.gap == null)) {
    return RefuelPlanState.blocked(
      set.excludedForCurrency
          ? RefuelPlanBlocker.noComparableCurrency
          : RefuelPlanBlocker.noPricedStations,
      candidates: set,
    );
  }
  return RefuelPlanState.ready(plans, candidates: set);
});
