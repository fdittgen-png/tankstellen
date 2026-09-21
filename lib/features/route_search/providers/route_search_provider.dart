// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/exceptions.dart';
import '../../../core/location/location_service.dart';
import '../../../core/time/app_clock.dart';
import '../../../core/logging/error_logger.dart';
import '../../../core/utils/geo_utils.dart';
import '../../../core/utils/station_extensions.dart';
import '../../../core/domain/fuel_type.dart';
import '../../../core/domain/search_result_item.dart';
import '../../profile/data/models/user_profile.dart';
import '../../profile/providers/profile_provider.dart';
import '../data/cross_border_corridor.dart';
import '../data/ev_along_route.dart';
import '../domain/min_saving_filter.dart';
import '../domain/route_origin.dart';
import '../domain/route_search_request.dart';
import '../data/services/routing_service.dart';
import '../domain/entities/route_info.dart';
import '../domain/route_search_result.dart';
import '../domain/route_search_strategy.dart';
import '../domain/route_search_strategy_factory.dart';

// Re-export so existing imports of route_search_provider.dart keep working.
export '../domain/min_saving_filter.dart';
export '../domain/route_search_request.dart';
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

  /// #4432 — the active request generation.
  ///
  /// Every submission takes the next number and every publication —
  /// loading, each streamed partial, the final result and each error
  /// arm — is fenced against it. Without this, a slow first search
  /// could overwrite the results of the search the driver ran after it
  /// (the corridor sweep streams for seconds), and [clear] could not
  /// retire work already in flight. Incremented, never reused.
  int _generation = 0;

  /// #4432 — the last submitted search, so [refresh] can re-run THAT
  /// request instead of the nearby replay the screens used to call.
  RouteSearchRequest? _lastRequest;

  /// The generation a publication must carry to be accepted.
  @visibleForTesting
  int get activeRevision => _generation;

  /// Write [value] only if [generation] is still the active request.
  ///
  /// Visible for the provider's own tests: an obsolete completion must
  /// be a no-op, not a state write nobody notices.
  @visibleForTesting
  void publish(int generation, AsyncValue<RouteSearchResult?> value) {
    if (generation != _generation || !ref.mounted) return;
    state = value;
  }

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
    DateTime? originCapturedAt,
  }) async {
    final generation = ++_generation;
    _lastRequest = RouteSearchRequest(
      revision: generation,
      waypoints: waypoints,
      fuelType: fuelType,
      searchRadiusKm: searchRadiusKm,
      strategyType: strategyType,
      segmentKm: segmentKm,
      minSavingPerLiter: minSavingPerLiter,
      originCapturedAt: originCapturedAt,
    );
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
      if (kDebugMode) { // #3610 — release skips the interpolation.
        debugPrint(
            'RouteSearch: fetching route for ${usableWaypoints.length} waypoints, avoidHighways=$avoidHighways, strategy=${strategyType.key}');
      }
      final routeResult = await routingService.getRoute(usableWaypoints, avoidHighways: avoidHighways);
      final route = routeResult.data;
      if (kDebugMode) {
        debugPrint(
            'RouteSearch: route=${route.distanceKm.round()}km, ${route.geometry.length} polyline pts, ${route.samplePoints.length} sample pts');
      }

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
        allResults = await searchEvAlongRoute(ref, route, effectiveRadius);
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
            publish(generation, AsyncValue.data(RouteSearchResult(
              route: route,
              stations: partial,
              cheapestId: null,
              cheapestPerSegment: null,
              strategyType: strategyType,
              isPartial: true,
              corridorCountryCodes: corridorMap.keys.toSet(),
              profileFuelByCountry: profileFuels,
            )));
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

      publish(generation, AsyncValue.data(RouteSearchResult(
        route: route,
        stations: allResults,
        cheapestId: cheapestId,
        cheapestPerSegment: segmentCheapest,
        strategyType: strategyType,
        corridorCountryCodes: corridorMap.keys.toSet(),
        // #2631 — carried to the map/list so each station prices by its
        // own country fuel (cross-border ES → E10 instead of '--').
        profileFuelByCountry: profileFuels,
      )));
    } catch (e, st) {
      // A cancelled request is the caller superseding us, not a failure.
      if (e is DioException && e.type == DioExceptionType.cancel) return;
      // #2308 — log so an OSRM outage is distinguishable from a
      // country-service exhaustion or a Dart error in exportable logs.
      unawaited(errorLogger.log(ErrorLayer.providers, e, st,
          context: const {'where': 'RouteSearchState.searchAlongRoute'}));
      publish(generation, AsyncValue.error(e, st));
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

  void clear() {
    // #4432 — retire whatever is in flight FIRST. A sweep that was
    // already streaming partials could otherwise repopulate the list
    // the user just cleared.
    _generation++;
    _lastRequest = null;
    state = const AsyncValue.data(null);
  }

  /// #4432 — re-run the ACTIVE route search.
  ///
  /// The list and map refresh actions called the nearby
  /// `repeatLastSearch()` even while route results were on screen: they
  /// re-fixed the separately stored user position and re-ran a
  /// proximity search, leaving the corridor exactly as stale as before.
  /// A current-position route re-resolves its origin here, so refresh
  /// means "from where I am now"; a named origin stays put and only the
  /// prices move. Returns false when there is no route to refresh, so
  /// the caller can fall back to the nearby replay.
  Future<bool> refresh() async {
    var request = _lastRequest;
    if (request == null) return false;
    if (request.originIsVehiclePosition) {
      final first = request.waypoints.first;
      final origin = await resolveCurrentPositionOrigin(
        locationService: ref.read(locationServiceProvider),
        clock: ref.read(appClockProvider),
        stored: LatLng(first.lat, first.lng),
        capturedAt: request.originCapturedAt,
      );
      if (!ref.mounted) return true;
      // No usable origin at all: keep the one the request already has
      // and refresh the prices. Refusing to do anything would make the
      // refresh action a silent no-op, which is its own small lie.
      final coords = origin.coords;
      if (coords != null) {
        request = request.withOrigin(
          coords,
          ref.read(appClockProvider).now().subtract(origin.age),
        );
      }
    }
    await searchAlongRoute(
      waypoints: request.waypoints,
      fuelType: request.fuelType,
      searchRadiusKm: request.searchRadiusKm,
      strategyType: request.strategyType,
      segmentKm: request.segmentKm,
      minSavingPerLiter: request.minSavingPerLiter,
      originCapturedAt: request.originCapturedAt,
    );
    return true;
  }
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
