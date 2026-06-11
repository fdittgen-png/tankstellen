// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../search/data/models/search_params.dart';
import '../../search/domain/entities/fuel_type.dart';
import '../../search/domain/entities/station.dart';
import '../../../core/error/exceptions.dart';
import '../../../core/services/dio_factory.dart';
import '../../../core/services/mixins/station_service_helpers.dart';
import '../../../core/services/service_result.dart';
import '../../../core/services/station_service.dart';
import 'romania_observatory_keys.dart';
import 'romania_response_parser.dart';
import '../../../core/logging/error_logger.dart';

/// Romania fuel prices — *Monitorul Prețurilor*, the Competition
/// Council's official price observatory at `monitorulpreturilor.info`
/// (#577, rebased in #3193).
///
/// The previous endpoint (`pretcarburant.ro/api/stations`) was a
/// third-party aggregator misdescribed as official, its URL a live 404
/// and its response schema invented (#3193). The real government
/// observatory is **monitorulpreturilor.info**; its map frontend talks
/// to an undocumented-but-stable WCF/WebAPI backend that this service
/// now consumes directly. Endpoint contract, live-verified and recorded
/// on 2026-06-10 (`test/fixtures/ro_monitorul_*_slice.json` are
/// trimmed copies of real responses):
///
/// ```
/// GET https://monitorulpreturilor.info/pmonsvc/Gas/GetGasItemsByLatLon
///     ?lon=<wgs84 lng>&lat=<wgs84 lat>&buffer=<meters>
///     &CSVGasCatalogProductIds=<one catalog id>&OrderBy=dist
/// Accept: application/json          (otherwise the backend serves XML)
/// ```
///
/// returning
///
/// ```json
/// {
///   "Stations": [
///     {
///       "id": "041B11",
///       "name": "Vulcan Judetu (Bucuresti)",
///       "updatedate": "11/06/2026 00:19 ",
///       "network": { "id": "ROMPETROL", "name": "Rompetrol", "logo": {...} },
///       "addr": {
///         "addrstring": "Sos. Mihai Bravu nr. 396, sector 3, 030327, Bucuresti",
///         "zipcode": "396",
///         "location": { "Lat": 44.421467, "Lon": 26.136633 },
///         "wkt": "POINT(26.136633 44.421467)",
///         "uatid": "179132"
///       }
///     }
///   ],
///   "Products": [
///     {
///       "id": "02",
///       "stationid": "R1009",
///       "name": "Benzina Standard 95 / Benzina 95",
///       "price": 9.12,
///       "distance": 0.68405,
///       "catprod": { "id": "11", "name": "Benzină standard" }
///     }
///   ],
///   "services": [...], "area": {...}, "areawkt": "..."
/// }
/// ```
///
/// Quirks (all live-verified):
///  - despite the `CSV` prefix, `CSVGasCatalogProductIds` accepts only a
///    **single** id — a comma-separated list 500s with an Npgsql
///    `invalid input syntax for type integer` error. Like OPINET (KR)
///    the service therefore fans out one parallel call per fuel and
///    merges by station id (`Products[].stationid` → `Stations[].id`).
///  - prices are RON (lei) per litre, `Stations[].updatedate` is a
///    pre-formatted `dd/MM/yyyy HH:mm` string (passed through; the UI
///    treats `updatedAt` as lossy display text).
///  - some parameter mistakes make the backend answer `200 []` (a bare
///    empty JSON list) instead of the envelope — treated as "no
///    stations", while a `Message`/`ExceptionMessage` body raises.
///
/// Fuel-type mapping lives on [RomaniaObservatoryKeys]
/// (`romania_observatory_keys.dart`):
///
/// ```
/// 11 Benzină standard  → FuelType.e5
/// 12 Benzină premium   → FuelType.e98
/// 21 Motorină standard → FuelType.diesel
/// 22 Motorină premium  → FuelType.dieselPremium
/// 31 GPL               → FuelType.lpg
/// ```
///
/// **Respectful scraping**: every request carries a descriptive
/// `User-Agent` with a contact URL, and the service-level rate limit
/// is 500 ms between requests so a burst of user refreshes cannot
/// turn into a thundering herd against the upstream. The
/// observatory is a public service — we keep our footprint small.
///
/// No auth, no keys — the feed is public.
class RomaniaStationService
    with StationServiceHelpers
    implements StationService {
  /// Official observatory backend base URL (the `Gas` controller).
  /// Override via the constructor's `baseUrl` argument for tests or if
  /// the host ever moves; the parser stays valid.
  static const String defaultBaseUrl =
      'https://monitorulpreturilor.info/pmonsvc/Gas';

  /// Path segment appended to [_baseUrl] for the radius search.
  static const String searchPath = '/GetGasItemsByLatLon';

  /// Respectful scraping contact header — the upstream maintainers
  /// can reach out via this URL if Tankstellen's usage is
  /// problematic.
  static const String userAgent =
      'Tankstellen/5.0 (fuel price comparison) contact: github.com/fdittgen/tankstellen';

  /// The observatory caps useful buffers server-side; clamp to a sane
  /// window so an accidental huge radius cannot turn into a country
  /// dump request.
  static const int _minBufferMeters = 1000;
  static const int _maxBufferMeters = 30000;

  final Dio _dio;
  final String _baseUrl;

  RomaniaStationService({
    Dio? dio,
    String? baseUrl,
  })  : _dio = dio ??
            DioFactory.create(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 20),
              rateLimit: const Duration(milliseconds: 500),
              rateLimitJitterRangeMs: 250,
            ),
        _baseUrl = baseUrl ?? defaultBaseUrl {
    // Stamp the respectful-scraping UA onto every request this Dio
    // instance makes, and force JSON — the WCF backend defaults to XML.
    _dio.options.headers['User-Agent'] = userAgent;
    _dio.options.headers['Accept'] = 'application/json';
  }

  @override
  Future<ServiceResult<List<Station>>> searchStations(
    SearchParams params, {
    CancelToken? cancelToken,
  }) async {
    try {
      final buffer = (params.radiusKm * 1000)
          .clamp(_minBufferMeters, _maxBufferMeters)
          .round();

      // One call per catalog product (the backend rejects CSV lists —
      // see class docs), fanned out in parallel like the KR service.
      // The fixed [entries] order is the contract that lets us zip each
      // response back to its fuel type positionally.
      final entries = RomaniaObservatoryKeys.fuelForCatalogProductId.entries
          .toList(growable: false);

      final responses = await Future.wait([
        for (final entry in entries)
          _dio.get<dynamic>(
            '$_baseUrl$searchPath',
            queryParameters: {
              'lon': params.lng,
              'lat': params.lat,
              'buffer': buffer,
              'CSVGasCatalogProductIds': entry.key,
              'OrderBy': 'dist',
            },
            cancelToken: cancelToken,
          ),
      ]);

      // Merge by station id so one station gathers all fuels.
      final byId = <String, MonitorulStationAccumulator>{};
      for (var i = 0; i < entries.length; i++) {
        mergeMonitorulProductResponse(responses[i].data, byId, entries[i].value);
      }

      final stations = byId.values
          .map((acc) => acc.toStation(params.lat, params.lng))
          .whereType<Station>()
          .toList();

      final filtered = filterByRadius(stations, params.radiusKm);
      sortStations(filtered, params);

      return ServiceResult(
        data: filtered,
        source: ServiceSource.romaniaApi,
        fetchedAt: DateTime.now(),
      );
    } on DioException catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.other, e, st,
          context: const {'where': 'RO Monitorul fetch failed'}));
      final status = e.response?.statusCode;
      throw ApiException(
        message: 'Monitorul Prețurilor unreachable (${e.type.name})'
            '${status != null ? ' [HTTP $status]' : ''}',
        statusCode: status,
      );
    } on ApiException {
      rethrow;
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.other, e, st,
          context: const {'where': 'RO Monitorul unexpected error'}));
      throw ApiException(message: 'Monitorul Prețurilor parse error: $e');
    }
  }

  /// Parse one single-product observatory response into [Station]
  /// objects (the per-fuel price stamped from [fuelType]). Exposed for
  /// tests so the parser is driven by the recorded fixtures
  /// independent of any Dio mock.
  @visibleForTesting
  List<Station> parseSingleProductResponse(
    dynamic data,
    FuelType fuelType, {
    required double fromLat,
    required double fromLng,
  }) {
    final byId = <String, MonitorulStationAccumulator>{};
    mergeMonitorulProductResponse(data, byId, fuelType);
    return byId.values
        .map((acc) => acc.toStation(fromLat, fromLng))
        .whereType<Station>()
        .toList();
  }

  /// Exposed for tests — single source of truth for the catalog
  /// product-id → [FuelType] mapping.
  @visibleForTesting
  static FuelType? fuelForCatalogProductId(String id) =>
      RomaniaObservatoryKeys.lookup(id);

  @override
  Future<ServiceResult<StationDetail>> getStationDetail(
    String stationId,
  ) async {
    throwDetailUnavailable('Monitorul Prețurilor');
  }

  @override
  Future<ServiceResult<Map<String, StationPrices>>> getPrices(
    List<String> ids,
  ) async {
    return emptyPricesResult(ServiceSource.romaniaApi);
  }

}
