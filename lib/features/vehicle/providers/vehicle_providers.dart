// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/storage/storage_providers.dart';
import '../../../core/sync/sync_events.dart';
import '../../../core/sync/vehicles_sync.dart';
import '../data/repositories/vehicle_profile_repository.dart';
import '../../../core/domain/vehicle_profile.dart';

part 'vehicle_providers.g.dart';

/// Signature of the bidirectional vehicles merge. Defaults to
/// [VehiclesSync.merge]; injectable so the #3077 pull-persist wiring is
/// unit-testable without a live Supabase session (the real merge returns
/// the input unchanged when unauthenticated, masking the wiring under test).
typedef VehiclesMergeFn = Future<List<VehicleProfile>> Function(
    List<VehicleProfile> local);

/// Repository for reading/writing [VehicleProfile] entries.
@Riverpod(keepAlive: true)
VehicleProfileRepository vehicleProfileRepository(Ref ref) {
  final storage = ref.watch(settingsStorageProvider);
  return VehicleProfileRepository(storage);
}

/// Full list of stored vehicle profiles.
@Riverpod(keepAlive: true)
class VehicleProfileList extends _$VehicleProfileList {
  @override
  List<VehicleProfile> build() {
    final repo = ref.watch(vehicleProfileRepositoryProvider);
    return repo.getAll();
  }

  /// Persist [profile] (insert or update by id) and refresh the list.
  ///
  /// Also invalidates [activeVehicleProfileProvider] so callers that depend
  /// on the active vehicle re-read it — saving the first profile auto-sets
  /// it as active.
  ///
  /// #3122 — every local create/edit through here is stamped with a UTC
  /// `updatedAt` so the last-write-wins sync merge can propagate the edit.
  /// Server-pulled writes go through [mergeFrom] instead, which preserves
  /// the stamp the other device embedded in the blob.
  Future<void> save(VehicleProfile profile) async {
    final repo = ref.read(vehicleProfileRepositoryProvider);
    await repo.save(profile.copyWith(updatedAt: DateTime.now().toUtc()));
    state = repo.getAll();
    ref.invalidate(activeVehicleProfileProvider);
  }

  /// Delete the profile with the given [id] and refresh the list.
  Future<void> remove(String id) async {
    final repo = ref.read(vehicleProfileRepositoryProvider);
    await repo.delete(id);
    state = repo.getAll();
    ref.invalidate(activeVehicleProfileProvider);
  }

  /// Wipe all stored vehicle profiles. Used when the user resets the app.
  Future<void> clearAll() async {
    final repo = ref.read(vehicleProfileRepositoryProvider);
    await repo.clear();
    state = repo.getAll();
    ref.invalidate(activeVehicleProfileProvider);
  }

  /// Merge [incoming] vehicles into local storage. Existing ids are
  /// overwritten; new ids are added. Returns the number of new entries
  /// actually inserted. Used by the device-linking flow (#713).
  Future<int> mergeFrom(Iterable<VehicleProfile> incoming) async {
    final repo = ref.read(vehicleProfileRepositoryProvider);
    final localIds = repo.getAll().map((v) => v.id).toSet();
    var added = 0;
    for (final v in incoming) {
      if (!localIds.contains(v.id)) added++;
      await repo.save(v);
    }
    state = repo.getAll();
    ref.invalidate(activeVehicleProfileProvider);
    // #3446 — this is the vehicles persist chokepoint (launch/sync-now
    // pulls AND the #713 device-link import): announce every incoming
    // write on the sync bus for any other reader of the table.
    SyncEvents.instance
        .emit(SyncTableChanged(SyncTables.vehicles, incoming.length));
    return added;
  }

  /// Pull the user's server vehicle profiles and **persist the server-side
  /// changes into local storage** (#3077, #3122).
  ///
  /// [VehiclesSync.merge] uploads local-only profiles AND returns the union
  /// (`[...local, ...downloaded]`) with last-write-wins applied to ids
  /// present on both sides (#3122). We persist every returned entry that
  /// differs from the local copy: server-only profiles (the #3077 pull) and
  /// server-newer overwrites (the #3122 LWW download). Entries the merge
  /// left untouched — including local-newer edits, which the merge already
  /// re-uploaded — compare equal (freezed deep equality) and are skipped,
  /// so an in-flight local edit is never clobbered. Returns the count of
  /// newly-added (previously unknown) profiles.
  ///
  /// The caller owns the consent gate — this is invoked behind the
  /// trip-data sync gate (a vehicle profile is the anchor its trips +
  /// fill-ups attach to). [mergeFn] defaults to the real sync and is
  /// injectable for unit tests.
  Future<int> pullFromServer(
      {VehiclesMergeFn mergeFn = VehiclesSync.merge}) async {
    final repo = ref.read(vehicleProfileRepositoryProvider);
    final localById = {for (final v in repo.getAll()) v.id: v};
    final merged = await mergeFn(repo.getAll());
    final changed = merged.where((v) => localById[v.id] != v).toList();
    if (changed.isEmpty) return 0;
    return mergeFrom(changed);
  }
}

/// Currently active vehicle profile, or `null` when none is selected.
@Riverpod(keepAlive: true)
class ActiveVehicleProfile extends _$ActiveVehicleProfile {
  @override
  VehicleProfile? build() {
    ref.watch(vehicleProfileListProvider);
    final repo = ref.watch(vehicleProfileRepositoryProvider);
    return repo.getActive();
  }

  /// Mark the profile with [id] as active and rebuild this provider so
  /// dependent UI (EV filters, route calculator) picks up the new vehicle.
  Future<void> setActive(String id) async {
    final repo = ref.read(vehicleProfileRepositoryProvider);
    await repo.setActive(id);
    state = repo.getActive();
  }
}
