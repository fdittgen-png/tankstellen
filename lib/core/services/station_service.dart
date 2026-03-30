import 'package:dio/dio.dart';

import '../../features/search/data/models/search_params.dart';
import '../../features/search/domain/entities/station.dart';
import 'service_result.dart';

/// Prices for a single station, returned by the batch price refresh endpoint.
///
/// Contains nullable price fields for each fuel type. A null value means
/// the station does not sell that fuel or the price is unavailable.
/// The [status] field indicates whether the station is currently open.
class StationPrices {
  final double? e5;
  final double? e10;
  final double? diesel;
  final String status;

  const StationPrices({this.e5, this.e10, this.diesel, required this.status});
  bool get isOpen => status == 'open';

  Map<String, dynamic> toJson() => {
        'e5': e5,
        'e10': e10,
        'diesel': diesel,
        'status': status,
      };

  factory StationPrices.fromJson(Map<String, dynamic> json) => StationPrices(
        e5: json['e5'] is num ? (json['e5'] as num).toDouble() : null,
        e10: json['e10'] is num ? (json['e10'] as num).toDouble() : null,
        diesel:
            json['diesel'] is num ? (json['diesel'] as num).toDouble() : null,
        status: json['status'] as String? ?? 'closed',
      );
}

/// Abstract interface for station data providers.
///
/// Any data source that can answer "what stations are near here?" and
/// "what are the current prices?" implements this interface. Each
/// country-specific API has its own implementation (Tankerkoenig for DE,
/// Prix-Carburants for FR, E-Control for AT, etc.).
///
/// The document format (JSON structure, field names, coordinate encoding)
/// is handled inside each implementation -- consumers only see domain
/// objects ([Station], [StationDetail], [StationPrices]).
///
/// All implementations are wrapped in [StationServiceChain] which adds
/// caching, fallback, and request deduplication on top.
///
/// To add a new country, implement this interface and register it in
/// `service_providers.dart`. See CONTRIBUTING.md for the full guide.
abstract class StationService {
  /// Search for stations near a geographic location.
  ///
  /// [params] specifies the search center (lat/lng), radius, fuel type
  /// filter, sort order, and optional postal code. Returns a list of
  /// [Station] objects sorted according to [SearchParams.sortBy].
  ///
  /// Throws [ApiException] on network or API errors. The caller
  /// ([StationServiceChain]) catches these and falls back to cache.
  Future<ServiceResult<List<Station>>> searchStations(
    SearchParams params, {
    CancelToken? cancelToken,
  });

  /// Get full details for a single station by its ID.
  ///
  /// Returns extended data including opening times, overrides, and state.
  /// Not all country APIs support this -- unsupported implementations
  /// throw [ApiException] with an appropriate message.
  Future<ServiceResult<StationDetail>> getStationDetail(String stationId);

  /// Refresh current prices for up to 10 stations in a single request.
  ///
  /// [ids] is the list of station IDs to query. Returns a map from
  /// station ID to [StationPrices]. Used by the favorites screen to
  /// update prices without performing a full search.
  ///
  /// Not all country APIs support batch price queries. Unsupported
  /// implementations return an empty map.
  Future<ServiceResult<Map<String, StationPrices>>> getPrices(
    List<String> ids,
  );
}
