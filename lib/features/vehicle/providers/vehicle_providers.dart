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

  Future<void> save(VehicleProfile profile) async {
    final repo = ref.read(vehicleProfileRepositoryProvider);
    await repo.save(profile);
    state = repo.getAll();
    // Nudge the active-profile provider in case it just got auto-set.
    ref.invalidate(activeVehicleProfileProvider);
  }

  Future<void> remove(String id) async {
    final repo = ref.read(vehicleProfileRepositoryProvider);
    await repo.delete(id);
    state = repo.getAll();
    ref.invalidate(activeVehicleProfileProvider);
  }

  Future<void> clearAll() async {
    final repo = ref.read(vehicleProfileRepositoryProvider);
    await repo.clear();
    state = repo.getAll();
    ref.invalidate(activeVehicleProfileProvider);
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

  Future<void> setActive(String id) async {
    final repo = ref.read(vehicleProfileRepositoryProvider);
    await repo.setActive(id);
    state = repo.getActive();
  }
}
