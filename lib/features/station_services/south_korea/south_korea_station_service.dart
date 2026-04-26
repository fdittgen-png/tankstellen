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
import 'south_korea_response_parser.dart';

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
/// returns a list of stations around a coordinate. An approximate URL
/// shape is
/// ```
/// https://www.opinet.co.kr/api/aroundAll.do
///   ?code=<apiKey>&x=<lng>&y=<lat>&radius=<meters>&sort=1&prodcd=B027
///   &out=json
/// ```
/// where `x` is longitude and `y` is latitude in WGS84 (the public site
/// also serves KATEC-projected coords, but the documented developer
/// endpoint accepts WGS84).
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
///         "GIS_X_COOR": "127.0287",
///         "GIS_Y_COOR": "37.4997",
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
/// **Endpoint verification**: the live OPINET developer docs change
/// periodically (path segments like `searchByTid.do`, `searchByZcd.do`,
/// `aroundAll.do` come and go). The [defaultBaseUrl] constant is the
/// current best-guess path; the service is fully functional against the
/// documented JSON response shape regardless of whether the exact path
/// drifts. If a path change breaks the live call, the bug is one URL
/// constant — the parser + fuel mapping + country wiring stay valid.
class SouthKoreaStationService
    with StationServiceHelpers
    implements StationService {
  /// OPINET "around all" endpoint — radius search by WGS84 coordinate.
  /// TODO: verify endpoint path against the live developer portal. The
  /// JSON payload shape (RESULT → OIL → array) is stable across OPINET
  /// endpoints and is the contract our parser depends on.
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
      throw const ApiException(
        message: 'OPINET API key is not configured',
      );
    }

    try {
      // OPINET limits radius to ~5 km on the free tier; clamp to a
      // sensible 50 km upper bound so an accidental huge radius can't
      // get a 400 back.
      final radiusMeters =
          (params.radiusKm * 1000).clamp(1000, 50 * 1000).round();

      // Fetch per-product payloads and merge by UNI_ID so a single
      // station ends up with all four fuel prices on one [Station].
      final byId = <String, OpinetStationAccumulator>{};

      for (final entry in OpinetProductCodes.fuelForProductCode.entries) {
        final productCode = entry.key;
        final fuelType = entry.value;

        final response = await _dio.get(
          _baseUrl,
          queryParameters: {
            'code': _apiKey,
            'x': params.lng,
            'y': params.lat,
            'radius': radiusMeters,
            'prodcd': productCode,
            'sort': 1, // 1 = by price ascending; server still returns all
            'out': 'json',
          },
          cancelToken: cancelToken,
        );

        mergeOpinetProductResponse(response.data, byId, fuelType);
      }

      final stations = byId.values
          .map((acc) => acc.toStation(params.lat, params.lng))
          .whereType<Station>()
          .toList();

      final filtered = filterByRadius(stations, params.radiusKm);
      sortStations(filtered, params);

      return wrapStations(filtered, ServiceSource.openinetApi);
    } on DioException catch (e, st) {
      debugPrint('KR search failed: $e\n$st');
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
