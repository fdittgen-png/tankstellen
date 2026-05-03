import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/feature_management/application/feature_flags_provider.dart';
import '../../features/feature_management/domain/feature.dart';

part 'unified_search_results_enabled.g.dart';

/// Feature flag for the #1116 phase-3 unified fuel + EV search results.
///
/// As of #1373 phase 3f this is a thin shim over [featureFlagsProvider]
/// — the canonical state lives in the central feature-flag set keyed by
/// [Feature.unifiedSearchResults]. The legacy
/// `StorageKeys.unifiedSearchResultsEnabled` Hive-settings key is read
/// once by the `legacyToggleMigrationProvider` on first launch after
/// upgrade and promoted into the central set; subsequent reads/writes
/// go through here.
///
/// Defaults to `false` per the manifest because the unified UI is still
/// converging — flipping the flag without all phase 3b/c surfaces
/// installed produces an empty result list, which is the safer
/// fallback than a partial rendering.
@Riverpod(keepAlive: true)
class UnifiedSearchResultsEnabled extends _$UnifiedSearchResultsEnabled {
  @override
  bool build() {
    return ref
        .watch(featureFlagsProvider)
        .contains(Feature.unifiedSearchResults);
  }

  /// Flip the flag. Delegates to [set] so the toggle/set paths share a
  /// single dependency-violation guard and a single central-provider
  /// write.
  Future<void> toggle() async {
    await set(!state);
  }

  /// Delegate to [featureFlagsProvider]'s `enable` / `disable`. The
  /// downstream `unifiedSearchResultsProvider` watches this shim, so a
  /// `set(true)` re-derives the unified card list immediately and a
  /// `set(false)` collapses it back to the legacy fuel-only path.
  ///
  /// A [StateError] from a dependency-violation is intentionally
  /// swallowed and the toggle stays at its prior state — see the
  /// catch block below for why.
  Future<void> set(bool value) async {
    final notifier = ref.read(featureFlagsProvider.notifier);
    try {
      if (value) {
        await notifier.enable(Feature.unifiedSearchResults);
      } else {
        await notifier.disable(Feature.unifiedSearchResults);
      }
      // The central provider throws a StateError specifically for
      // dependency-violation; we want to swallow ONLY that — see the
      // body comment for why. The lint deliberately discourages
      // catching Error subclasses, but the central API's contract
      // documents this exact StateError as the dependency-violation
      // signal, so the catch is intentional and narrow.
      // ignore: avoid_catching_errors
    } on StateError {
      // TODO(1373): Phase 2's settings UI already pre-checks
      // `canEnable` / `blockingDisable` before invoking this setter, so
      // a dependency-violation here is a defensive-only catch — the UI
      // path can't currently reach it. We swallow rather than rethrow
      // so a programmatic caller (e.g. a test or a future call site)
      // sees the toggle stay at its prior state instead of crashing
      // the widget tree. Remove once every call site has been audited
      // for `canEnable` pre-check coverage.
    }
  }
}
