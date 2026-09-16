// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/domain/fuel/tank_blend_snapshot.dart';
import '../../trips/api.dart';
import '../../vehicle/api.dart';
import '../domain/services/tank_blend_event_log.dart';
import 'consumption_providers.dart';

part 'tank_blend_provider.g.dart';

/// The versioned, evidence-only tank blend of [vehicleId] (#4279).
///
/// Recomputed from the fill-up list and the trip history whenever either
/// changes — never persisted, so there is no derived state to go stale,
/// migrate, or double-apply after a restart. A vehicle with no history
/// yields a fully unknown blend (confidence 0), never an empty tank.
///
/// Read [TankBlendSnapshot.confidence] / [TankBlendSnapshot.exactShare] to
/// tell an established blend from a partly unknown one: this is the
/// "estimated, not measured" signal a summary must surface (#4278).
@riverpod
TankBlendSnapshot tankBlend(Ref ref, String vehicleId) {
  final vehicle = ref
      .watch(vehicleProfileListProvider)
      .where((v) => v.id == vehicleId)
      .firstOrNull;
  return deriveTankBlend(
    vehicleId: vehicleId,
    vehicle: vehicle,
    fillUps: ref.watch(fillUpListProvider),
    trips: ref.watch(tripHistoryListProvider),
  );
}
