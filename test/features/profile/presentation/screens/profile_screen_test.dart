import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/features/profile/presentation/screens/profile_screen.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';
import '../../../../mocks/mocks.dart';

void main() {
  group('ProfileScreen', () {
    late MockHiveStorage mockStorage;
    late List<Object> overrides;

    setUp(() {
      mockStorage = MockHiveStorage();
      when(() => mockStorage.hasApiKey()).thenReturn(false);
      when(() => mockStorage.getApiKey()).thenReturn(null);
      when(() => mockStorage.getActiveProfileId()).thenReturn(null);
      when(() => mockStorage.getAllProfiles()).thenReturn([]);
      when(() => mockStorage.getRatings()).thenReturn({});
      when(() => mockStorage.getIgnoredIds()).thenReturn([]);
      when(() => mockStorage.getSetting(any())).thenReturn(null);
      when(() => mockStorage.storageStats).thenReturn((
        settings: 0,
        profiles: 0,
        favorites: 0,
        cache: 0,
        priceHistory: 0,
        alerts: 0,
        total: 0,
      ));
      when(() => mockStorage.profileCount).thenReturn(0);
      when(() => mockStorage.favoriteCount).thenReturn(0);
      when(() => mockStorage.cacheEntryCount).thenReturn(0);
      when(() => mockStorage.priceHistoryEntryCount).thenReturn(0);
      when(() => mockStorage.alertCount).thenReturn(0);
      when(() => mockStorage.getFavoriteIds()).thenReturn([]);
      when(() => mockStorage.getAlerts()).thenReturn([]);
      when(() => mockStorage.getEvApiKey()).thenReturn(null);
      when(() => mockStorage.hasCustomEvApiKey()).thenReturn(false);

      final test = standardTestOverrides();
      overrides = test.overrides;
      // Replace the mockStorage used in standardTestOverrides
      overrides = [
        hiveStorageProvider.overrideWithValue(mockStorage),
        ...test.overrides.skip(1), // Skip the default storage override
      ];
    });

    testWidgets('renders Scaffold with Settings title', (tester) async {
      await pumpApp(
        tester,
        const ProfileScreen(),
        overrides: overrides,
      );

      expect(find.byType(Scaffold), findsAtLeast(1));
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('renders section headers', (tester) async {
      await pumpApp(
        tester,
        const ProfileScreen(),
        overrides: overrides,
      );

      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Location'), findsOneWidget);
    });

    testWidgets('does not render Data Transparency section', (tester) async {
      await pumpApp(
        tester,
        const ProfileScreen(),
        overrides: overrides,
      );

      // Data Transparency was removed in favor of the Privacy Dashboard
      expect(find.text('Data transparency'), findsNothing);
    });

    testWidgets('renders Privacy Dashboard navigation link', (tester) async {
      await pumpApp(
        tester,
        const ProfileScreen(),
        overrides: overrides,
      );

      // Scroll down to find the Privacy Dashboard link
      await tester.scrollUntilVisible(
        find.text('Privacy Dashboard'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('Privacy Dashboard'), findsOneWidget);
      expect(find.text('View, export, or delete your data'), findsOneWidget);
    });

    testWidgets('renders body as a scrollable ListView', (tester) async {
      await pumpApp(
        tester,
        const ProfileScreen(),
        overrides: overrides,
      );

      // ProfileScreen body is a ListView
      expect(find.byType(ListView), findsAtLeast(1));
    });
  });
}
