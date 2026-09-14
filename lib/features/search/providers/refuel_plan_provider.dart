// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/refuel_plan.dart';
import '../../../core/domain/refuel_planner.dart';
import '../../../core/domain/refuel_profile_provider.dart';
import '../../../core/domain/search_result_item.dart';
import '../../../core/utils/station_extensions.dart';
import '../../../core/domain/tank_state_provider.dart';
import '../../../core/utils/route_projection.dart';
import '../../route_search/api.dart';
import 'search_provider.dart';

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

  final candidates = <PlanCandidate>[];
  for (final item in result.stations) {
    if (item is! FuelStationResult) continue;
    final station = item.station;
    // #2631 — each station is priced by its own country's profile fuel
    // on a cross-border route, exactly as the list and the map do.
    final fuel = fuelForStation(station, result.profileFuelByCountry, fuelType);
    final price = station.priceFor(fuel);
    if (price == null || price <= 0) continue;

    final at = projection.project(station.lat, station.lng);
    candidates.add(PlanCandidate(
      stationId: station.id,
      alongRouteKm: at.alongKm,
      pricePerLitre: price,
      detourKm: at.offRouteKm,
    ));
  }

  if (candidates.isEmpty) {
    return const RefuelPlanState.blocked(RefuelPlanBlocker.noPricedStations);
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
  )));
});
