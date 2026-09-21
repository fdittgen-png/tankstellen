// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// The real per-vehicle planning inputs behind the #4367 same-trip
/// comparison (Epic #4358 work package H).
///
/// `comparedVehicleBasesProvider` is declared in core so the planning
/// side can compare vehicles without importing this feature; this is
/// the implementation it is overridden with at the composition root,
/// exactly as `realTankStateProvider` and `realRefuelProfileProvider`
/// already are (#4089/#4146).
///
/// ## Everything is read PER VEHICLE, by id
///
/// The selection is #4365's — the same notifier, the same normalised
/// [VehicleComparisonKey], so picking A then B and B then A is one
/// question. Each column's capacity and current level come from
/// `tankLevelProvider(<that vehicle's id>)` and each column's
/// consumption from that vehicle's own closed fill windows through
/// `vehicleHistoryComparisonProvider`. `activeVehicleProfileProvider`
/// is not read here at all, in either direction: comparing cars cannot
/// change which one the driver is driving, and the car being driven
/// has no privileged column.
///
/// ## Provenance survives into the forecast
///
/// A consumption figure arrives as #4364's [ComparableMetric], so its
/// eligibility, its staleness and its uncontrolled-conditions caveat
/// travel with it into the plan. An unavailable figure stays
/// unavailable: there is no fleet average and no catalogue guess
/// standing in for a car with no history, because a silent fallback is
/// exactly how a supposedly measured winner gets manufactured.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

import '../../../core/domain/comparison_eligibility.dart';
import '../../../core/domain/data_value.dart';
import '../../../core/domain/fuel_type.dart';
import '../../../core/domain/vehicle_profile.dart';
import '../../../core/domain/vehicle_trip_providers.dart';
import '../../vehicle/api.dart';
import '../domain/services/vehicle_history_comparison.dart';
import 'tank_level_provider.dart';
import 'vehicle_comparison_provider.dart';

/// The compared vehicles' real planning inputs.
final realComparedVehicleBasesProvider =
    Provider<ComparedVehicleBases>((ref) {
  final selection = ref.watch(vehicleComparisonSelectorProvider);
  if (selection.vehicleIds.isEmpty) return ComparedVehicleBases();

  final vehicles = {
    for (final VehicleProfile v in ref.watch(vehicleProfileListProvider))
      v.id: v,
  };
  // #4365's own result, over the same key: its per-vehicle consumption
  // already carries the evidence rules #4364 laid down, so the forecast
  // inherits them instead of re-deriving a second opinion.
  final history = ref.watch(vehicleHistoryComparisonProvider(selection.key));

  final bases = <VehicleTripBasis>[];
  final missing = <String>[];
  for (final id in selection.vehicleIds) {
    final vehicle = vehicles[id];
    if (vehicle == null) {
      missing.add(id);
      continue;
    }
    final tank = ref.watch(tankLevelProvider(id));
    final consumption = history.columnFor(id)?.consumptionPer100Km;
    final capacity = tank.capacityL ?? vehicle.tankCapacityL;
    final fuel = vehicle.preferredFuelType;
    bases.add(VehicleTripBasis(
      vehicleId: id,
      vehicleName: vehicle.name,
      fuel: (fuel == null || fuel.isEmpty) ? null : FuelType.fromString(fuel),
      capacityL: capacity,
      // A level is only known once a fill has anchored it; capacity
      // alone says nothing about what is in the tank right now.
      startLitres: tank.lastFillUpDate == null ? null : tank.levelL,
      consumptionLPer100km: consumption?.valueOrNull,
      consumptionSource: _sourceOf(consumption),
      levelSource: tank.lastFillUpDate == null
          ? TripInputSource.unknown
          : TripInputSource.measured,
      qualifications: consumption?.qualifications ?? const {},
    ));
  }

  return ComparedVehicleBases(
    key: selection.key,
    bases: bases,
    referenceVehicleId: selection.effectiveReferenceId,
    missingVehicleIds: missing,
  );
});

/// How a consumption figure was arrived at, carried into the forecast.
TripInputSource _sourceOf(ComparableMetric<double>? metric) {
  final figure = metric?.figure;
  return switch (figure) {
    Measured<double>() => TripInputSource.measured,
    // A measurement too old to present as current is still a
    // measurement; the staleness rides along in the qualifications.
    Stale<double>() => TripInputSource.measured,
    Estimated<double>() => TripInputSource.estimated,
    Unknown<double>() || null => TripInputSource.unknown,
  };
}

/// Wires [realComparedVehicleBasesProvider] into the core declaration.
/// Added to the composition root's override list, the one place allowed
/// to know both sides.
List<Override> vehicleTripBasisOverrides() => [
      comparedVehicleBasesProvider
          .overrideWith((ref) => ref.watch(realComparedVehicleBasesProvider)),
    ];
