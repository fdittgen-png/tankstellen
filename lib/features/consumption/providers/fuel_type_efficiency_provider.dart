// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../vehicle/providers/vehicle_providers.dart';
import '../domain/entities/fuel_type_efficiency_stats.dart';
import '../domain/services/fuel_type_efficiency_aggregator.dart';
import 'consumption_providers.dart';

part 'fuel_type_efficiency_provider.g.dart';

/// Per-fuel-type efficiency comparison for the active vehicle (Epic #2881).
///
/// Watches [fillUpListProvider] + [activeVehicleProfileProvider], filters the
/// fills to the selected vehicle's `vehicleId` (when a vehicle is active;
/// otherwise all fills), and returns
/// `FuelTypeEfficiencyAggregator.byFuelType(...)` — one
/// [FuelTypeEfficiencyStats] per fuel, sorted by €/km ascending.
///
/// Read-only re-slice of data the user already logged: no `FillUpList.add`
/// hook, no storage, no `Feature` gate (mirrors the #2698 no-gate precedent).
/// Lives in its own file (not the line-guarded consumption_providers.dart),
/// parallel to `monthlyFuelStatsProvider`.
@riverpod
List<FuelTypeEfficiencyStats> fuelTypeEfficiencyComparison(Ref ref) {
  final fills = ref.watch(fillUpListProvider);
  final vehicle = ref.watch(activeVehicleProfileProvider);
  final scoped = vehicle == null
      ? fills
      : fills.where((f) => f.vehicleId == vehicle.id).toList(growable: false);
  return FuelTypeEfficiencyAggregator.byFuelType(scoped);
}
