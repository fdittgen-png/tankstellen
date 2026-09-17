// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/domain/fuel/fuel_grade.dart';
import '../../vehicle/api.dart';
import '../domain/services/tank_mix_view.dart';
import '../domain/services/vehicle_fuel_capability_policy.dart';
import 'consumption_providers.dart';
import 'tank_blend_provider.dart';

part 'tank_mix_provider.g.dart';

/// Fuel mix of the current tank content for [vehicleId] (#3652), read from
/// the one mix model the app has: the evidence-only tank blend (#4322).
///
/// It is [tankBlendProvider] reduced to the [TankMixView] the Fuel & Tank
/// surface renders, so a mix line anywhere else (the tank level card) can
/// never disagree with that surface — guaranteed minimums, the unknown
/// share said out loud. The grades this vehicle was filled with or is
/// approved for bound [TankMixView.plausibleMaxEthanolShare], the upper
/// ethanol bound the trip lessons excuse lean trims with (#3701).
///
/// Null when the vehicle is unknown or not flagged multi-fuel capable
/// (#2885) — a single-fuel vehicle's tank is trivially 100 % of its grade
/// and surfacing that would be noise.
@riverpod
TankMixView? tankMix(Ref ref, String vehicleId) {
  final vehicle = ref
      .watch(vehicleProfileListProvider)
      .where((v) => v.id == vehicleId)
      .firstOrNull;
  if (vehicle == null || !vehicle.multiFuelCapable) return null;
  final evidence = <FuelGrade>{
    ...vehicleFuelCapabilityOf(vehicle).approvedGrades,
    for (final f in ref.watch(fillUpListProvider))
      if (f.vehicleId == vehicleId) FuelGrade.fromKey(f.fuelType.apiValue),
  }.where((g) => g.isLiquid);
  return TankMixView.of(ref.watch(tankBlendProvider(vehicleId)),
      ethanolEvidence: evidence);
}
