// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../vehicle/providers/vehicle_providers.dart';
import '../domain/entities/fill_up.dart';
import '../domain/entities/fuel_type_efficiency_stats.dart';
import '../domain/services/fill_up_vehicle_scope.dart';
import '../domain/services/fuel_type_efficiency_aggregator.dart';
import 'consumption_providers.dart';

part 'fuel_type_efficiency_provider.g.dart';

/// The fills that belong to the ACTIVE vehicle (#3945).
///
/// Every per-vehicle consumption read (the per-fuel comparison below, the
/// all-prices table's cost model) scopes through this one seam so they can
/// never disagree on whose fill a fill is. The rule lives in
/// [scopeFillUpsToVehicle]: the vehicle's own fills, plus — for a user with
/// exactly ONE vehicle profile — the fills carrying no `vehicleId` (their
/// pre-profile history, which can only be that car's). With two or more
/// profiles an unassigned fill is ambiguous and stays excluded. No active
/// vehicle ⇒ every fill.
@riverpod
List<FillUp> activeVehicleFillUps(Ref ref) {
  final fills = ref.watch(fillUpListProvider);
  final vehicle = ref.watch(activeVehicleProfileProvider);
  if (vehicle == null) return fills;
  return scopeFillUpsToVehicle(
    fills,
    vehicle: vehicle,
    vehicleCount: ref.watch(vehicleProfileListProvider).length,
  );
}

/// Per-fuel-type efficiency comparison for the active vehicle (Epic #2881).
///
/// Watches [activeVehicleFillUpsProvider] (the fill-up list scoped to the
/// selected vehicle — or every fill when none is active) +
/// [activeVehicleProfileProvider], and returns
/// `FuelTypeEfficiencyAggregator.byFuelType(...)` — one
/// [FuelTypeEfficiencyStats] per fuel, sorted by €/km ascending.
///
/// Read-only re-slice of data the user already logged: no `FillUpList.add`
/// hook, no storage, no `Feature` gate (mirrors the #2698 no-gate precedent).
/// Lives in its own file (not the line-guarded consumption_providers.dart),
/// parallel to `monthlyFuelStatsProvider`.
@riverpod
List<FuelTypeEfficiencyStats> fuelTypeEfficiencyComparison(Ref ref) {
  final scoped = ref.watch(activeVehicleFillUpsProvider);
  final vehicle = ref.watch(activeVehicleProfileProvider);
  // #3764 v3 — the vehicle's tank capacity (user-set, or backfilled from
  // the reference catalog by the vehicle editor) unlocks the carried-content
  // composition: each interval opening on a plein is classified including
  // the full tank's estimated mix at that fill. Null capacity (or no active
  // vehicle — capacity would be ambiguous across vehicles) keeps the v2
  // contributing-fills behaviour.
  return FuelTypeEfficiencyAggregator.byFuelType(
    scoped,
    tankCapacityL: vehicle?.tankCapacityL,
  );
}
