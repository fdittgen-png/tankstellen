import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../feature_management/application/feature_flags_provider.dart';
import '../../feature_management/domain/feature.dart';
import '../../feature_management/domain/feature_dependency_graph.dart';

part 'show_electric_enabled_provider.g.dart';

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
@Riverpod(keepAlive: true)
class ShowElectricEnabled extends _$ShowElectricEnabled {
  @override
  bool build() {
    // Routes through `isEffectivelyEnabled` for symmetry with the other
    // shims and forward-compat (#1447). `Feature.showElectric` has no
    // requires today so the helper short-circuits to `state.contains` —
    // identical observable behaviour to the prior `.contains` call.
    final enabled = ref.watch(enabledFeaturesProvider);
    final manifest = ref.watch(featureManifestProvider);
    return isEffectivelyEnabled(Feature.showElectric, manifest, enabled);
  }

  /// Delegate to [featureFlagsProvider]'s `enable` / `disable`. The
  /// central provider enforces the manifest dependency graph
  /// ([Feature.showElectric] has no prerequisites today, so the
  /// dependency-violation path is defensive only).
  Future<void> set(bool value) async {
    final notifier = ref.read(featureFlagsProvider.notifier);
    try {
      if (value) {
        await notifier.enable(Feature.showElectric);
      } else {
        await notifier.disable(Feature.showElectric);
      }
      // ignore: avoid_catching_errors
    } on StateError {
      // Defensive — Feature.showElectric currently has no prerequisites
      // and no dependents, so this branch is unreachable at runtime.
      // Kept for symmetry with the precedent shims.
    }
  }
}
