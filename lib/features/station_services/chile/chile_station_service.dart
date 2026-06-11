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
import 'chile_response_parser.dart' as parser;
import '../../../core/logging/error_logger.dart';

/// Chile fuel prices from the **CNE Bencina en Línea** developer API
/// (#596).
///
/// CNE (Comisión Nacional de Energía) publishes the official retail-fuel
/// price registry for Chile through its developer portal at
/// https://api.cne.cl/. Key facts:
///
/// - **Auth**: free registration yields a personal API token. The
///   official docs (apidocs.cne.cl, fetched live for #3200) require it
///   in an `Authorization: Bearer <token>` **header** — the old
///   `?token=` query-parameter form 404s. Note the API answers auth
///   failures with **HTTP 200** and a JSON `{"status": "..."}` body
///   (live-recorded: `Authorization Token not found` / `Token is
///   Invalid` — see `test/fixtures/cl_cne_v4_auth_error.json`), so the
///   parser, not the HTTP status, is the auth gate.
/// - **Coverage**: ~6 000 service stations ("estaciones de servicio")
///   nationwide.
/// - **Fuels published per station** (CNE product codes):
///     `gasolina_93`   Gasolina 93 octanos        → [FuelType.e5]
///     `gasolina_95`   Gasolina 95 octanos        → [FuelType.e5]
///                     (merged with 93 into the e5 slot — Chilean cars
///                      fuel with either; 95 wins when both are quoted
///                      because it is the closer match to the European
///                      E5 RON-95 benchmark)
///     `gasolina_97`   Gasolina 97 octanos        → [FuelType.e98]
///     `diesel`        Diésel                     → [FuelType.diesel]
///     `glp` / `gas_licuado`  Gas licuado (LPG)   → [FuelType.lpg]
///     `kerosene`      Kerosene                   → no enum today;
///                     the parser silently skips it for MVP so a
///                     future enum addition is a one-line change.
/// - **Transport**: HTTP GET, JSON. Responses are UTF-8; Spanish
///   place names survive Dio's default decoding.
///
/// A typical "all stations" dump looks like:
/// ```
/// GET https://api.cne.cl/api/v4/estaciones
/// Authorization: Bearer <apiKey>
/// ```
/// returning
/// ```json
/// {
///   "data": [
///     {
///       "codigo":       "cl-123456",
///       "distribuidor": { "nombre": "Copec" },
///       "nombre_fantasia": "Copec Providencia",
///       "direccion_calle":  "Av. Providencia",
///       "direccion_numero": "1234",
///       "nombre_comuna":    "Providencia",
///       "nombre_region":    "Metropolitana de Santiago",
///       "ubicacion":    { "latitud": -33.4254, "longitud": -70.6115 },
///       "precios":      {
///         "gasolina_93": 1290.0,
///         "gasolina_95": 1310.0,
///         "gasolina_97": 1340.0,
///         "diesel":      1150.0,
///         "glp":         820.0,
///         "kerosene":    1050.0
///       },
///       "horario_atencion": "24_horas"
///     }
///   ]
/// }
/// ```
///
/// Because CNE exposes prices per-station (one payload with all fuels
/// nested under `precios`), a single request is enough to cover the
/// whole fuel family — unlike OPINET (KR) which fans out one call per
/// product. We keep the service radius-filter-aware even so: once the
/// full list is parsed we drop everything outside the user's radius
/// through the shared [StationServiceHelpers.filterByRadius] pass.
///
/// **Endpoint verification (#3200)**: the official docs at
/// apidocs.cne.cl document `GET /api/v4/estaciones` with Bearer-header
/// auth; the old best-guess `/api/v4/combustibles/estaciones?token=`
/// 404s live (host alive — verified 2026-06-10). [defaultBaseUrl] now
/// matches the documented path and the auth header is stamped in the
/// constructor. The station payload shape (`precios` scalar vs nested)
/// remains unconfirmed until a registered token exists — the parser's
/// contract above is the docs' shape.
///
/// **Split (#563)**: the JSON parsing + per-row → [Station] mapping
/// lives in `chile_response_parser.dart` so it can be tested as a pure
/// function without Dio. This shell keeps only the [StationService]
/// implementation: HTTP via Dio, [ServiceResult] plumbing, error
/// classification, and radius filtering.
class ChileStationService
    with StationServiceHelpers
    implements StationService {
  /// CNE "estaciones" dump — returns every station with nested prices
  /// for each product code. Path per the official apidocs.cne.cl docs
  /// (#3200); the endpoint answers (with an auth-error body) on this
  /// exact path, live-verified 2026-06-10.
  static const String defaultBaseUrl = 'https://api.cne.cl/api/v4/estaciones';

  /// Product keys we deliberately drop because no [FuelType] exists
  /// yet. Re-exported from the parser for tests that pin the MVP
  /// policy without crossing into the parser's namespace.
  static const Set<String> droppedProductKeys = parser.chileDroppedProductKeys;

  final Dio _dio;
  final String _apiKey;
  final String _baseUrl;

  ChileStationService({
    required String apiKey,
    Dio? dio,
    String? baseUrl,
  })  : _dio = dio ??
            DioFactory.create(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 20),
            ),
        _apiKey = apiKey,
        _baseUrl = baseUrl ?? defaultBaseUrl {
    // #3200 — CNE requires the token in an Authorization: Bearer header
    // (the old `?token=` query form 404s). Stamped once here so every
    // request this Dio instance makes carries it.
    if (_apiKey.isNotEmpty) {
      _dio.options.headers['Authorization'] = 'Bearer $_apiKey';
    }
  }

  @override
  Future<ServiceResult<List<Station>>> searchStations(
    SearchParams params, {
    CancelToken? cancelToken,
  }) async {
    if (_apiKey.isEmpty) {
      throw const ApiException(
        message: 'CNE API key is not configured',
      );
    }

    try {
      // The token travels in the Authorization header (constructor).
      // No query parameters: we pull everything and filter locally so
      // the radius / sort semantics from [StationServiceHelpers] stay
      // consistent with every other country.
      final response = await _dio.get<dynamic>(
        _baseUrl,
        cancelToken: cancelToken,
      );

      final stations = parseStationsResponse(
        response.data,
        fromLat: params.lat,
        fromLng: params.lng,
      );

      final filtered = filterByRadius(stations, params.radiusKm);
      sortStations(filtered, params);

      return wrapStations(filtered, ServiceSource.chileApi);
    } on DioException catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.other, e, st, context: const {'where': 'CL search failed'}));
      final status = e.response?.statusCode;
      if (status == 401 || status == 403) {
        throw ApiException(
          message: 'CNE rejected API key (HTTP $status)',
          statusCode: status,
        );
      }
      throwApiException(e, defaultMessage: 'Network error (CNE)', stackTrace: st);
    }
  }

  /// Parse the CNE "estaciones" envelope into [Station] instances.
  ///
  /// Thin delegate over [parser.parseChileStationsResponse]; kept on
  /// the service so existing tests + any external callers continue to
  /// work after the #563 split.
  @visibleForTesting
  List<Station> parseStationsResponse(
    dynamic data, {
    required double fromLat,
    required double fromLng,
  }) =>
      parser.parseChileStationsResponse(
        data,
        fromLat: fromLat,
        fromLng: fromLng,
      );

  /// Single source of truth for the CNE-key → [FuelType] mapping.
  /// Delegates to the parser; kept on the service for legacy callers
  /// that import [ChileStationService] directly.
  @visibleForTesting
  static FuelType? fuelForProductKey(String productKey) =>
      parser.fuelForChileProductKey(productKey);

  @override
  Future<ServiceResult<StationDetail>> getStationDetail(
    String stationId,
  ) async {
    throwDetailUnavailable('CNE Bencina en Línea');
  }

  @override
  Future<ServiceResult<Map<String, StationPrices>>> getPrices(
    List<String> ids,
  ) async {
    return emptyPricesResult(ServiceSource.chileApi);
  }
}
