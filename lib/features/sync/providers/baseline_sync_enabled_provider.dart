import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../feature_management/application/feature_flags_provider.dart';
import '../../feature_management/domain/feature.dart';

part 'baseline_sync_enabled_provider.g.dart';

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
@Riverpod(keepAlive: true)
class BaselineSyncEnabled extends _$BaselineSyncEnabled {
  @override
  bool build() {
    return ref.watch(featureFlagsProvider).contains(Feature.baselineSync);
  }

  /// Delegate to [featureFlagsProvider]'s `enable` / `disable`. The
  /// downstream `_syncBaselineAfterFlush` reads this value via
  /// `ref.read` at flush time — there's no reactive subscriber to
  /// invalidate, so the only consumer of a state flip is the next
  /// trip's flush.
  ///
  /// A [StateError] from a dependency-violation is intentionally
  /// swallowed and the toggle stays at its prior state — see the
  /// catch block below for why.
  Future<void> set(bool value) async {
    final notifier = ref.read(featureFlagsProvider.notifier);
    try {
      if (value) {
        await notifier.enable(Feature.baselineSync);
      } else {
        await notifier.disable(Feature.baselineSync);
      }
      // The central provider throws a StateError specifically for
      // dependency-violation (Feature.baselineSync requires
      // Feature.tankSync per the manifest); we want to swallow ONLY
      // that — see the body comment for why. The lint deliberately
      // discourages catching Error subclasses, but the central API's
      // contract documents this exact StateError as the
      // dependency-violation signal, so the catch is intentional and
      // narrow.
      // ignore: avoid_catching_errors
    } on StateError {
      // TODO(1373): The settings UI's canEnable / blockingDisable
      // pre-check already guards against the dependency-violation
      // path before invoking this setter, so a StateError here is a
      // defensive-only catch — the UI path can't currently reach it.
      // We swallow rather than rethrow so a programmatic caller (e.g.
      // a test or the trip-recording flush hook) sees the toggle stay
      // at its prior state instead of crashing the widget tree.
      // Remove once every call site has been audited for canEnable
      // pre-check coverage.
    }
  }
}
