// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// The same journey, planned once per selected vehicle (#4367, Epic
/// #4358 work package H).
///
/// ## One journey, several vehicles, one planner
///
/// The route, its duration, the comparison currency, the driver's
/// extra-km/minute limits and the selected objective are assembled ONCE
/// into a [VehicleTripJourney] and handed to every column unchanged. The
/// per-vehicle half — the compatible fuel, the capacity, the current
/// level, the reserve and the consumption evidence — arrives through
/// `comparedVehicleBasesProvider`, the core seam `fill_ups` overrides,
/// so this file never reads a fill window and never reads the ACTIVE
/// vehicle at all.
///
/// Every column's numbers come from `RefuelPlanner.plan` over a request
/// built by `tripPlanRequestFor` — the same function
/// `refuelPlanProvider` uses for the single-vehicle case. That is what
/// makes the two surfaces agree by construction rather than by
/// coincidence.
///
/// ## Why the candidate set is built per vehicle
///
/// A station that does not sell a car's fuel is not a stop for that
/// car, and on a cross-border route each side prices a different grade.
/// So `buildPlanCandidates` runs once per vehicle with ITS fuel, and
/// the currency normalisation, the reference-price gate and the ignored
/// stations are applied per vehicle too. One vehicle may therefore need
/// a bridge fill where another reaches the cheaper station — which is
/// the difference the comparison exists to make concrete.
///
/// ## A late road quote cannot land on a newer selection
///
/// The road quotes go through the one #4359 seam, whose family key is
/// the context AND the exact stop list. Changing the selection changes
/// the stop union, so it is a different request: the previous one's
/// answer resolves into an auto-disposed provider nothing watches, and
/// `actionableTravelEstimate` additionally fences every estimate on its
/// own context key. The comparison itself is keyed on
/// [VehicleTripComparisonKey], so a result for a superseded selection
/// cannot be mistaken for the current one either.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/exchange_rate_provider.dart';
import '../../../core/domain/travel_estimate.dart';
import '../../../core/domain/vehicle_trip_comparison_builder.dart';
import '../../../core/domain/vehicle_trip_providers.dart';
import '../../../core/time/app_clock.dart';
import '../../../core/utils/route_projection.dart';
import '../../route_search/api.dart';
import 'ignored_stations_provider.dart';
import 'refuel_plan_candidates.dart';
import 'search_provider.dart';
import 'station_travel_estimates_provider.dart';

/// Why there is no same-trip comparison to show.
enum VehicleTripComparisonBlocker {
  /// No active route: there is no journey to compare over.
  noRoute,

  /// Fewer than two vehicles selected.
  notEnoughVehicles,
}

/// The comparison, or the reason there is none.
@immutable
class VehicleTripComparisonState {
  const VehicleTripComparisonState.ready(
    VehicleTripComparison this.comparison, {
    this.stationNames = const {},
    this.candidatesByVehicle = const {},
    this.quotesPending = false,
  }) : blocker = null;

  const VehicleTripComparisonState.blocked(
    VehicleTripComparisonBlocker this.blocker,
  )   : comparison = null,
        stationNames = const {},
        candidatesByVehicle = const {},
        quotesPending = false;

  final VehicleTripComparison? comparison;
  final VehicleTripComparisonBlocker? blocker;

  /// Station id → display name, so a plan can name its stops (#4363).
  final Map<String, String> stationNames;

  /// Each vehicle's allowed stops and what was excluded from them —
  /// carried so "apply this plan" can go through the existing route
  /// boundary with the right vehicle's set.
  final Map<String, PlanCandidateSet> candidatesByVehicle;

  /// True while a road quote is still in flight: the distances on
  /// screen are the explicitly approximate ones meanwhile.
  final bool quotesPending;

  bool get isReady => comparison != null;
}

/// Plan the active route once per compared vehicle.
final vehicleTripComparisonProvider =
    Provider<VehicleTripComparisonState>((ref) {
  final bases = ref.watch(comparedVehicleBasesProvider);
  if (!bases.isComparable) {
    return const VehicleTripComparisonState.blocked(
        VehicleTripComparisonBlocker.notEnoughVehicles);
  }

  final result = ref.watch(routeSearchStateProvider).value;
  final geometry = result?.route.geometry ?? const [];
  if (result == null || geometry.isEmpty) {
    return const VehicleTripComparisonState.blocked(
        VehicleTripComparisonBlocker.noRoute);
  }

  final now = ref.watch(appClockProvider).now();
  final currency = ref.watch(comparisonCurrencyProvider);
  final rates = ref.watch(exchangeRatesProvider);
  final ignored = ref.watch(ignoredStationsProvider).toSet();
  final fallbackFuel = ref.watch(selectedFuelTypeProvider);
  final projection = RouteProjection(geometry);
  final assumptions = ref.watch(vehicleTripAssumptionsProvider);

  final journey = VehicleTripJourney(
    // The polyline's own length, not the router's reported distance:
    // stop positions and the total must come from one measurement.
    routeKm: projection.totalKm,
    drivingMinutes: result.route.durationMinutes,
    currencyCode: currency,
    departAt: now,
    objective: ref.watch(vehicleTripObjectiveProvider),
    routeRevision: Object.hash(geometry.length, result.route.distanceKm),
  );

  // One candidate set per vehicle, from ITS fuel. Hard exclusions are
  // applied here and recorded; soft display filters never reach this
  // far (#4362).
  final sets = <String, PlanCandidateSet>{
    for (final basis in bases.bases)
      basis.vehicleId: buildPlanCandidates(
        stations: result.stations,
        profileFuelByCountry: result.profileFuelByCountry,
        fuelType: basis.fuel ?? fallbackFuel,
        projection: projection,
        ignoredStationIds: ignored,
        currency: currency,
        rates: rates,
        now: now,
      ),
  };

  // ONE road-quote request for the union of every column's stops, in
  // nearest-to-route order: the columns share a journey, so they may
  // share the #4359 budget too. A changed selection changes this stop
  // list, which makes it a different request and strands the old
  // answer in a provider nothing watches.
  final seen = <String>{};
  final union = <TravelStop>[
    for (final set in sets.values)
      for (final stop in set.travelStops)
        if (seen.add(stop.id)) stop,
  ];
  final context = TravelContext(
    origin: TravelPoint(geometry.first.latitude, geometry.first.longitude),
    destination: TravelPoint(geometry.last.latitude, geometry.last.longitude),
    purpose: TravelPurpose.stopOnJourney,
    routeRevision: journey.routeRevision,
  );
  final request = TravelQuoteRequest.budgeted(context, union);
  final estimates = ref.watch(stationTravelEstimatesProvider(request));

  final inputs = <VehicleTripInput>[
    for (final basis in bases.bases)
      VehicleTripInput(
        basis: basis
            .withAssumption(assumptions[basis.vehicleId] ??
                VehicleTripAssumption.none),
        candidates: withRoadEstimates(
          sets[basis.vehicleId]!.candidates,
          (id) => actionableTravelEstimate(estimates, request, id, now),
        ),
        evidenceIncomplete: sets[basis.vehicleId]!.coverageIncomplete ||
            sets[basis.vehicleId]!
                .exclusions
                .values
                .contains(PlanCandidateExclusion.ignoredByUser),
        excludedForCurrency: sets[basis.vehicleId]!.excludedForCurrency,
      ),
  ];

  final key = VehicleTripComparisonKey(
    vehicles: bases.key,
    journey: journey,
    basisSignature: [for (final i in inputs) i.basis.signature].join('+'),
  );

  return VehicleTripComparisonState.ready(
    buildVehicleTripComparison(
      key: key,
      asOf: now,
      inputs: inputs,
      referenceVehicleId: bases.referenceVehicleId,
      missingVehicleIds: bases.missingVehicleIds,
    ),
    stationNames: {
      for (final set in sets.values) ...set.stationNames,
    },
    candidatesByVehicle: sets,
    quotesPending: estimates.isLoading,
  );
});
