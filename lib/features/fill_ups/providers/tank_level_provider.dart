// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/guarded.dart';
import '../../obd2/api.dart';
import '../../vehicle/api.dart';
import '../data/obd2_fuel_level_snapshot_store.dart';
import '../domain/services/tank_level_estimator.dart';
import 'consumption_providers.dart';

part 'tank_level_provider.g.dart';

/// Tank level for [vehicleId] — v2 model (#3647): the most recent
/// physical fill-up anchors the level (full → 100 %), an OBD2
/// fuel-level reading newer than that fill overrides it, and trip
/// recordings are not consulted at all.
///
/// Sensor source preference:
///  1. the LIVE reading while a recording is active
///     ([currentObd2FuelLevelLitres] — PSA CAN > OEM litres > 0x2F),
///     stamped "now";
///  2. the persisted per-vehicle snapshot the tracker wrote during the
///     last drive ([Obd2FuelLevelSnapshotStore]);
///  3. none — the estimator stays on the fill anchor.
///
/// The live watch also keeps this provider rebuilding during a drive,
/// so the Carburant card follows the gauge in real time; after the
/// drive the live value drops to null and the freshly-persisted
/// snapshot takes over seamlessly.
///
/// Returns [TankLevelEstimate.unknown] when [vehicleId] matches no
/// stored vehicle profile or the vehicle has no fill-ups logged yet.
@riverpod
TankLevelEstimate tankLevel(Ref ref, String vehicleId) {
  final vehicles = ref.watch(vehicleProfileListProvider);
  final vehicle = vehicles.where((v) => v.id == vehicleId).firstOrNull;
  if (vehicle == null) {
    return const TankLevelEstimate.unknown();
  }

  final allFillUps = ref.watch(fillUpListProvider);
  final fillUps = allFillUps.where((f) => f.vehicleId == vehicleId).toList();
  if (fillUps.isEmpty) {
    return const TankLevelEstimate.unknown();
  }

  // The fill-up list is already newest-first via FillUpRepository, but
  // be defensive: a malformed import could hand us a different order.
  fillUps.sort((a, b) => b.date.compareTo(a.date));

  // Shell-safety idiom (#2163): the live chain reaches into the
  // recording graph, which isolated widget tests don't wire — degrade
  // to "no live reading" instead of crashing the card.
  final liveLitres = guard(
    () {
      final active = ref.watch(activeVehicleProfileProvider);
      if (active?.id != vehicleId) return null;
      return ref.watch(currentObd2FuelLevelLitresProvider);
    },
    where: 'tankLevel: live fuel-level watch failed',
    fallback: null,
  );

  final sensor = liveLitres != null
      ? Obd2FuelLevelSnapshot(liters: liveLitres, at: DateTime.now())
      : ref.watch(obd2FuelLevelSnapshotStoreProvider).read(vehicleId);

  return estimateTankLevel(
    vehicle: vehicle,
    fillUps: fillUps,
    sensor: sensor,
  );
}
