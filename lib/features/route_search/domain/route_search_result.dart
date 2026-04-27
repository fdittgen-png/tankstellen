import '../../search/domain/entities/search_result_item.dart';
import 'entities/route_info.dart';
import 'route_search_strategy.dart';

/// State for route-based search: the route itself + stations found along it.
class RouteSearchResult {
  final RouteInfo route;
  final List<SearchResultItem> stations;
  final String? cheapestId;

  /// Maps segment index to the cheapest station ID within that segment.
  /// Segments are computed based on [segmentKm] intervals along the route.
  final Map<int, String>? cheapestPerSegment;

  /// Which strategy was used for this search.
  final RouteSearchStrategyType strategyType;

  const RouteSearchResult({
    required this.route,
    required this.stations,
    this.cheapestId,
    this.cheapestPerSegment,
    this.strategyType = RouteSearchStrategyType.uniform,
  });
}
