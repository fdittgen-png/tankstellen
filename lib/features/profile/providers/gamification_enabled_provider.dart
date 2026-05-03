import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../feature_management/application/feature_flags_provider.dart';
import '../../feature_management/domain/feature.dart';

part 'gamification_enabled_provider.g.dart';

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
@Riverpod(keepAlive: true)
class GamificationEnabled extends _$GamificationEnabled {
  @override
  bool build() {
    return ref.watch(featureFlagsProvider).contains(Feature.gamification);
  }

  /// Delegate to [featureFlagsProvider]'s `enable` / `disable`. The
  /// central provider enforces the manifest dependency graph
  /// ([Feature.gamification] requires [Feature.obd2TripRecording]) and
  /// throws [StateError] when a prerequisite is missing or a dependent
  /// would block disabling.
  ///
  /// A [StateError] from a dependency-violation is intentionally
  /// swallowed and the toggle stays at its prior state — see the
  /// catch block below for why.
  Future<void> set(bool value) async {
    final notifier = ref.read(featureFlagsProvider.notifier);
    try {
      if (value) {
        await notifier.enable(Feature.gamification);
      } else {
        await notifier.disable(Feature.gamification);
      }
      // The central provider throws a StateError specifically for
      // dependency-violation; we want to swallow ONLY that — see the
      // body comment for why. The lint deliberately discourages
      // catching Error subclasses, but the central API's contract
      // documents this exact StateError as the dependency-violation
      // signal, so the catch is intentional and narrow.
      // ignore: avoid_catching_errors
    } on StateError {
      // TODO(1373): Phase 2's settings UI canEnable / blockingDisable
      // pre-check already guards this setter at the UI layer, so a
      // dependency-violation here is a defensive-only catch — the UI
      // path can't currently reach it. We swallow rather than rethrow
      // so a programmatic caller (e.g. a test or a future call site)
      // sees the toggle stay at its prior state instead of crashing
      // the widget tree. Remove once every call site has been audited
      // for `canEnable` pre-check coverage.
    }
  }
}
