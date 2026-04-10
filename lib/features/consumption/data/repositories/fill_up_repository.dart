import '../../../../core/data/storage_repository.dart';
import '../../../../core/storage/hive_boxes.dart';
import '../../../../core/storage/storage_keys.dart';
import '../../domain/entities/fill_up.dart';

/// Repository for CRUD operations on [FillUp] records.
///
/// Persists as a simple list under [StorageKeys.consumptionLog] in the
/// existing settings box — adding a dedicated Hive box is overkill for
/// a small, user-owned log.
class FillUpRepository {
  final SettingsStorage _storage;

  FillUpRepository(this._storage);

  static const String _key = StorageKeys.consumptionLog;

  /// Returns all stored fill-ups, newest first.
  List<FillUp> getAll() {
    final raw = _storage.getSetting(_key);
    if (raw == null) return const [];
    if (raw is! List) return const [];

    final result = <FillUp>[];
    for (final item in raw) {
      final map = HiveBoxes.toStringDynamicMap(item);
      if (map == null) continue;
      try {
        result.add(FillUp.fromJson(map));
      } catch (_) {
        // Skip malformed entries rather than crashing the whole list.
      }
    }
    result.sort((a, b) => b.date.compareTo(a.date));
    return result;
  }

  /// Add or update a single fill-up (matched by id).
  Future<void> save(FillUp fillUp) async {
    final all = [...getAll()];
    final index = all.indexWhere((f) => f.id == fillUp.id);
    if (index >= 0) {
      all[index] = fillUp;
    } else {
      all.add(fillUp);
    }
    await _writeAll(all);
  }

  /// Delete a fill-up by id.
  Future<void> delete(String id) async {
    final all = [...getAll()]..removeWhere((f) => f.id == id);
    await _writeAll(all);
  }

  /// Remove all stored fill-ups.
  Future<void> clear() => _storage.putSetting(_key, <Map<String, dynamic>>[]);

  Future<void> _writeAll(List<FillUp> list) async {
    final json = list.map((f) => f.toJson()).toList();
    await _storage.putSetting(_key, json);
  }
}
