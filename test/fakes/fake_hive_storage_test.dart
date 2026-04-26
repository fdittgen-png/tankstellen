import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';

import 'fake_hive_storage.dart';
import 'fake_storage_repository.dart';

/// Locks the public-facing semantics of [FakeHiveStorage] / [FakeStorageRepository].
/// The fakes replace mocktail mocks for stateful storage tests; if these
/// tests pass, the fake-based migrations downstream can rely on a real
/// state machine rather than per-test stubs.
void main() {
  group('FakeHiveStorage', () {
    test('implements HiveStorage and StorageRepository', () {
      final fake = FakeHiveStorage();
      expect(fake, isA<HiveStorage>());
      expect(fake, isA<StorageRepository>());
    });

    test('favorites round-trip', () async {
      final fake = FakeHiveStorage();
      expect(fake.getFavoriteIds(), isEmpty);
      expect(fake.favoriteCount, 0);

      await fake.addFavorite('s1');
      await fake.addFavorite('s2');
      expect(fake.getFavoriteIds(), ['s1', 's2']);
      expect(fake.isFavorite('s1'), isTrue);
      expect(fake.isFavorite('missing'), isFalse);
      expect(fake.favoriteCount, 2);

      // Adding the same id twice is a no-op (matches real Hive set semantics).
      await fake.addFavorite('s1');
      expect(fake.favoriteCount, 2);

      await fake.removeFavorite('s1');
      expect(fake.isFavorite('s1'), isFalse);
      expect(fake.favoriteCount, 1);
    });

    test('favorite station data round-trip and isolation', () async {
      final fake = FakeHiveStorage();
      final data = {'brand': 'Shell', 'name': 'Foo'};
      await fake.saveFavoriteStationData('s1', data);

      final read = fake.getFavoriteStationData('s1');
      expect(read, {'brand': 'Shell', 'name': 'Foo'});

      // Mutating the returned map must NOT poison the store (defensive copy).
      read!['brand'] = 'Aral';
      expect(fake.getFavoriteStationData('s1'),
          {'brand': 'Shell', 'name': 'Foo'});

      // Mutating the original input must also not poison the store.
      data['brand'] = 'BP';
      expect(fake.getFavoriteStationData('s1'),
          {'brand': 'Shell', 'name': 'Foo'});

      await fake.removeFavoriteStationData('s1');
      expect(fake.getFavoriteStationData('s1'), isNull);
    });

    test('ev favorites are independent from fuel favorites', () async {
      final fake = FakeHiveStorage();
      await fake.addFavorite('fuel-1');
      await fake.addEvFavorite('ev-1');

      expect(fake.isFavorite('fuel-1'), isTrue);
      expect(fake.isFavorite('ev-1'), isFalse);
      expect(fake.isEvFavorite('ev-1'), isTrue);
      expect(fake.isEvFavorite('fuel-1'), isFalse);
      expect(fake.favoriteCount, 1);
      expect(fake.evFavoriteCount, 1);
    });

    test('ignored stations round-trip', () async {
      final fake = FakeHiveStorage();
      await fake.addIgnored('s1');
      expect(fake.isIgnored('s1'), isTrue);
      await fake.removeIgnored('s1');
      expect(fake.getIgnoredIds(), isEmpty);

      await fake.setIgnoredIds(['a', 'b']);
      expect(fake.getIgnoredIds(), ['a', 'b']);
    });

    test('ratings round-trip', () async {
      final fake = FakeHiveStorage();
      expect(fake.getRating('s1'), isNull);

      await fake.setRating('s1', 4);
      expect(fake.getRating('s1'), 4);
      expect(fake.getRatings(), {'s1': 4});

      await fake.removeRating('s1');
      expect(fake.getRating('s1'), isNull);
      expect(fake.getRatings(), isEmpty);
    });

    test('settings round-trip', () async {
      final fake = FakeHiveStorage();
      expect(fake.getSetting('missing'), isNull);
      await fake.putSetting('foo', 'bar');
      expect(fake.getSetting('foo'), 'bar');
    });

    test('setup-complete flag exposed via test helper', () async {
      final fake = FakeHiveStorage();
      expect(fake.isSetupComplete, isFalse);
      fake.setSetupComplete(true);
      expect(fake.isSetupComplete, isTrue);

      expect(fake.isSetupSkipped, isFalse);
      await fake.skipSetup();
      expect(fake.isSetupSkipped, isTrue);
      await fake.resetSetupSkip();
      expect(fake.isSetupSkipped, isFalse);
    });

    test('api keys round-trip; bundled-default flag toggles hasApiKey',
        () async {
      final fake = FakeHiveStorage();
      // Bundled default: hasApiKey true even with no custom key.
      expect(fake.getApiKey(), isNull);
      expect(fake.hasApiKey(), isTrue);
      expect(fake.hasCustomApiKey(), isFalse);

      // Without bundled default: must have a real key to be true.
      fake.hasBundledDefaultKey = false;
      expect(fake.hasApiKey(), isFalse);

      await fake.setApiKey('user-key');
      expect(fake.getApiKey(), 'user-key');
      expect(fake.hasApiKey(), isTrue);
      expect(fake.hasCustomApiKey(), isTrue);

      await fake.deleteApiKey();
      expect(fake.getApiKey(), isNull);
      expect(fake.hasApiKey(), isFalse);
    });

    test('ev api key + supabase anon key round-trip', () async {
      final fake = FakeHiveStorage();
      expect(fake.getEvApiKey(), isNull);
      expect(fake.hasEvApiKey(), isFalse);
      await fake.setEvApiKey('ev-key');
      expect(fake.getEvApiKey(), 'ev-key');
      expect(fake.hasEvApiKey(), isTrue);
      expect(fake.hasCustomEvApiKey(), isTrue);

      expect(fake.getSupabaseAnonKey(), isNull);
      await fake.setSupabaseAnonKey('anon');
      expect(fake.getSupabaseAnonKey(), 'anon');
      await fake.deleteSupabaseAnonKey();
      expect(fake.getSupabaseAnonKey(), isNull);
    });

    test('profiles round-trip', () async {
      final fake = FakeHiveStorage();
      await fake.saveProfile('p1', {'name': 'Test'});
      await fake.saveProfile('p2', {'name': 'Other'});
      expect(fake.profileCount, 2);
      expect(fake.getProfile('p1'), {'name': 'Test'});
      expect(fake.getAllProfiles(), hasLength(2));

      await fake.setActiveProfileId('p1');
      expect(fake.getActiveProfileId(), 'p1');

      await fake.deleteProfile('p1');
      expect(fake.profileCount, 1);
      expect(fake.getProfile('p1'), isNull);
    });

    test('cache round-trip with TTL', () async {
      final fake = FakeHiveStorage();
      await fake.cacheData('k1', {'value': 1});
      expect(fake.cacheEntryCount, 1);
      expect(fake.cacheKeys, contains('k1'));
      expect(fake.getCachedData('k1'), {'value': 1});

      // maxAge in the past -> entry treated as expired.
      expect(fake.getCachedData('k1', maxAge: Duration.zero), isNull);

      // maxAge generous -> still fresh.
      expect(fake.getCachedData('k1', maxAge: const Duration(hours: 1)),
          {'value': 1});

      await fake.deleteCacheEntry('k1');
      expect(fake.cacheEntryCount, 0);

      await fake.cacheData('k2', 'plain-value');
      // Non-map values are wrapped, mirroring real Hive.
      expect(fake.getCachedData('k2'), {'value': 'plain-value'});

      await fake.clearCache();
      expect(fake.cacheEntryCount, 0);
    });

    test('itineraries round-trip', () async {
      final fake = FakeHiveStorage();
      await fake.addItinerary({'id': 'i1', 'name': 'Trip 1'});
      await fake.addItinerary({'id': 'i2', 'name': 'Trip 2'});
      expect(fake.getItineraries(), hasLength(2));

      await fake.deleteItinerary('i1');
      expect(fake.getItineraries(), hasLength(1));
      expect(fake.getItineraries().first['id'], 'i2');

      await fake.saveItineraries([
        {'id': 'i3', 'name': 'Trip 3'},
      ]);
      expect(fake.getItineraries(), hasLength(1));
      expect(fake.getItineraries().first['id'], 'i3');
    });

    test('price history round-trip', () async {
      final fake = FakeHiveStorage();
      await fake.savePriceRecords('s1', [
        {'ts': '2026-04-01', 'e10': 1.799},
        {'ts': '2026-04-02', 'e10': 1.789},
      ]);
      expect(fake.priceHistoryEntryCount, 2);
      expect(fake.getPriceRecords('s1'), hasLength(2));
      expect(fake.getPriceHistoryKeys(), ['s1']);

      await fake.savePriceRecords('s2', [
        {'ts': '2026-04-03', 'e10': 1.769},
      ]);
      expect(fake.priceHistoryEntryCount, 3);

      await fake.clearPriceHistoryForStation('s1');
      expect(fake.priceHistoryEntryCount, 1);
      expect(fake.getPriceRecords('s1'), isEmpty);

      await fake.clearPriceHistory();
      expect(fake.priceHistoryEntryCount, 0);
      expect(fake.getPriceHistoryKeys(), isEmpty);
    });

    test('alerts round-trip', () async {
      final fake = FakeHiveStorage();
      await fake.saveAlerts([
        {'id': 'a1', 'station': 's1'},
      ]);
      expect(fake.alertCount, 1);
      expect(fake.getAlerts(), hasLength(1));

      await fake.clearAlerts();
      expect(fake.alertCount, 0);
    });

    test('storageStats default approximation + override', () {
      final fake = FakeHiveStorage()
        ..hasBundledDefaultKey = false
        ..statsOverride = (box) => box == 'cache' ? 999 : 0;
      expect(fake.storageStats.cache, 999);
      expect(fake.storageStats.total, 999);
    });
  });

  group('FakeStorageRepository', () {
    test('implements StorageRepository', () {
      expect(FakeStorageRepository(), isA<StorageRepository>());
    });

    test('delegates state changes to its inner FakeHiveStorage', () async {
      final inner = FakeHiveStorage();
      final repo = FakeStorageRepository(inner: inner);

      await repo.addFavorite('s1');
      expect(repo.isFavorite('s1'), isTrue);
      // The inner fake sees the change too, so tests can mix-and-match.
      expect(inner.isFavorite('s1'), isTrue);
    });

    test('default constructor builds its own inner fake', () async {
      final repo = FakeStorageRepository();
      await repo.addFavorite('x');
      expect(repo.getFavoriteIds(), ['x']);
    });
  });
}
