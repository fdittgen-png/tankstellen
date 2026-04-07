import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/storage_repository.dart';
import 'hive_boxes.dart';
import 'stores/alerts_hive_store.dart';
import 'stores/cache_hive_store.dart';
import 'stores/favorites_hive_store.dart';
import 'stores/price_history_hive_store.dart';
import 'stores/profiles_hive_store.dart';
import 'stores/settings_hive_store.dart';

part 'hive_storage.g.dart';

@Riverpod(keepAlive: true)
HiveStorage hiveStorage(Ref ref) {
  return HiveStorage();
}

/// Facade that composes all domain-specific Hive stores into one
/// [StorageRepository].
///
/// Individual domain logic lives in the `stores/` directory:
/// - [SettingsHiveStore] — app settings + API keys
/// - [FavoritesHiveStore] — favorites, ignored stations, ratings
/// - [ProfilesHiveStore] — user search profiles
/// - [CacheHiveStore] — API response cache + itineraries
/// - [PriceHistoryHiveStore] — 30-day price records
/// - [AlertsHiveStore] — price alerts
///
/// This class delegates all interface methods to the appropriate store.
/// Static lifecycle methods (init, loadApiKey) delegate to [HiveBoxes]
/// and [SettingsHiveStore].
class HiveStorage implements StorageRepository {
  final SettingsHiveStore _settings = SettingsHiveStore();
  final FavoritesHiveStore _favorites = FavoritesHiveStore();
  final ProfilesHiveStore _profiles = ProfilesHiveStore();
  final CacheHiveStore _cache = CacheHiveStore();
  final PriceHistoryHiveStore _priceHistory = PriceHistoryHiveStore();
  final AlertsHiveStore _alerts = AlertsHiveStore();

  // ---------------------------------------------------------------------------
  // Lifecycle (static — called before providers are created)
  // ---------------------------------------------------------------------------

  static Future<void> init() => HiveBoxes.init();

  static Future<void> initInIsolate() => HiveBoxes.initInIsolate();

  /// Close all Hive boxes opened by [initInIsolate].
  ///
  /// Must be called at the end of every background task to release file
  /// handles and prevent race conditions with the main isolate.
  static Future<void> closeIsolateBoxes() => HiveBoxes.closeIsolateBoxes();

  @visibleForTesting
  // ignore: invalid_use_of_visible_for_testing_member
  static Future<void> initForTest() => HiveBoxes.initForTest();

  static Future<void> loadApiKey() => SettingsHiveStore.loadApiKey();

  // ---------------------------------------------------------------------------
  // SettingsStorage
  // ---------------------------------------------------------------------------
  @override
  dynamic getSetting(String key) => _settings.getSetting(key);
  @override
  Future<void> putSetting(String key, dynamic value) =>
      _settings.putSetting(key, value);
  @override
  bool get isSetupComplete => _settings.isSetupComplete;
  @override
  bool get isSetupSkipped => _settings.isSetupSkipped;
  @override
  Future<void> skipSetup() => _settings.skipSetup();
  @override
  Future<void> resetSetupSkip() => _settings.resetSetupSkip();

  // ---------------------------------------------------------------------------
  // ApiKeyStorage
  // ---------------------------------------------------------------------------
  @override
  String? getApiKey() => _settings.getApiKey();
  @override
  Future<void> setApiKey(String key) => _settings.setApiKey(key);
  @override
  Future<void> deleteApiKey() => _settings.deleteApiKey();
  @override
  bool hasApiKey() => _settings.hasApiKey();
  @override
  String? getEvApiKey() => _settings.getEvApiKey();
  @override
  bool hasEvApiKey() => _settings.hasEvApiKey();
  @override
  bool hasCustomEvApiKey() => _settings.hasCustomEvApiKey();
  @override
  Future<void> setEvApiKey(String key) => _settings.setEvApiKey(key);

  // ---------------------------------------------------------------------------
  // FavoriteStorage
  // ---------------------------------------------------------------------------
  @override
  List<String> getFavoriteIds() => _favorites.getFavoriteIds();
  @override
  Future<void> setFavoriteIds(List<String> ids) =>
      _favorites.setFavoriteIds(ids);
  @override
  Future<void> addFavorite(String id) => _favorites.addFavorite(id);
  @override
  Future<void> removeFavorite(String id) => _favorites.removeFavorite(id);
  @override
  bool isFavorite(String id) => _favorites.isFavorite(id);
  @override
  int get favoriteCount => _favorites.favoriteCount;
  @override
  Future<void> saveFavoriteStationData(
          String stationId, Map<String, dynamic> data) =>
      _favorites.saveFavoriteStationData(stationId, data);
  @override
  Map<String, dynamic>? getFavoriteStationData(String stationId) =>
      _favorites.getFavoriteStationData(stationId);
  @override
  Map<String, dynamic> getAllFavoriteStationData() =>
      _favorites.getAllFavoriteStationData();
  @override
  Future<void> removeFavoriteStationData(String stationId) =>
      _favorites.removeFavoriteStationData(stationId);

  // ---------------------------------------------------------------------------
  // IgnoredStorage
  // ---------------------------------------------------------------------------
  @override
  List<String> getIgnoredIds() => _favorites.getIgnoredIds();
  @override
  Future<void> setIgnoredIds(List<String> ids) =>
      _favorites.setIgnoredIds(ids);
  @override
  Future<void> addIgnored(String id) => _favorites.addIgnored(id);
  @override
  Future<void> removeIgnored(String id) => _favorites.removeIgnored(id);
  @override
  bool isIgnored(String id) => _favorites.isIgnored(id);

  // ---------------------------------------------------------------------------
  // RatingStorage
  // ---------------------------------------------------------------------------
  @override
  Map<String, int> getRatings() => _favorites.getRatings();
  @override
  Future<void> setRating(String stationId, int rating) =>
      _favorites.setRating(stationId, rating);
  @override
  Future<void> removeRating(String stationId) =>
      _favorites.removeRating(stationId);
  @override
  int? getRating(String stationId) => _favorites.getRating(stationId);

  // ---------------------------------------------------------------------------
  // ProfileStorage
  // ---------------------------------------------------------------------------
  @override
  String? getActiveProfileId() => _profiles.getActiveProfileId();
  @override
  Future<void> setActiveProfileId(String id) =>
      _profiles.setActiveProfileId(id);
  @override
  Map<String, dynamic>? getProfile(String id) => _profiles.getProfile(id);
  @override
  List<Map<String, dynamic>> getAllProfiles() => _profiles.getAllProfiles();
  @override
  Future<void> saveProfile(String id, Map<String, dynamic> profile) =>
      _profiles.saveProfile(id, profile);
  @override
  Future<void> deleteProfile(String id) => _profiles.deleteProfile(id);
  @override
  int get profileCount => _profiles.profileCount;

  // ---------------------------------------------------------------------------
  // CacheStorage
  // ---------------------------------------------------------------------------
  @override
  Future<void> cacheData(String key, dynamic data) =>
      _cache.cacheData(key, data);
  @override
  Map<String, dynamic>? getCachedData(String key, {Duration? maxAge}) =>
      _cache.getCachedData(key, maxAge: maxAge);
  @override
  Future<void> clearCache() => _cache.clearCache();
  @override
  Iterable<dynamic> get cacheKeys => _cache.cacheKeys;
  @override
  Future<void> deleteCacheEntry(String key) => _cache.deleteCacheEntry(key);
  @override
  int get cacheEntryCount => _cache.cacheEntryCount;

  // ---------------------------------------------------------------------------
  // ItineraryStorage
  // ---------------------------------------------------------------------------
  @override
  List<Map<String, dynamic>> getItineraries() => _cache.getItineraries();
  @override
  Future<void> saveItineraries(List<Map<String, dynamic>> itineraries) =>
      _cache.saveItineraries(itineraries);
  @override
  Future<void> addItinerary(Map<String, dynamic> itinerary) =>
      _cache.addItinerary(itinerary);
  @override
  Future<void> deleteItinerary(String id) => _cache.deleteItinerary(id);

  // ---------------------------------------------------------------------------
  // PriceHistoryStorage
  // ---------------------------------------------------------------------------
  @override
  Future<void> savePriceRecords(
          String stationId, List<Map<String, dynamic>> records) =>
      _priceHistory.savePriceRecords(stationId, records);
  @override
  List<Map<String, dynamic>> getPriceRecords(String stationId) =>
      _priceHistory.getPriceRecords(stationId);
  @override
  List<String> getPriceHistoryKeys() => _priceHistory.getPriceHistoryKeys();
  @override
  Future<void> clearPriceHistoryForStation(String stationId) =>
      _priceHistory.clearPriceHistoryForStation(stationId);
  @override
  Future<void> clearPriceHistory() => _priceHistory.clearPriceHistory();
  @override
  int get priceHistoryEntryCount => _priceHistory.priceHistoryEntryCount;

  // ---------------------------------------------------------------------------
  // AlertStorage
  // ---------------------------------------------------------------------------
  @override
  List<Map<String, dynamic>> getAlerts() => _alerts.getAlerts();
  @override
  Future<void> saveAlerts(List<Map<String, dynamic>> alerts) =>
      _alerts.saveAlerts(alerts);
  @override
  Future<void> clearAlerts() => _alerts.clearAlerts();
  @override
  int get alertCount => _alerts.alertCount;

  // ---------------------------------------------------------------------------
  // StorageRepository extras
  // ---------------------------------------------------------------------------
  @override
  ({int settings, int profiles, int favorites, int cache, int priceHistory, int alerts, int total})
      get storageStats {
    const avgEntryBytes = 512;
    final settingsBox = Hive.box(HiveBoxes.settings);
    final profilesBox = Hive.box(HiveBoxes.profiles);
    final favoritesBox = Hive.box(HiveBoxes.favorites);
    final cacheBox = Hive.box(HiveBoxes.cache);
    final priceHistoryBox = Hive.box(HiveBoxes.priceHistory);
    final alertsBox = Hive.box(HiveBoxes.alerts);

    final settings = settingsBox.length * avgEntryBytes;
    final profiles = profilesBox.length * avgEntryBytes;
    final favorites = favoritesBox.length * 64;
    final cache = cacheBox.length * 2048;
    final priceHistory = priceHistoryBox.length * 1024;
    final alerts = alertsBox.length * 256;
    return (
      settings: settings,
      profiles: profiles,
      favorites: favorites,
      cache: cache,
      priceHistory: priceHistory,
      alerts: alerts,
      total: settings + profiles + favorites + cache + priceHistory + alerts,
    );
  }
}
