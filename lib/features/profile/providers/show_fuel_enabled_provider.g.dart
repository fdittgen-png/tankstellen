// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'show_fuel_enabled_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Visibility gate for fuel-station results in search and on the map
/// (#1373 phase 3c).
///
/// Thin shim over [featureFlagsProvider] — the canonical state lives in
/// the central feature-flag set keyed by [Feature.showFuel]. The legacy
/// `UserProfile.showFuel` field is read once by
/// `legacyToggleMigrationProvider` on first launch after upgrade
/// (gated on a `showFuelMigratedKey` flag in the settings box) and
/// promoted into the central set; subsequent reads/writes go through
/// here.
///
/// The manifest defaults [Feature.showFuel] to `true`, so fresh-install
/// users see the same behaviour they had before this migration. Users
/// who had toggled `showFuel = false` keep their preference because
/// the migrator preserves the explicit-false value through the gate.
///
/// Consumers wrap their fuel-station UI with:
/// ```dart
/// if (!ref.watch(showFuelEnabledProvider)) {
///   // hide fuel station chips, results, map markers …
/// }
/// ```

@ProviderFor(ShowFuelEnabled)
final showFuelEnabledProvider = ShowFuelEnabledProvider._();

/// Visibility gate for fuel-station results in search and on the map
/// (#1373 phase 3c).
///
/// Thin shim over [featureFlagsProvider] — the canonical state lives in
/// the central feature-flag set keyed by [Feature.showFuel]. The legacy
/// `UserProfile.showFuel` field is read once by
/// `legacyToggleMigrationProvider` on first launch after upgrade
/// (gated on a `showFuelMigratedKey` flag in the settings box) and
/// promoted into the central set; subsequent reads/writes go through
/// here.
///
/// The manifest defaults [Feature.showFuel] to `true`, so fresh-install
/// users see the same behaviour they had before this migration. Users
/// who had toggled `showFuel = false` keep their preference because
/// the migrator preserves the explicit-false value through the gate.
///
/// Consumers wrap their fuel-station UI with:
/// ```dart
/// if (!ref.watch(showFuelEnabledProvider)) {
///   // hide fuel station chips, results, map markers …
/// }
/// ```
final class ShowFuelEnabledProvider
    extends $NotifierProvider<ShowFuelEnabled, bool> {
  /// Visibility gate for fuel-station results in search and on the map
  /// (#1373 phase 3c).
  ///
  /// Thin shim over [featureFlagsProvider] — the canonical state lives in
  /// the central feature-flag set keyed by [Feature.showFuel]. The legacy
  /// `UserProfile.showFuel` field is read once by
  /// `legacyToggleMigrationProvider` on first launch after upgrade
  /// (gated on a `showFuelMigratedKey` flag in the settings box) and
  /// promoted into the central set; subsequent reads/writes go through
  /// here.
  ///
  /// The manifest defaults [Feature.showFuel] to `true`, so fresh-install
  /// users see the same behaviour they had before this migration. Users
  /// who had toggled `showFuel = false` keep their preference because
  /// the migrator preserves the explicit-false value through the gate.
  ///
  /// Consumers wrap their fuel-station UI with:
  /// ```dart
  /// if (!ref.watch(showFuelEnabledProvider)) {
  ///   // hide fuel station chips, results, map markers …
  /// }
  /// ```
  ShowFuelEnabledProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'showFuelEnabledProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$showFuelEnabledHash();

  @$internal
  @override
  ShowFuelEnabled create() => ShowFuelEnabled();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$showFuelEnabledHash() => r'8684b30abfec185bc65a3f64a54e1be453ca35f6';

/// Visibility gate for fuel-station results in search and on the map
/// (#1373 phase 3c).
///
/// Thin shim over [featureFlagsProvider] — the canonical state lives in
/// the central feature-flag set keyed by [Feature.showFuel]. The legacy
/// `UserProfile.showFuel` field is read once by
/// `legacyToggleMigrationProvider` on first launch after upgrade
/// (gated on a `showFuelMigratedKey` flag in the settings box) and
/// promoted into the central set; subsequent reads/writes go through
/// here.
///
/// The manifest defaults [Feature.showFuel] to `true`, so fresh-install
/// users see the same behaviour they had before this migration. Users
/// who had toggled `showFuel = false` keep their preference because
/// the migrator preserves the explicit-false value through the gate.
///
/// Consumers wrap their fuel-station UI with:
/// ```dart
/// if (!ref.watch(showFuelEnabledProvider)) {
///   // hide fuel station chips, results, map markers …
/// }
/// ```

abstract class _$ShowFuelEnabled extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
