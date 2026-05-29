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
import 'route_geometry.dart';

/// Strategy that prioritizes finding the cheapest stations along the route.
///
/// Samples fewer points but with a wider radius, then aggressively filters
/// to keep only the top N cheapest stations that cover the route evenly.
class CheapestSearchStrategy implements RouteSearchStrategy {
  @override
  String get name => 'Cheapest';

  @override
  String get l10nKey => 'cheapestSearch';

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
    // Use wider radius but sample every other point for speed
    final effectiveRadius = searchRadiusKm * 1.5;
    final step = route.samplePoints.length > 10 ? 2 : 1;
    final sampledPoints = [
      for (var i = 0; i < route.samplePoints.length; i += step)
        route.samplePoints[i],
    ];

    debugPrint('CheapestSearch: querying ${sampledPoints.length} points with radius=${effectiveRadius.toStringAsFixed(1)}km');

    const batchHelper = BatchQueryHelper();
    final results = await batchHelper.queryAll(
      samplePoints: sampledPoints,
      queryStations: queryStations,
      fuelType: fuelType,
      searchRadiusKm: effectiveRadius,
      topNPerSamplePoint: topNPerSamplePoint,
      criterion: criterion,
      onPartial: onPartial,
    );

    // Filter by detour distance (more generous for cheapest strategy)
    final detourLimit = (maxDetourKm ?? searchRadiusKm) * 1.5;
    final filtered = <SearchResultItem>[];
    for (final item in results) {
      if (item is FuelStationResult) {
        final minDist = minDistanceToPolyline(
          item.station.lat, item.station.lng, route.geometry,
        );
        if (minDist <= detourLimit) {
          filtered.add(item);
        }
      } else {
        filtered.add(item);
      }
    }

    // Sort by position along route (itinerary order)
    sortByItineraryOrder(filtered, route.geometry);

    return filtered;
  }

  @override
  Map<int, String>? computeBestStops({
    required RouteInfo route,
    required List<SearchResultItem> results,
    required FuelType fuelType,
    required double segmentKm,
  }) {
    // Same segment logic as uniform, but with price-first ordering.
    // #2183 — carry the leader's price in a parallel map so the
    // per-station comparison is O(1) instead of re-scanning `results`
    // for the current leader (was O(n²)). uniform/balanced already do this.
    final segmentCheapest = <int, String>{};
    final segmentCheapestPrice = <int, double>{};

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
          final currentBestPrice = segmentCheapestPrice[segmentIdx];
          // Strict < keeps first-occurrence-wins on equal prices,
          // matching the previous behaviour.
          if (currentBestPrice == null || price < currentBestPrice) {
            segmentCheapest[segmentIdx] = station.id;
            segmentCheapestPrice[segmentIdx] = price;
          }
        }
      }
    }

    return segmentCheapest;
  }
}
