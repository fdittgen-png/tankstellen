// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

// The mocktail Mock* storage doubles are deprecated as a steering hint
// (prefer the stateful fakes) but remain sanctioned for widget tests that
// stub reads exclusively -- see test/helpers/mock_providers.dart (#3742).
// ignore_for_file: deprecated_member_use_from_same_package

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/storage/storage_keys.dart';
import 'package:tankstellen/core/storage/storage_providers.dart';
import 'package:tankstellen/features/profile/providers/privacy_data_provider.dart';

import '../../../mocks/mocks.dart';

void main() {
  group('deviceDataInventoryProvider (#3910)', () {
    late MockStorageRepository mockStorage;
    late ProviderContainer container;

    setUp(() {
      mockStorage = MockStorageRepository();

      when(() => mockStorage.favoriteCount).thenReturn(3);
      when(() => mockStorage.getIgnoredIds()).thenReturn(['a', 'b']);
      when(() => mockStorage.getRatings()).thenReturn({'s1': 4, 's2': 5});
      when(() => mockStorage.alertCount).thenReturn(1);
      when(() => mockStorage.getPriceHistoryKeys()).thenReturn(['k1']);
      when(() => mockStorage.profileCount).thenReturn(2);
      when(() => mockStorage.cacheEntryCount).thenReturn(10);
      when(() => mockStorage.getItineraries()).thenReturn([]);
      when(() => mockStorage.getSetting(StorageKeys.blockedContentAuthorIds))
          .thenReturn(['user-x']);
      when(() => mockStorage.storageStats).thenReturn((
        settings: 1024,
        profiles: 2048,
        favorites: 192,
        cache: 20480,
        priceHistory: 1024,
        alerts: 256,
        total: 25024,
      ));

      container = ProviderContainer(overrides: [
        storageRepositoryProvider.overrideWithValue(mockStorage),
      ]);
    });

    tearDown(() => container.dispose());

    test('returns one category per kind with count + bytes from storage', () {
      final inv = container.read(deviceDataInventoryProvider);

      expect(inv.categories.map((c) => c.kind), DeviceDataKind.values);
      expect(inv.byKind(DeviceDataKind.favorites).count, 3);
      expect(inv.byKind(DeviceDataKind.favorites).bytes, 192);
      expect(inv.byKind(DeviceDataKind.ignoredStations).count, 2);
      expect(inv.byKind(DeviceDataKind.ignoredStations).bytes,
          2 * kDeviceDataSmallEntryBytes);
      expect(inv.byKind(DeviceDataKind.ratings).count, 2);
      expect(inv.byKind(DeviceDataKind.alerts).count, 1);
      expect(inv.byKind(DeviceDataKind.alerts).bytes, 256);
      expect(inv.byKind(DeviceDataKind.priceHistory).count, 1);
      expect(inv.byKind(DeviceDataKind.profiles).count, 2);
      expect(inv.byKind(DeviceDataKind.profiles).bytes, 2048);
      expect(inv.byKind(DeviceDataKind.cache).count, 10);
      expect(inv.byKind(DeviceDataKind.cache).bytes, 20480);
      expect(inv.byKind(DeviceDataKind.blockedUsers).count, 1);
      expect(inv.byKind(DeviceDataKind.itineraries).count, 0);
      expect(inv.byKind(DeviceDataKind.settings).count, isNull);
      expect(inv.byKind(DeviceDataKind.settings).bytes, 1024);
      expect(inv.totalBytes, 25024);
    });

    test('empty categories sort last for display; settings never counts as '
        'empty', () {
      final inv = container.read(deviceDataInventoryProvider);
      final ordered = inv.orderedForDisplay;

      expect(ordered.last.kind, DeviceDataKind.itineraries);
      expect(ordered.last.isEmpty, isTrue);
      expect(inv.byKind(DeviceDataKind.settings).isEmpty, isFalse);
      expect(inv.nonEmptyCount, DeviceDataKind.values.length - 1);
      // Canonical order is kept among the non-empty rows.
      expect(ordered.first.kind, DeviceDataKind.favorites);
      expect(ordered[ordered.length - 2].kind, DeviceDataKind.settings);
    });

    test('returns zero counts when storage is empty', () {
      when(() => mockStorage.favoriteCount).thenReturn(0);
      when(() => mockStorage.getIgnoredIds()).thenReturn([]);
      when(() => mockStorage.getRatings()).thenReturn({});
      when(() => mockStorage.alertCount).thenReturn(0);
      when(() => mockStorage.getPriceHistoryKeys()).thenReturn([]);
      when(() => mockStorage.profileCount).thenReturn(0);
      when(() => mockStorage.cacheEntryCount).thenReturn(0);
      when(() => mockStorage.getItineraries()).thenReturn([]);
      when(() => mockStorage.getSetting(StorageKeys.blockedContentAuthorIds))
          .thenReturn(null);
      when(() => mockStorage.storageStats).thenReturn((
        settings: 0,
        profiles: 0,
        favorites: 0,
        cache: 0,
        priceHistory: 0,
        alerts: 0,
        total: 0,
      ));

      final fresh = ProviderContainer(overrides: [
        storageRepositoryProvider.overrideWithValue(mockStorage),
      ]);
      addTearDown(fresh.dispose);

      final inv = fresh.read(deviceDataInventoryProvider);
      expect(inv.totalBytes, 0);
      expect(inv.nonEmptyCount, 1, reason: 'only the settings row');
      for (final c in inv.categories) {
        if (c.kind == DeviceDataKind.settings) continue;
        expect(c.count, 0, reason: c.kind.name);
        expect(c.isEmpty, isTrue, reason: c.kind.name);
      }
    });
  });

  group('exportPrivacyDataProvider', () {
    late MockStorageRepository mockStorage;

    test('exports JSON containing all user data categories', () {
      mockStorage = MockStorageRepository();

      when(() => mockStorage.getFavoriteIds()).thenReturn(['fav1', 'fav2']);
      when(() => mockStorage.getAllFavoriteStationData()).thenReturn({
        'fav1': {'name': 'Station 1'},
      });
      when(() => mockStorage.getIgnoredIds()).thenReturn(['ign1']);
      when(() => mockStorage.getRatings()).thenReturn({'s1': 5});
      when(() => mockStorage.getAllProfiles()).thenReturn([
        {'id': 'p1', 'name': 'Profile 1'},
      ]);
      when(() => mockStorage.getAlerts()).thenReturn([
        {'stationId': 's1', 'threshold': 1.5},
      ]);
      when(() => mockStorage.getItineraries()).thenReturn([]);
      when(() => mockStorage.getPriceHistoryKeys()).thenReturn(['s1']);
      when(() => mockStorage.getPriceRecords('s1')).thenReturn([
        {'price': 1.45, 'date': '2026-04-01'},
      ]);

      final container = ProviderContainer(overrides: [
        storageRepositoryProvider.overrideWithValue(mockStorage),
      ]);
      addTearDown(container.dispose);

      final json = container.read(exportPrivacyDataProvider);

      expect(json, contains('"favorites"'));
      expect(json, contains('"fav1"'));
      expect(json, contains('"fav2"'));
      expect(json, contains('"favoriteStationData"'));
      expect(json, contains('"ignoredStations"'));
      expect(json, contains('"ign1"'));
      expect(json, contains('"ratings"'));
      expect(json, contains('"profiles"'));
      expect(json, contains('"alerts"'));
      expect(json, contains('"priceHistory"'));
      expect(json, contains('"exportedAt"'));
      expect(json, contains('"appVersion"'));
      // Ensure API keys are NOT exported
      expect(json, isNot(contains('apiKey')));
    });
  });
}
