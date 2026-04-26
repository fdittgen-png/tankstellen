import 'package:tankstellen/core/data/storage_repository.dart';

import 'fake_hive_storage.dart';

/// In-memory fake of [StorageRepository] for unit tests.
///
/// Replaces the previous `MockStorageRepository` (mocktail) for tests that
/// exercise real state transitions. See the doc comment on [FakeHiveStorage]
/// for the full rationale.
///
/// Implementation note: this delegates to a [FakeHiveStorage] under the hood
/// because `HiveStorage` already implements every method of
/// [StorageRepository]. Sharing one implementation keeps the two fakes
/// behaviourally identical and avoids drift.
class FakeStorageRepository implements StorageRepository {
  /// The underlying [FakeHiveStorage] backing this fake.
  ///
  /// Tests that need to seed state directly (e.g. `inner.setSetupComplete(...)`
  /// or `inner.hasBundledDefaultKey = false`) can reach through here. For the
  /// public [StorageRepository] surface, prefer the methods on this class
  /// directly.
  final FakeHiveStorage inner;

  FakeStorageRepository({FakeHiveStorage? inner})
      : inner = inner ?? FakeHiveStorage();

  // ---------------------------------------------------------------------------
  // SettingsStorage
  // ---------------------------------------------------------------------------
  @override
  dynamic getSetting(String key) => inner.getSetting(key);
  @override
  Future<void> putSetting(String key, dynamic value) =>
      inner.putSetting(key, value);
  @override
  bool get isSetupComplete => inner.isSetupComplete;
  @override
  bool get isSetupSkipped => inner.isSetupSkipped;
  @override
  Future<void> skipSetup() => inner.skipSetup();
  @override
  Future<void> resetSetupSkip() => inner.resetSetupSkip();

  // ---------------------------------------------------------------------------
  // ApiKeyStorage
  // ---------------------------------------------------------------------------
  @override
  String? getApiKey() => inner.getApiKey();
  @override
  Future<void> setApiKey(String key) => inner.setApiKey(key);
  @override
  Future<void> deleteApiKey() => inner.deleteApiKey();
  @override
  bool hasApiKey() => inner.hasApiKey();
  @override
  bool hasCustomApiKey() => inner.hasCustomApiKey();
  @override
  String? getEvApiKey() => inner.getEvApiKey();
  @override
  bool hasEvApiKey() => inner.hasEvApiKey();
  @override
  bool hasCustomEvApiKey() => inner.hasCustomEvApiKey();
  @override
  Future<void> setEvApiKey(String key) => inner.setEvApiKey(key);
  @override
  String? getSupabaseAnonKey() => inner.getSupabaseAnonKey();
  @override
  Future<void> setSupabaseAnonKey(String key) =>
      inner.setSupabaseAnonKey(key);
  @override
  Future<void> deleteSupabaseAnonKey() => inner.deleteSupabaseAnonKey();

  // ---------------------------------------------------------------------------
  // FavoriteStorage
  // ---------------------------------------------------------------------------
  @override
  List<String> getFavoriteIds() => inner.getFavoriteIds();
  @override
  Future<void> setFavoriteIds(List<String> ids) => inner.setFavoriteIds(ids);
  @override
  Future<void> addFavorite(String id) => inner.addFavorite(id);
  @override
  Future<void> removeFavorite(String id) => inner.removeFavorite(id);
  @override
  bool isFavorite(String id) => inner.isFavorite(id);
  @override
  int get favoriteCount => inner.favoriteCount;
  @override
  Future<void> saveFavoriteStationData(
          String stationId, Map<String, dynamic> data) =>
      inner.saveFavoriteStationData(stationId, data);
  @override
  Map<String, dynamic>? getFavoriteStationData(String stationId) =>
      inner.getFavoriteStationData(stationId);
  @override
  Map<String, dynamic> getAllFavoriteStationData() =>
      inner.getAllFavoriteStationData();
  @override
  Future<void> removeFavoriteStationData(String stationId) =>
      inner.removeFavoriteStationData(stationId);

  // ---------------------------------------------------------------------------
  // EvFavoriteStorage
  // ---------------------------------------------------------------------------
  @override
  List<String> getEvFavoriteIds() => inner.getEvFavoriteIds();
  @override
  Future<void> setEvFavoriteIds(List<String> ids) =>
      inner.setEvFavoriteIds(ids);
  @override
  Future<void> addEvFavorite(String id) => inner.addEvFavorite(id);
  @override
  Future<void> removeEvFavorite(String id) => inner.removeEvFavorite(id);
  @override
  bool isEvFavorite(String id) => inner.isEvFavorite(id);
  @override
  int get evFavoriteCount => inner.evFavoriteCount;
  @override
  Future<void> saveEvFavoriteStationData(
          String stationId, Map<String, dynamic> data) =>
      inner.saveEvFavoriteStationData(stationId, data);
  @override
  Map<String, dynamic>? getEvFavoriteStationData(String stationId) =>
      inner.getEvFavoriteStationData(stationId);
  @override
  Future<void> removeEvFavoriteStationData(String stationId) =>
      inner.removeEvFavoriteStationData(stationId);

  // ---------------------------------------------------------------------------
  // IgnoredStorage
  // ---------------------------------------------------------------------------
  @override
  List<String> getIgnoredIds() => inner.getIgnoredIds();
  @override
  Future<void> setIgnoredIds(List<String> ids) => inner.setIgnoredIds(ids);
  @override
  Future<void> addIgnored(String id) => inner.addIgnored(id);
  @override
  Future<void> removeIgnored(String id) => inner.removeIgnored(id);
  @override
  bool isIgnored(String id) => inner.isIgnored(id);

  // ---------------------------------------------------------------------------
  // RatingStorage
  // ---------------------------------------------------------------------------
  @override
  Map<String, int> getRatings() => inner.getRatings();
  @override
  Future<void> setRating(String stationId, int rating) =>
      inner.setRating(stationId, rating);
  @override
  Future<void> removeRating(String stationId) => inner.removeRating(stationId);
  @override
  int? getRating(String stationId) => inner.getRating(stationId);

  // ---------------------------------------------------------------------------
  // ProfileStorage
  // ---------------------------------------------------------------------------
  @override
  String? getActiveProfileId() => inner.getActiveProfileId();
  @override
  Future<void> setActiveProfileId(String id) => inner.setActiveProfileId(id);
  @override
  Map<String, dynamic>? getProfile(String id) => inner.getProfile(id);
  @override
  List<Map<String, dynamic>> getAllProfiles() => inner.getAllProfiles();
  @override
  Future<void> saveProfile(String id, Map<String, dynamic> profile) =>
      inner.saveProfile(id, profile);
  @override
  Future<void> deleteProfile(String id) => inner.deleteProfile(id);
  @override
  int get profileCount => inner.profileCount;

  // ---------------------------------------------------------------------------
  // CacheStorage
  // ---------------------------------------------------------------------------
  @override
  Future<void> cacheData(String key, dynamic data) =>
      inner.cacheData(key, data);
  @override
  Map<String, dynamic>? getCachedData(String key, {Duration? maxAge}) =>
      inner.getCachedData(key, maxAge: maxAge);
  @override
  Future<void> clearCache() => inner.clearCache();
  @override
  Iterable<dynamic> get cacheKeys => inner.cacheKeys;
  @override
  Future<void> deleteCacheEntry(String key) => inner.deleteCacheEntry(key);
  @override
  int get cacheEntryCount => inner.cacheEntryCount;

  // ---------------------------------------------------------------------------
  // ItineraryStorage
  // ---------------------------------------------------------------------------
  @override
  List<Map<String, dynamic>> getItineraries() => inner.getItineraries();
  @override
  Future<void> saveItineraries(List<Map<String, dynamic>> itineraries) =>
      inner.saveItineraries(itineraries);
  @override
  Future<void> addItinerary(Map<String, dynamic> itinerary) =>
      inner.addItinerary(itinerary);
  @override
  Future<void> deleteItinerary(String id) => inner.deleteItinerary(id);

  // ---------------------------------------------------------------------------
  // PriceHistoryStorage
  // ---------------------------------------------------------------------------
  @override
  Future<void> savePriceRecords(
          String stationId, List<Map<String, dynamic>> records) =>
      inner.savePriceRecords(stationId, records);
  @override
  List<Map<String, dynamic>> getPriceRecords(String stationId) =>
      inner.getPriceRecords(stationId);
  @override
  List<String> getPriceHistoryKeys() => inner.getPriceHistoryKeys();
  @override
  Future<void> clearPriceHistoryForStation(String stationId) =>
      inner.clearPriceHistoryForStation(stationId);
  @override
  Future<void> clearPriceHistory() => inner.clearPriceHistory();
  @override
  int get priceHistoryEntryCount => inner.priceHistoryEntryCount;

  // ---------------------------------------------------------------------------
  // AlertStorage
  // ---------------------------------------------------------------------------
  @override
  List<Map<String, dynamic>> getAlerts() => inner.getAlerts();
  @override
  Future<void> saveAlerts(List<Map<String, dynamic>> alerts) =>
      inner.saveAlerts(alerts);
  @override
  Future<void> clearAlerts() => inner.clearAlerts();
  @override
  int get alertCount => inner.alertCount;

  // ---------------------------------------------------------------------------
  // StorageRepository extras
  // ---------------------------------------------------------------------------
  @override
  ({
    int settings,
    int profiles,
    int favorites,
    int cache,
    int priceHistory,
    int alerts,
    int total
  }) get storageStats => inner.storageStats;
}
