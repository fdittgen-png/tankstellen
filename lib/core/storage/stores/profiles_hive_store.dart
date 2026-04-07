import 'package:hive_flutter/hive_flutter.dart';

import '../../data/storage_repository.dart';
import '../hive_boxes.dart';
import '../storage_keys.dart';

/// Hive-backed implementation of [ProfileStorage].
///
/// Manages user search profiles (country, fuel type, radius, etc.).
/// Profile data is stored in an encrypted Hive box.
class ProfilesHiveStore implements ProfileStorage {
  Box get _profiles => Hive.box(HiveBoxes.profiles);
  Box get _settings => Hive.box(HiveBoxes.settings);

  @override
  String? getActiveProfileId() =>
      _settings.get(StorageKeys.activeProfileId) as String?;

  @override
  Future<void> setActiveProfileId(String id) =>
      _settings.put(StorageKeys.activeProfileId, id);

  @override
  Map<String, dynamic>? getProfile(String id) {
    final data = _profiles.get(id);
    return HiveBoxes.toStringDynamicMap(data);
  }

  @override
  List<Map<String, dynamic>> getAllProfiles() {
    return _profiles.values
        .map((e) => HiveBoxes.toStringDynamicMap(e))
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  @override
  Future<void> saveProfile(String id, Map<String, dynamic> profile) =>
      _profiles.put(id, profile);

  @override
  Future<void> deleteProfile(String id) => _profiles.delete(id);

  @override
  int get profileCount => _profiles.length;
}
