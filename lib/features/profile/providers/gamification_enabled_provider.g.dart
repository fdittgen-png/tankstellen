// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gamification_enabled_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Master gate for gamification surfaces (#1194).
///
/// As of #1373 phase 3b this is a thin shim over [featureFlagsProvider]
/// — the canonical state lives in the central feature-flag set keyed by
/// [Feature.gamification]. The legacy `UserProfile.gamificationEnabled`
/// field is read once by `legacyToggleMigrationProvider` on first
/// launch after upgrade (gated on a `gamificationMigratedKey` flag in
/// the settings box) and promoted into the central set; subsequent
/// reads/writes go through here.
///
/// The manifest defaults [Feature.gamification] to `true`, so
/// fresh-install users see the same behaviour they had before this
/// migration. Users who had toggled `gamificationEnabled = false` keep
/// their preference because the migrator preserves the explicit-false
/// value through the gate.
///
/// Consumers wrap their gamification UI with:
/// ```dart
/// if (!ref.watch(gamificationEnabledProvider)) {
///   return const SizedBox.shrink();
/// }
/// ```
///
/// The achievement-engine itself is intentionally NOT gated — it keeps
/// running so that toggling back on instantly restores any badges
/// earned during the opt-out window.

@ProviderFor(GamificationEnabled)
final gamificationEnabledProvider = GamificationEnabledProvider._();

/// Master gate for gamification surfaces (#1194).
///
/// As of #1373 phase 3b this is a thin shim over [featureFlagsProvider]
/// — the canonical state lives in the central feature-flag set keyed by
/// [Feature.gamification]. The legacy `UserProfile.gamificationEnabled`
/// field is read once by `legacyToggleMigrationProvider` on first
/// launch after upgrade (gated on a `gamificationMigratedKey` flag in
/// the settings box) and promoted into the central set; subsequent
/// reads/writes go through here.
///
/// The manifest defaults [Feature.gamification] to `true`, so
/// fresh-install users see the same behaviour they had before this
/// migration. Users who had toggled `gamificationEnabled = false` keep
/// their preference because the migrator preserves the explicit-false
/// value through the gate.
///
/// Consumers wrap their gamification UI with:
/// ```dart
/// if (!ref.watch(gamificationEnabledProvider)) {
///   return const SizedBox.shrink();
/// }
/// ```
///
/// The achievement-engine itself is intentionally NOT gated — it keeps
/// running so that toggling back on instantly restores any badges
/// earned during the opt-out window.
final class GamificationEnabledProvider
    extends $NotifierProvider<GamificationEnabled, bool> {
  /// Master gate for gamification surfaces (#1194).
  ///
  /// As of #1373 phase 3b this is a thin shim over [featureFlagsProvider]
  /// — the canonical state lives in the central feature-flag set keyed by
  /// [Feature.gamification]. The legacy `UserProfile.gamificationEnabled`
  /// field is read once by `legacyToggleMigrationProvider` on first
  /// launch after upgrade (gated on a `gamificationMigratedKey` flag in
  /// the settings box) and promoted into the central set; subsequent
  /// reads/writes go through here.
  ///
  /// The manifest defaults [Feature.gamification] to `true`, so
  /// fresh-install users see the same behaviour they had before this
  /// migration. Users who had toggled `gamificationEnabled = false` keep
  /// their preference because the migrator preserves the explicit-false
  /// value through the gate.
  ///
  /// Consumers wrap their gamification UI with:
  /// ```dart
  /// if (!ref.watch(gamificationEnabledProvider)) {
  ///   return const SizedBox.shrink();
  /// }
  /// ```
  ///
  /// The achievement-engine itself is intentionally NOT gated — it keeps
  /// running so that toggling back on instantly restores any badges
  /// earned during the opt-out window.
  GamificationEnabledProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'gamificationEnabledProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$gamificationEnabledHash();

  @$internal
  @override
  GamificationEnabled create() => GamificationEnabled();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$gamificationEnabledHash() =>
    r'd7fcd834f133f5c0a09e13d51100bc49cb785a50';

/// Master gate for gamification surfaces (#1194).
///
/// As of #1373 phase 3b this is a thin shim over [featureFlagsProvider]
/// — the canonical state lives in the central feature-flag set keyed by
/// [Feature.gamification]. The legacy `UserProfile.gamificationEnabled`
/// field is read once by `legacyToggleMigrationProvider` on first
/// launch after upgrade (gated on a `gamificationMigratedKey` flag in
/// the settings box) and promoted into the central set; subsequent
/// reads/writes go through here.
///
/// The manifest defaults [Feature.gamification] to `true`, so
/// fresh-install users see the same behaviour they had before this
/// migration. Users who had toggled `gamificationEnabled = false` keep
/// their preference because the migrator preserves the explicit-false
/// value through the gate.
///
/// Consumers wrap their gamification UI with:
/// ```dart
/// if (!ref.watch(gamificationEnabledProvider)) {
///   return const SizedBox.shrink();
/// }
/// ```
///
/// The achievement-engine itself is intentionally NOT gated — it keeps
/// running so that toggling back on instantly restores any badges
/// earned during the opt-out window.

abstract class _$GamificationEnabled extends $Notifier<bool> {
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
