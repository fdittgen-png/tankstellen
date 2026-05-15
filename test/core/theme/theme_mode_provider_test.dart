import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tankstellen/core/theme/theme_mode_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(const {});
  });

  group('themeModeSettingProvider (#752; Eco theme #1712)', () {
    test('defaults to AppThemeChoice.system on first launch', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(themeModeSettingProvider),
        AppThemeChoice.system,
      );
    });

    test('restores a previously-persisted choice on startup', () async {
      SharedPreferences.setMockInitialValues(const {
        'settings.themeMode': 'dark',
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(themeModeSettingProvider);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(themeModeSettingProvider), AppThemeChoice.dark);
    });

    test('set() updates the in-memory state and persists to prefs',
        () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container
          .read(themeModeSettingProvider.notifier)
          .set(AppThemeChoice.light);

      expect(container.read(themeModeSettingProvider), AppThemeChoice.light);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('settings.themeMode'), 'light');
    });

    test('set(system) persists the system keyword', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container
          .read(themeModeSettingProvider.notifier)
          .set(AppThemeChoice.system);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('settings.themeMode'), 'system');
    });

    test('unknown persisted value falls back to system', () async {
      SharedPreferences.setMockInitialValues(const {
        'settings.themeMode': 'bogus',
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(themeModeSettingProvider);
      await Future<void>.delayed(Duration.zero);

      expect(
        container.read(themeModeSettingProvider),
        AppThemeChoice.system,
      );
    });

    group('Eco theme (#1712)', () {
      test('set(eco) updates state and persists the "eco" keyword',
          () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        await container
            .read(themeModeSettingProvider.notifier)
            .set(AppThemeChoice.eco);

        expect(container.read(themeModeSettingProvider), AppThemeChoice.eco);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('settings.themeMode'), 'eco');
      });

      test('restores a persisted "eco" choice on startup', () async {
        SharedPreferences.setMockInitialValues(const {
          'settings.themeMode': 'eco',
        });
        final container = ProviderContainer();
        addTearDown(container.dispose);

        container.read(themeModeSettingProvider);
        await Future<void>.delayed(Duration.zero);

        expect(container.read(themeModeSettingProvider), AppThemeChoice.eco);
      });

      test('eco resolves to the light ThemeMode slot', () {
        // The Eco theme is light-family — never dark. The app supplies
        // AppTheme.eco() as MaterialApp.theme when this choice is active.
        expect(AppThemeChoice.eco.themeMode, ThemeMode.light);
      });

      test('each choice maps to the expected ThemeMode', () {
        expect(AppThemeChoice.system.themeMode, ThemeMode.system);
        expect(AppThemeChoice.light.themeMode, ThemeMode.light);
        expect(AppThemeChoice.dark.themeMode, ThemeMode.dark);
      });
    });
  });
}
