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

/// Romania fuel prices — *Monitorul Prețurilor la Carburanți*
/// (pretcarburant.ro), the Competition Council + ANPC joint
/// government-mandated observatory (#577).
///
/// Romanian law requires every fuel retailer to push up-to-date
/// pump prices to the national observatory at least every 15 minutes.
/// The consumer-facing frontend at `pretcarburant.ro/en/map` renders
/// ~1 500 stations nationwide (Petrom / OMV / Rompetrol / MOL / Lukoil
/// / Socar / …) but does **not** expose a documented public API —
/// the map page fetches its station feed via an internal XHR whose
/// URL and shape are not contractually stable.
///
/// We follow the same fixture-driven strategy Greece (#576) uses:
/// the parser is fully implemented against a hand-crafted fixture
/// mirroring the shape the site appears to return, and the actual
/// endpoint is a best-guess constant. If / when the real URL or
/// shape drifts, fixing this service is a one-line change — the
/// parser is already battle-tested.
///
/// **Expected endpoint contract** (best guess — verify with browser
/// devtools before wiring to a live feed):
///
/// ```
/// GET https://pretcarburant.ro/api/stations
/// ```
///
/// returns a list of station objects:
///
/// ```json
/// [
///   {
///     "id": "PETROM-00123",
///     "brand": "Petrom",
///     "name": "Petrom Bucuresti Pipera",
///     "address": "Str. Dimitrie Pompeiu 1A",
///     "postal_code": "020335",
///     "city": "București",
///     "county": "București",
///     "lat": 44.478,
///     "lng": 26.115,
///     "is_open": true,
///     "updated_at": "2026-04-22T10:30:00Z",
///     "prices": {
///       "benzina_standard": 7.25,
///       "benzina_premium": 7.89,
///       "motorina_standard": 7.45,
///       "motorina_premium": 7.95,
///       "gpl": 3.85
///     }
///   }
/// ]
/// ```
///
/// Fuel-type mapping used by [_fuelForObservatoryKey]:
///
/// ```
/// benzina_standard   → FuelType.e5
/// benzina_premium    → FuelType.e98
/// motorina_standard  → FuelType.diesel
/// motorina_premium   → FuelType.dieselPremium
/// gpl                → FuelType.lpg
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
  /// Default base URL. The actual XHR endpoint is not documented;
  /// override via the constructor's `baseUrl` argument without
  /// changing the parser when the real URL is confirmed.
  static const String defaultBaseUrl = 'https://pretcarburant.ro';

  /// Path segment appended to [_baseUrl] for the stations listing.
  /// Kept as a separate constant so tests can point at
  /// `https://test/api/stations` and still exercise the parser.
  static const String stationsPath = '/api/stations';

  /// Respectful scraping contact header — the upstream maintainers
  /// can reach out via this URL if Tankstellen's usage is
  /// problematic.
  static const String userAgent =
      'Tankstellen/5.0 (fuel price comparison) contact: github.com/fdittgen/tankstellen';

  /// Observatory fuel-key → canonical [FuelType]. Kept lowercase so
  /// the lookup is case-insensitive against upstream drift.
  static const Map<String, FuelType> _fuelForObservatoryKey = {
    'benzina_standard': FuelType.e5,
    'benzina_premium': FuelType.e98,
    'motorina_standard': FuelType.diesel,
    'motorina_premium': FuelType.dieselPremium,
    'gpl': FuelType.lpg,
  };

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
    // instance makes. The default UA from [DioFactory] is generic —
    // for a scraped feed we want a contactable identifier.
    _dio.options.headers['User-Agent'] = userAgent;
  }

  @override
  Future<ServiceResult<List<Station>>> searchStations(
    SearchParams params, {
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get(
        '$_baseUrl$stationsPath',
        cancelToken: cancelToken,
      );
      final stations = parseStationsResponse(
        response.data,
        fromLat: params.lat,
        fromLng: params.lng,
      );

      final filtered = filterByRadius(stations, params.radiusKm);
      sortStations(filtered, params);

      return ServiceResult(
        data: filtered,
        source: ServiceSource.romaniaApi,
        fetchedAt: DateTime.now(),
      );
    } on DioException catch (e, st) {
      debugPrint('RO Monitorul fetch failed: $e\n$st');
      final status = e.response?.statusCode;
      throw ApiException(
        message:
            'Monitorul Prețurilor unreachable (${e.type.name})'
            '${status != null ? ' [HTTP $status]' : ''}',
        statusCode: status,
      );
    } on ApiException {
      rethrow;
    } catch (e, st) {
      debugPrint('RO Monitorul unexpected error: $e\n$st');
      throw ApiException(message: 'Monitorul Prețurilor parse error: $e');
    }
  }

  /// Parse a stations-listing response into [Station] objects.
  /// Exposed for tests so the parser is driven by fixtures
  /// independent of any Dio mock.
  ///
  /// Every station gets the `ro-` prefix so the favorites /
  /// currency-lookup layer can route it to the RO config by id
  /// alone (see #514).
  @visibleForTesting
  List<Station> parseStationsResponse(
    dynamic data, {
    required double fromLat,
    required double fromLng,
  }) {
    final list = _coerceList(data);
    if (list == null) {
      throw const ApiException(
        message: 'Monitorul Prețurilor returned unparseable body',
      );
    }

    final out = <Station>[];
    for (final raw in list) {
      if (raw is! Map) continue;
      final station = _parseStation(raw, fromLat: fromLat, fromLng: fromLng);
      if (station != null) out.add(station);
    }
    return out;
  }

  /// Exposed for tests — single source of truth for the observatory
  /// fuel-key → [FuelType] mapping.
  @visibleForTesting
  static FuelType? fuelForObservatoryKey(String key) =>
      _fuelForObservatoryKey[key.toLowerCase()];

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

  // ──────────────────────────────────────────────────────────────────────
  // Helpers
  // ──────────────────────────────────────────────────────────────────────

  Station? _parseStation(
    Map raw, {
    required double fromLat,
    required double fromLng,
  }) {
    final rawId = raw['id']?.toString();
    if (rawId == null || rawId.isEmpty) return null;

    final lat = _parseDouble(raw['lat']);
    final lng = _parseDouble(raw['lng']);
    if (lat == null || lng == null) return null;

    final prices = _parsePrices(raw['prices']);
    // Drop stations that advertise no recognised motoring fuel —
    // nothing actionable to show the user.
    if (prices.isEmpty) return null;

    final id = rawId.startsWith('ro-') ? rawId : 'ro-$rawId';

    return Station(
      id: id,
      name: raw['name']?.toString() ?? raw['brand']?.toString() ?? 'Stație',
      brand: raw['brand']?.toString() ?? '',
      street: raw['address']?.toString() ?? '',
      postCode: raw['postal_code']?.toString() ?? '',
      place: raw['city']?.toString() ?? raw['county']?.toString() ?? '',
      lat: lat,
      lng: lng,
      dist: roundedDistance(fromLat, fromLng, lat, lng),
      e5: prices[FuelType.e5],
      e98: prices[FuelType.e98],
      diesel: prices[FuelType.diesel],
      dieselPremium: prices[FuelType.dieselPremium],
      lpg: prices[FuelType.lpg],
      isOpen: raw['is_open'] is bool ? raw['is_open'] as bool : true,
      updatedAt: raw['updated_at']?.toString(),
    );
  }

  Map<FuelType, double> _parsePrices(dynamic rawPrices) {
    final out = <FuelType, double>{};
    if (rawPrices is! Map) return out;
    for (final entry in rawPrices.entries) {
      final key = entry.key.toString();
      final fuel = _fuelForObservatoryKey[key.toLowerCase()];
      if (fuel == null) continue; // unknown / intentionally dropped
      final price = _parseLeiPerLitre(entry.value);
      if (price == null) continue;
      out[fuel] = price;
    }
    return out;
  }

  /// Romanian pump prices are RON (lei) per litre with up to three
  /// decimals (e.g. `7.259`). Accepts `num` and numeric strings.
  /// Rejects zero and negative values.
  double? _parseLeiPerLitre(dynamic raw) {
    if (raw == null) return null;
    if (raw is num) {
      if (raw <= 0) return null;
      return raw.toDouble();
    }
    if (raw is String) {
      final t = raw.trim();
      if (t.isEmpty) return null;
      final v = double.tryParse(t);
      if (v == null || v <= 0) return null;
      return v;
    }
    return null;
  }

  double? _parseDouble(dynamic raw) {
    if (raw == null) return null;
    if (raw is num) return raw.toDouble();
    if (raw is String) return double.tryParse(raw.trim());
    return null;
  }

  List? _coerceList(dynamic data) {
    if (data is List) return data;
    return null;
  }
}
