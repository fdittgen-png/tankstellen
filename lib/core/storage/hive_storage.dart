import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../constants/app_constants.dart';
import '../data/storage_repository.dart';
import 'storage_keys.dart';

part 'hive_storage.g.dart';

@Riverpod(keepAlive: true)
HiveStorage hiveStorage(Ref ref) {
  return HiveStorage();
}

class HiveStorage implements StorageRepository {
  static const String _settingsBox = 'settings';
  static const String _favoritesBox = 'favorites';
  static const String _cacheBox = 'cache';
  static const String _profilesBox = 'profiles';
  static const String _priceHistoryBox = 'price_history';
  static const String _alertsBox = 'alerts';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_settingsBox);
    await Hive.openBox(_favoritesBox);
    await Hive.openBox(_cacheBox);
    await Hive.openBox(_profilesBox);
    await Hive.openBox(_priceHistoryBox);
    await Hive.openBox(_alertsBox);
  }

  Box get _settings => Hive.box(_settingsBox);
  Box get _favorites => Hive.box(_favoritesBox);
  Box get _cache => Hive.box(_cacheBox);
  Box get _profiles => Hive.box(_profilesBox);
  Box get _priceHistory => Hive.box(_priceHistoryBox);
  Box get _alerts => Hive.box(_alertsBox);

  // Generic settings access (used by TraceUploader config, etc.)
  dynamic getSetting(String key) => _settings.get(key);
  Future<void> putSetting(String key, dynamic value) =>
      _settings.put(key, value);

  // API Key — stored in platform secure enclave, NOT in plain Hive.
  // On Android: Android Keystore. On Windows: DPAPI. On iOS: Keychain.
  static const _secureStorage = FlutterSecureStorage();

  // In-memory cache to avoid async reads on every API call.
  static String? _apiKeyCache;

  /// Load API key from secure storage into memory. Call once at startup.
  static Future<void> loadApiKey() async {
    _apiKeyCache = await _secureStorage.read(key: StorageKeys.apiKey);
    await loadEvApiKey();
  }

  String? getApiKey() => _apiKeyCache;

  Future<void> setApiKey(String key) async {
    await _secureStorage.write(key: StorageKeys.apiKey, value: key);
    _apiKeyCache = key;
  }

  Future<void> deleteApiKey() async {
    await _secureStorage.delete(key: StorageKeys.apiKey);
    _apiKeyCache = null;
  }

  bool hasApiKey() {
    final key = getApiKey();
    return key != null && key.isNotEmpty;
  }

  // EV Charging API key (OpenChargeMap)
  static String? _evApiKeyCache;

  static Future<void> loadEvApiKey() async {
    _evApiKeyCache = await _secureStorage.read(key: StorageKeys.evApiKey);
  }

  String? getEvApiKey() => _evApiKeyCache ?? AppConstants.openChargeMapApiKey;

  bool hasEvApiKey() => true; // Always true since we have a default key

  bool hasCustomEvApiKey() => _evApiKeyCache != null && _evApiKeyCache!.isNotEmpty;

  Future<void> setEvApiKey(String key) async {
    await _secureStorage.write(key: StorageKeys.evApiKey, value: key);
    _evApiKeyCache = key;
  }

  // Setup skip (demo mode)
  bool get isSetupComplete =>
      hasApiKey() ||
      (_settings.get(StorageKeys.setupSkipped) == true);

  bool get isSetupSkipped =>
      _settings.get(StorageKeys.setupSkipped) == true;

  Future<void> skipSetup() =>
      _settings.put(StorageKeys.setupSkipped, true);

  Future<void> resetSetupSkip() =>
      _settings.delete(StorageKeys.setupSkipped);

  // Active Profile
  String? getActiveProfileId() =>
      _settings.get(StorageKeys.activeProfileId) as String?;
  Future<void> setActiveProfileId(String id) =>
      _settings.put(StorageKeys.activeProfileId, id);

  // Profiles
  Map<String, dynamic>? getProfile(String id) {
    final data = _profiles.get(id);
    return _toStringDynamicMap(data);
  }

  List<Map<String, dynamic>> getAllProfiles() {
    return _profiles.values
        .map((e) => _toStringDynamicMap(e))
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  Future<void> saveProfile(String id, Map<String, dynamic> profile) =>
      _profiles.put(id, profile);

  Future<void> deleteProfile(String id) => _profiles.delete(id);

  // Favorites
  List<String> getFavoriteIds() {
    final ids = _favorites.get(StorageKeys.favoriteStationIds);
    if (ids == null) return [];
    return List<String>.from(ids as List);
  }

  Future<void> setFavoriteIds(List<String> ids) =>
      _favorites.put(StorageKeys.favoriteStationIds, ids);

  Future<void> addFavorite(String id) async {
    final ids = getFavoriteIds();
    if (!ids.contains(id)) {
      ids.add(id);
      await setFavoriteIds(ids);
    }
  }

  Future<void> removeFavorite(String id) async {
    final ids = getFavoriteIds();
    ids.remove(id);
    await setFavoriteIds(ids);
  }

  bool isFavorite(String id) => getFavoriteIds().contains(id);

  // Favorite Station Data (permanent, never expires)

  /// Persist full station JSON for a favorite.
  Future<void> saveFavoriteStationData(String stationId, Map<String, dynamic> data) async {
    final all = _getFavoriteStationDataRaw();
    all[stationId] = data;
    await _favorites.put(StorageKeys.favoriteStationData, all);
  }

  /// Get persisted station JSON for a single favorite.
  Map<String, dynamic>? getFavoriteStationData(String stationId) {
    final raw = _getFavoriteStationDataRaw()[stationId];
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  /// Get all persisted favorite station data.
  Map<String, dynamic> getAllFavoriteStationData() => _getFavoriteStationDataRaw();

  /// Remove persisted station data when unfavoriting.
  Future<void> removeFavoriteStationData(String stationId) async {
    final all = _getFavoriteStationDataRaw();
    all.remove(stationId);
    await _favorites.put(StorageKeys.favoriteStationData, all);
  }

  Map<String, dynamic> _getFavoriteStationDataRaw() {
    final raw = _favorites.get(StorageKeys.favoriteStationData);
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {};
  }

  // Ignored Stations
  List<String> getIgnoredIds() {
    final ids = _favorites.get(StorageKeys.ignoredStationIds);
    if (ids == null) return [];
    return List<String>.from(ids as List);
  }

  Future<void> setIgnoredIds(List<String> ids) =>
      _favorites.put(StorageKeys.ignoredStationIds, ids);

  Future<void> addIgnored(String id) async {
    final ids = getIgnoredIds();
    if (!ids.contains(id)) {
      ids.add(id);
      await setIgnoredIds(ids);
    }
  }

  Future<void> removeIgnored(String id) async {
    final ids = getIgnoredIds();
    ids.remove(id);
    await setIgnoredIds(ids);
  }

  bool isIgnored(String id) => getIgnoredIds().contains(id);

  // Station Ratings (1-5 stars)
  Map<String, int> getRatings() {
    final data = _favorites.get(StorageKeys.stationRatings);
    if (data == null) return {};
    if (data is Map) {
      return Map<String, int>.fromEntries(
        data.entries.map((e) => MapEntry(e.key.toString(), (e.value as num).toInt())),
      );
    }
    return {};
  }

  Future<void> setRating(String stationId, int rating) async {
    final ratings = getRatings();
    ratings[stationId] = rating;
    await _favorites.put(StorageKeys.stationRatings, ratings);
  }

  Future<void> removeRating(String stationId) async {
    final ratings = getRatings();
    ratings.remove(stationId);
    await _favorites.put(StorageKeys.stationRatings, ratings);
  }

  int? getRating(String stationId) => getRatings()[stationId];

  // Cache
  Future<void> cacheData(String key, dynamic data) async {
    await _cache.put(key, {
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Map<String, dynamic>? getCachedData(String key, {Duration? maxAge}) {
    final cached = _cache.get(key);
    if (cached == null) return null;

    // Hive on Android returns _Map<dynamic, dynamic> — must deep-convert
    final map = _toStringDynamicMap(cached);
    if (map == null) return null;

    if (maxAge != null) {
      final timestamp = map['timestamp'] as int?;
      if (timestamp != null) {
        final age = DateTime.now().millisecondsSinceEpoch - timestamp;
        if (age > maxAge.inMilliseconds) return null;
      }
    }
    final data = map['data'];
    if (data is Map) return _toStringDynamicMap(data);
    return null;
  }

  Future<void> clearCache() => _cache.clear();

  /// All cache keys, for eviction iteration.
  Iterable<dynamic> get cacheKeys => _cache.keys;

  /// Delete a specific cache entry by key.
  Future<void> deleteCacheEntry(String key) => _cache.delete(key);

  // Price History
  Future<void> savePriceRecords(
      String stationId, List<Map<String, dynamic>> records) =>
      _priceHistory.put(stationId, records);

  List<Map<String, dynamic>> getPriceRecords(String stationId) {
    final data = _priceHistory.get(stationId);
    if (data == null) return [];
    return (data as List)
        .map((e) => _toStringDynamicMap(e))
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  /// Returns all station IDs that have price history records.
  List<String> getPriceHistoryKeys() =>
      _priceHistory.keys.cast<String>().toList();

  /// Clear price history for a single station.
  Future<void> clearPriceHistoryForStation(String stationId) =>
      _priceHistory.delete(stationId);

  /// Clear all price history data.
  Future<void> clearPriceHistory() => _priceHistory.clear();

  // Price Alerts
  List<Map<String, dynamic>> getAlerts() {
    final data = _alerts.get('alerts');
    if (data == null) return [];
    return (data as List)
        .map((e) => _toStringDynamicMap(e))
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  Future<void> saveAlerts(List<Map<String, dynamic>> alerts) =>
      _alerts.put('alerts', alerts);

  Future<void> clearAlerts() => _alerts.clear();

  int get alertCount => getAlerts().length;

  // Itineraries (local-first storage)
  List<Map<String, dynamic>> getItineraries() {
    final data = _cache.get('itineraries');
    if (data == null) return [];
    return (data as List)
        .map((e) => _toStringDynamicMap(e))
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  Future<void> saveItineraries(List<Map<String, dynamic>> itineraries) =>
      _cache.put('itineraries', itineraries);

  Future<void> addItinerary(Map<String, dynamic> itinerary) async {
    final list = getItineraries();
    // Replace if same id, otherwise add
    final idx = list.indexWhere((i) => i['id'] == itinerary['id']);
    if (idx >= 0) {
      list[idx] = itinerary;
    } else {
      list.insert(0, itinerary);
    }
    await saveItineraries(list);
  }

  Future<void> deleteItinerary(String id) async {
    final list = getItineraries();
    list.removeWhere((i) => i['id'] == id);
    await saveItineraries(list);
  }

  // Storage statistics
  int get cacheEntryCount => _cache.length;
  int get profileCount => _profiles.length;
  int get favoriteCount => getFavoriteIds().length;

  /// Estimated total storage size across all Hive boxes (bytes).
  /// Hive doesn't expose exact file sizes, so we estimate from entry count
  /// and a conservative avg bytes per entry.
  int get priceHistoryEntryCount => _priceHistory.length;

  ({int settings, int profiles, int favorites, int cache, int priceHistory, int alerts, int total})
      get storageStats {
    // Rough estimate: Hive overhead + serialized JSON per entry
    const avgEntryBytes = 512; // conservative average
    final settings = _settings.length * avgEntryBytes;
    final profiles = _profiles.length * avgEntryBytes;
    final favorites = _favorites.length * 64; // just IDs, small
    final cache = _cache.length * 2048; // cache entries are larger (full JSON)
    final priceHistory = _priceHistory.length * 1024; // mid-size lists
    final alerts = _alerts.length * 256; // small alert objects
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

  /// Safely converts any Hive map to a typed map.
  /// Returns null if input is not a Map.
  static Map<String, dynamic>? _toStringDynamicMap(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return _deepConvert(value);
    if (value is Map) {
      return _deepConvert(Map<String, dynamic>.fromEntries(
        value.entries.map((e) => MapEntry(e.key.toString(), e.value)),
      ));
    }
    return null;
  }

  /// Recursively convert nested Hive `_Map` to `Map<String, dynamic>`.
  static Map<String, dynamic> _deepConvert(Map<String, dynamic> map) {
    return map.map((key, value) {
      if (value is Map && value is! Map<String, dynamic>) {
        return MapEntry(key, _toStringDynamicMap(value));
      }
      if (value is List) {
        return MapEntry(key, value.map((e) {
          if (e is Map) return _toStringDynamicMap(e);
          return e;
        }).toList());
      }
      return MapEntry(key, value);
    });
  }
}
