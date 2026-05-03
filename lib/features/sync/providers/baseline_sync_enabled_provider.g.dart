// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'baseline_sync_enabled_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Persisted opt-in switch for per-vehicle driving-baseline sync via
/// TankSync (#780). As of #1373 phase 3e this is a thin shim over
/// [featureFlagsProvider] — the canonical state lives in the central
/// feature-flag set keyed by [Feature.baselineSync]. The legacy
/// [StorageKeys.syncBaselinesEnabled] Hive-settings key is read once
/// by the `legacyToggleMigrationProvider` on first launch after
/// upgrade and promoted into the central set; subsequent reads/writes
/// go through here.
///
/// [Feature.baselineSync] declares [Feature.tankSync] as a hard
/// prerequisite in the manifest, so a `set(true)` will fail unless
/// `tankSync` is already enabled (the migrator cascade-enables both).
/// The settings UI is expected to pre-check `canEnable` before invoking
/// the setter; the defensive `on StateError` catch below is a backstop
/// for programmatic callers that bypass that guard.
///
/// `keepAlive: true` so a flush at the end of a trip (which reads this
/// provider one-shot via `ref.read`) observes the same notifier as the
/// settings screen that flipped it.

@ProviderFor(BaselineSyncEnabled)
final baselineSyncEnabledProvider = BaselineSyncEnabledProvider._();

/// Persisted opt-in switch for per-vehicle driving-baseline sync via
/// TankSync (#780). As of #1373 phase 3e this is a thin shim over
/// [featureFlagsProvider] — the canonical state lives in the central
/// feature-flag set keyed by [Feature.baselineSync]. The legacy
/// [StorageKeys.syncBaselinesEnabled] Hive-settings key is read once
/// by the `legacyToggleMigrationProvider` on first launch after
/// upgrade and promoted into the central set; subsequent reads/writes
/// go through here.
///
/// [Feature.baselineSync] declares [Feature.tankSync] as a hard
/// prerequisite in the manifest, so a `set(true)` will fail unless
/// `tankSync` is already enabled (the migrator cascade-enables both).
/// The settings UI is expected to pre-check `canEnable` before invoking
/// the setter; the defensive `on StateError` catch below is a backstop
/// for programmatic callers that bypass that guard.
///
/// `keepAlive: true` so a flush at the end of a trip (which reads this
/// provider one-shot via `ref.read`) observes the same notifier as the
/// settings screen that flipped it.
final class BaselineSyncEnabledProvider
    extends $NotifierProvider<BaselineSyncEnabled, bool> {
  /// Persisted opt-in switch for per-vehicle driving-baseline sync via
  /// TankSync (#780). As of #1373 phase 3e this is a thin shim over
  /// [featureFlagsProvider] — the canonical state lives in the central
  /// feature-flag set keyed by [Feature.baselineSync]. The legacy
  /// [StorageKeys.syncBaselinesEnabled] Hive-settings key is read once
  /// by the `legacyToggleMigrationProvider` on first launch after
  /// upgrade and promoted into the central set; subsequent reads/writes
  /// go through here.
  ///
  /// [Feature.baselineSync] declares [Feature.tankSync] as a hard
  /// prerequisite in the manifest, so a `set(true)` will fail unless
  /// `tankSync` is already enabled (the migrator cascade-enables both).
  /// The settings UI is expected to pre-check `canEnable` before invoking
  /// the setter; the defensive `on StateError` catch below is a backstop
  /// for programmatic callers that bypass that guard.
  ///
  /// `keepAlive: true` so a flush at the end of a trip (which reads this
  /// provider one-shot via `ref.read`) observes the same notifier as the
  /// settings screen that flipped it.
  BaselineSyncEnabledProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'baselineSyncEnabledProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$baselineSyncEnabledHash();

  @$internal
  @override
  BaselineSyncEnabled create() => BaselineSyncEnabled();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$baselineSyncEnabledHash() =>
    r'f720cd43ea15882893d6be855bb2e8e1652732b1';

/// Persisted opt-in switch for per-vehicle driving-baseline sync via
/// TankSync (#780). As of #1373 phase 3e this is a thin shim over
/// [featureFlagsProvider] — the canonical state lives in the central
/// feature-flag set keyed by [Feature.baselineSync]. The legacy
/// [StorageKeys.syncBaselinesEnabled] Hive-settings key is read once
/// by the `legacyToggleMigrationProvider` on first launch after
/// upgrade and promoted into the central set; subsequent reads/writes
/// go through here.
///
/// [Feature.baselineSync] declares [Feature.tankSync] as a hard
/// prerequisite in the manifest, so a `set(true)` will fail unless
/// `tankSync` is already enabled (the migrator cascade-enables both).
/// The settings UI is expected to pre-check `canEnable` before invoking
/// the setter; the defensive `on StateError` catch below is a backstop
/// for programmatic callers that bypass that guard.
///
/// `keepAlive: true` so a flush at the end of a trip (which reads this
/// provider one-shot via `ref.read`) observes the same notifier as the
/// settings screen that flipped it.

abstract class _$BaselineSyncEnabled extends $Notifier<bool> {
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
