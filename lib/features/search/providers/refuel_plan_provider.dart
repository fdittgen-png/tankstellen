// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/country/country_config.dart';
import '../../../core/domain/exchange_rate_provider.dart';
import '../../../core/domain/money.dart';
import '../../../core/domain/refuel_plan.dart';
import '../../../core/domain/refuel_planner.dart';
import '../../../core/domain/refuel_profile_provider.dart';
import '../../../core/domain/search_result_item.dart';
import '../../../core/domain/station.dart';
import '../../../core/domain/travel_estimate.dart';
import '../../../core/services/station_offer.dart';
import '../../../core/time/app_clock.dart';
import '../../../core/utils/station_extensions.dart';
import '../../../core/domain/tank_state_provider.dart';
import '../../../core/utils/route_projection.dart';
import '../../route_search/api.dart';
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

/// A plan, or the reason there is none.
class RefuelPlanState {
  const RefuelPlanState.ready(this.plans) : blocker = null;
  const RefuelPlanState.blocked(this.blocker) : plans = null;

  final RefuelPlanSet? plans;
  final RefuelPlanBlocker? blocker;

  bool get isReady => plans != null;
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
  final priced = <({
    Station station,
    double price,
    Money? native,
    String? country,
    double along,
    double off,
  })>[];
  var currencyBlocked = false;
  for (final item in result.stations) {
    if (item is! FuelStationResult) continue;
    final station = item.station;
    // #4348 — a reference price is not a stop anyone can make.
    final offer = StationOffer.forStation(
        stationId: station.id, lat: station.lat, lng: station.lng);
    if (!offer.canRouteTo) continue;
    // #2631 — each station is priced by its own country's profile fuel
    // on a cross-border route, exactly as the list and the map do.
    final fuel = fuelForStation(station, result.profileFuelByCountry, fuelType);
    final price = station.priceFor(fuel);
    if (price == null || price <= 0) continue;

    // #4361 — normalise BEFORE planning. A price that cannot be stated
    // in the plan's currency is excluded with a reason, never converted
    // at an assumed rate and never compared as a bare number.
    final code = offer.countryCode == null
        ? null
        : Countries.byCode(offer.countryCode!)?.currency;
    final native = code == null ? null : Money(price, code);
    final double normalised;
    if (native == null || code == currency) {
      normalised = price;
    } else {
      final converted = rates.convert(native, currency, now).converted;
      if (converted == null) {
        currencyBlocked = true;
        continue;
      }
      normalised = converted.amount;
    }

    final at = projection.project(station.lat, station.lng);
    priced.add((
      station: station,
      price: normalised,
      native: native,
      country: offer.countryCode,
      along: at.alongKm,
      off: at.offRouteKm,
    ));
  }

  // #4359 — the exit/rejoin cost of each stop, routed as origin → station
  // → destination against origin → destination in ONE budgeted request,
  // nearest-to-route first. A current road quote replaces the projection
  // (the crow-flies gap to the nearest sampled vertex); anything else
  // keeps the projection, and the plan says its detour time is
  // approximate.
  final context = TravelContext(
    origin: TravelPoint(geometry.first.latitude, geometry.first.longitude),
    destination: TravelPoint(geometry.last.latitude, geometry.last.longitude),
    purpose: TravelPurpose.stopOnJourney,
    // A recomputed route with the same endpoints is still a new journey.
    routeRevision: Object.hash(geometry.length, result.route.distanceKm),
  );
  final request = TravelQuoteRequest.budgeted(context, [
    for (final p in [...priced]..sort((a, b) => a.off.compareTo(b.off)))
      (id: p.station.id, lat: p.station.lat, lng: p.station.lng),
  ]);
  final estimates = ref.watch(stationTravelEstimatesProvider(request));

  final candidates = <PlanCandidate>[
    for (final p in priced)
      if (actionableTravelEstimate(estimates, request, p.station.id, now)
          case final road?)
        PlanCandidate(
          stationId: p.station.id,
          alongRouteKm: p.along,
          pricePerLitre: p.price,
          nativePrice: p.native,
          countryCode: p.country,
          detourKm: p.off,
          roadExtraKm: road.extraKm,
          roadExtraMinutes: road.extraDrivingMinutes,
        )
      else
        PlanCandidate(
          stationId: p.station.id,
          alongRouteKm: p.along,
          pricePerLitre: p.price,
          nativePrice: p.native,
          countryCode: p.country,
          detourKm: p.off,
        ),
  ];

  if (candidates.isEmpty) {
    return RefuelPlanState.blocked(currencyBlocked
        ? RefuelPlanBlocker.noComparableCurrency
        : RefuelPlanBlocker.noPricedStations);
  }

  return RefuelPlanState.ready(RefuelPlanner.plan(RefuelPlanRequest(
    // The polyline's own length, not the routing service's reported
    // distance: positions and total must come from one measurement or a
    // stop can land past the end of the route.
    routeKm: projection.totalKm,
    drivingMinutes: result.route.durationMinutes,
    tankCapacityL: tank.capacityL!,
    startLitres: startLitres,
    consumptionLPer100km: consumption,
    candidates: candidates,
    currencyCode: currency,
  )));
});
