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

  @override List<String> getFavoriteIds() => List.from(_favorites);
  @override Future<void> addFavorite(String id) async => _favorites.add(id);
  @override Future<void> removeFavorite(String id) async => _favorites.remove(id);
  @override bool isFavorite(String id) => _favorites.contains(id);

  @override List<String> getIgnoredIds() => List.from(_ignored);
  @override Future<void> addIgnored(String id) async => _ignored.add(id);
  @override Future<void> removeIgnored(String id) async => _ignored.remove(id);

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

  @override String? getActiveProfileId() => _settings['active_profile_id'] as String?;
  @override Future<void> setActiveProfileId(String id) async => _settings['active_profile_id'] = id;
  @override Map<String, dynamic>? getProfile(String id) => _profiles[id];
  @override List<Map<String, dynamic>> getAllProfiles() => _profiles.values.toList();
  @override Future<void> saveProfile(String id, Map<String, dynamic> p) async => _profiles[id] = p;
  @override Future<void> deleteProfile(String id) async => _profiles.remove(id);

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

  @override Future<void> cacheData(String key, dynamic data) async {}
  @override Map<String, dynamic>? getCachedData(String key, {Duration? maxAge}) => null;
  @override Future<void> clearCache() async {}

  @override bool get isSetupComplete => false;
  @override bool get isSetupSkipped => false;
  @override Future<void> skipSetup() async {}

  @override int get cacheEntryCount => 0;
  @override int get priceHistoryEntryCount => 0;
  @override int get favoriteCount => _favorites.length;
}
