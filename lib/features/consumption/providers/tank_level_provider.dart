import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../vehicle/providers/vehicle_providers.dart';
import '../domain/services/tank_level_estimator.dart';
import 'consumption_providers.dart';
import 'trip_history_provider.dart';

part 'tank_level_provider.g.dart';

/// Current tank-level estimate for [vehicleId] (#1195).
///
/// Composes the vehicle profile, the fill-up list filtered to that
/// vehicle, and the trip history filtered to trips recorded since the
/// most recent fill-up. The pure [estimateTankLevel] function does the
/// math; this provider just wires inputs together and stays per-screen
/// (no `keepAlive`).
///
/// Returns [TankLevelEstimate.unknown] when:
/// * [vehicleId] does not match any stored vehicle profile
/// * the vehicle has no fill-ups logged yet
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

  // Pass every trip for the vehicle (with a real `startedAt`) — the
  // estimator needs prior trips to compute "level just before the
  // most recent partial fill" (#1360). Trips with null `startedAt`
  // are dropped because they can't be placed on the timeline.
  // The estimator additionally filters by date for the post-fill
  // consumption tally, so the broader input is safe.
  final allTrips = ref.watch(tripHistoryListProvider);
  final vehicleTrips = allTrips.where((t) {
    if (t.vehicleId != vehicleId) return false;
    return t.summary.startedAt != null;
  }).toList(growable: false);

  return estimateTankLevel(
    vehicle: vehicle,
    fillUps: fillUps,
    trips: vehicleTrips,
  );
}
