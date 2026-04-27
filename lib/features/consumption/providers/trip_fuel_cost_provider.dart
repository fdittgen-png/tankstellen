import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/services/trip_fuel_cost_estimator.dart';
import 'consumption_providers.dart';
import 'trip_history_provider.dart';

part 'trip_fuel_cost_provider.g.dart';

/// Estimated fuel cost for the trip identified by [tripId] (#1209).
///
/// Composes the trip history list and the fill-up list filtered to the
/// trip's vehicle, then delegates to the pure
/// [estimateTripFuelCost] helper. Returns `null` when the trip is
/// absent, has no `fuelLitersConsumed` / `startedAt`, has no
/// `vehicleId`, or no eligible fill-up has a usable price — the trip
/// detail summary card uses that null to hide the cost row entirely.
///
/// Per-screen (no `keepAlive`) — matches the [tankLevel] composition
/// pattern from #1195.
@riverpod
double? tripFuelCost(Ref ref, String tripId) {
  final trips = ref.watch(tripHistoryListProvider);
  final trip = trips.where((t) => t.id == tripId).firstOrNull;
  if (trip == null) return null;
  final vehicleId = trip.vehicleId;
  if (vehicleId == null) return null;

  final allFillUps = ref.watch(fillUpListProvider);
  final fillUpsForVehicle =
      allFillUps.where((f) => f.vehicleId == vehicleId).toList();
  if (fillUpsForVehicle.isEmpty) return null;
  // FillUpRepository returns the list newest-first; defend against
  // a malformed import handing us a different order.
  fillUpsForVehicle.sort((a, b) => b.date.compareTo(a.date));

  return estimateTripFuelCost(
    trip: trip,
    fillUpsForVehicle: fillUpsForVehicle,
  );
}
