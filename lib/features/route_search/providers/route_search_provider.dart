// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/exceptions.dart';
import '../../../core/logging/error_logger.dart';
import '../../../core/services/service_providers.dart';
import '../../../core/services/station_service.dart';
import '../../../core/country/country_provider.dart';
import '../../../core/utils/station_extensions.dart';
import '../../profile/data/models/user_profile.dart';
import '../../search/data/models/search_params.dart';
import '../../search/providers/ev_charging_service_provider.dart';
import '../../search/domain/entities/fuel_type.dart';
import '../../search/domain/entities/search_result_item.dart';
import '../../profile/providers/profile_provider.dart';
import '../data/strategies/route_geometry.dart';
import '../data/services/routing_service.dart';
import '../domain/entities/route_info.dart';
import '../domain/route_search_result.dart';
import '../domain/route_search_strategy.dart';
import '../domain/route_search_strategy_factory.dart';

// Re-export so existing imports of route_search_provider.dart keep working.
export '../domain/route_search_result.dart';
export '../domain/route_search_strategy_factory.dart';

part 'route_search_provider.g.dart';

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
      final minSaving = profile?.minRouteSavingPerLiter ?? 0.0;
      // #2101 lever B — profile-configurable top-N cap + criterion.
      final topN = profile?.routeSearchTopNPerSamplePoint ?? 10;
      final criterion =
          profile?.routeSearchCriterion ?? RouteSearchCriterion.cheapest;
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
          topNPerSamplePoint: topN,
          criterion: criterion,
          // #2103 lever C — emit each batch's running accumulator so
          // the list shows the first screenful while later batches
          // are still in flight. The final state.write below replaces
          // this with the fully-reduced, isolate-sorted result.
          onPartial: (partial) {
            state = AsyncValue.data(RouteSearchResult(
              route: route,
              stations: partial,
              cheapestId: null,
              cheapestPerSegment: null,
              strategyType: strategyType,
              isPartial: true,
            ));
          },
        );
      }

      // 2b. #1872 — drop fuel stations that don't beat the route's
      // cheapest by at least the user's minimum-saving threshold.
      if (fuelType != FuelType.electric && minSaving > 0) {
        allResults =
            filterRouteResultsByMinSaving(allResults, fuelType, minSaving);
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
      // #2308 — log so an OSRM outage is distinguishable from a
      // country-service exhaustion or a Dart error in exportable logs.
      unawaited(errorLogger.log(ErrorLayer.providers, e, st,
          context: const {'where': 'RouteSearchState.searchAlongRoute'}));
      state = AsyncValue.error(e, st);
    } on AppException catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.providers, e, st,
          context: const {'where': 'RouteSearchState.searchAlongRoute'}));
      state = AsyncValue.error(e, st);
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.providers, e, st,
          context: const {'where': 'RouteSearchState.searchAlongRoute'}));
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
        // #2146 — non-fatal (falls through to fallbackService) but
        // surface on the log so country-detection blackholes are
        // recoverable from a bug report.
        unawaited(errorLogger.log(ErrorLayer.services, e, st, context: {
          'where': 'RouteSearch: fuel country detection',
          'lat': lat, 'lng': lng,
        }));
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
          // #2146 — non-fatal (uses fallbackCountry) but surface
          // so triage can spot misconfigured geocoding chains.
          unawaited(errorLogger.log(ErrorLayer.services, e, st, context: {
            'where': 'RouteSearch EV: country detection',
            'lat': point.latitude, 'lng': point.longitude,
          }));
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
        // #2146 — sample failures are tolerated (other points still
        // yield results), but route to the exportable log so
        // recurring blackouts of EV results are recoverable.
        unawaited(errorLogger.log(ErrorLayer.services, e, st, context: {
          'where': 'RouteSearch EV: sample point query',
          'lat': point.latitude, 'lng': point.longitude,
        }));
      }
    }

    // Sort by position along route (itinerary order)
    sortByItineraryOrder(results, route.geometry);
    return results;
  }

  void clear() {
    state = const AsyncValue.data(null);
  }
}

/// Keeps only fuel stations priced within [minSaving] €/L of the
/// cheapest station found along the route (#1872).
///
/// The cheapest priced station is the anchor; a station survives when
/// its [fuelType] price is at most `cheapest + minSaving`. Stations
/// with no price for [fuelType] are kept — an unknown price is not a
/// reason to hide a stop — and the list is returned unchanged when no
/// station carries a comparable price. EV results never reach here
/// (the caller gates on a non-electric fuel type).
List<SearchResultItem> filterRouteResultsByMinSaving(
  List<SearchResultItem> results,
  FuelType fuelType,
  double minSaving,
) {
  double? cheapest;
  for (final item in results) {
    if (item is FuelStationResult) {
      final price = item.station.priceFor(fuelType);
      if (price != null && (cheapest == null || price < cheapest)) {
        cheapest = price;
      }
    }
  }
  if (cheapest == null) return results;
  final ceiling = cheapest + minSaving;
  return results.where((item) {
    if (item is! FuelStationResult) return true;
    final price = item.station.priceFor(fuelType);
    return price == null || price <= ceiling;
  }).toList();
}
