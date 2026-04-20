/// Segregated storage interfaces following the Interface Segregation Principle.
///
/// Each interface covers a single data domain (3-5 methods).
/// Providers should import only the interface they need.
/// [StorageRepository] composes all interfaces for DI.
library;

/// Favorite station storage.
abstract class FavoriteStorage {
  List<String> getFavoriteIds();
  Future<void> setFavoriteIds(List<String> ids);
  Future<void> addFavorite(String id);
  Future<void> removeFavorite(String id);
  bool isFavorite(String id);
  int get favoriteCount;

  // Favorite station data (permanent, never expires)
  Future<void> saveFavoriteStationData(String stationId, Map<String, dynamic> data);
  Map<String, dynamic>? getFavoriteStationData(String stationId);
  Map<String, dynamic> getAllFavoriteStationData();
  Future<void> removeFavoriteStationData(String stationId);
}

/// EV charging station favorite storage.
abstract class EvFavoriteStorage {
  List<String> getEvFavoriteIds();
  Future<void> setEvFavoriteIds(List<String> ids);
  Future<void> addEvFavorite(String id);
  Future<void> removeEvFavorite(String id);
  bool isEvFavorite(String id);
  int get evFavoriteCount;

  Future<void> saveEvFavoriteStationData(String stationId, Map<String, dynamic> data);
  Map<String, dynamic>? getEvFavoriteStationData(String stationId);
  Future<void> removeEvFavoriteStationData(String stationId);
}

/// Ignored station storage.
abstract class IgnoredStorage {
  List<String> getIgnoredIds();
  Future<void> setIgnoredIds(List<String> ids);
  Future<void> addIgnored(String id);
  Future<void> removeIgnored(String id);
  bool isIgnored(String id);
}

/// Station rating storage.
abstract class RatingStorage {
  Map<String, int> getRatings();
  Future<void> setRating(String stationId, int rating);
  Future<void> removeRating(String stationId);
  int? getRating(String stationId);
}

/// App settings storage.
abstract class SettingsStorage {
  dynamic getSetting(String key);
  Future<void> putSetting(String key, dynamic value);
  bool get isSetupComplete;
  bool get isSetupSkipped;
  Future<void> skipSetup();
  Future<void> resetSetupSkip();
}

/// API key secure storage.
abstract class ApiKeyStorage {
  /// Returns the user's personal Tankerkönig API key from secure storage,
  /// or `null` when no key has been configured. The app ships with NO
  /// bundled key (#713) — the Tankerkönig terms of service forbid
  /// publishing any key, including demo keys, on public repositories.
  /// Users register their free personal key at
  /// https://creativecommons.tankerkoenig.de.
  String? getApiKey();
  Future<void> setApiKey(String key);
  Future<void> deleteApiKey();

  /// Whether the user has configured a personal Tankerkönig key.
  /// When false, Germany search falls back to [DemoStationService].
  bool hasApiKey();

  /// Alias of [hasApiKey] kept for backwards compatibility with older
  /// callers. Since there is no longer a bundled default key, any
  /// configured key IS the user's custom key.
  bool hasCustomApiKey();

  String? getEvApiKey();
  bool hasEvApiKey();
  bool hasCustomEvApiKey();
  Future<void> setEvApiKey(String key);

  /// Supabase anon key — stored in the platform secure enclave, mirrored
  /// to an in-memory cache so callers can read synchronously.
  String? getSupabaseAnonKey();
  Future<void> setSupabaseAnonKey(String key);
  Future<void> deleteSupabaseAnonKey();
}

/// User profile storage.
abstract class ProfileStorage {
  String? getActiveProfileId();
  Future<void> setActiveProfileId(String id);
  Map<String, dynamic>? getProfile(String id);
  List<Map<String, dynamic>> getAllProfiles();
  Future<void> saveProfile(String id, Map<String, dynamic> profile);
  Future<void> deleteProfile(String id);
  int get profileCount;
}

/// Price history storage.
abstract class PriceHistoryStorage {
  Future<void> savePriceRecords(String stationId, List<Map<String, dynamic>> records);
  List<Map<String, dynamic>> getPriceRecords(String stationId);
  List<String> getPriceHistoryKeys();
  Future<void> clearPriceHistoryForStation(String stationId);
  Future<void> clearPriceHistory();
  int get priceHistoryEntryCount;
}

/// Price alert storage.
abstract class AlertStorage {
  List<Map<String, dynamic>> getAlerts();
  Future<void> saveAlerts(List<Map<String, dynamic>> alerts);
  Future<void> clearAlerts();
  int get alertCount;
}

/// Itinerary storage.
abstract class ItineraryStorage {
  List<Map<String, dynamic>> getItineraries();
  Future<void> addItinerary(Map<String, dynamic> itinerary);
  Future<void> deleteItinerary(String id);
  Future<void> saveItineraries(List<Map<String, dynamic>> itineraries);
}

/// Cache storage.
abstract class CacheStorage {
  Future<void> cacheData(String key, dynamic data);
  Map<String, dynamic>? getCachedData(String key, {Duration? maxAge});
  Future<void> clearCache();
  int get cacheEntryCount;
  Iterable<dynamic> get cacheKeys;
  Future<void> deleteCacheEntry(String key);
}

/// Composite interface that implements all segregated storage interfaces.
/// Used for DI — providers and services receive [StorageRepository],
/// but can narrow to specific interfaces in their type signatures.
abstract class StorageRepository implements
    FavoriteStorage, EvFavoriteStorage, IgnoredStorage, RatingStorage,
    SettingsStorage, ApiKeyStorage, ProfileStorage, PriceHistoryStorage,
    AlertStorage, ItineraryStorage, CacheStorage {
  /// Estimated storage size across all data domains (bytes).
  ({int settings, int profiles, int favorites, int cache, int priceHistory, int alerts, int total})
      get storageStats;
}
