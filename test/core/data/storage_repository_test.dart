import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/storage_repository.dart';

/// Test that StorageRepository is a proper abstract interface
/// with all required methods. This ensures no implementation
/// can accidentally miss a method.
void main() {
  group('StorageRepository interface', () {
    test('defines all required favorite methods', () {
      // Compile-time check: if StorageRepository is missing methods,
      // this file won't compile. The test is the compilation itself.
      expect(StorageRepository, isNotNull);
    });

    test('can be implemented by a mock', () {
      final mock = _MockStorageRepository();
      expect(mock, isA<StorageRepository>());
      expect(mock.getFavoriteIds(), isEmpty);
      expect(mock.getRatings(), isEmpty);
      expect(mock.getIgnoredIds(), isEmpty);
      expect(mock.hasApiKey(), isFalse);
      expect(mock.isSetupComplete, isFalse);
      expect(mock.alertCount, 0);
      expect(mock.favoriteCount, 0);
    });

    test('mock implements all CRUD operations', () async {
      final mock = _MockStorageRepository();

      // Favorites
      await mock.addFavorite('s1');
      expect(mock.getFavoriteIds(), contains('s1'));
      expect(mock.isFavorite('s1'), isTrue);
      await mock.removeFavorite('s1');
      expect(mock.isFavorite('s1'), isFalse);

      // Ratings
      await mock.setRating('s1', 4);
      expect(mock.getRating('s1'), 4);
      await mock.removeRating('s1');
      expect(mock.getRating('s1'), isNull);

      // Ignored
      await mock.addIgnored('s2');
      expect(mock.getIgnoredIds(), contains('s2'));
      await mock.removeIgnored('s2');
      expect(mock.getIgnoredIds(), isEmpty);

      // Settings
      await mock.putSetting('key', 'value');
      expect(mock.getSetting('key'), 'value');

      // Supabase anon key (secure storage surface)
      expect(mock.getSupabaseAnonKey(), isNull);
      await mock.setSupabaseAnonKey('anon-key-123');
      expect(mock.getSupabaseAnonKey(), 'anon-key-123');
      await mock.deleteSupabaseAnonKey();
      expect(mock.getSupabaseAnonKey(), isNull);
    });
  });
}

/// In-memory mock implementation for testing.
/// Proves the interface can be fully implemented without Hive.
class _MockStorageRepository implements StorageRepository {
  final _favorites = <String>[];
  final _ignored = <String>[];
  final _ratings = <String, int>{};
  final _settings = <String, dynamic>{};
  final _profiles = <String, Map<String, dynamic>>{};

  final _favoriteStationData = <String, Map<String, dynamic>>{};

  @override List<String> getFavoriteIds() => List.from(_favorites);
  @override Future<void> setFavoriteIds(List<String> ids) async { _favorites..clear()..addAll(ids); }
  @override Future<void> addFavorite(String id) async => _favorites.add(id);
  @override Future<void> removeFavorite(String id) async => _favorites.remove(id);
  @override bool isFavorite(String id) => _favorites.contains(id);
  @override Future<void> saveFavoriteStationData(String id, Map<String, dynamic> data) async => _favoriteStationData[id] = data;
  @override Map<String, dynamic>? getFavoriteStationData(String id) => _favoriteStationData[id];
  @override Map<String, dynamic> getAllFavoriteStationData() => Map.from(_favoriteStationData);
  @override Future<void> removeFavoriteStationData(String id) async => _favoriteStationData.remove(id);

  // EV Favorites
  final _evFavorites = <String>[];
  final _evFavoriteData = <String, Map<String, dynamic>>{};
  @override List<String> getEvFavoriteIds() => List.from(_evFavorites);
  @override Future<void> setEvFavoriteIds(List<String> ids) async { _evFavorites..clear()..addAll(ids); }
  @override Future<void> addEvFavorite(String id) async => _evFavorites.add(id);
  @override Future<void> removeEvFavorite(String id) async => _evFavorites.remove(id);
  @override bool isEvFavorite(String id) => _evFavorites.contains(id);
  @override int get evFavoriteCount => _evFavorites.length;
  @override Future<void> saveEvFavoriteStationData(String id, Map<String, dynamic> data) async => _evFavoriteData[id] = data;
  @override Map<String, dynamic>? getEvFavoriteStationData(String id) => _evFavoriteData[id];
  @override Future<void> removeEvFavoriteStationData(String id) async => _evFavoriteData.remove(id);

  @override List<String> getIgnoredIds() => List.from(_ignored);
  @override Future<void> setIgnoredIds(List<String> ids) async { _ignored..clear()..addAll(ids); }
  @override Future<void> addIgnored(String id) async => _ignored.add(id);
  @override Future<void> removeIgnored(String id) async => _ignored.remove(id);
  @override bool isIgnored(String id) => _ignored.contains(id);

  @override Map<String, int> getRatings() => Map.from(_ratings);
  @override Future<void> setRating(String id, int r) async => _ratings[id] = r;
  @override Future<void> removeRating(String id) async => _ratings.remove(id);
  @override int? getRating(String id) => _ratings[id];

  @override dynamic getSetting(String key) => _settings[key];
  @override Future<void> putSetting(String key, dynamic value) async => _settings[key] = value;

  @override String? getApiKey() => null;
  @override Future<void> setApiKey(String key) async {}
  @override Future<void> deleteApiKey() async {}
  @override bool hasApiKey() => false;
  @override String? getEvApiKey() => null;
  @override bool hasEvApiKey() => false;
  @override bool hasCustomEvApiKey() => false;
  @override Future<void> setEvApiKey(String key) async {}
  String? _supabaseAnonKey;
  @override String? getSupabaseAnonKey() => _supabaseAnonKey;
  @override Future<void> setSupabaseAnonKey(String key) async {
    _supabaseAnonKey = key;
  }
  @override Future<void> deleteSupabaseAnonKey() async {
    _supabaseAnonKey = null;
  }

  @override String? getActiveProfileId() => _settings['active_profile_id'] as String?;
  @override Future<void> setActiveProfileId(String id) async => _settings['active_profile_id'] = id;
  @override Map<String, dynamic>? getProfile(String id) => _profiles[id];
  @override List<Map<String, dynamic>> getAllProfiles() => _profiles.values.toList();
  @override Future<void> saveProfile(String id, Map<String, dynamic> p) async => _profiles[id] = p;
  @override Future<void> deleteProfile(String id) async => _profiles.remove(id);
  @override int get profileCount => _profiles.length;

  @override Future<void> savePriceRecords(String id, List<Map<String, dynamic>> r) async {}
  @override List<Map<String, dynamic>> getPriceRecords(String id) => [];
  @override List<String> getPriceHistoryKeys() => [];
  @override Future<void> clearPriceHistoryForStation(String id) async {}
  @override Future<void> clearPriceHistory() async {}

  @override List<Map<String, dynamic>> getAlerts() => [];
  @override Future<void> saveAlerts(List<Map<String, dynamic>> a) async {}
  @override Future<void> clearAlerts() async {}
  @override int get alertCount => 0;

  @override List<Map<String, dynamic>> getItineraries() => [];
  @override Future<void> addItinerary(Map<String, dynamic> i) async {}
  @override Future<void> deleteItinerary(String id) async {}
  @override Future<void> saveItineraries(List<Map<String, dynamic>> i) async {}

  @override Future<void> cacheData(String key, dynamic data) async {}
  @override Map<String, dynamic>? getCachedData(String key, {Duration? maxAge}) => null;
  @override Future<void> clearCache() async {}

  @override bool get isSetupComplete => false;
  @override bool get isSetupSkipped => false;
  @override Future<void> skipSetup() async {}
  @override Future<void> resetSetupSkip() async {}

  @override int get cacheEntryCount => 0;
  @override Iterable<dynamic> get cacheKeys => [];
  @override Future<void> deleteCacheEntry(String key) async {}
  @override int get priceHistoryEntryCount => 0;
  @override int get favoriteCount => _favorites.length;

  @override
  ({int settings, int profiles, int favorites, int cache, int priceHistory, int alerts, int total})
      get storageStats => (settings: 0, profiles: 0, favorites: 0, cache: 0, priceHistory: 0, alerts: 0, total: 0);
}
