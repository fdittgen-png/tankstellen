import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tankstellen/core/theme/theme_mode_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(const {});
  });

  group('themeModeSettingProvider (#752)', () {
    test('defaults to ThemeMode.system on first launch', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(themeModeSettingProvider), ThemeMode.system);
    });

    test('restores a previously-persisted ThemeMode on startup', () async {
      SharedPreferences.setMockInitialValues(const {
        'settings.themeMode': 'dark',
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // _load fires async on build; give the microtask queue a chance.
      container.read(themeModeSettingProvider);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(themeModeSettingProvider), ThemeMode.dark);
    });

    test('set() updates the in-memory state and persists to prefs',
        () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container
          .read(themeModeSettingProvider.notifier)
          .set(ThemeMode.light);

      expect(container.read(themeModeSettingProvider), ThemeMode.light);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('settings.themeMode'), 'light');
    });

    test('set(system) persists the system keyword', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container
          .read(themeModeSettingProvider.notifier)
          .set(ThemeMode.system);

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

      expect(container.read(themeModeSettingProvider), ThemeMode.system);
    });
  });
}
