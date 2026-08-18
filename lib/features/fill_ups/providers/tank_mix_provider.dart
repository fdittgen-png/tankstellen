// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../vehicle/api.dart';
import '../domain/services/tank_mix_estimator.dart';
import 'consumption_providers.dart';

part 'tank_mix_provider.g.dart';

/// Fuel mix of the current tank content for [vehicleId] (#3652).
///
/// Null when the vehicle is unknown, has no physical fills, or is not
/// flagged multi-fuel capable (#2885) — a single-fuel vehicle's tank is
/// trivially 100 % of its grade and surfacing that would be noise.
@riverpod
TankMixEstimate? tankMix(Ref ref, String vehicleId) {
  final vehicle = ref
      .watch(vehicleProfileListProvider)
      .where((v) => v.id == vehicleId)
      .firstOrNull;
  if (vehicle == null || !vehicle.multiFuelCapable) return null;

  final fillUps = ref
      .watch(fillUpListProvider)
      .where((f) => f.vehicleId == vehicleId)
      .toList();
  return estimateTankMix(vehicle: vehicle, fillUps: fillUps);
}
