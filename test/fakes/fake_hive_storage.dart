import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';

/// In-memory fake of [HiveStorage] for unit tests.
///
/// Replaces the previous `MockHiveStorage` (mocktail) for tests that exercise
/// real state transitions — write a value, read it back, mutate, etc. A mock
/// of a stateful repository does not track those transitions: a stub like
/// `when(storage.getFavoriteIds()).thenReturn(['x'])` does not update when
/// production code calls `addFavorite('y')`. Tests pass while production
/// breaks under genuine state changes.
///
/// This fake mirrors [HiveStorage] semantics by backing every domain in a
/// plain in-memory `Map`/`List`, with method bodies that match what the
/// production stores do (add/remove/clear, etc.).
///
/// Use [FakeStorageRepository] when you only need the [StorageRepository]
/// interface — it's an alias of this class with a narrower static type.
class FakeHiveStorage implements HiveStorage {
  // ---------------------------------------------------------------------------
  // Backing state
  // ---------------------------------------------------------------------------

  final List<String> _favorites = <String>[];
  final Map<String, Map<String, dynamic>> _favoriteData =
      <String, Map<String, dynamic>>{};

  final List<String> _evFavorites = <String>[];
  final Map<String, Map<String, dynamic>> _evFavoriteData =
      <String, Map<String, dynamic>>{};

  final List<String> _ignored = <String>[];
  final Map<String, int> _ratings = <String, int>{};
  final Map<String, dynamic> _settings = <String, dynamic>{};
  final Map<String, Map<String, dynamic>> _profiles =
      <String, Map<String, dynamic>>{};

  final Map<String, dynamic> _cacheRaw = <String, dynamic>{};
  final Map<String, DateTime> _cacheTimestamps = <String, DateTime>{};

  final Map<String, List<Map<String, dynamic>>> _priceHistory =
      <String, List<Map<String, dynamic>>>{};

  List<Map<String, dynamic>> _alerts = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _itineraries = <Map<String, dynamic>>[];

  bool _isSetupComplete = false;
  bool _isSetupSkipped = false;

  String? _apiKey;
  String? _evApiKey;
  String? _supabaseAnonKey;

  /// If true, [hasApiKey] returns true even with no key — mirrors the
  /// real behaviour where the bundled community key counts (#521).
  /// Default true keeps parity with the in-memory test doubles that
  /// previously lived inline in test files.
  bool hasBundledDefaultKey = true;

  // ---------------------------------------------------------------------------
  // SettingsStorage
  // ---------------------------------------------------------------------------

  @override
  dynamic getSetting(String key) => _settings[key];

  @override
  Future<void> putSetting(String key, dynamic value) async {
    _settings[key] = value;
  }

  @override
  bool get isSetupComplete => _isSetupComplete;

  @override
  bool get isSetupSkipped => _isSetupSkipped;

  @override
  Future<void> skipSetup() async {
    _isSetupSkipped = true;
  }

  @override
  Future<void> resetSetupSkip() async {
    _isSetupSkipped = false;
  }

  /// Test helper: flip the setup-complete flag (production sets this via
  /// the wizard finishing). No equivalent exists on real [HiveStorage].
  void setSetupComplete(bool value) {
    _isSetupComplete = value;
  }

  // ---------------------------------------------------------------------------
  // ApiKeyStorage
  // ---------------------------------------------------------------------------

  @override
  String? getApiKey() => _apiKey;

  @override
  Future<void> setApiKey(String key) async {
    _apiKey = key;
  }

  @override
  Future<void> deleteApiKey() async {
    _apiKey = null;
  }

  @override
  bool hasApiKey() => _apiKey != null || hasBundledDefaultKey;

  @override
  bool hasCustomApiKey() => _apiKey != null;

  @override
  String? getEvApiKey() => _evApiKey;

  @override
  bool hasEvApiKey() => _evApiKey != null;

  @override
  bool hasCustomEvApiKey() => _evApiKey != null;

  @override
  Future<void> setEvApiKey(String key) async {
    _evApiKey = key;
  }

  @override
  String? getSupabaseAnonKey() => _supabaseAnonKey;

  @override
  Future<void> setSupabaseAnonKey(String key) async {
    _supabaseAnonKey = key;
  }

  @override
  Future<void> deleteSupabaseAnonKey() async {
    _supabaseAnonKey = null;
  }

  // ---------------------------------------------------------------------------
  // FavoriteStorage
  // ---------------------------------------------------------------------------

  @override
  List<String> getFavoriteIds() => List<String>.from(_favorites);

  @override
  Future<void> setFavoriteIds(List<String> ids) async {
    _favorites
      ..clear()
      ..addAll(ids);
  }

  @override
  Future<void> addFavorite(String id) async {
    if (!_favorites.contains(id)) _favorites.add(id);
  }

  @override
  Future<void> removeFavorite(String id) async {
    _favorites.remove(id);
  }

  @override
  bool isFavorite(String id) => _favorites.contains(id);

  @override
  int get favoriteCount => _favorites.length;

  @override
  Future<void> saveFavoriteStationData(
      String stationId, Map<String, dynamic> data) async {
    _favoriteData[stationId] = Map<String, dynamic>.from(data);
  }

  @override
  Map<String, dynamic>? getFavoriteStationData(String stationId) {
    final data = _favoriteData[stationId];
    return data == null ? null : Map<String, dynamic>.from(data);
  }

  @override
  Map<String, dynamic> getAllFavoriteStationData() =>
      Map<String, dynamic>.from(_favoriteData);

  @override
  Future<void> removeFavoriteStationData(String stationId) async {
    _favoriteData.remove(stationId);
  }

  // ---------------------------------------------------------------------------
  // EvFavoriteStorage
  // ---------------------------------------------------------------------------

  @override
  List<String> getEvFavoriteIds() => List<String>.from(_evFavorites);

  @override
  Future<void> setEvFavoriteIds(List<String> ids) async {
    _evFavorites
      ..clear()
      ..addAll(ids);
  }

  @override
  Future<void> addEvFavorite(String id) async {
    if (!_evFavorites.contains(id)) _evFavorites.add(id);
  }

  @override
  Future<void> removeEvFavorite(String id) async {
    _evFavorites.remove(id);
  }

  @override
  bool isEvFavorite(String id) => _evFavorites.contains(id);

  @override
  int get evFavoriteCount => _evFavorites.length;

  @override
  Future<void> saveEvFavoriteStationData(
      String stationId, Map<String, dynamic> data) async {
    _evFavoriteData[stationId] = Map<String, dynamic>.from(data);
  }

  @override
  Map<String, dynamic>? getEvFavoriteStationData(String stationId) {
    final data = _evFavoriteData[stationId];
    return data == null ? null : Map<String, dynamic>.from(data);
  }

  @override
  Future<void> removeEvFavoriteStationData(String stationId) async {
    _evFavoriteData.remove(stationId);
  }

  // ---------------------------------------------------------------------------
  // IgnoredStorage
  // ---------------------------------------------------------------------------

  @override
  List<String> getIgnoredIds() => List<String>.from(_ignored);

  @override
  Future<void> setIgnoredIds(List<String> ids) async {
    _ignored
      ..clear()
      ..addAll(ids);
  }

  @override
  Future<void> addIgnored(String id) async {
    if (!_ignored.contains(id)) _ignored.add(id);
  }

  @override
  Future<void> removeIgnored(String id) async {
    _ignored.remove(id);
  }

  @override
  bool isIgnored(String id) => _ignored.contains(id);

  // ---------------------------------------------------------------------------
  // RatingStorage
  // ---------------------------------------------------------------------------

  @override
  Map<String, int> getRatings() => Map<String, int>.from(_ratings);

  @override
  Future<void> setRating(String stationId, int rating) async {
    _ratings[stationId] = rating;
  }

  @override
  Future<void> removeRating(String stationId) async {
    _ratings.remove(stationId);
  }

  @override
  int? getRating(String stationId) => _ratings[stationId];

  // ---------------------------------------------------------------------------
  // ProfileStorage
  // ---------------------------------------------------------------------------

  @override
  String? getActiveProfileId() => _settings['active_profile_id'] as String?;

  @override
  Future<void> setActiveProfileId(String id) async {
    _settings['active_profile_id'] = id;
  }

  @override
  Map<String, dynamic>? getProfile(String id) {
    final p = _profiles[id];
    return p == null ? null : Map<String, dynamic>.from(p);
  }

  @override
  List<Map<String, dynamic>> getAllProfiles() => _profiles.values
      .map((p) => Map<String, dynamic>.from(p))
      .toList(growable: false);

  @override
  Future<void> saveProfile(String id, Map<String, dynamic> profile) async {
    _profiles[id] = Map<String, dynamic>.from(profile);
  }

  @override
  Future<void> deleteProfile(String id) async {
    _profiles.remove(id);
  }

  @override
  int get profileCount => _profiles.length;

  // ---------------------------------------------------------------------------
  // CacheStorage
  // ---------------------------------------------------------------------------

  @override
  Future<void> cacheData(String key, dynamic data) async {
    _cacheRaw[key] = data;
    _cacheTimestamps[key] = DateTime.now();
  }

  @override
  Map<String, dynamic>? getCachedData(String key, {Duration? maxAge}) {
    final raw = _cacheRaw[key];
    if (raw == null) return null;
    if (maxAge != null) {
      final ts = _cacheTimestamps[key];
      if (ts == null) return null;
      if (DateTime.now().difference(ts) > maxAge) return null;
    }
    if (raw is Map) return Map<String, dynamic>.from(raw);
    // Mirror real Hive behaviour: if a non-map slipped in, surface it
    // wrapped under a single key so the caller sees something.
    return <String, dynamic>{'value': raw};
  }

  @override
  Future<void> clearCache() async {
    _cacheRaw.clear();
    _cacheTimestamps.clear();
  }

  @override
  Iterable<dynamic> get cacheKeys => List<dynamic>.from(_cacheRaw.keys);

  @override
  Future<void> deleteCacheEntry(String key) async {
    _cacheRaw.remove(key);
    _cacheTimestamps.remove(key);
  }

  @override
  int get cacheEntryCount => _cacheRaw.length;

  // ---------------------------------------------------------------------------
  // ItineraryStorage
  // ---------------------------------------------------------------------------

  @override
  List<Map<String, dynamic>> getItineraries() =>
      _itineraries.map((i) => Map<String, dynamic>.from(i)).toList();

  @override
  Future<void> saveItineraries(
      List<Map<String, dynamic>> itineraries) async {
    _itineraries =
        itineraries.map((i) => Map<String, dynamic>.from(i)).toList();
  }

  @override
  Future<void> addItinerary(Map<String, dynamic> itinerary) async {
    _itineraries.add(Map<String, dynamic>.from(itinerary));
  }

  @override
  Future<void> deleteItinerary(String id) async {
    _itineraries.removeWhere((i) => i['id'] == id);
  }

  // ---------------------------------------------------------------------------
  // PriceHistoryStorage
  // ---------------------------------------------------------------------------

  @override
  Future<void> savePriceRecords(
      String stationId, List<Map<String, dynamic>> records) async {
    _priceHistory[stationId] =
        records.map((r) => Map<String, dynamic>.from(r)).toList();
  }

  @override
  List<Map<String, dynamic>> getPriceRecords(String stationId) =>
      _priceHistory[stationId]
          ?.map((r) => Map<String, dynamic>.from(r))
          .toList() ??
      <Map<String, dynamic>>[];

  @override
  List<String> getPriceHistoryKeys() => _priceHistory.keys.toList();

  @override
  Future<void> clearPriceHistoryForStation(String stationId) async {
    _priceHistory.remove(stationId);
  }

  @override
  Future<void> clearPriceHistory() async {
    _priceHistory.clear();
  }

  @override
  int get priceHistoryEntryCount =>
      _priceHistory.values.fold<int>(0, (sum, list) => sum + list.length);

  // ---------------------------------------------------------------------------
  // AlertStorage
  // ---------------------------------------------------------------------------

  @override
  List<Map<String, dynamic>> getAlerts() =>
      _alerts.map((a) => Map<String, dynamic>.from(a)).toList();

  @override
  Future<void> saveAlerts(List<Map<String, dynamic>> alerts) async {
    _alerts = alerts.map((a) => Map<String, dynamic>.from(a)).toList();
  }

  @override
  Future<void> clearAlerts() async {
    _alerts.clear();
  }

  @override
  int get alertCount => _alerts.length;

  // ---------------------------------------------------------------------------
  // StorageRepository extras
  // ---------------------------------------------------------------------------

  /// Test helper: tweak the bytes returned by [storageStats] / [boxSizeBytes].
  /// Defaults to a fixed 1024-bytes-per-non-empty-domain so tests don't have
  /// to set this up by default.
  int Function(String box)? statsOverride;

  @override
  ({
    int settings,
    int profiles,
    int favorites,
    int cache,
    int priceHistory,
    int alerts,
    int total
  }) get storageStats {
    final settings = boxSizeBytes('settings', fallbackPerEntry: 0);
    final profiles = boxSizeBytes('profiles', fallbackPerEntry: 0);
    final favorites = boxSizeBytes('favorites', fallbackPerEntry: 0);
    final cache = boxSizeBytes('cache', fallbackPerEntry: 0);
    final priceHistory = boxSizeBytes('priceHistory', fallbackPerEntry: 0);
    final alerts = boxSizeBytes('alerts', fallbackPerEntry: 0);
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

  @override
  int boxSizeBytes(String boxName, {required int fallbackPerEntry}) {
    if (statsOverride != null) return statsOverride!(boxName);
    // Best-effort approximation: count entries in the matching domain
    // and multiply by [fallbackPerEntry]. Tests that care about exact
    // byte counts should set [statsOverride].
    int entries;
    switch (boxName) {
      case 'settings':
        entries = _settings.length;
        break;
      case 'profiles':
        entries = _profiles.length;
        break;
      case 'favorites':
        entries = _favorites.length + _favoriteData.length;
        break;
      case 'cache':
        entries = _cacheRaw.length;
        break;
      case 'priceHistory':
        entries = _priceHistory.length;
        break;
      case 'alerts':
        entries = _alerts.length;
        break;
      default:
        entries = 0;
    }
    return entries * fallbackPerEntry;
  }
}
