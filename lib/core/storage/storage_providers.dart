import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/storage_repository.dart';
import 'hive_storage.dart';

part 'storage_providers.g.dart';

/// Narrow provider for API key operations (presentation-safe).
@Riverpod(keepAlive: true)
ApiKeyStorage apiKeyStorage(Ref ref) => ref.watch(hiveStorageProvider);

/// Narrow provider for app settings (presentation-safe).
@Riverpod(keepAlive: true)
SettingsStorage settingsStorage(Ref ref) => ref.watch(hiveStorageProvider);

/// Narrow provider for cache + storage management (presentation-safe).
@Riverpod(keepAlive: true)
StorageManagement storageManagement(Ref ref) => StorageManagement(ref.watch(hiveStorageProvider));

/// Combines cache, price history, and stats operations for the storage settings screen.
class StorageManagement {
  final HiveStorage _storage;
  StorageManagement(this._storage);

  ({int settings, int profiles, int favorites, int cache, int priceHistory, int alerts, int total})
      get storageStats => _storage.storageStats;

  int get profileCount => _storage.profileCount;
  int get favoriteCount => _storage.favoriteCount;
  int get cacheEntryCount => _storage.cacheEntryCount;
  int get priceHistoryEntryCount => _storage.priceHistoryEntryCount;
  int get alertCount => _storage.alertCount;
  List<String> getIgnoredIds() => _storage.getIgnoredIds();
  Map<String, int> getRatings() => _storage.getRatings();

  Future<void> clearCache() => _storage.clearCache();
  Future<void> clearPriceHistory() => _storage.clearPriceHistory();
  Future<void> deleteApiKey() => _storage.deleteApiKey();

  Future<void> savePriceRecords(String stationId, List<Map<String, dynamic>> records) =>
      _storage.savePriceRecords(stationId, records);
}
