import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/storage/storage_providers.dart';
import '../data/repositories/vehicle_profile_repository.dart';
import '../domain/entities/vehicle_profile.dart';

part 'vehicle_providers.g.dart';

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
  Future<void> save(VehicleProfile profile) async {
    final repo = ref.read(vehicleProfileRepositoryProvider);
    await repo.save(profile);
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
    return added;
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
