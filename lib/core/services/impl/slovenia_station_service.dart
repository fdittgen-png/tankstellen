import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../features/search/data/models/search_params.dart';
import '../../../features/search/domain/entities/station.dart';
import '../dio_factory.dart';
import '../mixins/station_service_helpers.dart';
import '../service_result.dart';
import '../station_service.dart';

/// Slovenia fuel prices from the community `goriva.si` API (#575).
///
/// Background:
/// - Retail fuel prices in Slovenia are **government-regulated** — the
///   Ministry of the Economy publishes a ceiling/reference price by
///   decree (weekly/biweekly). The source PDF/HTML on `gov.si` is
///   awkward to parse, so we use the well-maintained community feed at
///   `goriva.si` which aggregates the same data into clean JSON.
/// - No API key, no request quota documented, free to use under the
///   spirit of the underlying public dataset.
/// - The live endpoint supports a `position=lat,lng&radius=<meters>`
///   server-side radius query, which keeps responses small and avoids
///   downloading the full ~550-station national dataset on every search.
///
/// Response shape (single entry):
/// ```json
/// {
///   "pk": 2048,
///   "franchise": 1,
///   "name": "PETROL LJUBLJANA - TIVOLSKA",
///   "address": "TIVOLSKA CESTA 43",
///   "lat": 46.0580724,
///   "lng": 14.50344546,
///   "prices": {
///     "95": 1.605,             // NMB-95  -> e5
///     "dizel": 1.736,          // Dizel   -> diesel
///     "98": null,              // NMB-98  -> e98
///     "100": 1.901,            // NMB-100 -> dieselPremium *no* — petrol premium
///     "dizel-premium": null,   // Diesel premium
///     "avtoplin-lpg": 1.049,   // LPG
///     "KOEL": null,            // heating oil (ignored)
///     "hvo": null,
///     "cng": null,
///     "lng": null
///   },
///   "distance": 785.73,         // metres from query position
///   "open_hours": "...",
///   "zip_code": "1000"
/// }
/// ```
///
/// Fuel type mapping (issue #575):
/// - `95`          → E5            (NMB-95, 95-oktanski motorni bencin)
/// - `100`         → E98           (NMB-100 premium petrol — closest fit
///                                  in our sealed class; E98 is already
///                                  used as the "premium petrol" bucket
///                                  for other countries, e.g. ES 98)
/// - `dizel`       → diesel        (Standardno dizelsko gorivo)
/// - `dizel-premium` → dieselPremium
/// - `avtoplin-lpg` → lpg
/// - `cng`         → cng
///
/// `98` (NMB-98) is also mapped to e98 but only when `100` is null, so
/// we never lose the "best petrol price at this pump" signal.
///
/// Prices are in EUR per litre, inclusive of VAT, which matches our
/// canonical internal price convention — no rescaling needed.
class SloveniaStationService with StationServiceHelpers implements StationService {
  /// Live community feed. Uses the same backing dataset as `gov.si` but
  /// exposes it as clean paginated JSON with a server-side radius query.
  static const String defaultBaseUrl = 'https://goriva.si/api/v1/search/';

  final Dio _dio;
  final String _baseUrl;

  SloveniaStationService({Dio? dio, String? baseUrl})
      : _dio = dio ??
            DioFactory.create(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 15),
            ),
        _baseUrl = baseUrl ?? defaultBaseUrl;

  @override
  Future<ServiceResult<List<Station>>> searchStations(
    SearchParams params, {
    CancelToken? cancelToken,
  }) async {
    try {
      // goriva.si takes `position=lat,lng` and `radius` in **meters**.
      // Multiply radiusKm by 1000 and clamp to a sensible upper bound
      // (200 km) so an accidental huge radius can't DOS their server.
      final radiusMeters = (params.radiusKm * 1000)
          .clamp(1000, 200 * 1000)
          .round();

      final response = await _dio.get(
        _baseUrl,
        queryParameters: {
          'format': 'json',
          'position': '${params.lat},${params.lng}',
          'radius': radiusMeters,
        },
        cancelToken: cancelToken,
      );

      final stations = parseResponse(response.data);

      // `distance` from goriva.si is already the straight-line meters
      // distance from the search position — trust it where present,
      // otherwise compute from lat/lng like every other country service
      // so the list sort is stable.
      final withDistance = stations.map((s) {
        if (s.dist > 0) return s; // already populated from API `distance`
        return s.copyWith(
          dist: roundedDistance(params.lat, params.lng, s.lat, s.lng),
        );
      }).toList();

      final filtered = filterByRadius(withDistance, params.radiusKm);
      sortStations(filtered, params);

      return wrapStations(filtered, ServiceSource.sloveniaApi);
    } on DioException catch (e) {
      throwApiException(e, defaultMessage: 'Network error (Slovenia goriva.si)');
    }
  }

  /// Parses a goriva.si paginated search response into [Station]s.
  ///
  /// Exposed for unit testing — mirrors the exact transformation the
  /// production code path runs after the HTTP fetch.
  @visibleForTesting
  List<Station> parseResponse(dynamic data) {
    if (data is! Map) return const [];
    final results = data['results'];
    if (results is! List) return const [];

    final parsed = <Station>[];
    for (final raw in results) {
      if (raw is! Map) continue;
      final station = _parseStation(raw);
      if (station != null) parsed.add(station);
    }
    return parsed;
  }

  Station? _parseStation(Map raw) {
    final lat = (raw['lat'] as num?)?.toDouble();
    final lng = (raw['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) return null;
    if (lat == 0 && lng == 0) return null;

    final prices = raw['prices'];
    final pricesMap = prices is Map ? prices : const <String, dynamic>{};

    final pk = raw['pk']?.toString() ?? '';
    final name = raw['name']?.toString().trim() ?? '';
    final address = raw['address']?.toString().trim() ?? '';
    final zipCode = raw['zip_code']?.toString() ?? '';

    // `98` only wins when `100` is absent — higher-octane 100 is the
    // premium pump price consumers actually see on the forecourt.
    final nmb95 = _priceFor(pricesMap, '95');
    final nmb100 = _priceFor(pricesMap, '100');
    final nmb98 = _priceFor(pricesMap, '98');
    final dizel = _priceFor(pricesMap, 'dizel');
    final dizelPremium = _priceFor(pricesMap, 'dizel-premium');
    final lpg = _priceFor(pricesMap, 'avtoplin-lpg');
    final cng = _priceFor(pricesMap, 'cng');

    // API may pre-compute `distance` in meters. Convert to km so it's
    // ready for the standard filterByRadius pipeline, rounded to 0.1 km.
    double distKm = 0;
    final distanceRaw = raw['distance'];
    if (distanceRaw is num) {
      distKm = double.parse((distanceRaw / 1000.0).toStringAsFixed(1));
    }

    // Brand extraction: goriva.si's `name` is the display label
    // ("PETROL LJUBLJANA - TIVOLSKA"). The first whitespace-delimited
    // token is the corporate brand (Petrol, MOL, Shell, OMV, ...) which
    // is what other services expose as `brand`. We title-case it for
    // consistency with other country services.
    final brand = _extractBrand(name);

    return Station(
      id: 'si-$pk',
      name: name.isEmpty ? brand : name,
      brand: brand,
      street: address,
      postCode: zipCode,
      place: '',
      lat: lat,
      lng: lng,
      dist: distKm,
      e5: nmb95,
      e10: nmb95, // Slovenia ships a single 95-octane grade; surface as both
      e98: nmb100 ?? nmb98,
      diesel: dizel,
      dieselPremium: dizelPremium,
      lpg: lpg,
      cng: cng,
      isOpen: true, // the API doesn't expose open/closed state reliably
    );
  }

  /// Convert one entry of the `prices` map into a double or null.
  ///
  /// goriva.si stores missing prices as JSON `null` and present prices
  /// as numeric EUR-per-litre values. Anything else (empty string, bad
  /// number) is treated as missing.
  double? _priceFor(Map prices, String key) {
    final v = prices[key];
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  /// Best-effort brand extraction from a goriva.si display name.
  ///
  /// Examples:
  /// - "PETROL LJUBLJANA - TIVOLSKA" → "Petrol"
  /// - "MOL BRESTOVICA"              → "MOL"
  /// - "OMV Celje"                   → "OMV"
  /// - "Tankomat Grosuplje"          → "Tankomat"
  String _extractBrand(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    // First whitespace-delimited token. Keep well-known all-caps acronyms
    // (MOL, OMV) in upper case; title-case everything else.
    final token = trimmed.split(RegExp(r'\s+')).first;
    if (token.length <= 3 && token == token.toUpperCase()) return token;
    return '${token[0].toUpperCase()}${token.substring(1).toLowerCase()}';
  }

  @override
  Future<ServiceResult<StationDetail>> getStationDetail(String stationId) async {
    // goriva.si does not expose a per-station detail endpoint with
    // opening hours / services beyond what the search already returns,
    // so we degrade gracefully like the Denmark / Portugal services.
    throwDetailUnavailable('goriva.si');
  }

  @override
  Future<ServiceResult<Map<String, StationPrices>>> getPrices(
    List<String> ids,
  ) async {
    // No batch price refresh — favourites refresh falls back to
    // re-running searchStations, which is cheap because goriva.si
    // already paginates at ~30 stations per page.
    return emptyPricesResult(ServiceSource.sloveniaApi);
  }
}
