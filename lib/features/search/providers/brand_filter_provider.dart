import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/storage/storage_keys.dart';
import '../../../core/storage/storage_providers.dart';

part 'brand_filter_provider.g.dart';

/// Manages the set of selected brand names for filtering search results.
///
/// App-lifetime state (keepAlive) so the filter selection survives the
/// criteria screen ⇄ results screen navigation. Previously screen-scoped,
/// which auto-disposed the state between navigation frames and silently
/// reset the filter to empty (#491). Empty set means "show all brands".
@Riverpod(keepAlive: true)
class SelectedBrands extends _$SelectedBrands {
  @override
  Set<String> build() {
    // #1792 — restore the saved default brand selection. Defensive:
    // degrades to "show all brands" if storage is unavailable.
    try {
      final raw = ref
          .watch(storageRepositoryProvider)
          .getSetting(StorageKeys.defaultBrands);
      if (raw is! List) return const {};
      return raw.whereType<String>().toSet();
    } catch (_) {
      return const {};
    }
  }

  /// Toggle a brand on/off. If toggling off the last brand, reset to show all.
  void toggle(String brand) {
    if (state.contains(brand)) {
      final next = Set<String>.from(state)..remove(brand);
      state = next;
    } else {
      state = {...state, brand};
    }
  }

  /// Reset filter to show all brands.
  void clear() => state = const {};

  /// Select only one specific brand (single-tap shortcut).
  void selectOnly(String brand) => state = {brand};
}

/// Whether the motorway/highway station filter is active.
/// When true, stations with stationType == "A" (autoroute) are excluded.
///
/// keepAlive so the toggle survives navigation, matching [SelectedBrands] (#491).
@Riverpod(keepAlive: true)
class ExcludeHighwayStations extends _$ExcludeHighwayStations {
  @override
  bool build() {
    // #1792 — restore the saved "No highway" default. Defensive:
    // degrades to "include highway stations" if storage is unavailable.
    try {
      final raw = ref
          .watch(storageRepositoryProvider)
          .getSetting(StorageKeys.defaultExcludeHighway);
      return raw as bool? ?? false;
    } catch (_) {
      return false;
    }
  }

  void toggle() => state = !state;

  void set(bool value) => state = value;
}
