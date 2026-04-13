import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/core/storage/storage_providers.dart';

class _MockHiveStorage extends Mock implements HiveStorage {}

void main() {
  group('storageRepositoryProvider', () {
    test('returns a StorageRepository', () {
      final mock = _MockHiveStorage();
      final container = ProviderContainer(overrides: [
        hiveStorageProvider.overrideWithValue(mock),
      ]);
      addTearDown(container.dispose);

      final repo = container.read(storageRepositoryProvider);
      expect(repo, isA<StorageRepository>());
      expect(repo, same(mock));
    });

    test('propagates hiveStorageProvider override', () {
      final mock = _MockHiveStorage();
      when(() => mock.hasApiKey()).thenReturn(true);
      when(() => mock.getFavoriteIds()).thenReturn(['s1', 's2']);

      final container = ProviderContainer(overrides: [
        hiveStorageProvider.overrideWithValue(mock),
      ]);
      addTearDown(container.dispose);

      final repo = container.read(storageRepositoryProvider);
      expect(repo.hasApiKey(), isTrue);
      expect(repo.getFavoriteIds(), ['s1', 's2']);
    });

    test('can be overridden directly with MockStorageRepository', () {
      final mock = _MockStorageRepository();
      when(() => mock.isSetupComplete).thenReturn(true);
      when(() => mock.getFavoriteIds()).thenReturn(['x']);

      final container = ProviderContainer(overrides: [
        storageRepositoryProvider.overrideWithValue(mock),
      ]);
      addTearDown(container.dispose);

      final repo = container.read(storageRepositoryProvider);
      expect(repo.isSetupComplete, isTrue);
      expect(repo.getFavoriteIds(), ['x']);
    });
  });

  group('narrow interface providers', () {
    late _MockStorageRepository mock;
    late ProviderContainer container;

    setUp(() {
      mock = _MockStorageRepository();
      container = ProviderContainer(overrides: [
        storageRepositoryProvider.overrideWithValue(mock),
      ]);
    });

    tearDown(() => container.dispose());

    test('apiKeyStorageProvider returns ApiKeyStorage', () {
      when(() => mock.hasApiKey()).thenReturn(false);
      final storage = container.read(apiKeyStorageProvider);
      expect(storage, isA<ApiKeyStorage>());
      expect(storage.hasApiKey(), isFalse);
    });

    test('settingsStorageProvider returns SettingsStorage', () {
      when(() => mock.isSetupComplete).thenReturn(true);
      final storage = container.read(settingsStorageProvider);
      expect(storage, isA<SettingsStorage>());
      expect(storage.isSetupComplete, isTrue);
    });

    test('favoriteStorageProvider returns FavoriteStorage', () {
      when(() => mock.getFavoriteIds()).thenReturn(['a']);
      final storage = container.read(favoriteStorageProvider);
      expect(storage, isA<FavoriteStorage>());
      expect(storage.getFavoriteIds(), ['a']);
    });

    test('ignoredStorageProvider returns IgnoredStorage', () {
      when(() => mock.getIgnoredIds()).thenReturn([]);
      final storage = container.read(ignoredStorageProvider);
      expect(storage, isA<IgnoredStorage>());
      expect(storage.getIgnoredIds(), isEmpty);
    });

    test('ratingStorageProvider returns RatingStorage', () {
      when(() => mock.getRatings()).thenReturn({'s1': 5});
      final storage = container.read(ratingStorageProvider);
      expect(storage, isA<RatingStorage>());
      expect(storage.getRatings(), {'s1': 5});
    });

    test('profileStorageProvider returns ProfileStorage', () {
      when(() => mock.getAllProfiles()).thenReturn([]);
      final storage = container.read(profileStorageProvider);
      expect(storage, isA<ProfileStorage>());
      expect(storage.getAllProfiles(), isEmpty);
    });

    test('priceHistoryStorageProvider returns PriceHistoryStorage', () {
      when(() => mock.getPriceHistoryKeys()).thenReturn([]);
      final storage = container.read(priceHistoryStorageProvider);
      expect(storage, isA<PriceHistoryStorage>());
      expect(storage.getPriceHistoryKeys(), isEmpty);
    });

    test('alertStorageProvider returns AlertStorage', () {
      when(() => mock.getAlerts()).thenReturn([]);
      final storage = container.read(alertStorageProvider);
      expect(storage, isA<AlertStorage>());
      expect(storage.getAlerts(), isEmpty);
    });

    test('itineraryStorageProvider returns ItineraryStorage', () {
      when(() => mock.getItineraries()).thenReturn([]);
      final storage = container.read(itineraryStorageProvider);
      expect(storage, isA<ItineraryStorage>());
      expect(storage.getItineraries(), isEmpty);
    });

    test('cacheStorageProvider returns CacheStorage', () {
      when(() => mock.cacheEntryCount).thenReturn(0);
      final storage = container.read(cacheStorageProvider);
      expect(storage, isA<CacheStorage>());
      expect(storage.cacheEntryCount, 0);
    });
  });

  group('StorageManagement', () {
    test('delegates to StorageRepository', () {
      final mock = _MockStorageRepository();
      when(() => mock.storageStats).thenReturn(
        (settings: 100, profiles: 200, favorites: 50, cache: 300, priceHistory: 150, alerts: 75, total: 875),
      );
      when(() => mock.profileCount).thenReturn(2);
      when(() => mock.favoriteCount).thenReturn(5);
      when(() => mock.cacheEntryCount).thenReturn(10);
      when(() => mock.priceHistoryEntryCount).thenReturn(3);
      when(() => mock.alertCount).thenReturn(1);
      when(() => mock.getIgnoredIds()).thenReturn(['i1']);
      when(() => mock.getRatings()).thenReturn({'s1': 4});

      final container = ProviderContainer(overrides: [
        storageRepositoryProvider.overrideWithValue(mock),
      ]);
      addTearDown(container.dispose);

      final mgmt = container.read(storageManagementProvider);
      expect(mgmt.storageStats.total, 875);
      expect(mgmt.profileCount, 2);
      expect(mgmt.favoriteCount, 5);
      expect(mgmt.cacheEntryCount, 10);
      expect(mgmt.priceHistoryEntryCount, 3);
      expect(mgmt.alertCount, 1);
      expect(mgmt.getIgnoredIds(), ['i1']);
      expect(mgmt.getRatings(), {'s1': 4});
    });
  });

  group('FakeStorageRepository (in-memory)', () {
    test('implements all CRUD operations without Hive', () async {
      final storage = _InMemoryStorageRepository();

      // Favorites
      await storage.addFavorite('s1');
      expect(storage.getFavoriteIds(), ['s1']);
      expect(storage.isFavorite('s1'), isTrue);
      expect(storage.favoriteCount, 1);
      await storage.removeFavorite('s1');
      expect(storage.isFavorite('s1'), isFalse);

      // Favorite station data
      await storage.saveFavoriteStationData('s1', {'brand': 'Shell'});
      expect(storage.getFavoriteStationData('s1'), {'brand': 'Shell'});
      await storage.removeFavoriteStationData('s1');
      expect(storage.getFavoriteStationData('s1'), isNull);

      // Ignored
      await storage.addIgnored('s2');
      expect(storage.isIgnored('s2'), isTrue);
      await storage.removeIgnored('s2');
      expect(storage.getIgnoredIds(), isEmpty);

      // Ratings
      await storage.setRating('s1', 4);
      expect(storage.getRating('s1'), 4);
      await storage.removeRating('s1');
      expect(storage.getRating('s1'), isNull);

      // Settings
      await storage.putSetting('key', 'value');
      expect(storage.getSetting('key'), 'value');

      // Profiles
      await storage.saveProfile('p1', {'name': 'Test'});
      expect(storage.getProfile('p1'), {'name': 'Test'});
      expect(storage.profileCount, 1);
      await storage.deleteProfile('p1');
      expect(storage.profileCount, 0);

      // Cache
      await storage.cacheData('k1', {'data': true});
      expect(storage.cacheEntryCount, 1);
      await storage.clearCache();
      expect(storage.cacheEntryCount, 0);

      // Alerts
      await storage.saveAlerts([{'id': 'a1'}]);
      expect(storage.alertCount, 1);
      await storage.clearAlerts();
      expect(storage.alertCount, 0);
    });
  });
}

class _MockStorageRepository extends Mock implements StorageRepository {}

/// Proves StorageRepository can be fully implemented in-memory (no Hive).
class _InMemoryStorageRepository implements StorageRepository {
  final _favorites = <String>[];
  final _favoriteData = <String, Map<String, dynamic>>{};
  final _ignored = <String>[];
  final _ratings = <String, int>{};
  final _settings = <String, dynamic>{};
  final _profiles = <String, Map<String, dynamic>>{};
  final _cache = <String, dynamic>{};
  var _alerts = <Map<String, dynamic>>[];

  // FavoriteStorage
  @override List<String> getFavoriteIds() => List.from(_favorites);
  @override Future<void> setFavoriteIds(List<String> ids) async { _favorites..clear()..addAll(ids); }
  @override Future<void> addFavorite(String id) async { if (!_favorites.contains(id)) _favorites.add(id); }
  @override Future<void> removeFavorite(String id) async => _favorites.remove(id);
  @override bool isFavorite(String id) => _favorites.contains(id);
  @override int get favoriteCount => _favorites.length;
  @override Future<void> saveFavoriteStationData(String id, Map<String, dynamic> data) async => _favoriteData[id] = data;
  @override Map<String, dynamic>? getFavoriteStationData(String id) => _favoriteData[id];
  @override Map<String, dynamic> getAllFavoriteStationData() => Map.from(_favoriteData);
  @override Future<void> removeFavoriteStationData(String id) async => _favoriteData.remove(id);

  // EvFavoriteStorage
  final _evFavorites = <String>[];
  final _evFavoriteData = <String, Map<String, dynamic>>{};
  @override List<String> getEvFavoriteIds() => List.from(_evFavorites);
  @override Future<void> setEvFavoriteIds(List<String> ids) async { _evFavorites..clear()..addAll(ids); }
  @override Future<void> addEvFavorite(String id) async { if (!_evFavorites.contains(id)) _evFavorites.add(id); }
  @override Future<void> removeEvFavorite(String id) async => _evFavorites.remove(id);
  @override bool isEvFavorite(String id) => _evFavorites.contains(id);
  @override int get evFavoriteCount => _evFavorites.length;
  @override Future<void> saveEvFavoriteStationData(String id, Map<String, dynamic> data) async => _evFavoriteData[id] = data;
  @override Map<String, dynamic>? getEvFavoriteStationData(String id) => _evFavoriteData[id];
  @override Future<void> removeEvFavoriteStationData(String id) async => _evFavoriteData.remove(id);

  // IgnoredStorage
  @override List<String> getIgnoredIds() => List.from(_ignored);
  @override Future<void> setIgnoredIds(List<String> ids) async { _ignored..clear()..addAll(ids); }
  @override Future<void> addIgnored(String id) async { if (!_ignored.contains(id)) _ignored.add(id); }
  @override Future<void> removeIgnored(String id) async => _ignored.remove(id);
  @override bool isIgnored(String id) => _ignored.contains(id);

  // RatingStorage
  @override Map<String, int> getRatings() => Map.from(_ratings);
  @override Future<void> setRating(String id, int r) async => _ratings[id] = r;
  @override Future<void> removeRating(String id) async => _ratings.remove(id);
  @override int? getRating(String id) => _ratings[id];

  // SettingsStorage
  @override dynamic getSetting(String key) => _settings[key];
  @override Future<void> putSetting(String key, dynamic value) async => _settings[key] = value;
  @override bool get isSetupComplete => false;
  @override bool get isSetupSkipped => false;
  @override Future<void> skipSetup() async {}
  @override Future<void> resetSetupSkip() async {}

  // ApiKeyStorage
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

  // ProfileStorage
  @override String? getActiveProfileId() => _settings['active_profile_id'] as String?;
  @override Future<void> setActiveProfileId(String id) async => _settings['active_profile_id'] = id;
  @override Map<String, dynamic>? getProfile(String id) => _profiles[id];
  @override List<Map<String, dynamic>> getAllProfiles() => _profiles.values.toList();
  @override Future<void> saveProfile(String id, Map<String, dynamic> p) async => _profiles[id] = p;
  @override Future<void> deleteProfile(String id) async => _profiles.remove(id);
  @override int get profileCount => _profiles.length;

  // PriceHistoryStorage
  @override Future<void> savePriceRecords(String id, List<Map<String, dynamic>> r) async {}
  @override List<Map<String, dynamic>> getPriceRecords(String id) => [];
  @override List<String> getPriceHistoryKeys() => [];
  @override Future<void> clearPriceHistoryForStation(String id) async {}
  @override Future<void> clearPriceHistory() async {}
  @override int get priceHistoryEntryCount => 0;

  // AlertStorage
  @override List<Map<String, dynamic>> getAlerts() => List.from(_alerts);
  @override Future<void> saveAlerts(List<Map<String, dynamic>> a) async => _alerts = List.from(a);
  @override Future<void> clearAlerts() async => _alerts.clear();
  @override int get alertCount => _alerts.length;

  // ItineraryStorage
  @override List<Map<String, dynamic>> getItineraries() => [];
  @override Future<void> addItinerary(Map<String, dynamic> i) async {}
  @override Future<void> deleteItinerary(String id) async {}
  @override Future<void> saveItineraries(List<Map<String, dynamic>> i) async {}

  // CacheStorage
  @override Future<void> cacheData(String key, dynamic data) async => _cache[key] = data;
  @override Map<String, dynamic>? getCachedData(String key, {Duration? maxAge}) => null;
  @override Future<void> clearCache() async => _cache.clear();
  @override int get cacheEntryCount => _cache.length;
  @override Iterable<dynamic> get cacheKeys => _cache.keys;
  @override Future<void> deleteCacheEntry(String key) async => _cache.remove(key);

  // StorageRepository
  @override
  ({int settings, int profiles, int favorites, int cache, int priceHistory, int alerts, int total})
      get storageStats => (settings: 0, profiles: 0, favorites: 0, cache: 0, priceHistory: 0, alerts: 0, total: 0);
}
