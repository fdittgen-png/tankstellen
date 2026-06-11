// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:dio/dio.dart';

import '../../domain/search_params.dart';
import '../../domain/fuel_type.dart';
import '../../domain/station.dart';
import '../../error/exceptions.dart';
import '../../utils/geo_utils.dart';
import '../../utils/station_extensions.dart';
import '../rate_limit_interceptor.dart';
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
  /// carry enough context to diagnose without a repro (#524). Pass the
  /// caught stack trace as [stackTrace] (#1103) so the rethrown
  /// [ApiException] keeps the original Dio call site instead of being
  /// re-stamped at the throw point — required for usable Sentry /
  /// `TraceRecorder` triage.
  ///
  /// Use in catch blocks:
  /// `on DioException catch (e, st) { throwApiException(e, stackTrace: st); }`
  Never throwApiException(
    DioException e, {
    String defaultMessage = 'Network error',
    StackTrace? stackTrace,
  }) {
    final path = e.requestOptions.uri.replace(queryParameters: {}).path;
    final detail = e.message ?? defaultMessage;
    final apiException = ApiException(
      message: '${e.type.name}: $detail (path: $path)',
      statusCode: e.response?.statusCode,
      kind: failureKindFromDio(e),
      // #2255 — the RetryAfterInterceptor stashes the parsed Retry-After on
      // `requestOptions.extra` before the error propagates; fall back to
      // parsing the response header directly for the (rare) path where no
      // interceptor ran.
      retryAfter: retryAfterFromDio(e),
    );
    if (stackTrace != null) {
      Error.throwWithStackTrace(apiException, stackTrace);
    }
    throw apiException;
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

  /// Keep only stations that actually SELL [fuelType] — i.e. carry a usable
  /// (`> 0`) price for it (#2926). This is the HARD-filter semantic the search
  /// and the Fuel Station Radar must share: when the user selects a specific
  /// fuel, both surfaces show ONLY forecourts that sell it, never a `--`
  /// placeholder row, so the two result sets are identical for the same
  /// position + radius + fuel.
  ///
  /// Returns the list unchanged for:
  ///  - [FuelType.all] — the explicit "every fuel" wildcard (no filter), and
  ///  - fuels the [Station] entity does not price (electric / hydrogen, whose
  ///    [StationDisplay.priceFor] is always `null`). Those run through their
  ///    own (EV) feed; filtering here would wrongly empty every list.
  static List<Station> filterByFuel(List<Station> stations, FuelType fuelType) {
    if (fuelType == FuelType.all || !_isPricedFuel(fuelType)) return stations;
    return stations
        .where((s) {
          final price = s.priceFor(fuelType);
          return price != null && price > 0;
        })
        .toList(growable: false);
  }

  /// Whether [fuelType] is one the [Station] entity carries a price for — the
  /// liquid/gas pumps (E5/E10/E98/diesel/diesel+/E85/LPG/CNG). Electric and
  /// hydrogen are never priced on [Station] (their `priceFor` is `null`), so
  /// [filterByFuel] must not hard-drop on them.
  static bool _isPricedFuel(FuelType fuelType) => switch (fuelType) {
        FuelTypeHydrogen() || FuelTypeElectric() || FuelTypeAll() => false,
        _ => true,
      };

  // ---------------------------------------------------------------------------
  // Default implementations for unsupported endpoints
  // ---------------------------------------------------------------------------

  /// Throw [ApiException] for services that don't support single-station detail.
  Never throwDetailUnavailable(String apiName) {
    throw ApiException(
      message: 'Detail not available from $apiName',
      kind: FailureKind.unsupported,
    );
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
