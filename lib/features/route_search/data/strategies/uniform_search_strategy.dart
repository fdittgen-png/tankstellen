import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/utils/geo_utils.dart';
import '../../../../core/utils/station_extensions.dart';
import '../../../search/domain/entities/fuel_type.dart';
import '../../../search/domain/entities/search_result_item.dart';
import '../../domain/entities/route_info.dart';
import '../../domain/route_search_strategy.dart';

/// Default strategy: samples every ~15km along the route,
/// queries stations at each sample point, deduplicates, and filters
/// by detour distance.
class UniformSearchStrategy implements RouteSearchStrategy {
  @override
  String get name => 'Uniform';

  @override
  String get l10nKey => 'uniformSearch';

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
    int successCount = 0;
    int failCount = 0;

    debugPrint('UniformSearch: querying ${route.samplePoints.length} sample points with radius=${searchRadiusKm}km');

    for (var i = 0; i < route.samplePoints.length; i++) {
      final point = route.samplePoints[i];
      try {
        final stations = await queryStations(
          lat: point.latitude,
          lng: point.longitude,
          radiusKm: searchRadiusKm,
          fuelType: fuelType,
        );
        for (final item in stations) {
          if (seen.add(item.id)) {
            results.add(item);
          }
        }
        successCount++;
      } catch (e) {
        failCount++;
        debugPrint('UniformSearch: point $i FAILED: $e');
      }
      // Rate limit: wait 500ms between API calls
      if (i < route.samplePoints.length - 1) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
    }
    debugPrint('UniformSearch: $successCount succeeded, $failCount failed, ${results.length} unique stations');

    // Filter by detour distance
    final detourLimit = maxDetourKm ?? searchRadiusKm;
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

    // Sort by price
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
    final segmentCheapest = <int, String>{};

    for (final item in results) {
      if (item is FuelStationResult) {
        final station = item.station;
        // Find nearest sample point
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
