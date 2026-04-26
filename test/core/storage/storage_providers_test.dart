import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/core/storage/storage_providers.dart';

import '../../fakes/fake_hive_storage.dart';

void main() {
  late FakeHiveStorage fakeStorage;

  setUp(() {
    fakeStorage = FakeHiveStorage();
  });

  ProviderContainer make() {
    final c = ProviderContainer(overrides: [
      hiveStorageProvider.overrideWithValue(fakeStorage),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  group('narrow storage providers', () {
    test('storageRepositoryProvider resolves to the HiveStorage instance',
        () {
      final c = make();
      expect(c.read(storageRepositoryProvider), isA<StorageRepository>());
      expect(c.read(storageRepositoryProvider), same(fakeStorage));
    });

    test('every narrow interface provider returns the same backing object',
        () {
      // The point of the narrow providers is presentation safety —
      // they expose only the interface methods — but they all MUST
      // resolve to the same underlying storage, otherwise changes
      // made through one API won't be visible through another.
      final c = make();
      final base = c.read(storageRepositoryProvider);

      expect(c.read(apiKeyStorageProvider), same(base));
      expect(c.read(settingsStorageProvider), same(base));
      expect(c.read(favoriteStorageProvider), same(base));
      expect(c.read(evFavoriteStorageProvider), same(base));
      expect(c.read(ignoredStorageProvider), same(base));
      expect(c.read(ratingStorageProvider), same(base));
      expect(c.read(profileStorageProvider), same(base));
      expect(c.read(priceHistoryStorageProvider), same(base));
      expect(c.read(alertStorageProvider), same(base));
      expect(c.read(itineraryStorageProvider), same(base));
      expect(c.read(cacheStorageProvider), same(base));
    });
  });

  group('StorageManagement', () {
    test('exposes storageStats as a passthrough', () {
      // Wire the fake's stats through a deterministic override so the
      // assertion stays explicit; the default approximation is purely
      // best-effort.
      fakeStorage.statsOverride = (box) {
        switch (box) {
          case 'settings':
            return 1;
          case 'profiles':
            return 2;
          case 'favorites':
            return 3;
          case 'cache':
            return 4;
          case 'priceHistory':
            return 5;
          case 'alerts':
            return 6;
          default:
            return 0;
        }
      };

      final c = make();
      final mgmt = c.read(storageManagementProvider);
      final stats = mgmt.storageStats;

      expect(stats.settings, 1);
      expect(stats.profiles, 2);
      expect(stats.total, 21);
    });

    test('count getters are passthroughs', () async {
      // Seed the fake so the count getters return the expected values.
      await fakeStorage.saveProfile('p1', {});
      await fakeStorage.saveProfile('p2', {});
      await fakeStorage.saveProfile('p3', {});
      await fakeStorage.setFavoriteIds(List.generate(12, (i) => 's$i'));
      for (var i = 0; i < 87; i++) {
        await fakeStorage.cacheData('k$i', {});
      }
      await fakeStorage.savePriceRecords('s1', [
        {'a': 1},
        {'a': 2},
        {'a': 3},
        {'a': 4},
        {'a': 5},
      ]);
      await fakeStorage.saveAlerts([
        {'id': 'a1'},
        {'id': 'a2'},
      ]);

      final mgmt = make().read(storageManagementProvider);
      expect(mgmt.profileCount, 3);
      expect(mgmt.favoriteCount, 12);
      expect(mgmt.cacheEntryCount, 87);
      expect(mgmt.priceHistoryEntryCount, 5);
      expect(mgmt.alertCount, 2);
    });

    test('getIgnoredIds returns the storage list verbatim', () async {
      await fakeStorage.setIgnoredIds(['a', 'b']);
      final mgmt = make().read(storageManagementProvider);
      expect(mgmt.getIgnoredIds(), ['a', 'b']);
    });

    test('getRatings returns the storage map verbatim', () async {
      await fakeStorage.setRating('st-1', 5);
      await fakeStorage.setRating('st-2', 3);
      final mgmt = make().read(storageManagementProvider);
      expect(mgmt.getRatings(), {'st-1': 5, 'st-2': 3});
    });

    test('clearCache / clearPriceHistory / deleteApiKey delegate',
        () async {
      // Seed state so the clear operations are observable.
      await fakeStorage.cacheData('k', {'v': 1});
      await fakeStorage.savePriceRecords('s', [
        {'p': 1.5},
      ]);
      await fakeStorage.setApiKey('user-key');

      final mgmt = make().read(storageManagementProvider);
      await mgmt.clearCache();
      await mgmt.clearPriceHistory();
      await mgmt.deleteApiKey();

      expect(fakeStorage.cacheEntryCount, 0);
      expect(fakeStorage.priceHistoryEntryCount, 0);
      expect(fakeStorage.getApiKey(), isNull);
    });

    test('savePriceRecords delegates with the same args', () async {
      final mgmt = make().read(storageManagementProvider);
      final records = [
        {'timestamp': '2026-04-01T10:00:00Z', 'e10': 1.799},
      ];
      await mgmt.savePriceRecords('st-1', records);

      expect(fakeStorage.getPriceRecords('st-1'), records);
    });
  });
}
