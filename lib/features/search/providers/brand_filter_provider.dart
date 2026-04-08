import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'brand_filter_provider.g.dart';

/// Manages the set of selected brand names for filtering search results.
///
/// Screen-scoped (not keepAlive) — resets when the user navigates away.
/// Empty set means "show all brands" (no filter active).
@riverpod
class SelectedBrands extends _$SelectedBrands {
  @override
  Set<String> build() => const {};

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
@riverpod
class ExcludeHighwayStations extends _$ExcludeHighwayStations {
  @override
  bool build() => false;

  void toggle() => state = !state;

  void set(bool value) => state = value;
}
