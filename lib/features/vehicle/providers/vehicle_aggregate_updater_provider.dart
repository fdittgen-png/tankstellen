import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../consumption/providers/trip_history_provider.dart';
import '../data/vehicle_aggregate_updater.dart';
import 'vehicle_providers.dart';

part 'vehicle_aggregate_updater_provider.g.dart';

/// Riverpod-managed instance of [VehicleAggregateUpdater] (#1193 phase 2).
///
/// `keepAlive: true` so the production wiring can `ref.read` it once
/// from `app_initializer.dart`, install it as the
/// `TripHistoryRepository.onSavedHook`, and let it live for the rest
/// of the app session. Tests override it with a fake updater that
/// records calls.
@Riverpod(keepAlive: true)
VehicleAggregateUpdater vehicleAggregateUpdater(Ref ref) {
  final vehicleRepo = ref.watch(vehicleProfileRepositoryProvider);
  return VehicleAggregateUpdater(
    vehicleRepo: vehicleRepo,
    tripRepoLookup: () => ref.read(tripHistoryRepositoryProvider),
  );
}

/// Idempotent wiring step: install the aggregator's
/// `runForVehicle` as the trip-history repository's `onSavedHook`.
///
/// Called from `app_initializer.dart` once after the root container
/// is built. Returns `true` when the hook was wired, `false` when the
/// trip-history box isn't open yet (cold-start path before Hive has
/// finished initialising — the next call retries).
///
/// Takes a [ProviderContainer] (not a [Ref]) so it can be invoked
/// from outside any provider's `build` — `app_initializer` owns the
/// root container directly.
///
/// Lives on the provider file rather than as a method on
/// [VehicleAggregateUpdater] because the dependency direction is
/// "wire-up code reads providers"; the updater itself shouldn't
/// import the trip-history provider.
bool wireAggregatorIntoTripHistory(ProviderContainer container) {
  final tripRepo = container.read(tripHistoryRepositoryProvider);
  if (tripRepo == null) return false;
  final updater = container.read(vehicleAggregateUpdaterProvider);
  // Fire-and-forget; the hook itself stays sync (the repo passes a
  // `void Function`), and `runForVehicle` swallows + logs every
  // failure so this is safe.
  tripRepo.onSavedHook = (vehicleId) {
    unawaited(updater.runForVehicle(vehicleId));
  };
  return true;
}
