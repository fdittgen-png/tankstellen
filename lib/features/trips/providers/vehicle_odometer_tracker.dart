// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/guarded.dart';
import '../../../core/time/app_clock.dart';
import '../../vehicle/api.dart'
    show
        VehicleOdometerSnapshot,
        VehicleOdometerSource,
        activeVehicleProfileProvider,
        vehicleOdometerSnapshotStoreProvider;
import 'trip_recording_provider.dart';

part 'vehicle_odometer_tracker.g.dart';

/// #3877 — mirrors the recording's live odometer into the per-vehicle
/// snapshot store WHILE the trip runs (the fuel-level tracker's twin), so
/// a crash or a discarded trip still leaves the last known km for the
/// next fill-up. Armed by `TripRecordingBanner`; the stop path writes the
/// final value itself (`_recordEndOdometer`).
///
/// Write policy: whenever the live READING changes (a periodic refresh
/// landed — at most one per `odometerRefreshInterval`), never on the
/// estimate ticking up, so the settings box sees a handful of writes per
/// drive.
@Riverpod(keepAlive: true)
class VehicleOdometerTracker extends _$VehicleOdometerTracker {
  final Map<String, double> _lastWritten = {};

  @override
  void build() {
    final reading = guard<double?>(
      () => ref.watch(tripRecordingProvider).live?.odometerNowKm,
      where: 'VehicleOdometerTracker: live odometer watch failed',
      fallback: null,
    );
    if (reading == null) return;
    final vehicleId = guard(
      () => ref.watch(activeVehicleProfileProvider)?.id,
      where: 'VehicleOdometerTracker: active-vehicle watch failed',
      fallback: null,
    );
    if (vehicleId == null || vehicleId.isEmpty) return;
    if (_lastWritten[vehicleId] == reading) return;
    _lastWritten[vehicleId] = reading;
    unawaited(ref.read(vehicleOdometerSnapshotStoreProvider).write(
          vehicleId,
          VehicleOdometerSnapshot(
            km: reading,
            at: ref.read(appClockProvider).now(),
            source: VehicleOdometerSource.obd2,
          ),
        ));
  }
}
