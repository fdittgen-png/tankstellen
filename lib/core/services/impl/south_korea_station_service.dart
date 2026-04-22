import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../features/search/data/models/search_params.dart';
import '../../../features/search/domain/entities/fuel_type.dart';
import '../../../features/search/domain/entities/station.dart';
import '../../error/exceptions.dart';
import '../dio_factory.dart';
import '../mixins/station_service_helpers.dart';
import '../service_result.dart';
import '../station_service.dart';

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
/// matching slot on [Station].
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

  /// OPINET product codes → our canonical [FuelType].
  ///
  /// The four we ship today; kerosene (`C004`) has no enum yet and is
  /// intentionally omitted so the parser skips it silently.
  static const Map<String, FuelType> _productCodeToFuel = {
    'B027': FuelType.e5,
    'B034': FuelType.e98,
    'D047': FuelType.diesel,
    'K015': FuelType.lpg,
  };

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
      final byId = <String, _StationAccumulator>{};

      for (final entry in _productCodeToFuel.entries) {
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

        _mergeProductResponse(response.data, byId, fuelType);
      }

      final stations = byId.values
          .map((acc) => acc.toStation(params.lat, params.lng, this))
          .whereType<Station>()
          .toList();

      final filtered = filterByRadius(stations, params.radiusKm);
      sortStations(filtered, params);

      return wrapStations(filtered, ServiceSource.openinetApi);
    } on DioException catch (e) {
      debugPrint('KR search failed: $e');
      final status = e.response?.statusCode;
      if (status == 401 || status == 403) {
        throw ApiException(
          message: 'OPINET rejected API key (HTTP $status)',
          statusCode: status,
        );
      }
      throwApiException(e, defaultMessage: 'Network error (OPINET)');
    }
  }

  void _mergeProductResponse(
    dynamic data,
    Map<String, _StationAccumulator> byId,
    FuelType fuelType,
  ) {
    // Accept either already-parsed maps or raw strings (some proxies
    // hand back JSON as text/plain).
    final parsed = _coerceMap(data);
    if (parsed == null) {
      throw const ApiException(message: 'OPINET returned unparseable body');
    }

    // Propagate an OPINET-level error (RESULT.OIL is always a list on
    // success; when auth fails OPINET returns `{"RESULT":{"OIL":[]}}`
    // with an HTTP 200 and sometimes a top-level `ERROR` field).
    final errField = parsed['ERROR'];
    if (errField != null) {
      throw ApiException(message: 'OPINET error: $errField');
    }

    final result = parsed['RESULT'];
    if (result is! Map) return; // tolerate empty
    final oil = result['OIL'];
    if (oil is! List) return;

    for (final raw in oil) {
      if (raw is! Map) continue;
      final uniId = raw['UNI_ID']?.toString();
      if (uniId == null || uniId.isEmpty) continue;

      final acc = byId.putIfAbsent(
        uniId,
        () => _StationAccumulator(uniId: uniId),
      );
      acc.absorbBase(raw);

      final priceRaw = raw['PRICE'];
      final price = _parseWonPerLitre(priceRaw);
      if (price != null) acc.prices[fuelType] = price;
    }
  }

  /// Exposed helper for parser tests.
  @visibleForTesting
  List<Station> parseSingleProductResponse(
    dynamic data,
    FuelType fuelType, {
    required double fromLat,
    required double fromLng,
  }) {
    final byId = <String, _StationAccumulator>{};
    _mergeProductResponse(data, byId, fuelType);
    return byId.values
        .map((acc) => acc.toStation(fromLat, fromLng, this))
        .whereType<Station>()
        .toList();
  }

  /// Exposed for tests — single source of truth for the product-code
  /// → [FuelType] mapping.
  @visibleForTesting
  static FuelType? fuelForProductCode(String productCode) =>
      _productCodeToFuel[productCode];

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

  // ──────────────────────────────────────────────────────────────────────
  // Helpers
  // ──────────────────────────────────────────────────────────────────────

  /// OPINET prices are integer strings in **KRW per litre** (e.g.
  /// `"1689"` = ₩1 689/L). Tankstellen holds prices as `double` in the
  /// local currency unit, matching what the forecourt sign shows. No
  /// scaling is applied — we keep KRW/L as-is.
  double? _parseWonPerLitre(dynamic raw) {
    if (raw == null) return null;
    if (raw is num) {
      if (raw <= 0) return null;
      return raw.toDouble();
    }
    if (raw is String) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return null;
      final v = double.tryParse(trimmed);
      if (v == null || v <= 0) return null;
      return v;
    }
    return null;
  }

  Map? _coerceMap(dynamic data) {
    if (data is Map) return data;
    return null;
  }
}

/// In-flight accumulator while merging per-product OPINET responses.
///
/// Exposed as non-private so the service's `@visibleForTesting` helpers
/// can hand it across the test boundary without duplicating the
/// merge algorithm.
class _StationAccumulator {
  final String uniId;
  String? brandCode; // POLL_DIV_CD (SKE, GS, HDO, …)
  String? name; // OS_NM
  String? address; // NEW_ADR
  double? lat; // GIS_Y_COOR
  double? lng; // GIS_X_COOR
  double? apiDistanceKm; // DISTANCE (meters → km)
  final Map<FuelType, double> prices = <FuelType, double>{};

  _StationAccumulator({required this.uniId});

  void absorbBase(Map raw) {
    brandCode ??= raw['POLL_DIV_CD']?.toString();
    name ??= raw['OS_NM']?.toString().trim();
    address ??= raw['NEW_ADR']?.toString().trim();

    lat ??= _parseDouble(raw['GIS_Y_COOR']);
    lng ??= _parseDouble(raw['GIS_X_COOR']);

    final distRaw = raw['DISTANCE'];
    final distMeters = _parseDouble(distRaw);
    if (distMeters != null && distMeters > 0) {
      final km = double.parse((distMeters / 1000.0).toStringAsFixed(1));
      apiDistanceKm ??= km;
    }
  }

  Station? toStation(
    double fromLat,
    double fromLng,
    SouthKoreaStationService host,
  ) {
    final resolvedLat = lat;
    final resolvedLng = lng;
    if (resolvedLat == null || resolvedLng == null) return null;
    if (resolvedLat == 0 && resolvedLng == 0) return null;

    final brand = _brandFromCode(brandCode);
    final distKm = apiDistanceKm ??
        host.roundedDistance(fromLat, fromLng, resolvedLat, resolvedLng);

    return Station(
      id: 'kr-$uniId',
      name: name?.isNotEmpty == true ? name! : brand,
      brand: brand,
      street: address ?? '',
      postCode: '',
      place: '',
      lat: resolvedLat,
      lng: resolvedLng,
      dist: distKm,
      e5: prices[FuelType.e5],
      e98: prices[FuelType.e98],
      diesel: prices[FuelType.diesel],
      lpg: prices[FuelType.lpg],
      isOpen: true, // OPINET does not expose a reliable open/closed flag
    );
  }

  static double? _parseDouble(dynamic raw) {
    if (raw == null) return null;
    if (raw is num) return raw.toDouble();
    if (raw is String) {
      final t = raw.trim();
      if (t.isEmpty) return null;
      return double.tryParse(t);
    }
    return null;
  }

  /// Map OPINET `POLL_DIV_CD` codes to forecourt brand labels. Covers
  /// the four "refiners" that dominate the Korean market plus the
  /// generic independent label (`RTO`, `ETC`).
  static String _brandFromCode(String? code) {
    switch (code) {
      case 'SKE':
        return 'SK에너지';
      case 'GSC':
        return 'GS칼텍스';
      case 'HDO':
        return '현대오일뱅크';
      case 'SOL':
        return 'S-OIL';
      case 'RTO':
        return '알뜰주유소';
      case 'NHO':
        return 'NH농협';
      case 'ETC':
      case null:
      case '':
        return 'Independent';
      default:
        return code;
    }
  }
}
