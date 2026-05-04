// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'show_electric_enabled_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Visibility gate for EV charging-station results in search and on
/// the map (#1373 phase 3c).
///
/// Thin shim over [featureFlagsProvider] — the canonical state lives in
/// the central feature-flag set keyed by [Feature.showElectric]. The
/// legacy `UserProfile.showElectric` field is read once by
/// `legacyToggleMigrationProvider` on first launch after upgrade
/// (gated on a `showElectricMigratedKey` flag in the settings box) and
/// promoted into the central set; subsequent reads/writes go through
/// here.
///
/// The manifest defaults [Feature.showElectric] to `true`, so
/// fresh-install users see the same behaviour they had before this
/// migration. Users who had toggled `showElectric = false` keep their
/// preference because the migrator preserves the explicit-false value
/// through the gate.
///
/// Consumers wrap their EV-station UI with:
/// ```dart
/// if (!ref.watch(showElectricEnabledProvider)) {
///   // hide EV chips, charging-station results, map markers …
/// }
/// ```

@ProviderFor(ShowElectricEnabled)
final showElectricEnabledProvider = ShowElectricEnabledProvider._();

/// Visibility gate for EV charging-station results in search and on
/// the map (#1373 phase 3c).
///
/// Thin shim over [featureFlagsProvider] — the canonical state lives in
/// the central feature-flag set keyed by [Feature.showElectric]. The
/// legacy `UserProfile.showElectric` field is read once by
/// `legacyToggleMigrationProvider` on first launch after upgrade
/// (gated on a `showElectricMigratedKey` flag in the settings box) and
/// promoted into the central set; subsequent reads/writes go through
/// here.
///
/// The manifest defaults [Feature.showElectric] to `true`, so
/// fresh-install users see the same behaviour they had before this
/// migration. Users who had toggled `showElectric = false` keep their
/// preference because the migrator preserves the explicit-false value
/// through the gate.
///
/// Consumers wrap their EV-station UI with:
/// ```dart
/// if (!ref.watch(showElectricEnabledProvider)) {
///   // hide EV chips, charging-station results, map markers …
/// }
/// ```
final class ShowElectricEnabledProvider
    extends $NotifierProvider<ShowElectricEnabled, bool> {
  /// Visibility gate for EV charging-station results in search and on
  /// the map (#1373 phase 3c).
  ///
  /// Thin shim over [featureFlagsProvider] — the canonical state lives in
  /// the central feature-flag set keyed by [Feature.showElectric]. The
  /// legacy `UserProfile.showElectric` field is read once by
  /// `legacyToggleMigrationProvider` on first launch after upgrade
  /// (gated on a `showElectricMigratedKey` flag in the settings box) and
  /// promoted into the central set; subsequent reads/writes go through
  /// here.
  ///
  /// The manifest defaults [Feature.showElectric] to `true`, so
  /// fresh-install users see the same behaviour they had before this
  /// migration. Users who had toggled `showElectric = false` keep their
  /// preference because the migrator preserves the explicit-false value
  /// through the gate.
  ///
  /// Consumers wrap their EV-station UI with:
  /// ```dart
  /// if (!ref.watch(showElectricEnabledProvider)) {
  ///   // hide EV chips, charging-station results, map markers …
  /// }
  /// ```
  ShowElectricEnabledProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'showElectricEnabledProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$showElectricEnabledHash();

  @$internal
  @override
  ShowElectricEnabled create() => ShowElectricEnabled();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$showElectricEnabledHash() =>
    r'3b6edfca1b0b3f02f61bb7884fbe808a33a3cfca';

/// Visibility gate for EV charging-station results in search and on
/// the map (#1373 phase 3c).
///
/// Thin shim over [featureFlagsProvider] — the canonical state lives in
/// the central feature-flag set keyed by [Feature.showElectric]. The
/// legacy `UserProfile.showElectric` field is read once by
/// `legacyToggleMigrationProvider` on first launch after upgrade
/// (gated on a `showElectricMigratedKey` flag in the settings box) and
/// promoted into the central set; subsequent reads/writes go through
/// here.
///
/// The manifest defaults [Feature.showElectric] to `true`, so
/// fresh-install users see the same behaviour they had before this
/// migration. Users who had toggled `showElectric = false` keep their
/// preference because the migrator preserves the explicit-false value
/// through the gate.
///
/// Consumers wrap their EV-station UI with:
/// ```dart
/// if (!ref.watch(showElectricEnabledProvider)) {
///   // hide EV chips, charging-station results, map markers …
/// }
/// ```

abstract class _$ShowElectricEnabled extends $Notifier<bool> {
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
