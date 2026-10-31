// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/domain/vehicle_profile.dart';
import '../../vehicle/providers/vehicle_providers.dart';
import '../domain/trip_ve_recompute.dart';
import 'trip_history_provider.dart';
import '../../../core/logging/error_logger.dart';
import '../../../core/logging/app_log.dart';

part 'trip_ve_recompute_provider.g.dart';

/// #1858 — retroactive η_v recompute trigger.
///
/// A keep-alive listener that watches [vehicleProfileListProvider] and,
/// whenever a vehicle's effective η_v changes via a manual profile
/// save, rescales that vehicle's η_v-recalculable trips in the
/// trip-history box (see [recomputeTripForVe]).
///
/// Scoped to **manual** edits by construction: the VeLearner writes
/// the vehicle-profile *repository* directly, not the
/// [VehicleProfileList] notifier, so its converging per-fill-up
/// micro-adjustments never reach this provider — only a deliberate
/// edit through the notifier does, which is the intended trigger.
/// #4544 — not strictly: a later `mergeFrom` (TankSync vehicles pull)
/// or an invalidate re-reads the learned η_v and fires it too, which is
/// why the recompute reads summaries and loads full trips off-isolate.
///
/// Instantiated once at startup (`app_initializer`) so the listener is
/// live for the whole session; it holds no state of its own.
@Riverpod(keepAlive: true)
class TripVeRecomputeListener extends _$TripVeRecomputeListener {
  @override
  void build() {
    ref.listen<List<VehicleProfile>>(
      vehicleProfileListProvider,
      _onVehiclesChanged,
    );
  }

  void _onVehiclesChanged(
    List<VehicleProfile>? previous,
    List<VehicleProfile> next,
  ) {
    // First emission has nothing to diff against.
    if (previous == null) return;
    final before = {for (final v in previous) v.id: _effectiveVe(v)};
    for (final vehicle in next) {
      final oldVe = before[vehicle.id];
      final newVe = _effectiveVe(vehicle);
      // Unchanged η_v (or a newly-added vehicle) → nothing to rescale.
      if (oldVe == null || oldVe == newVe) continue;
      unawaited(_recomputeVehicleTrips(vehicle.id, newVe));
    }
  }

  /// The η_v a trip should now be recomputed against: the manual
  /// override when the user has set one, otherwise the learned /
  /// default value.
  double _effectiveVe(VehicleProfile v) =>
      v.manualVolumetricEfficiencyOverride ?? v.volumetricEfficiency;

  /// Rescale every η_v-recalculable trip of [vehicleId] to [newVe] and
  /// write the changed entries back. Best-effort — a recompute failure
  /// must never derail the vehicle save that triggered it.
  Future<void> _recomputeVehicleTrips(String vehicleId, double newVe) async {
    try {
      final repo = ref.read(tripHistoryRepositoryProvider);
      if (repo == null) return;
      var changed = false;
      // #4544 — decide on summaries (meta rows only, no samples); the
      // old synchronous `loadAll()` decoded every chunk of every trip
      // on the UI isolate. `recomputeTripForVe` returns the same
      // instance when a trip is not recalculable / already at newVe.
      final ids = [
        for (final s in repo.loadSummaries())
          if (s.vehicleId == vehicleId &&
              !identical(recomputeTripForVe(s, newVe), s))
            s.id,
      ];
      for (final id in ids) {
        // Never save the summary-only entry: its empty samples would
        // wipe the trip's telemetry. Load the full one off-isolate.
        final full = await repo.loadByIdAsync(id);
        if (full != null) {
          await repo.save(recomputeTripForVe(full, newVe));
          changed = true;
        }
        await Future<void>.delayed(Duration.zero);
      }
      if (changed) {
        // Refresh the in-memory list so any open trip-history UI
        // re-reads the rescaled figures.
        ref.read(tripHistoryListProvider.notifier).refresh();
      }
    } catch (e, st) {
      log.error(e, st, layer: ErrorLayer.providers, context: const {'where': 'TripVeRecomputeListener: recompute failed'});
    }
  }
}
