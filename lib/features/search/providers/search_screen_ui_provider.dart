import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../route_search/domain/route_search_strategy.dart';

part 'search_screen_ui_provider.g.dart';

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
