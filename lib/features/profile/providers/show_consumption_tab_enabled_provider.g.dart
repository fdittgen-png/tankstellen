// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'show_consumption_tab_enabled_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Visibility gate for the consumption analytics tab in the bottom
/// navigation (#1373 phase 3c).
///
/// Thin shim over [featureFlagsProvider] — the canonical state lives in
/// the central feature-flag set keyed by [Feature.showConsumptionTab].
/// The legacy `UserProfile.showConsumptionTab` field is read once by
/// `legacyToggleMigrationProvider` on first launch after upgrade
/// (gated on a `showConsumptionTabMigratedKey` flag in the settings
/// box) and promoted into the central set; subsequent reads/writes go
/// through here.
///
/// The manifest defaults [Feature.showConsumptionTab] to `true` with
/// `requires: {Feature.obd2TripRecording}`. Because `obd2TripRecording`
/// defaults to `false`, the consumption tab is effectively hidden on
/// fresh installs until the user enables trip recording — matching
/// the original user-facing shape where the legacy field defaulted to
/// `false`.
///
/// Consumers wrap their consumption-tab UI with:
/// ```dart
/// if (!ref.watch(showConsumptionTabEnabledProvider)) {
///   // hide the bottom-nav tab, route entry, etc.
/// }
/// ```

@ProviderFor(ShowConsumptionTabEnabled)
final showConsumptionTabEnabledProvider = ShowConsumptionTabEnabledProvider._();

/// Visibility gate for the consumption analytics tab in the bottom
/// navigation (#1373 phase 3c).
///
/// Thin shim over [featureFlagsProvider] — the canonical state lives in
/// the central feature-flag set keyed by [Feature.showConsumptionTab].
/// The legacy `UserProfile.showConsumptionTab` field is read once by
/// `legacyToggleMigrationProvider` on first launch after upgrade
/// (gated on a `showConsumptionTabMigratedKey` flag in the settings
/// box) and promoted into the central set; subsequent reads/writes go
/// through here.
///
/// The manifest defaults [Feature.showConsumptionTab] to `true` with
/// `requires: {Feature.obd2TripRecording}`. Because `obd2TripRecording`
/// defaults to `false`, the consumption tab is effectively hidden on
/// fresh installs until the user enables trip recording — matching
/// the original user-facing shape where the legacy field defaulted to
/// `false`.
///
/// Consumers wrap their consumption-tab UI with:
/// ```dart
/// if (!ref.watch(showConsumptionTabEnabledProvider)) {
///   // hide the bottom-nav tab, route entry, etc.
/// }
/// ```
final class ShowConsumptionTabEnabledProvider
    extends $NotifierProvider<ShowConsumptionTabEnabled, bool> {
  /// Visibility gate for the consumption analytics tab in the bottom
  /// navigation (#1373 phase 3c).
  ///
  /// Thin shim over [featureFlagsProvider] — the canonical state lives in
  /// the central feature-flag set keyed by [Feature.showConsumptionTab].
  /// The legacy `UserProfile.showConsumptionTab` field is read once by
  /// `legacyToggleMigrationProvider` on first launch after upgrade
  /// (gated on a `showConsumptionTabMigratedKey` flag in the settings
  /// box) and promoted into the central set; subsequent reads/writes go
  /// through here.
  ///
  /// The manifest defaults [Feature.showConsumptionTab] to `true` with
  /// `requires: {Feature.obd2TripRecording}`. Because `obd2TripRecording`
  /// defaults to `false`, the consumption tab is effectively hidden on
  /// fresh installs until the user enables trip recording — matching
  /// the original user-facing shape where the legacy field defaulted to
  /// `false`.
  ///
  /// Consumers wrap their consumption-tab UI with:
  /// ```dart
  /// if (!ref.watch(showConsumptionTabEnabledProvider)) {
  ///   // hide the bottom-nav tab, route entry, etc.
  /// }
  /// ```
  ShowConsumptionTabEnabledProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'showConsumptionTabEnabledProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$showConsumptionTabEnabledHash();

  @$internal
  @override
  ShowConsumptionTabEnabled create() => ShowConsumptionTabEnabled();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$showConsumptionTabEnabledHash() =>
    r'b1d95666bbb747757a72e03ebb23e242657dd78e';

/// Visibility gate for the consumption analytics tab in the bottom
/// navigation (#1373 phase 3c).
///
/// Thin shim over [featureFlagsProvider] — the canonical state lives in
/// the central feature-flag set keyed by [Feature.showConsumptionTab].
/// The legacy `UserProfile.showConsumptionTab` field is read once by
/// `legacyToggleMigrationProvider` on first launch after upgrade
/// (gated on a `showConsumptionTabMigratedKey` flag in the settings
/// box) and promoted into the central set; subsequent reads/writes go
/// through here.
///
/// The manifest defaults [Feature.showConsumptionTab] to `true` with
/// `requires: {Feature.obd2TripRecording}`. Because `obd2TripRecording`
/// defaults to `false`, the consumption tab is effectively hidden on
/// fresh installs until the user enables trip recording — matching
/// the original user-facing shape where the legacy field defaulted to
/// `false`.
///
/// Consumers wrap their consumption-tab UI with:
/// ```dart
/// if (!ref.watch(showConsumptionTabEnabledProvider)) {
///   // hide the bottom-nav tab, route entry, etc.
/// }
/// ```

abstract class _$ShowConsumptionTabEnabled extends $Notifier<bool> {
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
