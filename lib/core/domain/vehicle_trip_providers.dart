// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// The seams the same-trip vehicle comparison is assembled from
/// (#4367, Epic #4358 work package H).
///
/// ## Why the bases are DECLARED here and implemented elsewhere
///
/// Planning lives in `features/search` (it needs the route and its
/// stations); the compared vehicles, their tanks and their consumption
/// evidence live in `features/fill_ups` (it owns the fill windows and
/// the level-v2 estimate, and it is where #4365's selection notifier
/// already is). Neither feature may import the other.
///
/// So the dependency is inverted exactly as `refuelProfileProvider` and
/// `tankStateProvider` already are: this file declares the contract
/// against core types, defaults to "nothing selected", and the
/// composition root overrides it with the real implementation through
/// `vehicleTripBasisOverrides()`. Search depends on core; fill_ups
/// supplies the value; neither knows about the other.
///
/// The default is deliberately empty rather than "the active vehicle":
/// a comparison surface that silently compares the car you are driving
/// with itself would be a wrong answer instead of an absent one.
///
/// ## The assumptions live here too
///
/// A typed consumption or tank level is a per-vehicle override the
/// PLANNING side reads and the fill-up side never sees, so it belongs
/// in core beside the seam. [VehicleTripAssumptions] changes exactly
/// one vehicle's entry at a time — which is what makes "changing a
/// vehicle's consumption assumption updates only its calculation"
/// checkable.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'refuel_plan.dart';
import 'vehicle_comparison_key.dart';
import 'vehicle_trip_basis.dart';

export 'vehicle_trip_basis.dart';

/// The compared vehicles' planning inputs, in the driver's selection
/// order, with the #4365 key that identifies the selection.
@immutable
class ComparedVehicleBases {
  ComparedVehicleBases({
    VehicleComparisonKey? key,
    List<VehicleTripBasis> bases = const [],
    this.referenceVehicleId,
    Iterable<String> missingVehicleIds = const [],
  })  : key = key ?? VehicleComparisonKey(vehicleIds: const []),
        bases = List.unmodifiable(bases),
        missingVehicleIds = List.unmodifiable(missingVehicleIds);

  /// #4365's normalised identity of the selection — deduped and sorted,
  /// so picking A then B and B then A is one question.
  final VehicleComparisonKey key;

  /// One per selected vehicle, in DISPLAY order.
  final List<VehicleTripBasis> bases;

  /// The column deltas are measured against.
  final String? referenceVehicleId;

  /// Selected ids whose vehicle profile is gone. Kept so the selection
  /// stays recoverable rather than silently shrinking.
  final List<String> missingVehicleIds;

  bool get isComparable => bases.length >= 2;

  /// Every field a forecast depends on, so a changed basis is a changed
  /// cache key.
  String get signature => [for (final b in bases) b.signature].join('+');
}

/// Declared in core so the planning side can compare vehicles without
/// importing `fill_ups`; overridden at the composition root with the
/// real implementation.
final comparedVehicleBasesProvider = Provider<ComparedVehicleBases>(
  (ref) => ComparedVehicleBases(),
);

/// The driver's own per-vehicle planning overrides.
///
/// Keyed by vehicle id. Setting one vehicle's consumption rebuilds that
/// vehicle's plan and then the comparison; the other columns' inputs
/// are untouched, because their map entries are untouched.
class VehicleTripAssumptions extends Notifier<Map<String, VehicleTripAssumption>> {
  @override
  Map<String, VehicleTripAssumption> build() => const {};

  VehicleTripAssumption forVehicle(String vehicleId) =>
      state[vehicleId] ?? VehicleTripAssumption.none;

  /// Replace [vehicleId]'s consumption assumption. A null value clears
  /// it and the measured evidence takes over again.
  void setConsumption(String vehicleId, double? lPer100km) => _update(
      vehicleId,
      (a) => VehicleTripAssumption(
            consumptionLPer100km: lPer100km,
            startLitres: a.startLitres,
            reserveLitres: a.reserveLitres,
          ));

  void setStartLitres(String vehicleId, double? litres) => _update(
      vehicleId,
      (a) => VehicleTripAssumption(
            consumptionLPer100km: a.consumptionLPer100km,
            startLitres: litres,
            reserveLitres: a.reserveLitres,
          ));

  void setReserveLitres(String vehicleId, double? litres) => _update(
      vehicleId,
      (a) => VehicleTripAssumption(
            consumptionLPer100km: a.consumptionLPer100km,
            startLitres: a.startLitres,
            reserveLitres: litres,
          ));

  /// Forget every override for [vehicleId].
  void clear(String vehicleId) {
    if (!state.containsKey(vehicleId)) return;
    state = {
      for (final e in state.entries)
        if (e.key != vehicleId) e.key: e.value,
    };
  }

  void _update(
    String vehicleId,
    VehicleTripAssumption Function(VehicleTripAssumption) change,
  ) {
    final next = change(forVehicle(vehicleId));
    if (next.isEmpty) {
      clear(vehicleId);
      return;
    }
    state = {...state, vehicleId: next};
  }
}

final vehicleTripAssumptionsProvider = NotifierProvider<VehicleTripAssumptions,
    Map<String, VehicleTripAssumption>>(VehicleTripAssumptions.new);

/// Which objective the comparison columns are reported on.
///
/// One choice for the whole comparison, never one per vehicle: columns
/// answering different questions are not a comparison.
class VehicleTripObjective extends Notifier<RefuelObjective> {
  @override
  RefuelObjective build() => RefuelObjective.lowestCost;

  void select(RefuelObjective objective) => state = objective;
}

final vehicleTripObjectiveProvider =
    NotifierProvider<VehicleTripObjective, RefuelObjective>(
        VehicleTripObjective.new);
