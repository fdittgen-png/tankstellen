// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/domain/fuel/fuel_behaviour_profile.dart';
import '../../trips/api.dart';
import '../../vehicle/api.dart';
import '../domain/services/fuel_behaviour_evidence_log.dart';
import 'consumption_providers.dart';

part 'fuel_behaviour_provider.g.dart';

/// How [vehicleId] behaves per fuel context (#4276), learned from its
/// canonical consumption evidence and full-to-full fill windows.
///
/// Recomputed from the fill-up list and trip history whenever either
/// changes, and never persisted — the UI (#4278) and the next-fill
/// decision (#4277) read this one result instead of re-analysing.
/// Every figure is a `BehaviourMetric`: a value with its interval, or
/// insufficient with the reason. See `deriveFuelBehaviourProfile` for what
/// the live history can and cannot supply today.
@riverpod
FuelBehaviourProfile fuelBehaviourProfile(Ref ref, String vehicleId) {
  final vehicle = ref
      .watch(vehicleProfileListProvider)
      .where((v) => v.id == vehicleId)
      .firstOrNull;
  return deriveFuelBehaviourProfile(
    vehicleId: vehicleId,
    vehicle: vehicle,
    fillUps: ref.watch(fillUpListProvider),
    trips: ref.watch(tripHistoryListProvider),
  );
}
