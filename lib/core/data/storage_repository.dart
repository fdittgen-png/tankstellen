/// Abstract interface for local data persistence.
///
/// ## Reusability
/// This interface decouples the app from any specific storage implementation
/// (Hive, SharedPreferences, SQLite, etc.). Any app can implement this
/// interface with their preferred storage backend.
///
/// ## Car Platform Compatibility
/// Android Auto and CarPlay run in separate processes. This interface
/// enables a MethodChannel-based implementation that bridges to the
/// main app's storage without importing Hive in the car process.
///
/// ## Huawei HMS Compatibility
/// No Google Play Services dependency — pure local storage abstraction.
abstract class StorageRepository {
  // ── API Keys ──
  String? getApiKey();
  Future<void> setApiKey(String key);
  Future<void> deleteApiKey();
  bool hasApiKey();
  String? getEvApiKey();

  // ── Favorites ──
  List<String> getFavoriteIds();
  Future<void> addFavorite(String id);
  Future<void> removeFavorite(String id);
  bool isFavorite(String id);

  // ── Ignored Stations ──
  List<String> getIgnoredIds();
  Future<void> addIgnored(String id);
  Future<void> removeIgnored(String id);

  // ── Ratings ──
  Map<String, int> getRatings();
  Future<void> setRating(String stationId, int rating);
  Future<void> removeRating(String stationId);
  int? getRating(String stationId);

  // ── Settings ──
  dynamic getSetting(String key);
  Future<void> putSetting(String key, dynamic value);

  // ── Profile ──
  String? getActiveProfileId();
  Future<void> setActiveProfileId(String id);
  Map<String, dynamic>? getProfile(String id);
  List<Map<String, dynamic>> getAllProfiles();
  Future<void> saveProfile(String id, Map<String, dynamic> profile);
  Future<void> deleteProfile(String id);

  // ── Price History ──
  Future<void> savePriceRecords(String stationId, List<Map<String, dynamic>> records);
  List<Map<String, dynamic>> getPriceRecords(String stationId);
  List<String> getPriceHistoryKeys();
  Future<void> clearPriceHistoryForStation(String stationId);
  Future<void> clearPriceHistory();

  // ── Alerts ──
  List<Map<String, dynamic>> getAlerts();
  Future<void> saveAlerts(List<Map<String, dynamic>> alerts);
  Future<void> clearAlerts();
  int get alertCount;

  // ── Itineraries ──
  List<Map<String, dynamic>> getItineraries();
  Future<void> addItinerary(Map<String, dynamic> itinerary);
  Future<void> deleteItinerary(String id);

  // ── Cache ──
  Future<void> cacheData(String key, dynamic data);
  Map<String, dynamic>? getCachedData(String key, {Duration? maxAge});
  Future<void> clearCache();

  // ── Setup State ──
  bool get isSetupComplete;
  bool get isSetupSkipped;
  Future<void> skipSetup();

  // ── Stats ──
  int get cacheEntryCount;
  int get priceHistoryEntryCount;
  int get favoriteCount;
}
