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
import 'katec_converter.dart';
import 'south_korea_response_parser.dart';
import '../../../core/logging/error_logger.dart';

/// South Korea fuel prices from the **OPINET** (Korea National Oil
/// Corporation, KNOC) developer API (#597).
///
/// OPINET is the official nationwide retail-fuel-price clearing house
/// operated by KNOC. Their developer portal at https://www.opinet.co.kr/
/// exposes several read-only REST endpoints. Key facts:
///
/// - **Auth**: every call carries `code=<apiKey>` where the key comes
///   from a free developer-portal registration (human review, normally
///   approved in a day or two).
/// - **Coverage**: ~14 000 filling stations (virtually every pump in the
///   country).
/// - **Fuels published per station** (OPINET product codes):
///     `B027` Gasoline (휘발유)           → [FuelType.e5]
///     `B034` Premium Gasoline (고급휘발유) → [FuelType.e98]
///     `D047` Diesel (경유)               → [FuelType.diesel]
///     `K015` LPG (부탄)                  → [FuelType.lpg]
///     `C004` Kerosene (실내등유)          → no enum today; dropped for
///                                          MVP (OPINET still returns it;
///                                          the parser silently skips).
/// - **Transport**: HTTP GET, `out=json` or `out=xml` — we use JSON.
///   Responses are UTF-8 (Korean place names survive Dio's default
///   decoding — do **not** override to latin1).
///
/// The typical station-lookup call is a radius / region query that
/// returns a list of stations around a coordinate. The documented URL
/// shape (opinet.co.kr API doc, apiId=3) is
/// ```
/// https://www.opinet.co.kr/api/aroundAll.do
///   ?code=<apiKey>&x=<easting>&y=<northing>&radius=<meters>&sort=1
///   &prodcd=B027&out=json
/// ```
/// where `x`/`y` are **KATEC** (Korean TM grid) metres, *not* WGS84
/// degrees (#3192). The service converts the caller's WGS84 search
/// point through [wgs84ToKatec] before querying, and the parser
/// converts the response's KATEC `GIS_X_COOR`/`GIS_Y_COOR` back to
/// WGS84 (see `south_korea_response_parser.dart`). The documented
/// radius ceiling is 5 000 m.
///
/// Response shape observed on the developer portal:
/// ```json
/// {
///   "RESULT": {
///     "OIL": [
///       {
///         "UNI_ID":  "A0010684",
///         "POLL_DIV_CD": "SKE",
///         "OS_NM":  "SK에너지 강남주유소",
///         "NEW_ADR": "서울특별시 강남구 테헤란로 152",
///         "GIS_X_COOR": "314312.63",   // KATEC easting (m) — not WGS84!
///         "GIS_Y_COOR": "544612.34",   // KATEC northing (m)
///         "PRICE":  "1689",   // KRW per litre (integer string)
///         "HPRICE": "1999",
///         "LPRICE": "1689",
///         "DISTANCE": "382"
///       }
///     ]
///   }
/// }
/// ```
///
/// Because prices are returned **one product at a time**, a full
/// multi-fuel search requires up to four separate calls. To keep the
/// UI responsive we merge by `UNI_ID` after each call and pre-fill the
/// matching slot on [Station] (see
/// [`south_korea_response_parser.dart`](south_korea_response_parser.dart)
/// for the merge accumulator + product-code map).
///
/// **Endpoint verification (#3176, live-probed 2026-06-10)**: the
/// [defaultBaseUrl] path is **confirmed live** — `GET aroundAll.do`
/// answers HTTP 200 with the documented `RESULT → OIL` envelope, so the
/// parser contract holds and the path is no longer a guess. The KATEC
/// coordinate conversion and the 5 000 m radius clamp shipped with
/// #3192. One live caveat remains (epic #3186): the portal documents
/// `certkey` while we send `code`, and an unknown/invalid key is
/// *silently* answered with an empty `OIL` array (verified live), never
/// an HTTP 401/403 — so an all-products-empty result is ambiguous
/// between "no stations in radius" and "bad key". [searchStations]
/// breadcrumbs that case via errorLogger without failing the search.
class SouthKoreaStationService
    with StationServiceHelpers
    implements StationService {
  /// OPINET "around all" endpoint — radius search by coordinate.
  /// Path live-verified 2026-06-10 (#3176): HTTP 200 + the documented
  /// `RESULT → OIL` JSON envelope. KATEC coordinates + the 5 km radius
  /// clamp shipped with #3192; the `certkey`-vs-`code` auth question is
  /// the remaining caveat — see the class doc.
  static const String defaultBaseUrl =
      'https://www.opinet.co.kr/api/aroundAll.do';

  final Dio _dio;
  final String _apiKey;
  final String _baseUrl;

  SouthKoreaStationService({
    required String apiKey,
    Dio? dio,
    String? baseUrl,
  })  : _dio = dio ??
            DioFactory.create(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 15),
            ),
        _apiKey = apiKey,
        _baseUrl = baseUrl ?? defaultBaseUrl;

  @override
  Future<ServiceResult<List<Station>>> searchStations(
    SearchParams params, {
    CancelToken? cancelToken,
  }) async {
    if (_apiKey.isEmpty) {
      // #3176 — classify the missing key as an auth failure (the enum's
      // documented home for "missing API key") and leave a trace, so the
      // chain treats it as terminal instead of retrying a doomed call.
      const e = ApiException(
        message: 'OPINET API key is not configured',
        kind: FailureKind.auth,
      );
      unawaited(errorLogger.log(ErrorLayer.other, e, StackTrace.current,
          context: const {'where': 'KR search without API key'}));
      throw e;
    }

    try {
      // OPINET documents a 5 000 m radius ceiling (#3192) — clamp so an
      // oversized search radius can't get a 400 (or silent truncation)
      // back. The shared filterByRadius pass keeps semantics consistent.
      final radiusMeters =
          (params.radiusKm * 1000).clamp(1000, 5000).round();

      // OPINET expects the query point in KATEC metres, not WGS84
      // degrees (#3192) — convert once for all four product calls.
      final katec = wgs84ToKatec(params.lat, params.lng);

      // OPINET returns prices one product at a time, so a full multi-fuel
      // search needs four calls. Issue them in parallel instead of serially
      // (#2301) — serial awaits multiplied latency 4× (4-12 s typical, up to
      // 100 s worst case). The fixed [entries] order is the contract that
      // lets us zip each response back to its fuel type positionally:
      // responses[i] is the payload for entries[i].value, so a slow/failed
      // call can never merge a price under the wrong fuel.
      final entries =
          OpinetProductCodes.fuelForProductCode.entries.toList(growable: false);

      final responses = await Future.wait([
        for (final entry in entries)
          _dio.get<dynamic>(
            _baseUrl,
            queryParameters: {
              'code': _apiKey,
              // KATEC easting/northing in metres (#3192). Sub-metre
              // precision is irrelevant for a radius search — round to
              // keep URLs short and logs readable.
              'x': double.parse(katec.x.toStringAsFixed(1)),
              'y': double.parse(katec.y.toStringAsFixed(1)),
              'radius': radiusMeters,
              'prodcd': entry.key,
              'sort': 1, // 1 = by price ascending; server still returns all
              'out': 'json',
            },
            cancelToken: cancelToken,
          ),
      ]);

      // Merge by UNI_ID so a single station ends up with all four fuel
      // prices on one [Station]. Pair each response with its fuel type by
      // index — Future.wait preserves order regardless of completion order.
      final byId = <String, OpinetStationAccumulator>{};
      for (var i = 0; i < entries.length; i++) {
        mergeOpinetProductResponse(responses[i].data, byId, entries[i].value);
      }

      // #3176 — with the KATEC conversion shipped (#3192) an empty merge
      // is usually a legitimately station-free radius, but OPINET also
      // answers an INVALID key with the same silent empty envelope
      // (verified live), so leave a trace for field diagnosis without
      // failing the search.
      if (byId.isEmpty) {
        unawaited(errorLogger.log(
            ErrorLayer.other,
            Exception('OPINET returned zero stations for every product '
                'code — empty radius or silently-rejected key (#3176)'),
            StackTrace.current,
            context: const {'where': 'KR all-products-empty (#3176)'}));
      }

      final stations = byId.values
          .map((acc) => acc.toStation(params.lat, params.lng))
          .whereType<Station>()
          .toList();

      final filtered = filterByRadius(stations, params.radiusKm);
      sortStations(filtered, params);

      return wrapStations(filtered, ServiceSource.openinetApi);
    } on DioException catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.other, e, st, context: const {'where': 'KR search failed'}));
      final status = e.response?.statusCode;
      if (status == 401 || status == 403) {
        throw ApiException(
          message: 'OPINET rejected API key (HTTP $status)',
          statusCode: status,
        );
      }
      throwApiException(e, defaultMessage: 'Network error (OPINET)', stackTrace: st);
    }
  }

  /// Exposed helper for parser tests. Delegates to
  /// [mergeOpinetProductResponse] so the accumulator + envelope rules
  /// live in exactly one place.
  @visibleForTesting
  List<Station> parseSingleProductResponse(
    dynamic data,
    FuelType fuelType, {
    required double fromLat,
    required double fromLng,
  }) {
    final byId = <String, OpinetStationAccumulator>{};
    mergeOpinetProductResponse(data, byId, fuelType);
    return byId.values
        .map((acc) => acc.toStation(fromLat, fromLng))
        .whereType<Station>()
        .toList();
  }

  /// Exposed for tests — single source of truth for the product-code
  /// → [FuelType] mapping. Delegates to [OpinetProductCodes.lookup] so
  /// the mapping table itself lives next to the parser it powers.
  @visibleForTesting
  static FuelType? fuelForProductCode(String productCode) =>
      OpinetProductCodes.lookup(productCode);

  @override
  Future<ServiceResult<StationDetail>> getStationDetail(
    String stationId,
  ) async {
    throwDetailUnavailable('OPINET (KNOC)');
  }

  @override
  Future<ServiceResult<Map<String, StationPrices>>> getPrices(
    List<String> ids,
  ) async {
    return emptyPricesResult(ServiceSource.openinetApi);
  }
}
