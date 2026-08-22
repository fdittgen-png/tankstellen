// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/guarded.dart';
import '../../obd2/api.dart';
import '../../vehicle/api.dart';
import '../data/obd2_fuel_level_snapshot_store.dart';

part 'obd2_fuel_level_tracker.g.dart';

/// Persists the live OBD2 tank-level reading so it survives the drive
/// (#3647) — the producer half of "the sensor tracks the tank between
/// fills".
///
/// Armed by `TripRecordingBanner` (which wraps every screen via
/// `MaterialApp.builder`), exactly like [LiveActivitySync]: the banner
/// `ref.watch`es this keepAlive notifier so it observes the live level
/// no matter which route is visible — including a backgrounded
/// recording. [currentObd2FuelLevelLitres] is null outside an active
/// recording, so this writes nothing when the car is parked; the last
/// persisted value from the previous drive IS the parked-tank truth.
///
/// Write policy: a change of at least [minDeltaLiters] against the last
/// persisted value (per vehicle). PID `0x2F` steps at 1/255 of tank
/// (~0.2 L on a small car), so 0.25 L keeps the settings-box churn at a
/// handful of writes per drive while never lagging the gauge by more
/// than one visible step. The first reading of a drive always writes.
@Riverpod(keepAlive: true)
class Obd2FuelLevelTracker extends _$Obd2FuelLevelTracker {
  /// Last litres persisted, per vehicle id — survives rebuilds because
  /// the notifier instance is keepAlive.
  final Map<String, double> _lastWritten = {};

  /// Injectable clock (#2513 idiom) so tests pin the snapshot's `at`.
  DateTime Function() now = DateTime.now;

  static const double minDeltaLiters = 0.25;

  @override
  void build() {
    // Shell-safety idiom: in a harness without the recording graph the
    // watches throw — degrade to "no reading" instead of crashing the
    // banner that arms us.
    final litres = guard(
      () => ref.watch(currentObd2FuelLevelLitresProvider),
      where: 'Obd2FuelLevelTracker: live fuel-level watch failed',
      fallback: null,
    );
    if (litres == null) return;

    final vehicleId = guard(
      () => ref.watch(activeVehicleProfileProvider)?.id,
      where: 'Obd2FuelLevelTracker: active-vehicle watch failed',
      fallback: null,
    );
    if (vehicleId == null || vehicleId.isEmpty) return;

    final last = _lastWritten[vehicleId];
    if (last != null && (litres - last).abs() < minDeltaLiters) return;
    _lastWritten[vehicleId] = litres;

    unawaited(
      ref.read(obd2FuelLevelSnapshotStoreProvider).write(
            vehicleId,
            Obd2FuelLevelSnapshot(liters: litres, at: now()),
          ),
    );
  }
}
