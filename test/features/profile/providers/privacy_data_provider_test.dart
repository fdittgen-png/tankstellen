import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/storage/storage_providers.dart';
import 'package:tankstellen/core/sync/sync_config.dart';
import 'package:tankstellen/core/sync/sync_provider.dart';
import 'package:tankstellen/features/profile/providers/privacy_data_provider.dart';

import '../../../mocks/mocks.dart';

void main() {
  group('privacyDataProvider', () {
    late MockStorageRepository mockStorage;
    late ProviderContainer container;

    setUp(() {
      mockStorage = MockStorageRepository();

      // Default stubs
      when(() => mockStorage.favoriteCount).thenReturn(3);
      when(() => mockStorage.getIgnoredIds()).thenReturn(['a', 'b']);
      when(() => mockStorage.getRatings()).thenReturn({'s1': 4, 's2': 5});
      when(() => mockStorage.alertCount).thenReturn(1);
      when(() => mockStorage.getPriceHistoryKeys()).thenReturn(['k1']);
      when(() => mockStorage.profileCount).thenReturn(2);
      when(() => mockStorage.cacheEntryCount).thenReturn(10);
      when(() => mockStorage.getItineraries()).thenReturn([]);
      when(() => mockStorage.hasApiKey()).thenReturn(true);
      when(() => mockStorage.hasEvApiKey()).thenReturn(false);
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
        syncStateProvider.overrideWith(() => _DisabledSyncState()),
      ]);
    });

    tearDown(() => container.dispose());

    test('returns correct counts from storage', () {
      final snapshot = container.read(privacyDataProvider);

      expect(snapshot.favoritesCount, 3);
      expect(snapshot.ignoredCount, 2);
      expect(snapshot.ratingsCount, 2);
      expect(snapshot.alertsCount, 1);
      expect(snapshot.priceHistoryStationCount, 1);
      expect(snapshot.profileCount, 2);
      expect(snapshot.cacheEntryCount, 10);
      expect(snapshot.itineraryCount, 0);
      expect(snapshot.hasApiKey, isTrue);
      expect(snapshot.hasEvApiKey, isFalse);
      expect(snapshot.estimatedTotalBytes, 25024);
    });

    test('reflects sync disabled state', () {
      final snapshot = container.read(privacyDataProvider);

      expect(snapshot.syncEnabled, isFalse);
      expect(snapshot.syncMode, isNull);
      expect(snapshot.syncUserId, isNull);
    });

    test('reflects sync enabled state', () {
      final enabledContainer = ProviderContainer(overrides: [
        storageRepositoryProvider.overrideWithValue(mockStorage),
        syncStateProvider.overrideWith(() => _EnabledSyncState()),
      ]);
      addTearDown(enabledContainer.dispose);

      final snapshot = enabledContainer.read(privacyDataProvider);

      expect(snapshot.syncEnabled, isTrue);
      expect(snapshot.syncMode, 'Tankstellen Community');
      expect(snapshot.syncUserId, 'user-123');
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
      when(() => mockStorage.hasApiKey()).thenReturn(false);
      when(() => mockStorage.hasEvApiKey()).thenReturn(false);
      when(() => mockStorage.storageStats).thenReturn((
        settings: 0,
        profiles: 0,
        favorites: 0,
        cache: 0,
        priceHistory: 0,
        alerts: 0,
        total: 0,
      ));

      // Need a fresh container to re-read
      final freshContainer = ProviderContainer(overrides: [
        storageRepositoryProvider.overrideWithValue(mockStorage),
        syncStateProvider.overrideWith(() => _DisabledSyncState()),
      ]);
      addTearDown(freshContainer.dispose);

      final snapshot = freshContainer.read(privacyDataProvider);
      expect(snapshot.favoritesCount, 0);
      expect(snapshot.ignoredCount, 0);
      expect(snapshot.ratingsCount, 0);
      expect(snapshot.alertsCount, 0);
      expect(snapshot.priceHistoryStationCount, 0);
      expect(snapshot.profileCount, 0);
      expect(snapshot.cacheEntryCount, 0);
      expect(snapshot.itineraryCount, 0);
      expect(snapshot.hasApiKey, isFalse);
      expect(snapshot.hasEvApiKey, isFalse);
      expect(snapshot.estimatedTotalBytes, 0);
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
      when(() => mockStorage.storageStats).thenReturn((
        settings: 0, profiles: 0, favorites: 0,
        cache: 0, priceHistory: 0, alerts: 0, total: 0,
      ));
      when(() => mockStorage.favoriteCount).thenReturn(2);
      when(() => mockStorage.profileCount).thenReturn(1);
      when(() => mockStorage.cacheEntryCount).thenReturn(0);
      when(() => mockStorage.alertCount).thenReturn(1);
      when(() => mockStorage.hasApiKey()).thenReturn(false);
      when(() => mockStorage.hasEvApiKey()).thenReturn(false);

      final container = ProviderContainer(overrides: [
        storageRepositoryProvider.overrideWithValue(mockStorage),
        syncStateProvider.overrideWith(() => _DisabledSyncState()),
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

class _DisabledSyncState extends SyncState {
  @override
  SyncConfig build() => const SyncConfig();
}

class _EnabledSyncState extends SyncState {
  @override
  SyncConfig build() => const SyncConfig(
        enabled: true,
        supabaseUrl: 'https://test.supabase.co',
        supabaseAnonKey: 'test-key',
        userId: 'user-123',
        mode: SyncMode.community,
      );
}
