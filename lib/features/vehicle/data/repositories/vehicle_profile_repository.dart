import '../../../../core/data/storage_repository.dart';
import '../../../../core/storage/hive_boxes.dart';
import '../../../../core/storage/storage_keys.dart';
import '../../domain/entities/vehicle_profile.dart';

/// CRUD repository for [VehicleProfile] entries.
///
/// Stored as a simple list under [StorageKeys.vehicleProfiles] and the
/// active profile id under [StorageKeys.activeVehicleProfileId] in the
/// settings box. No dedicated Hive box is needed — the list is small
/// (typically 1-3 profiles per household).
class VehicleProfileRepository {
  final SettingsStorage _storage;

  VehicleProfileRepository(this._storage);

  static const String _listKey = StorageKeys.vehicleProfiles;
  static const String _activeKey = StorageKeys.activeVehicleProfileId;

  /// Returns all stored vehicle profiles, in insertion order.
  List<VehicleProfile> getAll() {
    final raw = _storage.getSetting(_listKey);
    if (raw is! List) return const [];

    final result = <VehicleProfile>[];
    for (final item in raw) {
      final map = HiveBoxes.toStringDynamicMap(item);
      if (map == null) continue;
      try {
        result.add(VehicleProfile.fromJson(map));
      } catch (_) {
        // Skip malformed entries rather than crashing the whole list.
      }
    }
    return result;
  }

  /// Returns the profile matching [id] if present.
  VehicleProfile? getById(String id) {
    for (final v in getAll()) {
      if (v.id == id) return v;
    }
    return null;
  }

  /// Returns the active vehicle profile, or `null` if none is stored.
  VehicleProfile? getActive() {
    final id = _storage.getSetting(_activeKey) as String?;
    if (id == null) return null;
    return getById(id);
  }

  /// Add or update a vehicle profile (matched by id).
  Future<void> save(VehicleProfile profile) async {
    final all = [...getAll()];
    final index = all.indexWhere((v) => v.id == profile.id);
    if (index >= 0) {
      all[index] = profile;
    } else {
      all.add(profile);
    }
    await _writeAll(all);

    // Auto-activate the first vehicle so the UI always has one selected.
    if (_storage.getSetting(_activeKey) == null && all.isNotEmpty) {
      await _storage.putSetting(_activeKey, all.first.id);
    }
  }

  /// Delete a vehicle profile by id.
  ///
  /// If the deleted profile was the active one, the active selection
  /// switches to the first remaining profile (or clears if none).
  Future<void> delete(String id) async {
    final all = [...getAll()]..removeWhere((v) => v.id == id);
    await _writeAll(all);

    if (_storage.getSetting(_activeKey) == id) {
      if (all.isNotEmpty) {
        await _storage.putSetting(_activeKey, all.first.id);
      } else {
        await _storage.putSetting(_activeKey, null);
      }
    }
  }

  /// Set the active vehicle profile by id.
  Future<void> setActive(String id) async {
    await _storage.putSetting(_activeKey, id);
  }

  /// Remove all stored vehicle profiles.
  Future<void> clear() async {
    await _storage.putSetting(_listKey, <Map<String, dynamic>>[]);
    await _storage.putSetting(_activeKey, null);
  }

  Future<void> _writeAll(List<VehicleProfile> list) async {
    final json = list.map((v) => v.toJson()).toList();
    await _storage.putSetting(_listKey, json);
  }
}
