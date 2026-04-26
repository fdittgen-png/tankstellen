import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/profile/presentation/widgets/storage_section.dart';

import '../../../../fakes/fake_hive_storage.dart';
import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  group('StorageSection', () {
    testWidgets('renders storage title', (tester) async {
      final storage = fakeHiveStorageOverride();
      _seedStorageStats(storage.fake);

      await pumpApp(
        tester,
        const SingleChildScrollView(child: StorageSection()),
        overrides: [storage.override],
      );

      expect(find.text('Storage usage on this device'), findsOneWidget);
    });

    testWidgets('renders storage detail rows for each category',
        (tester) async {
      final storage = fakeHiveStorageOverride();
      _seedStorageStats(storage.fake, cacheEntries: 15, favorites: 3);

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
      final storage = fakeHiveStorageOverride();
      _seedStorageStats(storage.fake,
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
      final storage = fakeHiveStorageOverride();
      _seedStorageStats(storage.fake, cacheEntries: 10);

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
      final storage = fakeHiveStorageOverride();
      _seedStorageStats(storage.fake, cacheEntries: 0);

      await pumpApp(
        tester,
        const SingleChildScrollView(child: StorageSection()),
        overrides: [storage.override],
      );

      expect(find.text('Cache is empty'), findsOneWidget);
    });

    testWidgets('shows delete all button', (tester) async {
      final storage = fakeHiveStorageOverride();
      _seedStorageStats(storage.fake);

      await pumpApp(
        tester,
        const SingleChildScrollView(child: StorageSection()),
        overrides: [storage.override],
      );

      expect(find.byIcon(Icons.delete_forever), findsOneWidget);
      expect(find.text('Delete all'), findsOneWidget);
    });

    testWidgets('shows total storage size', (tester) async {
      final storage = fakeHiveStorageOverride();
      _seedStorageStats(storage.fake);

      await pumpApp(
        tester,
        const SingleChildScrollView(child: StorageSection()),
        overrides: [storage.override],
      );

      expect(find.text('Total'), findsOneWidget);
    });

    testWidgets('shows cache TTL information', (tester) async {
      final storage = fakeHiveStorageOverride();
      _seedStorageStats(storage.fake);

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

/// Seeds the fake with the storage state needed by [StorageSection].
void _seedStorageStats(
  FakeHiveStorage fake, {
  int profiles = 1,
  int favorites = 0,
  int cacheEntries = 5,
  int priceHistory = 0,
  int alerts = 0,
}) {
  for (var i = 0; i < profiles; i++) {
    fake.saveProfile('p$i', {'name': 'p$i'});
  }
  fake.setFavoriteIds(List.generate(favorites, (i) => 'f$i'));
  for (var i = 0; i < cacheEntries; i++) {
    fake.cacheData('k$i', {'v': i});
  }
  if (priceHistory > 0) {
    fake.savePriceRecords(
      's-history',
      List.generate(priceHistory, (i) => {'ts': '$i'}),
    );
  }
  if (alerts > 0) {
    fake.saveAlerts(List.generate(alerts, (i) => {'id': 'a$i'}));
  }

  // Override the byte-stats so the widget gets stable totals matching
  // the previous mock-based assertions (256 + profiles*512 +
  // favorites*128 + cacheEntries*1024 + priceHistory*256 + alerts*128).
  fake.statsOverride = (box) {
    switch (box) {
      case 'settings':
        return 256;
      case 'profiles':
        return profiles * 512;
      case 'favorites':
        return favorites * 128;
      case 'cache':
        return cacheEntries * 1024;
      case 'priceHistory':
        return priceHistory * 256;
      case 'alerts':
        return alerts * 128;
      default:
        return 0;
    }
  };
}
