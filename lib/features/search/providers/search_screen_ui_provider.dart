import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../profile/data/models/user_profile.dart';
import '../../profile/providers/profile_provider.dart';
import '../../route_search/domain/route_search_strategy.dart';
import '../domain/entities/station_amenity.dart';
import '../presentation/widgets/sort_selector.dart';

part 'search_screen_ui_provider.g.dart';

/// The currently selected sort mode for the search results list.
///
/// The initial value derives from the active profile's [LandingScreen]
/// preference: `cheapest` → price sort, everything else → distance.
/// Users can still override via [set] from the sort chips.
@riverpod
class SelectedSortMode extends _$SelectedSortMode {
  @override
  SortMode build() {
    final profile = ref.watch(activeProfileProvider);
    return switch (profile?.landingScreen) {
      LandingScreen.cheapest => SortMode.price,
      _ => SortMode.distance,
    };
  }

  void set(SortMode value) => state = value;
}

/// Whether the filter section (fuel type + radius) is expanded on the search
/// screen. Starts expanded; collapses automatically when a search is triggered
/// and in landscape orientation.
@riverpod
class FiltersExpanded extends _$FiltersExpanded {
  @override
  bool build() => true;

  void set(bool value) => state = value;

  void collapse() => state = false;

  void toggle() => state = !state;
}

/// The route search strategy selected by the user on the search screen.
@riverpod
class SelectedRouteStrategy extends _$SelectedRouteStrategy {
  @override
  RouteSearchStrategyType build() => RouteSearchStrategyType.uniform;

  void set(RouteSearchStrategyType value) => state = value;
}

/// Whether the brand filter chips section is expanded in the search results.
/// Starts collapsed; the user can expand via an ExpansionTile-like toggle.
@riverpod
class BrandFiltersExpanded extends _$BrandFiltersExpanded {
  @override
  bool build() => false;

  void set(bool value) => state = value;

  void toggle() => state = !state;
}

/// Whether to show the all-prices detail view instead of the compact card view.
@riverpod
class AllPricesViewEnabled extends _$AllPricesViewEnabled {
  @override
  bool build() => false;

  void toggle() => state = !state;

  void set(bool value) => state = value;
}

/// Whether results should be filtered to currently-open stations only.
/// Toggled from the search criteria screen; consumed by the results list.
@Riverpod(keepAlive: true)
class OpenOnlyFilter extends _$OpenOnlyFilter {
  @override
  bool build() => false;

  void set(bool value) => state = value;

  void toggle() => state = !state;
}

/// The set of amenities the user wants stations to provide.
/// Empty set means "no amenity filter" (all stations pass).
@Riverpod(keepAlive: true)
class SelectedAmenities extends _$SelectedAmenities {
  @override
  Set<StationAmenity> build() => const <StationAmenity>{};

  void toggle(StationAmenity amenity) {
    final next = Set<StationAmenity>.from(state);
    if (next.contains(amenity)) {
      next.remove(amenity);
    } else {
      next.add(amenity);
    }
    state = next;
  }

  void set(Set<StationAmenity> amenities) =>
      state = Set<StationAmenity>.from(amenities);

  void clear() => state = const <StationAmenity>{};
}
