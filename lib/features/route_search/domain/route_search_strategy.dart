// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../profile/data/models/user_profile.dart';
import '../../../core/domain/fuel_type.dart';
import '../../../core/domain/search_result_item.dart';
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
    /// #2101 — top-N cap applied **per sample point** before the
    /// downstream detour-filter + sort passes. Defaults to a sane
    /// per-point cap when unset, but callers should thread the
    /// user's profile value through.
    int topNPerSamplePoint = 10,
    /// #2101 — which criterion ranks the candidates inside each
    /// sample point's local pool.
    RouteSearchCriterion criterion = RouteSearchCriterion.cheapest,
    /// #2103 — optional sink for incremental per-batch results.
    /// When provided, the strategy emits each completed sample-point
    /// batch (already top-N reduced) as soon as it arrives, so the
    /// UI can render the first screenful before the full sweep
    /// finishes. Final returned list is still the fully reduced +
    /// sorted set (same contract as before).
    void Function(List<SearchResultItem> partial)? onPartial,
  });

  /// Compute the best stops per segment for the given results.
  ///
  /// Returns a map of segment index → station ID for the cheapest
  /// station in each segment. Returns null if not applicable.
  ///
  /// #2631 — each station is priced by ITS country's profile fuel via
  /// [profileFuelByCountry] (upper-cased country code → fuel), resolved
  /// offline from the station's lat/lng. A cross-border E85 driver thus
  /// sees Spanish stations ranked on the E10 price they'd actually pay,
  /// instead of being dropped because the single active fuel (E85) is
  /// null for ~95% of ES stations. When the map is empty (the historical
  /// single-country path) every station is priced by [fuelType], so the
  /// result is byte-identical to the pre-#2631 behaviour.
  Map<int, String>? computeBestStops({
    required RouteInfo route,
    required List<SearchResultItem> results,
    required FuelType fuelType,
    required double segmentKm,
    Map<String, FuelType> profileFuelByCountry = const {},
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
  balanced('balanced', 'balancedSearch'),

  /// Eco: pick a route + station set that minimise *fuel*, not *time*
  /// (#1123). Favours steady highway cruise over zigzag shortcuts;
  /// surfaces a predicted-litres-saved hint to the user.
  eco('eco', 'ecoSearch');

  final String key;
  final String l10nKey;
  const RouteSearchStrategyType(this.key, this.l10nKey);
}
