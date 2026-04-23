import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/features/profile/presentation/screens/profile_screen.dart';
import 'package:tankstellen/features/profile/presentation/screens/theme_settings_screen.dart';
import 'package:tankstellen/features/profile/presentation/widgets/settings_menu_tile.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';
import '../../../../mocks/mocks.dart';

/// Regression tests for #897 — the Theme section on the Settings screen
/// must use the same reusable widget class (`SettingsMenuTile`) as the
/// Privacy Dashboard and Storage sections, render the chevron/icon/
/// title/subtitle trio, and navigate to a dedicated `ThemeSettingsScreen`.
void main() {
  group('Settings screen Theme card (#897)', () {
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
      overrides = [
        hiveStorageProvider.overrideWithValue(mockStorage),
        ...test.overrides.skip(1),
      ];
    });

    testWidgets(
        'renders the Theme section via the same SettingsMenuTile class '
        'as the Privacy Dashboard tile', (tester) async {
      await pumpApp(tester, const ProfileScreen(), overrides: overrides);

      // Scroll far enough down to realise every bottom-half tile in
      // the lazy ListView.
      await tester.scrollUntilVisible(
        find.text('Privacy Dashboard'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      final tileTitles = tester
          .widgetList<SettingsMenuTile>(find.byType(SettingsMenuTile))
          .map((t) => t.title)
          .toList();

      expect(
        tileTitles.contains('Theme'),
        isTrue,
        reason: '#897: Theme must render via SettingsMenuTile, not a '
            'bespoke widget — found titles $tileTitles',
      );
      expect(
        tileTitles.contains('Privacy Dashboard'),
        isTrue,
        reason: 'Privacy Dashboard baseline must still render as a '
            'SettingsMenuTile',
      );
    });

    testWidgets(
        'Theme tile shows Icons.palette_outlined leading, a subtitle, '
        'and a trailing chevron', (tester) async {
      await pumpApp(tester, const ProfileScreen(), overrides: overrides);

      await tester.scrollUntilVisible(
        find.text('Theme'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      final themeTile = tester
          .widgetList<SettingsMenuTile>(find.byType(SettingsMenuTile))
          .firstWhere((t) => t.title == 'Theme');

      expect(themeTile.icon, Icons.palette_outlined);
      expect(
        themeTile.subtitle.startsWith('Current: '),
        isTrue,
        reason: 'subtitle should surface the active theme mode '
            '(found "${themeTile.subtitle}")',
      );

      final tileFinder = find.ancestor(
        of: find.text('Theme'),
        matching: find.byType(SettingsMenuTile),
      );
      expect(
        find.descendant(
          of: tileFinder,
          matching: find.byIcon(Icons.chevron_right),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: tileFinder,
          matching: find.byIcon(Icons.palette_outlined),
        ),
        findsOneWidget,
      );
    });

    testWidgets(
        'tapping the Theme tile navigates to ThemeSettingsScreen',
        (tester) async {
      await pumpApp(tester, const ProfileScreen(), overrides: overrides);

      await tester.scrollUntilVisible(
        find.text('Theme'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      await tester.tap(find.text('Theme'));
      await tester.pumpAndSettle();

      expect(find.byType(ThemeSettingsScreen), findsOneWidget);
    });
  });
}
