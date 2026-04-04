import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/utils/geo_utils.dart';
import '../../../../core/utils/station_extensions.dart';
import '../../../search/domain/entities/fuel_type.dart';
import '../../../search/domain/entities/search_result_item.dart';
import '../../domain/entities/route_info.dart';
import '../../domain/route_search_strategy.dart';
import '../helpers/batch_query_helper.dart';

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
  }) async {
    debugPrint('BalancedSearch: querying ${route.samplePoints.length} points with radius=${searchRadiusKm}km');

    const batchHelper = BatchQueryHelper(batchSize: 4);
    final results = await batchHelper.queryAll(
      samplePoints: route.samplePoints,
      queryStations: queryStations,
      fuelType: fuelType,
      searchRadiusKm: searchRadiusKm,
    );

    // Filter by detour distance
    final detourLimit = maxDetourKm ?? searchRadiusKm;
    final scored = <(SearchResultItem, double)>[];

    for (final item in results) {
      if (item is FuelStationResult) {
        final minDist = _minDistanceToPolyline(
          item.station.lat, item.station.lng, route.geometry,
        );
        if (minDist <= detourLimit) {
          final price = item.station.priceFor(fuelType) ?? 999;
          // Score: lower is better. Combine normalized price and distance.
          // Distance weight is higher to prefer stations close to route.
          final score = price + (minDist * 0.1);
          scored.add((item, score));
        }
      } else {
        scored.add((item, 0));
      }
    }

    // Sort by combined score
    scored.sort((a, b) => a.$2.compareTo(b.$2));

    return scored.map((e) => e.$1).toList();
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
        final segmentIdx = (nearestSampleIdx * 15 / segmentKm).floor();

        final price = station.priceFor(fuelType);
        if (price != null) {
          // Balanced score: price + distance penalty
          final routeDist = _minDistanceToPolyline(
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

  double _minDistanceToPolyline(double lat, double lng, List<LatLng> polyline) {
    if (polyline.isEmpty) return double.infinity;
    double minDist = double.infinity;
    final step = polyline.length > 300 ? 3 : 1;
    for (int i = 0; i < polyline.length; i += step) {
      final p = polyline[i];
      final d = distanceKm(lat, lng, p.latitude, p.longitude);
      if (d < minDist) minDist = d;
    }
    return minDist;
  }
}
