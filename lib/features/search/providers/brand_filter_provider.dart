import 'package:riverpod_annotation/riverpod_annotation.dart';

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
///
/// keepAlive so the toggle survives navigation, matching [SelectedBrands] (#491).
@Riverpod(keepAlive: true)
class ExcludeHighwayStations extends _$ExcludeHighwayStations {
  @override
  bool build() => false;

  void toggle() => state = !state;

  void set(bool value) => state = value;
}
