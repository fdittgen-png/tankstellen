import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/core/storage/storage_providers.dart';

import '../../fakes/fake_hive_storage.dart';
import '../../fakes/fake_storage_repository.dart';

void main() {
  group('storageRepositoryProvider', () {
    test('returns a StorageRepository', () {
      final fake = FakeHiveStorage();
      final container = ProviderContainer(overrides: [
        hiveStorageProvider.overrideWithValue(fake),
      ]);
      addTearDown(container.dispose);

      final repo = container.read(storageRepositoryProvider);
      expect(repo, isA<StorageRepository>());
      expect(repo, same(fake));
    });

    test('propagates hiveStorageProvider override', () async {
      final fake = FakeHiveStorage();
      await fake.setApiKey('user-key');
      await fake.setFavoriteIds(['s1', 's2']);

      final container = ProviderContainer(overrides: [
        hiveStorageProvider.overrideWithValue(fake),
      ]);
      addTearDown(container.dispose);

      final repo = container.read(storageRepositoryProvider);
      expect(repo.hasApiKey(), isTrue);
      expect(repo.getFavoriteIds(), ['s1', 's2']);
    });

    test('can be overridden directly with a FakeStorageRepository', () async {
      final fake = FakeStorageRepository();
      fake.inner.setSetupComplete(true);
      await fake.setFavoriteIds(['x']);

      final container = ProviderContainer(overrides: [
        storageRepositoryProvider.overrideWithValue(fake),
      ]);
      addTearDown(container.dispose);

      final repo = container.read(storageRepositoryProvider);
      expect(repo.isSetupComplete, isTrue);
      expect(repo.getFavoriteIds(), ['x']);
    });
  });

  group('narrow interface providers', () {
    late FakeStorageRepository fake;
    late ProviderContainer container;

    setUp(() {
      fake = FakeStorageRepository();
      container = ProviderContainer(overrides: [
        storageRepositoryProvider.overrideWithValue(fake),
      ]);
    });

    tearDown(() => container.dispose());

    test('apiKeyStorageProvider returns ApiKeyStorage', () {
      fake.inner.hasBundledDefaultKey = false;
      final storage = container.read(apiKeyStorageProvider);
      expect(storage, isA<ApiKeyStorage>());
      expect(storage.hasApiKey(), isFalse);
    });

    test('settingsStorageProvider returns SettingsStorage', () {
      fake.inner.setSetupComplete(true);
      final storage = container.read(settingsStorageProvider);
      expect(storage, isA<SettingsStorage>());
      expect(storage.isSetupComplete, isTrue);
    });

    test('favoriteStorageProvider returns FavoriteStorage', () async {
      await fake.addFavorite('a');
      final storage = container.read(favoriteStorageProvider);
      expect(storage, isA<FavoriteStorage>());
      expect(storage.getFavoriteIds(), ['a']);
    });

    test('ignoredStorageProvider returns IgnoredStorage', () {
      final storage = container.read(ignoredStorageProvider);
      expect(storage, isA<IgnoredStorage>());
      expect(storage.getIgnoredIds(), isEmpty);
    });

    test('ratingStorageProvider returns RatingStorage', () async {
      await fake.setRating('s1', 5);
      final storage = container.read(ratingStorageProvider);
      expect(storage, isA<RatingStorage>());
      expect(storage.getRatings(), {'s1': 5});
    });

    test('profileStorageProvider returns ProfileStorage', () {
      final storage = container.read(profileStorageProvider);
      expect(storage, isA<ProfileStorage>());
      expect(storage.getAllProfiles(), isEmpty);
    });

    test('priceHistoryStorageProvider returns PriceHistoryStorage', () {
      final storage = container.read(priceHistoryStorageProvider);
      expect(storage, isA<PriceHistoryStorage>());
      expect(storage.getPriceHistoryKeys(), isEmpty);
    });

    test('alertStorageProvider returns AlertStorage', () {
      final storage = container.read(alertStorageProvider);
      expect(storage, isA<AlertStorage>());
      expect(storage.getAlerts(), isEmpty);
    });

    test('itineraryStorageProvider returns ItineraryStorage', () {
      final storage = container.read(itineraryStorageProvider);
      expect(storage, isA<ItineraryStorage>());
      expect(storage.getItineraries(), isEmpty);
    });

    test('cacheStorageProvider returns CacheStorage', () {
      final storage = container.read(cacheStorageProvider);
      expect(storage, isA<CacheStorage>());
      expect(storage.cacheEntryCount, 0);
    });
  });

  group('StorageManagement', () {
    test('delegates to StorageRepository', () async {
      final fake = FakeStorageRepository();
      // Seed deterministic state.
      fake.inner.statsOverride = (box) {
        switch (box) {
          case 'settings':
            return 100;
          case 'profiles':
            return 200;
          case 'favorites':
            return 50;
          case 'cache':
            return 300;
          case 'priceHistory':
            return 150;
          case 'alerts':
            return 75;
          default:
            return 0;
        }
      };
      await fake.saveProfile('p1', {});
      await fake.saveProfile('p2', {});
      await fake.setFavoriteIds(['a', 'b', 'c', 'd', 'e']);
      for (var i = 0; i < 10; i++) {
        await fake.cacheData('k$i', {});
      }
      await fake.savePriceRecords('s1', [
        {'a': 1},
        {'a': 2},
        {'a': 3},
      ]);
      await fake.saveAlerts([
        {'id': 'a1'},
      ]);
      await fake.addIgnored('i1');
      await fake.setRating('s1', 4);

      final container = ProviderContainer(overrides: [
        storageRepositoryProvider.overrideWithValue(fake),
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
}
