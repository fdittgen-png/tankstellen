import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/core/theme/theme_mode_provider.dart';
import 'package:tankstellen/features/profile/presentation/screens/profile_screen.dart';
import 'package:tankstellen/features/profile/presentation/widgets/settings_menu_tile.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';
import '../../../../mocks/mocks.dart';

/// Test-only ThemeModeSetting that exposes a fixed `build()` value and
/// skips the real provider's SharedPreferences load — it would fail in
/// widget tests where plugin channels are not registered.
class _FixedThemeMode extends ThemeModeSetting {
  final ThemeMode _initial;
  _FixedThemeMode(this._initial);

  @override
  ThemeMode build() => _initial;

  @override
  Future<void> set(ThemeMode mode) async {
    state = mode;
  }
}

void main() {
  group('ProfileScreen Theme card (#897)', () {
    late MockHiveStorage mockStorage;

    List<Object> buildOverrides(ThemeMode themeMode) {
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
      return [
        hiveStorageProvider.overrideWithValue(mockStorage),
        ...test.overrides.skip(1),
        themeModeSettingProvider.overrideWith(() => _FixedThemeMode(themeMode)),
      ];
    }

    testWidgets(
        'Theme row is a SettingsMenuTile — same shape as Privacy + Storage '
        'instead of a bespoke bottom-sheet tile', (tester) async {
      await pumpApp(
        tester,
        const ProfileScreen(),
        overrides: buildOverrides(ThemeMode.system),
      );

      // Scroll so the Theme card is realized in the ListView.
      await tester.scrollUntilVisible(
        find.text('Theme'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      // A SettingsMenuTile exists with title "Theme" and a subtitle
      // that reflects the active ThemeMode (here: System).
      final themeTiles = tester
          .widgetList<SettingsMenuTile>(find.byType(SettingsMenuTile))
          .where((t) => t.title == 'Theme')
          .toList();
      expect(
        themeTiles.length,
        1,
        reason: '#897: there must be exactly one Theme SettingsMenuTile '
            'on the Settings screen',
      );
      expect(
        themeTiles.single.subtitle,
        'System',
        reason: '#897: the Theme card subtitle reflects the active '
            'ThemeMode.system — "System"',
      );
    });

    testWidgets('Theme subtitle reads "Light" when ThemeMode is light',
        (tester) async {
      await pumpApp(
        tester,
        const ProfileScreen(),
        overrides: buildOverrides(ThemeMode.light),
      );

      await tester.scrollUntilVisible(
        find.text('Theme'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      final themeTile = tester
          .widgetList<SettingsMenuTile>(find.byType(SettingsMenuTile))
          .firstWhere((t) => t.title == 'Theme');
      expect(themeTile.subtitle, 'Light');
    });

    testWidgets('Theme subtitle reads "Dark" when ThemeMode is dark',
        (tester) async {
      await pumpApp(
        tester,
        const ProfileScreen(),
        overrides: buildOverrides(ThemeMode.dark),
      );

      await tester.scrollUntilVisible(
        find.text('Theme'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      final themeTile = tester
          .widgetList<SettingsMenuTile>(find.byType(SettingsMenuTile))
          .firstWhere((t) => t.title == 'Theme');
      expect(themeTile.subtitle, 'Dark');
    });

    testWidgets(
        'legacy ThemeModeTile widget is NOT used on the Settings screen '
        '— it was replaced by a SettingsMenuTile in #897', (tester) async {
      await pumpApp(
        tester,
        const ProfileScreen(),
        overrides: buildOverrides(ThemeMode.system),
      );

      // The bespoke Theme bottom-sheet tile had key 'themeModeTile'.
      // After #897 that widget no longer appears on the Settings
      // screen — navigation goes to /theme-settings instead of
      // opening a sheet.
      expect(find.byKey(const Key('themeModeTile')), findsNothing);
    });
  });
}
