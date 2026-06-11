// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/exceptions.dart';
import '../../../core/logging/error_logger.dart';
import '../../../core/country/country_bounding_box.dart';
import '../../../core/country/country_provider.dart';
import '../../../core/utils/geo_utils.dart';
import '../../../core/utils/station_extensions.dart';
import '../../profile/data/models/user_profile.dart';
import '../../search/providers/ev_charging_service_provider.dart';
import '../../search/domain/entities/fuel_type.dart';
import '../../search/domain/entities/search_result_item.dart';
import '../../profile/providers/profile_provider.dart';
import '../data/cross_border_corridor.dart';
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
    // #2592 — per-search overrides from the criteria screen. When omitted
    // (e.g. the itineraries screen) they null-coalesce to the profile
    // defaults so existing callers are untouched.
    double? segmentKm,
    double? minSavingPerLiter,
  }) async {
    state = const AsyncValue.loading();
    try {
      // #2872 — last-line guard before routing: drop degenerate waypoints
      // ((0,0)/(lat,0) GPS or a `?? 0`-fallback geocode) so OSRM can't
      // route from the Gulf of Guinea and centre the route map in the
      // Sahara. < 2 usable → throw so the UI asks for a manual start.
      final usableWaypoints =
          waypoints.where((w) => isUsableCoord(w.lat, w.lng)).toList();
      if (usableWaypoints.length < 2) {
        throw const LocationException(
          message: 'Route needs two usable waypoints; '
              'a degenerate GPS/geocode origin was rejected.',
        );
      }

      // 1. Get route from OSRM
      final profile = ref.read(activeProfileProvider);
      final avoidHighways = profile?.avoidHighways ?? false;
      final segmentKmValue = resolveRouteSegmentKm(segmentKm, profile);
      final minSaving = resolveMinRouteSaving(minSavingPerLiter, profile);
      // #2101 lever B — profile-configurable top-N cap + criterion.
      final topN = profile?.routeSearchTopNPerSamplePoint ?? 10;
      final criterion =
          profile?.routeSearchCriterion ?? RouteSearchCriterion.cheapest;
      final routingService = RoutingService();
      debugPrint('RouteSearch: fetching route for ${usableWaypoints.length} waypoints, avoidHighways=$avoidHighways, strategy=${strategyType.key}');
      final routeResult = await routingService.getRoute(usableWaypoints, avoidHighways: avoidHighways);
      final route = routeResult.data;
      debugPrint('RouteSearch: route=${route.distanceKm.round()}km, ${route.geometry.length} polyline pts, ${route.samplePoints.length} sample pts');

      // 2. Search stations using the selected strategy.
      // Use at least 15km radius for route searches to ensure coverage
      // (sample points are 15km apart, so smaller radius would create gaps).
      final effectiveRadius = searchRadiusKm < 15 ? 15.0 : searchRadiusKm;

      // #2595 — resolve, OFFLINE, which countries the corridor crosses and
      // map each to its (service, profile-fuel). Used by the fuel query
      // function below and by the cross-border cheapest pricing.
      final profileFuels = profileFuelByCountry(ref);
      final corridorMap = buildCorridorServiceMap(ref, route, profileFuels);

      List<SearchResultItem> allResults;
      if (fuelType == FuelType.electric) {
        allResults = await _searchEVAlongRoute(route, effectiveRadius);
      } else {
        final strategy = strategyFor(strategyType);
        final queryFn = buildCorridorQueryFunction(
          ref,
          fuelType,
          corridorMap: corridorMap,
          criterion: criterion,
          topNPerSamplePoint: topN,
        );
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
              corridorCountryCodes: corridorMap.keys.toSet(),
              profileFuelByCountry: profileFuels,
            ));
          },
        );
      }

      // 2b. #1872 / #2595 — drop fuel stations that don't beat the
      // route's cheapest by at least the user's minimum-saving threshold.
      // Each station is priced by ITS country's profile fuel so an
      // E85-vs-E10 cross-border compare isn't apples-to-oranges.
      if (fuelType != FuelType.electric && minSaving > 0) {
        allResults = filterRouteResultsByMinSaving(
          allResults,
          fuelType,
          minSaving,
          profileFuelByCountry: profileFuels,
        );
      }

      // 3. Identify cheapest fuel station
      String? cheapestId;
      Map<int, String>? segmentCheapest;
      if (fuelType != FuelType.electric) {
        double? cheapestPrice;
        for (final item in allResults) {
          if (item is FuelStationResult) {
            // #2595 — price by the station's own country fuel, not the
            // single active-profile fuel, so the global cheapest across
            // a cross-border route compares like-for-like.
            final fuel = fuelForStation(item.station, profileFuels, fuelType);
            final price = item.station.priceFor(fuel);
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
          segmentKm: segmentKmValue,
          // #2631 — price each segment by ITS country's profile fuel so a
          // cross-border ES station (E10 set, E85 null) is ranked into Best
          // Stops rather than dropped on a null active-fuel price.
          profileFuelByCountry: profileFuels,
        );
      }

      state = AsyncValue.data(RouteSearchResult(
        route: route,
        stations: allResults,
        cheapestId: cheapestId,
        cheapestPerSegment: segmentCheapest,
        strategyType: strategyType,
        corridorCountryCodes: corridorMap.keys.toSet(),
        // #2631 — carried to the map/list so each station prices by its
        // own country fuel (cross-border ES → E10 instead of '--').
        profileFuelByCountry: profileFuels,
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

  /// Test seam (#2595): runs the cross-border station-search portion of
  /// [searchAlongRoute] against a PRE-BUILT [route], skipping the OSRM
  /// fetch (the `RoutingService` is constructed internally and not
  /// injectable). Exercises the real corridor-map build, per-country-fuel
  /// query function, strategy sweep + merge, and cross-border cheapest —
  /// so a test can assert each leg routes to its own service + fuel and
  /// the merged result interleaves both countries by corridor position.
  @visibleForTesting
  Future<RouteSearchResult> searchAlongPrebuiltRouteForTest({
    required RouteInfo route,
    required FuelType fuelType,
    double searchRadiusKm = 15.0,
    RouteSearchStrategyType strategyType = RouteSearchStrategyType.uniform,
    RouteSearchCriterion criterion = RouteSearchCriterion.cheapest,
    int topNPerSamplePoint = 10,
  }) async {
    final profileFuels = profileFuelByCountry(ref);
    final corridorMap = buildCorridorServiceMap(ref, route, profileFuels);
    final strategy = strategyFor(strategyType);
    final queryFn = buildCorridorQueryFunction(
      ref,
      fuelType,
      corridorMap: corridorMap,
      criterion: criterion,
      topNPerSamplePoint: topNPerSamplePoint,
    );
    final allResults = await strategy.searchAlongRoute(
      route: route,
      fuelType: fuelType,
      searchRadiusKm: searchRadiusKm,
      queryStations: queryFn,
      maxDetourKm: searchRadiusKm,
      topNPerSamplePoint: topNPerSamplePoint,
      criterion: criterion,
    );
    String? cheapestId;
    double? cheapestPrice;
    for (final item in allResults) {
      if (item is FuelStationResult) {
        final fuel = fuelForStation(item.station, profileFuels, fuelType);
        final price = item.station.priceFor(fuel);
        if (price != null &&
            (cheapestPrice == null || price < cheapestPrice)) {
          cheapestPrice = price;
          cheapestId = item.id;
        }
      }
    }
    return RouteSearchResult(
      route: route,
      stations: allResults,
      cheapestId: cheapestId,
      cheapestPerSegment: strategy.computeBestStops(
        route: route,
        results: allResults,
        fuelType: fuelType,
        segmentKm: 50.0,
        // #2631 — per-country profile fuel for cross-border Best Stops.
        profileFuelByCountry: profileFuels,
      ),
      strategyType: strategyType,
      corridorCountryCodes: corridorMap.keys.toSet(),
      profileFuelByCountry: profileFuels,
    );
  }

  Future<List<SearchResultItem>> _searchEVAlongRoute(
    RouteInfo route,
    double radiusKm,
  ) async {
    final service = ref.read(evChargingServiceProvider);
    if (service == null) {
      throw const ApiException(message: 'OpenChargeMap API key required');
    }

    final fallbackCountry = ref.read(activeCountryProvider).code;
    final seen = <String>{};
    final results = <SearchResultItem>[];

    for (final point in route.samplePoints) {
      try {
        // #2595 — detect the per-point country OFFLINE via the bbox
        // registry (no network geocode that could blackhole and fall
        // back to the active country). Outside every box (e.g. mid-sea)
        // falls back to the active country.
        final countryCode = countryCodeFromLatLng(
              point.latitude,
              point.longitude,
            ) ??
            fallbackCountry;

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
        // #3145 — coords bucketed to 1 decimal: triage never needs more.
        unawaited(errorLogger.log(ErrorLayer.services, e, st, context: {
          'where': 'RouteSearch EV: sample point query',
          'lat': point.latitude.toStringAsFixed(1),
          'lng': point.longitude.toStringAsFixed(1),
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
/// The cheapest priced station is the anchor; a station survives when its
/// price is at most `cheapest + minSaving`. Stations with no price are
/// kept — an unknown price is not a reason to hide a stop — and the list
/// is returned unchanged when no station carries a comparable price. EV
/// results never reach here (the caller gates on a non-electric fuel
/// type).
///
/// #2595 — each station is priced by ITS country's profile fuel via
/// [profileFuelByCountry] (resolved offline from the station's lat/lng),
/// falling back to [fuelType] for a country with no profile or a station
/// outside every bbox. This keeps the cross-border min-saving compare
/// like-for-like (FR→E85 vs ES→E10) instead of pricing every station by a
/// single fuel one country may not even sell. When [profileFuelByCountry]
/// is empty (the historical single-country path) every station is priced
/// by [fuelType], preserving the original behaviour exactly.
List<SearchResultItem> filterRouteResultsByMinSaving(
  List<SearchResultItem> results,
  FuelType fuelType,
  double minSaving, {
  Map<String, FuelType> profileFuelByCountry = const {},
}) {
  FuelType fuelFor(FuelStationResult item) {
    if (profileFuelByCountry.isEmpty) return fuelType;
    final code =
        countryCodeFromLatLng(item.station.lat, item.station.lng)?.toUpperCase();
    if (code == null) return fuelType;
    return profileFuelByCountry[code] ?? fuelType;
  }

  double? cheapest;
  for (final item in results) {
    if (item is FuelStationResult) {
      final price = item.station.priceFor(fuelFor(item));
      if (price != null && (cheapest == null || price < cheapest)) {
        cheapest = price;
      }
    }
  }
  if (cheapest == null) return results;
  final ceiling = cheapest + minSaving;
  return results.where((item) {
    if (item is! FuelStationResult) return true;
    final price = item.station.priceFor(fuelFor(item));
    return price == null || price <= ceiling;
  }).toList();
}

/// Resolves the route-segment spacing for a search (#2592).
///
/// A per-search [override] (from the criteria screen) wins; otherwise the
/// active [profile]'s `routeSegmentKm` default applies; with neither, the
/// 50 km fallback matches the profile field default. This keeps existing
/// callers that pass no override (e.g. the itineraries screen) on the
/// profile-default path.
double resolveRouteSegmentKm(double? override, UserProfile? profile) =>
    override ?? profile?.routeSegmentKm ?? 50.0;

/// Resolves the minimum-saving floor for a search (#2592). Same precedence
/// as [resolveRouteSegmentKm]: per-search override → profile → 0.0 (off).
double resolveMinRouteSaving(double? override, UserProfile? profile) =>
    override ?? profile?.minRouteSavingPerLiter ?? 0.0;
