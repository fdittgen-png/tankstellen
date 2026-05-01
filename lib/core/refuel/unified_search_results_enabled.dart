import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../storage/storage_keys.dart';
import '../storage/storage_providers.dart';

part 'unified_search_results_enabled.g.dart';

/// Feature flag for the #1116 phase-3 unified fuel + EV search results.
///
/// Phase 3a (this PR) introduces only the flag and the
/// [unifiedSearchResultsProvider] foundation; the search screen still
/// reads `searchStateProvider` directly. Phase 3b ships the mixed
/// fuel/EV card widgets, and phase 3c rewires the search screen to
/// consume [unifiedSearchResultsProvider] when this flag is on.
///
/// Persisted to the settings box so the user's preference survives
/// restarts. Defaults to `false` because the unified UI is not yet
/// shipping — flipping the flag without phase 3b/c installed produces
/// an empty result list, which is the safer fallback than a partial
/// rendering.
///
/// Mirrors the [EvShowOnMap] pattern from `lib/features/ev/providers/
/// ev_providers.dart`: keep-alive, Hive-backed, with [toggle] and [set]
/// mutators.
@Riverpod(keepAlive: true)
class UnifiedSearchResultsEnabled extends _$UnifiedSearchResultsEnabled {
  @override
  bool build() {
    final storage = ref.watch(settingsStorageProvider);
    final raw = storage.getSetting(StorageKeys.unifiedSearchResultsEnabled);
    return raw is bool ? raw : false;
  }

  /// Flip the flag. Persists the new value before updating [state] so a
  /// crash mid-toggle leaves the persisted + observed state consistent.
  Future<void> toggle() async {
    final storage = ref.read(settingsStorageProvider);
    final next = !state;
    await storage.putSetting(
      StorageKeys.unifiedSearchResultsEnabled,
      next,
    );
    state = next;
  }

  /// Set the flag to [value]. Idempotent — calling with the current
  /// value still rewrites the storage entry (cheap on Hive) so any
  /// callers that depend on a `putSetting` side-effect (e.g. tests)
  /// see a deterministic write.
  Future<void> set(bool value) async {
    final storage = ref.read(settingsStorageProvider);
    await storage.putSetting(
      StorageKeys.unifiedSearchResultsEnabled,
      value,
    );
    state = value;
  }
}
