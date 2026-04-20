// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_mode_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Persisted theme-mode preference (#752).
///
/// Stored as a plain string in SharedPreferences rather than Hive —
/// the value is device-local (not profile-bound), read on startup
/// before any Hive box is open, and tiny. SharedPreferences is the
/// right tool for this kind of "one-string-per-device" setting.
///
/// The pattern mirrors `activeLanguageProvider` — the app's other
/// strictly-device-local preference.

@ProviderFor(ThemeModeSetting)
final themeModeSettingProvider = ThemeModeSettingProvider._();

/// Persisted theme-mode preference (#752).
///
/// Stored as a plain string in SharedPreferences rather than Hive —
/// the value is device-local (not profile-bound), read on startup
/// before any Hive box is open, and tiny. SharedPreferences is the
/// right tool for this kind of "one-string-per-device" setting.
///
/// The pattern mirrors `activeLanguageProvider` — the app's other
/// strictly-device-local preference.
final class ThemeModeSettingProvider
    extends $NotifierProvider<ThemeModeSetting, ThemeMode> {
  /// Persisted theme-mode preference (#752).
  ///
  /// Stored as a plain string in SharedPreferences rather than Hive —
  /// the value is device-local (not profile-bound), read on startup
  /// before any Hive box is open, and tiny. SharedPreferences is the
  /// right tool for this kind of "one-string-per-device" setting.
  ///
  /// The pattern mirrors `activeLanguageProvider` — the app's other
  /// strictly-device-local preference.
  ThemeModeSettingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'themeModeSettingProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$themeModeSettingHash();

  @$internal
  @override
  ThemeModeSetting create() => ThemeModeSetting();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ThemeMode value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ThemeMode>(value),
    );
  }
}

String _$themeModeSettingHash() => r'391748e063daef817d379f2abdebd42cbe07c8ff';

/// Persisted theme-mode preference (#752).
///
/// Stored as a plain string in SharedPreferences rather than Hive —
/// the value is device-local (not profile-bound), read on startup
/// before any Hive box is open, and tiny. SharedPreferences is the
/// right tool for this kind of "one-string-per-device" setting.
///
/// The pattern mirrors `activeLanguageProvider` — the app's other
/// strictly-device-local preference.

abstract class _$ThemeModeSetting extends $Notifier<ThemeMode> {
  ThemeMode build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ThemeMode, ThemeMode>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ThemeMode, ThemeMode>,
              ThemeMode,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
