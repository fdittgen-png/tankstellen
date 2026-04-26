import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/exceptions.dart';
import '../../../core/utils/geo_utils.dart';
import '../../../core/services/service_providers.dart';
import '../../../core/services/station_service.dart';
import '../../../core/country/country_provider.dart';
import '../../../core/utils/station_extensions.dart';
import '../../search/data/models/search_params.dart';
import '../../search/providers/ev_charging_service_provider.dart';
import '../../search/domain/entities/fuel_type.dart';
import '../../search/domain/entities/search_result_item.dart';
import '../../profile/providers/profile_provider.dart';
import '../data/services/routing_service.dart';
import '../data/strategies/uniform_search_strategy.dart';
import '../data/strategies/cheapest_search_strategy.dart';
import '../data/strategies/balanced_search_strategy.dart';
import '../domain/entities/route_info.dart';
import '../domain/route_search_strategy.dart';

part 'route_search_provider.g.dart';

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

/// Factory to get the right strategy implementation.
RouteSearchStrategy strategyFor(RouteSearchStrategyType type) {
  switch (type) {
    case RouteSearchStrategyType.uniform:
      return UniformSearchStrategy();
    case RouteSearchStrategyType.cheapest:
      return CheapestSearchStrategy();
    case RouteSearchStrategyType.balanced:
      return BalancedSearchStrategy();
  }
}

/// Orchestrates "cheapest stations along my route" feature.
///
/// 1. Fetches route from OSRM
/// 2. Delegates station search to a [RouteSearchStrategy]
/// 3. Computes cheapest per segment
@riverpod
class RouteSearchState extends _$RouteSearchState {
  @override
  AsyncValue<RouteSearchResult?> build() => const AsyncValue.data(null);

  Future<void> searchAlongRoute({
    required List<RouteWaypoint> waypoints,
    required FuelType fuelType,
    double searchRadiusKm = 5.0,
    RouteSearchStrategyType strategyType = RouteSearchStrategyType.uniform,
  }) async {
    state = const AsyncValue.loading();
    try {
      // 1. Get route from OSRM
      final profile = ref.read(activeProfileProvider);
      final avoidHighways = profile?.avoidHighways ?? false;
      final segmentKm = profile?.routeSegmentKm ?? 50.0;
      final routingService = RoutingService();
      debugPrint('RouteSearch: fetching route for ${waypoints.length} waypoints, avoidHighways=$avoidHighways, strategy=${strategyType.key}');
      final routeResult = await routingService.getRoute(waypoints, avoidHighways: avoidHighways);
      final route = routeResult.data;
      debugPrint('RouteSearch: route=${route.distanceKm.round()}km, ${route.geometry.length} polyline pts, ${route.samplePoints.length} sample pts');

      // 2. Search stations using the selected strategy.
      // Use at least 15km radius for route searches to ensure coverage
      // (sample points are 15km apart, so smaller radius would create gaps).
      final effectiveRadius = searchRadiusKm < 15 ? 15.0 : searchRadiusKm;

      List<SearchResultItem> allResults;
      if (fuelType == FuelType.electric) {
        allResults = await _searchEVAlongRoute(route, effectiveRadius);
      } else {
        final strategy = strategyFor(strategyType);
        final queryFn = await _buildQueryFunction(route, fuelType);
        allResults = await strategy.searchAlongRoute(
          route: route,
          fuelType: fuelType,
          searchRadiusKm: effectiveRadius,
          queryStations: queryFn,
          maxDetourKm: searchRadiusKm,
        );
      }

      // 3. Identify cheapest fuel station
      String? cheapestId;
      Map<int, String>? segmentCheapest;
      if (fuelType != FuelType.electric) {
        double? cheapestPrice;
        for (final item in allResults) {
          if (item is FuelStationResult) {
            final price = item.station.priceFor(fuelType);
            if (price != null && (cheapestPrice == null || price < cheapestPrice)) {
              cheapestPrice = price;
              cheapestId = item.id;
            }
          }
        }

        // 4. Compute cheapest per route segment using strategy
        final strategy = strategyFor(strategyType);
        segmentCheapest = strategy.computeBestStops(
          route: route,
          results: allResults,
          fuelType: fuelType,
          segmentKm: segmentKm,
        );
      }

      state = AsyncValue.data(RouteSearchResult(
        route: route,
        stations: allResults,
        cheapestId: cheapestId,
        cheapestPerSegment: segmentCheapest,
        strategyType: strategyType,
      ));
    } on DioException catch (e, st) {
      if (e.type == DioExceptionType.cancel) return;
      state = AsyncValue.error(e, st);
    } on AppException catch (e, st) {
      state = AsyncValue.error(e, st);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Build a query function that detects country per sample point.
  ///
  /// Cross-border routes (e.g. Berlin→Paris) traverse multiple countries.
  /// Each query resolves the country from its coordinates and uses the
  /// matching country-specific station service.
  Future<StationQueryFunction> _buildQueryFunction(
    RouteInfo route,
    FuelType fuelType,
  ) async {
    final geocoding = ref.read(geocodingChainProvider);
    final fallbackService = ref.read(stationServiceProvider);

    // Cache: country code per sample point to avoid redundant geocoding
    String? lastCountry;
    StationService? lastService;

    return ({
      required double lat,
      required double lng,
      required double radiusKm,
      required FuelType fuelType,
    }) async {
      // Detect country for this specific point
      String? country;
      try {
        country = await geocoding.coordinatesToCountryCode(lat, lng);
      } catch (e, st) {
        debugPrint('RouteSearch: country detection failed at $lat,$lng: $e\n$st');
      }

      // Reuse cached service if country unchanged
      final StationService service;
      if (country != null && country == lastCountry && lastService != null) {
        service = lastService!;
      } else if (country != null) {
        service = stationServiceForCountry(ref, country);
        lastCountry = country;
        lastService = service;
        debugPrint('RouteSearch: switched to country=$country at $lat,$lng');
      } else {
        service = fallbackService;
      }

      final params = SearchParams(
        lat: lat,
        lng: lng,
        radiusKm: radiusKm,
        fuelType: fuelType,
        sortBy: SortBy.price,
      );
      final result = await service.searchStations(params);
      return result.data.map((s) => FuelStationResult(s) as SearchResultItem).toList();
    };
  }

  Future<List<SearchResultItem>> _searchEVAlongRoute(
    RouteInfo route,
    double radiusKm,
  ) async {
    final service = ref.read(evChargingServiceProvider);
    if (service == null) {
      throw const ApiException(message: 'OpenChargeMap API key required');
    }

    final geocoding = ref.read(geocodingChainProvider);
    final fallbackCountry = ref.read(activeCountryProvider).code;
    final seen = <String>{};
    final results = <SearchResultItem>[];

    for (final point in route.samplePoints) {
      try {
        // Detect country per sample point for cross-border routes
        String countryCode = fallbackCountry;
        try {
          final detected = await geocoding.coordinatesToCountryCode(
            point.latitude, point.longitude,
          );
          if (detected != null) countryCode = detected;
        } catch (e, st) {
          debugPrint('RouteSearch EV: country detection failed: $e\n$st');
        }

        final result = await service.searchStations(
          lat: point.latitude,
          lng: point.longitude,
          radiusKm: radiusKm,
          countryCode: countryCode,
          maxResults: 20,
        );
        for (final station in result.data) {
          if (seen.add(station.id)) {
            results.add(EVStationResult(station));
          }
        }
      } catch (e, st) {
        debugPrint('RouteSearch EV: sample point query failed: $e\n$st');
      }
    }

    // Sort by position along route (itinerary order)
    results.sort((a, b) {
      final da = distanceAlongPolyline(a.lat, a.lng, route.geometry);
      final db = distanceAlongPolyline(b.lat, b.lng, route.geometry);
      return da.compareTo(db);
    });
    return results;
  }

  void clear() {
    state = const AsyncValue.data(null);
  }
}
