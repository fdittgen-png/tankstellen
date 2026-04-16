import 'package:dio/dio.dart';

import '../../../features/search/data/models/search_params.dart';
import '../../../features/search/domain/entities/station.dart';
import '../../error/exceptions.dart';
import '../../utils/geo_utils.dart';
import '../../utils/station_extensions.dart';
import '../service_result.dart';
import '../station_service.dart';

/// Shared utilities for [StationService] implementations.
///
/// Eliminates duplicated boilerplate that was previously copy-pasted
/// across 7 country service implementations:
/// - DioException → ApiException conversion
/// - Sort by price/distance
/// - Distance calculation + rounding
/// - Radius filtering with top-N fallback
/// - Default implementations for unsupported endpoints
mixin StationServiceHelpers {
  // ---------------------------------------------------------------------------
  // Error handling
  // ---------------------------------------------------------------------------

  /// Convert a [DioException] to an [ApiException] and throw it.
  ///
  /// Includes the Dio exception type and request path so error reports
  /// carry enough context to diagnose without a repro (#524).
  ///
  /// Use in catch blocks: `on DioException catch (e) { throwApiException(e); }`
  Never throwApiException(DioException e, {String defaultMessage = 'Network error'}) {
    final path = e.requestOptions.uri.replace(queryParameters: {}).path;
    final detail = e.message ?? defaultMessage;
    throw ApiException(
      message: '${e.type.name}: $detail (path: $path)',
      statusCode: e.response?.statusCode,
    );
  }

  // ---------------------------------------------------------------------------
  // Sorting
  // ---------------------------------------------------------------------------

  /// Sort stations by price (for the selected fuel type) or distance.
  ///
  /// Stations without a price for the selected fuel sort to the bottom.
  void sortStations(List<Station> stations, SearchParams params) {
    if (params.sortBy == SortBy.price) {
      stations.sort((a, b) {
        final pa = a.priceFor(params.fuelType) ?? a.e5 ?? a.diesel ?? 999.0;
        final pb = b.priceFor(params.fuelType) ?? b.e5 ?? b.diesel ?? 999.0;
        return pa.compareTo(pb);
      });
    } else {
      stations.sort((a, b) => a.dist.compareTo(b.dist));
    }
  }

  // ---------------------------------------------------------------------------
  // Distance
  // ---------------------------------------------------------------------------

  /// Calculate Haversine distance and round to 1 decimal place.
  double roundedDistance(double lat1, double lng1, double lat2, double lng2) {
    final d = distanceKm(lat1, lng1, lat2, lng2);
    return double.parse(d.toStringAsFixed(1));
  }

  // ---------------------------------------------------------------------------
  // Filtering
  // ---------------------------------------------------------------------------

  /// Filter stations within [radiusKm]. If none match, return the nearest
  /// [fallbackCount] stations instead (prevents empty results when user
  /// is at the edge of coverage).
  List<Station> filterByRadius(
    List<Station> stations,
    double radiusKm, {
    int fallbackCount = 20,
  }) {
    final withinRadius = stations.where((s) => s.dist <= radiusKm).toList();
    if (withinRadius.isNotEmpty) return withinRadius;

    if (stations.isEmpty) return [];
    final sorted = List<Station>.from(stations)
      ..sort((a, b) => a.dist.compareTo(b.dist));
    return sorted.take(fallbackCount).toList();
  }

  // ---------------------------------------------------------------------------
  // Default implementations for unsupported endpoints
  // ---------------------------------------------------------------------------

  /// Throw [ApiException] for services that don't support single-station detail.
  Never throwDetailUnavailable(String apiName) {
    throw ApiException(message: 'Detail not available from $apiName');
  }

  /// Return an empty prices map for services that don't support batch price refresh.
  ServiceResult<Map<String, StationPrices>> emptyPricesResult(ServiceSource source) {
    return ServiceResult(
      data: const {},
      source: source,
      fetchedAt: DateTime.now(),
    );
  }

  // ---------------------------------------------------------------------------
  // Result wrapping
  // ---------------------------------------------------------------------------

  /// Wrap a station list in [ServiceResult] with standard metadata.
  ServiceResult<List<Station>> wrapStations(
    List<Station> stations,
    ServiceSource source, {
    int limit = 50,
  }) {
    return ServiceResult(
      data: stations.length > limit ? stations.take(limit).toList() : stations,
      source: source,
      fetchedAt: DateTime.now(),
    );
  }
}
