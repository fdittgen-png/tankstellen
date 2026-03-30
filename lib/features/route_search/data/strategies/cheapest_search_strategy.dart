import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/utils/geo_utils.dart';
import '../../../../core/utils/station_extensions.dart';
import '../../../search/domain/entities/fuel_type.dart';
import '../../../search/domain/entities/search_result_item.dart';
import '../../domain/entities/route_info.dart';
import '../../domain/route_search_strategy.dart';

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
  }) async {
    final seen = <String>{};
    final results = <SearchResultItem>[];

    // Use wider radius but sample every other point for speed
    final effectiveRadius = searchRadiusKm * 1.5;
    final step = route.samplePoints.length > 10 ? 2 : 1;

    debugPrint('CheapestSearch: querying ${(route.samplePoints.length / step).ceil()} points with radius=${effectiveRadius.toStringAsFixed(1)}km');

    for (var i = 0; i < route.samplePoints.length; i += step) {
      final point = route.samplePoints[i];
      try {
        final stations = await queryStations(
          lat: point.latitude,
          lng: point.longitude,
          radiusKm: effectiveRadius,
          fuelType: fuelType,
        );
        for (final item in stations) {
          if (seen.add(item.id)) {
            results.add(item);
          }
        }
      } catch (e) {
        debugPrint('CheapestSearch: point $i FAILED: $e');
      }
      if (i + step < route.samplePoints.length) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
    }

    // Filter by detour distance (more generous for cheapest strategy)
    final detourLimit = (maxDetourKm ?? searchRadiusKm) * 1.5;
    final filtered = <SearchResultItem>[];
    for (final item in results) {
      if (item is FuelStationResult) {
        final minDist = _minDistanceToPolyline(
          item.station.lat, item.station.lng, route.geometry,
        );
        if (minDist <= detourLimit) {
          filtered.add(item);
        }
      } else {
        filtered.add(item);
      }
    }

    // Sort strictly by price — cheapest first
    filtered.sort((a, b) {
      if (a is FuelStationResult && b is FuelStationResult) {
        final pa = a.station.priceFor(fuelType) ?? 999;
        final pb = b.station.priceFor(fuelType) ?? 999;
        return pa.compareTo(pb);
      }
      return 0;
    });

    return filtered;
  }

  @override
  Map<int, String>? computeBestStops({
    required RouteInfo route,
    required List<SearchResultItem> results,
    required FuelType fuelType,
    required double segmentKm,
  }) {
    // Same segment logic as uniform, but with price-first ordering
    final segmentCheapest = <int, String>{};

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
          final currentBest = segmentCheapest[segmentIdx];
          if (currentBest == null) {
            segmentCheapest[segmentIdx] = station.id;
          } else {
            final currentBestItem = results
                .whereType<FuelStationResult>()
                .where((r) => r.id == currentBest)
                .firstOrNull;
            final currentBestPrice = currentBestItem?.station.priceFor(fuelType);
            if (currentBestPrice == null || price < currentBestPrice) {
              segmentCheapest[segmentIdx] = station.id;
            }
          }
        }
      }
    }

    return segmentCheapest;
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
