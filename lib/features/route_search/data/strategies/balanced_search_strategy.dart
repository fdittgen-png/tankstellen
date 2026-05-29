// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';

import '../../../../core/utils/geo_utils.dart';
import '../../../../core/utils/station_extensions.dart';
import '../../../profile/data/models/user_profile.dart';
import '../../../search/domain/entities/fuel_type.dart';
import '../../../search/domain/entities/search_result_item.dart';
import '../../domain/entities/route_info.dart';
import '../../domain/route_search_strategy.dart';
import '../helpers/batch_query_helper.dart';
import 'route_filter_sort_isolate.dart';
import 'route_geometry.dart';

/// Balanced strategy: finds stations with a good balance between
/// price and distance from route (minimal detour).
///
/// Scores stations by combining price rank and proximity to route,
/// then selects the best-scoring station per segment.
class BalancedSearchStrategy implements RouteSearchStrategy {
  @override
  String get name => 'Balanced';

  @override
  String get l10nKey => 'balancedSearch';

  @override
  Future<List<SearchResultItem>> searchAlongRoute({
    required RouteInfo route,
    required FuelType fuelType,
    required double searchRadiusKm,
    required StationQueryFunction queryStations,
    double? maxDetourKm,
    int topNPerSamplePoint = 10,
    RouteSearchCriterion criterion = RouteSearchCriterion.cheapest,
    void Function(List<SearchResultItem> partial)? onPartial,
  }) async {
    debugPrint('BalancedSearch: querying ${route.samplePoints.length} points with radius=${searchRadiusKm}km');

    const batchHelper = BatchQueryHelper();
    final results = await batchHelper.queryAll(
      samplePoints: route.samplePoints,
      queryStations: queryStations,
      fuelType: fuelType,
      searchRadiusKm: searchRadiusKm,
      topNPerSamplePoint: topNPerSamplePoint,
      criterion: criterion,
      onPartial: onPartial,
    );

    // #2303 — detour filter + itinerary sort moved off the UI isolate. The
    // returned ordering is purely itinerary position (the per-station balanced
    // score only ever drives `computeBestStops`, never this list's order), so
    // the result is bit-identical to the previous on-UI-isolate filter+sort:
    // fuel stations farther than the detour limit drop, non-fuel results pass
    // through, survivors come back in itinerary order.
    final detourLimit = maxDetourKm ?? searchRadiusKm;
    return filterAndSortAlongRoute(
      results: results,
      polyline: route.geometry,
      detourLimitKm: detourLimit,
    );
  }

  @override
  Map<int, String>? computeBestStops({
    required RouteInfo route,
    required List<SearchResultItem> results,
    required FuelType fuelType,
    required double segmentKm,
  }) {
    final segmentBest = <int, (String, double)>{};

    for (final item in results) {
      if (item is FuelStationResult) {
        final station = item.station;
        int nearestSampleIdx = 0;
        double minDist = double.infinity;
        for (int i = 0; i < route.samplePoints.length; i++) {
          final d = distanceKm(
            station.lat, station.lng,
            route.samplePoints[i].latitude,
            route.samplePoints[i].longitude,
          );
          if (d < minDist) {
            minDist = d;
            nearestSampleIdx = i;
          }
        }
        final segmentIdx = segmentIndexFor(nearestSampleIdx, segmentKm);

        final price = station.priceFor(fuelType);
        if (price != null) {
          // Balanced score: price + distance penalty
          final routeDist = minDistanceToPolyline(
            station.lat, station.lng, route.geometry,
          );
          final score = price + (routeDist * 0.1);

          final current = segmentBest[segmentIdx];
          if (current == null || score < current.$2) {
            segmentBest[segmentIdx] = (station.id, score);
          }
        }
      }
    }

    return segmentBest.map((k, v) => MapEntry(k, v.$1));
  }
}
