import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/core/storage/storage_providers.dart';

import '../../mocks/mocks.dart';

void main() {
  late MockHiveStorage mockStorage;

  setUp(() {
    mockStorage = MockHiveStorage();
  });

  ProviderContainer make() {
    final c = ProviderContainer(overrides: [
      hiveStorageProvider.overrideWithValue(mockStorage),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  group('narrow storage providers', () {
    test('storageRepositoryProvider resolves to the HiveStorage instance',
        () {
      final c = make();
      expect(c.read(storageRepositoryProvider), isA<StorageRepository>());
      expect(c.read(storageRepositoryProvider), same(mockStorage));
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
      when(() => mockStorage.storageStats).thenReturn((
        settings: 1,
        profiles: 2,
        favorites: 3,
        cache: 4,
        priceHistory: 5,
        alerts: 6,
        total: 21,
      ));

      final c = make();
      final mgmt = c.read(storageManagementProvider);
      final stats = mgmt.storageStats;

      expect(stats.settings, 1);
      expect(stats.profiles, 2);
      expect(stats.total, 21);
    });

    test('count getters are passthroughs', () {
      when(() => mockStorage.profileCount).thenReturn(3);
      when(() => mockStorage.favoriteCount).thenReturn(12);
      when(() => mockStorage.cacheEntryCount).thenReturn(87);
      when(() => mockStorage.priceHistoryEntryCount).thenReturn(5);
      when(() => mockStorage.alertCount).thenReturn(2);

      final mgmt = make().read(storageManagementProvider);
      expect(mgmt.profileCount, 3);
      expect(mgmt.favoriteCount, 12);
      expect(mgmt.cacheEntryCount, 87);
      expect(mgmt.priceHistoryEntryCount, 5);
      expect(mgmt.alertCount, 2);
    });

    test('getIgnoredIds returns the storage list verbatim', () {
      when(() => mockStorage.getIgnoredIds()).thenReturn(['a', 'b']);
      final mgmt = make().read(storageManagementProvider);
      expect(mgmt.getIgnoredIds(), ['a', 'b']);
    });

    test('getRatings returns the storage map verbatim', () {
      when(() => mockStorage.getRatings()).thenReturn({'st-1': 5, 'st-2': 3});
      final mgmt = make().read(storageManagementProvider);
      expect(mgmt.getRatings(), {'st-1': 5, 'st-2': 3});
    });

    test('clearCache / clearPriceHistory / deleteApiKey delegate',
        () async {
      when(() => mockStorage.clearCache()).thenAnswer((_) async {});
      when(() => mockStorage.clearPriceHistory()).thenAnswer((_) async {});
      when(() => mockStorage.deleteApiKey()).thenAnswer((_) async {});

      final mgmt = make().read(storageManagementProvider);
      await mgmt.clearCache();
      await mgmt.clearPriceHistory();
      await mgmt.deleteApiKey();

      verify(() => mockStorage.clearCache()).called(1);
      verify(() => mockStorage.clearPriceHistory()).called(1);
      verify(() => mockStorage.deleteApiKey()).called(1);
    });

    test('savePriceRecords delegates with the same args', () async {
      when(() => mockStorage.savePriceRecords(any(), any()))
          .thenAnswer((_) async {});

      final mgmt = make().read(storageManagementProvider);
      final records = [
        {'timestamp': '2026-04-01T10:00:00Z', 'e10': 1.799},
      ];
      await mgmt.savePriceRecords('st-1', records);

      verify(() => mockStorage.savePriceRecords('st-1', records)).called(1);
    });
  });
}
