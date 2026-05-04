import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../feature_management/application/feature_flags_provider.dart';
import '../../feature_management/domain/feature.dart';

part 'show_fuel_enabled_provider.g.dart';

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
@Riverpod(keepAlive: true)
class ShowFuelEnabled extends _$ShowFuelEnabled {
  @override
  bool build() {
    return ref.watch(featureFlagsProvider).contains(Feature.showFuel);
  }

  /// Delegate to [featureFlagsProvider]'s `enable` / `disable`. The
  /// central provider enforces the manifest dependency graph
  /// ([Feature.showFuel] has no prerequisites today, so the
  /// dependency-violation path is defensive only).
  ///
  /// A [StateError] from a dependency-violation is intentionally
  /// swallowed and the toggle stays at its prior state — see the
  /// gamification shim's catch block for the full rationale.
  Future<void> set(bool value) async {
    final notifier = ref.read(featureFlagsProvider.notifier);
    try {
      if (value) {
        await notifier.enable(Feature.showFuel);
      } else {
        await notifier.disable(Feature.showFuel);
      }
      // The central provider throws a StateError specifically for
      // dependency-violation; we want to swallow ONLY that. Mirrors
      // the gamification / haptic / unifiedSearchResults shim
      // precedent.
      // ignore: avoid_catching_errors
    } on StateError {
      // Defensive — Feature.showFuel currently has no prerequisites
      // and no dependents, so this branch is unreachable at runtime.
      // Kept for symmetry with the precedent shims and forward-
      // compatibility if the manifest ever adds an edge.
    }
  }
}
