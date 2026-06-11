// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:dio/dio.dart';

import '../domain/search_params.dart';
import '../domain/station.dart';
import '../domain/station_prices.dart';
import 'service_result.dart';

/// [StationPrices] moved to the shared domain kernel (#3130); the re-export
/// keeps every existing `station_service.dart` import site compiling.
export '../domain/station_prices.dart' show StationPrices;

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
/// `service_providers.dart`. See docs/CONTRIBUTING.md for the full guide.
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
