import '../../search/domain/entities/fuel_type.dart';
import '../../search/domain/entities/search_result_item.dart';
import '../domain/entities/route_info.dart';

/// Strategy interface for different route search algorithms.
///
/// Implementations decide how to search for stations along a route
/// (e.g., every N km, only near exits, cluster-based, etc.)
/// and how to rank/select the "best" stops.
abstract class RouteSearchStrategy {
  /// Human-readable name for UI display.
  String get name;

  /// Localization key for the strategy name.
  String get l10nKey;

  /// Search for stations along the given [route].
  ///
  /// Returns a list of [SearchResultItem]s found along the route,
  /// already filtered and sorted according to this strategy's logic.
  Future<List<SearchResultItem>> searchAlongRoute({
    required RouteInfo route,
    required FuelType fuelType,
    required double searchRadiusKm,
    required StationQueryFunction queryStations,
    double? maxDetourKm,
  });

  /// Compute the best stops per segment for the given results.
  ///
  /// Returns a map of segment index → station ID for the cheapest
  /// station in each segment. Returns null if not applicable.
  Map<int, String>? computeBestStops({
    required RouteInfo route,
    required List<SearchResultItem> results,
    required FuelType fuelType,
    required double segmentKm,
  });
}

/// Function type for querying stations at a given point.
/// Used to decouple the strategy from specific service implementations.
typedef StationQueryFunction = Future<List<SearchResultItem>> Function({
  required double lat,
  required double lng,
  required double radiusKm,
  required FuelType fuelType,
});

/// Available route search strategy types.
enum RouteSearchStrategyType {
  /// Sample every ~15km, query at each point. Default strategy.
  uniform('uniform', 'uniformSearch'),

  /// Prioritize cheapest stations with fewer stops.
  cheapest('cheapest', 'cheapestSearch'),

  /// Balanced: find stations near highway exits / major intersections.
  balanced('balanced', 'balancedSearch');

  final String key;
  final String l10nKey;
  const RouteSearchStrategyType(this.key, this.l10nKey);
}
