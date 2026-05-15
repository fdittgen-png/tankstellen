import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'theme_mode_provider.g.dart';

/// The app's theme choice — the three Material modes plus the green
/// **Eco** theme (#1712).
///
/// `eco` is not a Flutter [ThemeMode]; it resolves to [ThemeMode.light]
/// and the app passes `AppTheme.eco()` as `MaterialApp.theme` when this
/// choice is active. See [themeMode].
enum AppThemeChoice {
  system,
  light,
  dark,
  eco;

  /// The Flutter [ThemeMode] this choice resolves to. `eco` uses the
  /// light slot — `AppTheme.eco()` is supplied as `MaterialApp.theme`.
  ThemeMode get themeMode => switch (this) {
        AppThemeChoice.system => ThemeMode.system,
        AppThemeChoice.light => ThemeMode.light,
        AppThemeChoice.dark => ThemeMode.dark,
        AppThemeChoice.eco => ThemeMode.light,
      };
}

/// Persisted theme preference (#752; Eco theme added #1712).
///
/// Stored as a plain string in SharedPreferences rather than Hive —
/// the value is device-local (not profile-bound), read on startup
/// before any Hive box is open, and tiny. SharedPreferences is the
/// right tool for this kind of "one-string-per-device" setting.
///
/// The pattern mirrors `activeLanguageProvider` — the app's other
/// strictly-device-local preference.
@Riverpod(keepAlive: true)
class ThemeModeSetting extends _$ThemeModeSetting {
  static const _prefsKey = 'settings.themeMode';

  @override
  AppThemeChoice build() {
    _load();
    return AppThemeChoice.system;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    final restored = _parse(raw);
    if (restored != state) state = restored;
  }

  Future<void> set(AppThemeChoice choice) async {
    state = choice;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, _serialize(choice));
  }

  static AppThemeChoice _parse(String? raw) {
    switch (raw) {
      case 'light':
        return AppThemeChoice.light;
      case 'dark':
        return AppThemeChoice.dark;
      case 'eco':
        return AppThemeChoice.eco;
      case 'system':
      default:
        return AppThemeChoice.system;
    }
  }

  static String _serialize(AppThemeChoice choice) => switch (choice) {
        AppThemeChoice.light => 'light',
        AppThemeChoice.dark => 'dark',
        AppThemeChoice.eco => 'eco',
        AppThemeChoice.system => 'system',
      };
}
