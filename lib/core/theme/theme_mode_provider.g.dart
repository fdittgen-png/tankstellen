// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_mode_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Persisted theme preference (#752; Eco theme added #1712).
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

/// Persisted theme preference (#752; Eco theme added #1712).
///
/// Stored as a plain string in SharedPreferences rather than Hive —
/// the value is device-local (not profile-bound), read on startup
/// before any Hive box is open, and tiny. SharedPreferences is the
/// right tool for this kind of "one-string-per-device" setting.
///
/// The pattern mirrors `activeLanguageProvider` — the app's other
/// strictly-device-local preference.
final class ThemeModeSettingProvider
    extends $NotifierProvider<ThemeModeSetting, AppThemeChoice> {
  /// Persisted theme preference (#752; Eco theme added #1712).
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
  Override overrideWithValue(AppThemeChoice value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppThemeChoice>(value),
    );
  }
}

String _$themeModeSettingHash() => r'a31a377f69c08674f0d53d90f83868c8b3ed5277';

/// Persisted theme preference (#752; Eco theme added #1712).
///
/// Stored as a plain string in SharedPreferences rather than Hive —
/// the value is device-local (not profile-bound), read on startup
/// before any Hive box is open, and tiny. SharedPreferences is the
/// right tool for this kind of "one-string-per-device" setting.
///
/// The pattern mirrors `activeLanguageProvider` — the app's other
/// strictly-device-local preference.

abstract class _$ThemeModeSetting extends $Notifier<AppThemeChoice> {
  AppThemeChoice build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AppThemeChoice, AppThemeChoice>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AppThemeChoice, AppThemeChoice>,
              AppThemeChoice,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
