// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_app_bar_action.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Where the Settings (Profile) branch returns to when its top-left back arrow
/// is tapped (#3061). [SettingsAppBarAction] records it from the app's reliable
/// branch tracker the moment the gear is tapped, so `ProfileScreen`'s back
/// button is a TRUE "back" to wherever the user came from. Defaults to home
/// (`/`).

@ProviderFor(SettingsReturnLocation)
final settingsReturnLocationProvider = SettingsReturnLocationProvider._();

/// Where the Settings (Profile) branch returns to when its top-left back arrow
/// is tapped (#3061). [SettingsAppBarAction] records it from the app's reliable
/// branch tracker the moment the gear is tapped, so `ProfileScreen`'s back
/// button is a TRUE "back" to wherever the user came from. Defaults to home
/// (`/`).
final class SettingsReturnLocationProvider
    extends $NotifierProvider<SettingsReturnLocation, String> {
  /// Where the Settings (Profile) branch returns to when its top-left back arrow
  /// is tapped (#3061). [SettingsAppBarAction] records it from the app's reliable
  /// branch tracker the moment the gear is tapped, so `ProfileScreen`'s back
  /// button is a TRUE "back" to wherever the user came from. Defaults to home
  /// (`/`).
  SettingsReturnLocationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'settingsReturnLocationProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$settingsReturnLocationHash();

  @$internal
  @override
  SettingsReturnLocation create() => SettingsReturnLocation();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$settingsReturnLocationHash() =>
    r'465f0edabba12b0c501f6142feb4c5a1c88fec58';

/// Where the Settings (Profile) branch returns to when its top-left back arrow
/// is tapped (#3061). [SettingsAppBarAction] records it from the app's reliable
/// branch tracker the moment the gear is tapped, so `ProfileScreen`'s back
/// button is a TRUE "back" to wherever the user came from. Defaults to home
/// (`/`).

abstract class _$SettingsReturnLocation extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
