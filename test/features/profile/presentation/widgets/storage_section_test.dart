import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/features/profile/presentation/widgets/storage_section.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';
import '../../../../mocks/mocks.dart';

void main() {
  group('StorageSection', () {
    testWidgets('renders storage title', (tester) async {
      final storage = mockHiveStorageOverride();
      _stubStorageStats(storage.mock);

      await pumpApp(
        tester,
        const SingleChildScrollView(child: StorageSection()),
        overrides: [storage.override],
      );

      expect(find.text('Storage usage on this device'), findsOneWidget);
    });

    testWidgets('renders storage detail rows for each category',
        (tester) async {
      final storage = mockHiveStorageOverride();
      _stubStorageStats(storage.mock, cacheEntries: 15, favorites: 3);

      await pumpApp(
        tester,
        const SingleChildScrollView(child: StorageSection()),
        overrides: [storage.override],
      );

      expect(find.text('Settings'), findsAtLeast(1));
      expect(find.text('Profile'), findsAtLeast(1));
      expect(find.text('Favorites'), findsAtLeast(1));
      expect(find.text('Cache'), findsAtLeast(1));
      expect(find.text('Price History'), findsAtLeast(1));
    });

    testWidgets('shows profile, favorite, and cache counts', (tester) async {
      final storage = mockHiveStorageOverride();
      _stubStorageStats(storage.mock,
          profiles: 2, favorites: 5, cacheEntries: 42);

      await pumpApp(
        tester,
        const SingleChildScrollView(child: StorageSection()),
        overrides: [storage.override],
      );

      expect(find.textContaining('2'), findsAtLeast(1)); // profile count
      expect(find.textContaining('5'), findsAtLeast(1)); // favorite count
      expect(find.textContaining('42'), findsAtLeast(1)); // cache count
    });

    testWidgets('shows clear cache button when cache has entries',
        (tester) async {
      final storage = mockHiveStorageOverride();
      _stubStorageStats(storage.mock, cacheEntries: 10);

      await pumpApp(
        tester,
        const SingleChildScrollView(child: StorageSection()),
        overrides: [storage.override],
      );

      expect(find.byIcon(Icons.delete_sweep), findsOneWidget);
      expect(find.textContaining('Clear cache'), findsOneWidget);
    });

    testWidgets('shows "Cache is empty" when no cache entries',
        (tester) async {
      final storage = mockHiveStorageOverride();
      _stubStorageStats(storage.mock, cacheEntries: 0);

      await pumpApp(
        tester,
        const SingleChildScrollView(child: StorageSection()),
        overrides: [storage.override],
      );

      expect(find.text('Cache is empty'), findsOneWidget);
    });

    testWidgets('shows delete all button', (tester) async {
      final storage = mockHiveStorageOverride();
      _stubStorageStats(storage.mock);

      await pumpApp(
        tester,
        const SingleChildScrollView(child: StorageSection()),
        overrides: [storage.override],
      );

      expect(find.byIcon(Icons.delete_forever), findsOneWidget);
      expect(find.text('Delete all'), findsOneWidget);
    });

    testWidgets('shows total storage size', (tester) async {
      final storage = mockHiveStorageOverride();
      _stubStorageStats(storage.mock);

      await pumpApp(
        tester,
        const SingleChildScrollView(child: StorageSection()),
        overrides: [storage.override],
      );

      expect(find.text('Total'), findsOneWidget);
    });

    testWidgets('shows cache TTL information', (tester) async {
      final storage = mockHiveStorageOverride();
      _stubStorageStats(storage.mock);

      await pumpApp(
        tester,
        const SingleChildScrollView(child: StorageSection()),
        overrides: [storage.override],
      );

      expect(find.text('Cache management'), findsOneWidget);
      expect(find.textContaining('Station search'), findsOneWidget);
      expect(find.textContaining('5 min'), findsAtLeast(1));
    });
  });
}

/// Stubs all HiveStorage methods needed by StorageSection.
void _stubStorageStats(
  MockHiveStorage mock, {
  int profiles = 1,
  int favorites = 0,
  int cacheEntries = 5,
  int priceHistory = 0,
  int alerts = 0,
}) {
  when(() => mock.getActiveProfileId()).thenReturn(null);
  when(() => mock.getSetting(any())).thenReturn(null);
  when(() => mock.profileCount).thenReturn(profiles);
  when(() => mock.favoriteCount).thenReturn(favorites);
  when(() => mock.cacheEntryCount).thenReturn(cacheEntries);
  when(() => mock.priceHistoryEntryCount).thenReturn(priceHistory);
  when(() => mock.alertCount).thenReturn(alerts);
  when(() => mock.getIgnoredIds()).thenReturn([]);
  when(() => mock.getRatings()).thenReturn({});
  when(() => mock.storageStats).thenReturn((
    settings: 256,
    profiles: profiles * 512,
    favorites: favorites * 128,
    cache: cacheEntries * 1024,
    priceHistory: priceHistory * 256,
    alerts: alerts * 128,
    total: 256 + profiles * 512 + favorites * 128 + cacheEntries * 1024,
  ));
}
