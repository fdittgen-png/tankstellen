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

/// Greece fuel prices — Paratiritirio Timon (Fuel Price Observatory) via the
/// community [fuelpricesgr](https://github.com/mavroprovato/fuelpricesgr)
/// FastAPI wrapper (#576).
///
/// Greece's government-run *Paratiritirio Timon Υγρών Καυσίμων* publishes
/// mandatory daily / weekly fuel price data, but only as brittle PDFs on
/// `catalog.data.gov.gr`. The community wrapper parses those PDFs into a
/// well-formed JSON API with no authentication.
///
/// **Crucial caveat**: unlike CNE (Chile) or OPINET (Korea), the Greek
/// feed is **not station-level** — the finest granularity published by
/// the Observatory (and therefore by the community API) is the
/// *prefecture* (νομός). Greek law requires each station to print its
/// prices on public-facing boards but there is no central per-station
/// registry open to the public.
///
/// We model this the same way [LuxembourgStationService] models its
/// uniform regulated prices: one synthetic "virtual station" per
/// representative prefecture, stamped with that prefecture's latest
/// daily mean price. The user sees a short list of `gr-attica`,
/// `gr-thessaloniki`, ... entries around the Greek mainland / islands,
/// each showing the prefecture-level average. For a pay-less-at-the-pump
/// decision this is not as sharp as a station-level feed, but it at
/// least surfaces regional variance (Attica vs. Thrace vs. Crete, which
/// can differ by 10–15 cents/L) and keeps the app usable in Greece
/// until — or unless — a station-level feed becomes available.
///
/// **Endpoint contract** (community API defaults to `https://fuelpricesgr.com/api/`):
///
/// ```
/// GET /data/daily/prefecture/{prefecture}
/// ```
///
/// returns the prefecture's most recent daily price points:
///
/// ```json
/// [
///   {
///     "date": "2026-04-21",
///     "data": [
///       { "fuel_type": "UNLEADED_95",  "price": 1.721 },
///       { "fuel_type": "UNLEADED_100", "price": 1.969 },
///       { "fuel_type": "DIESEL",       "price": 1.528 },
///       { "fuel_type": "DIESEL_HEATING", "price": 1.165 },
///       { "fuel_type": "GAS",          "price": 0.978 }
///     ]
///   }
/// ]
/// ```
///
/// Fuel-type mapping used by [_fuelForObservatoryKey]:
///
/// ```
/// UNLEADED_95      → FuelType.e5
/// UNLEADED_100     → FuelType.e98
/// DIESEL           → FuelType.diesel
/// DIESEL_HEATING   → (skipped — not a motoring fuel)
/// GAS              → FuelType.lpg    (Υγραέριο)
/// SUPER            → (skipped — leaded; phased out)
/// ```
///
/// No auth, no keys — the community API is free and open. The service
/// still round-trips the user's `_baseUrl` so operators can point
/// Tankstellen at a self-hosted mirror if the hosted endpoint goes
/// down; and the parser is fully fixture-driven so a URL-path drift at
/// upstream is a one-line fix.
class GreeceStationService
    with StationServiceHelpers
    implements StationService {
  /// Community API base URL. The upstream project documents that it
  /// runs at `http://localhost:8000/api` locally; a hosted mirror is
  /// commonly available at `https://fuelpricesgr.com/api/` (or a
  /// user-operated mirror). The exact hosted URL is a moving target
  /// between releases of the upstream project — if the hosted endpoint
  /// drifts, override via the constructor's `baseUrl` argument without
  /// changing the parser.
  static const String defaultBaseUrl = 'https://fuelpricesgr.com/api';

  /// Observatory fuel_type enum → canonical [FuelType].
  ///
  /// `DIESEL_HEATING` and `SUPER` are intentionally absent from the
  /// map. [droppedObservatoryKeys] pins the policy for tests.
  static const Map<String, FuelType> _fuelForObservatoryKey = {
    'unleaded_95': FuelType.e5,
    'unleaded_100': FuelType.e98,
    'diesel': FuelType.diesel,
    'gas': FuelType.lpg,
  };

  /// Keys the parser deliberately drops because no [FuelType] exists
  /// (DIESEL_HEATING is not a motoring fuel; SUPER is phased-out
  /// leaded).
  static const Set<String> droppedObservatoryKeys = {
    'diesel_heating',
    'super',
  };

  /// Representative prefectures used as virtual stations. Coordinates
  /// are each prefecture's capital (OpenStreetMap). The set is
  /// deliberately small and geographically spread so a user searching
  /// from anywhere in Greece hits at least one entry within a
  /// sensible radius, without flooding the map with 50+ synthetic
  /// pins.
  static const List<_GreekPrefecture> _prefectures = [
    _GreekPrefecture(
      apiName: 'ATTICA',
      id: 'gr-attica',
      displayName: 'Αττική / Attica',
      place: 'Αθήνα',
      lat: 37.9838,
      lng: 23.7275,
    ),
    _GreekPrefecture(
      apiName: 'THESSALONIKI',
      id: 'gr-thessaloniki',
      displayName: 'Θεσσαλονίκη / Thessaloniki',
      place: 'Θεσσαλονίκη',
      lat: 40.6401,
      lng: 22.9444,
    ),
    _GreekPrefecture(
      apiName: 'ACHAEA',
      id: 'gr-achaea',
      displayName: 'Αχαΐα / Achaea',
      place: 'Πάτρα',
      lat: 38.2466,
      lng: 21.7346,
    ),
    _GreekPrefecture(
      apiName: 'LARISSA',
      id: 'gr-larissa',
      displayName: 'Λάρισα / Larissa',
      place: 'Λάρισα',
      lat: 39.6390,
      lng: 22.4191,
    ),
    _GreekPrefecture(
      apiName: 'HERAKLION',
      id: 'gr-heraklion',
      displayName: 'Ηράκλειο / Heraklion',
      place: 'Ηράκλειο',
      lat: 35.3387,
      lng: 25.1442,
    ),
    _GreekPrefecture(
      apiName: 'IOANNINA',
      id: 'gr-ioannina',
      displayName: 'Ιωάννινα / Ioannina',
      place: 'Ιωάννινα',
      lat: 39.6650,
      lng: 20.8537,
    ),
    _GreekPrefecture(
      apiName: 'DODECANESE',
      id: 'gr-dodecanese',
      displayName: 'Δωδεκάνησα / Dodecanese',
      place: 'Ρόδος',
      lat: 36.4349,
      lng: 28.2176,
    ),
    _GreekPrefecture(
      apiName: 'CHANIA',
      id: 'gr-chania',
      displayName: 'Χανιά / Chania',
      place: 'Χανιά',
      lat: 35.5138,
      lng: 24.0180,
    ),
  ];

  final Dio _dio;
  final String _baseUrl;

  GreeceStationService({
    Dio? dio,
    String? baseUrl,
  })  : _dio = dio ??
            DioFactory.create(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 20),
            ),
        _baseUrl = baseUrl ?? defaultBaseUrl;

  @override
  Future<ServiceResult<List<Station>>> searchStations(
    SearchParams params, {
    CancelToken? cancelToken,
  }) async {
    // Pull the user's nearest prefectures first — a radius-based
    // pre-filter so we don't slam the upstream with 8 serial requests
    // when the user is standing in Athens and the answer is `ATTICA`.
    final candidates = _prefecturesForQuery(params);

    final stations = <Station>[];
    final errors = <ServiceError>[];

    for (final pref in candidates) {
      try {
        final response = await _dio.get(
          '$_baseUrl/data/daily/prefecture/${pref.apiName}',
          cancelToken: cancelToken,
        );
        final s = parsePrefectureResponse(
          response.data,
          stationId: pref.id,
          displayName: pref.displayName,
          place: pref.place,
          prefectureLat: pref.lat,
          prefectureLng: pref.lng,
          fromLat: params.lat,
          fromLng: params.lng,
        );
        if (s != null) stations.add(s);
      } on DioException catch (e) {
        debugPrint('GR daily fetch failed for ${pref.apiName}: $e');
        final status = e.response?.statusCode;
        if (status == 401 || status == 403) {
          // The community API is free and anonymous — a 401/403 means
          // the operator has proxied it behind auth. Surface as a hard
          // error so the fallback chain can log it.
          throw ApiException(
            message: 'Paratiritirio rejected request (HTTP $status)',
            statusCode: status,
          );
        }
        errors.add(ServiceError(
          source: ServiceSource.greeceApi,
          message: 'fetch ${pref.apiName}: ${e.type.name}',
          statusCode: status,
          occurredAt: DateTime.now(),
        ));
      } catch (e) {
        debugPrint('GR daily fetch unexpected error for ${pref.apiName}: $e');
        errors.add(ServiceError(
          source: ServiceSource.greeceApi,
          message: 'parse ${pref.apiName}: $e',
          occurredAt: DateTime.now(),
        ));
      }
    }

    // If every prefecture request failed hard, surface an ApiException
    // so the chain drops to stale cache.
    if (stations.isEmpty && candidates.isNotEmpty && errors.isNotEmpty) {
      throw ApiException(
        message:
            'Paratiritirio unreachable (${errors.length}/${candidates.length} '
            'prefectures failed)',
      );
    }

    final filtered = filterByRadius(stations, params.radiusKm);
    sortStations(filtered, params);

    return ServiceResult(
      data: filtered,
      source: ServiceSource.greeceApi,
      fetchedAt: DateTime.now(),
      errors: errors,
    );
  }

  /// Parse a single prefecture's daily response into a synthetic
  /// [Station]. Exposed for tests so the parser is driven by fixtures
  /// independent of any Dio mock.
  ///
  /// The response is either:
  /// - A list of `PriceResponse` objects (most recent first), or
  /// - An empty list when the prefecture has no recent data.
  ///
  /// We pick the most recent entry (first in the list) and stamp its
  /// fuel prices onto the virtual station.
  ///
  /// The prefecture is addressed by its stable `stationId` so tests do
  /// not need access to the private `_GreekPrefecture` class.
  @visibleForTesting
  Station? parsePrefectureResponse(
    dynamic data, {
    required String stationId,
    required String displayName,
    required String place,
    required double prefectureLat,
    required double prefectureLng,
    required double fromLat,
    required double fromLng,
  }) {
    final list = _coerceList(data);
    if (list == null) {
      throw const ApiException(
        message: 'Paratiritirio returned unparseable body',
      );
    }

    // Empty list is valid — just means no recent data for this
    // prefecture. Drop the station (a synthetic entry with no prices
    // would clutter the list).
    if (list.isEmpty) return null;

    // Prefer the newest entry. The community API documents "most recent
    // first" but we defend against order drift by picking the entry with
    // the greatest `date` string (ISO-8601 lexicographic order works).
    Map? newest;
    String newestDate = '';
    for (final item in list) {
      if (item is! Map) continue;
      final date = item['date']?.toString() ?? '';
      if (date.compareTo(newestDate) > 0) {
        newestDate = date;
        newest = item;
      }
    }
    if (newest == null) return null;

    final prices = _parsePrices(newest['data']);
    // A prefecture with zero recognised fuel rows is dropped — no
    // synthetic pin for "nothing to show".
    if (prices.isEmpty) return null;

    return Station(
      id: stationId,
      name: displayName,
      brand: 'Paratiritirio',
      street: '',
      postCode: '',
      place: place,
      lat: prefectureLat,
      lng: prefectureLng,
      dist: roundedDistance(fromLat, fromLng, prefectureLat, prefectureLng),
      e5: prices[FuelType.e5],
      e98: prices[FuelType.e98],
      diesel: prices[FuelType.diesel],
      lpg: prices[FuelType.lpg],
      isOpen: true,
      updatedAt: newestDate.isEmpty ? null : newestDate,
    );
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
    throwDetailUnavailable('Paratiritirio Timon');
  }

  @override
  Future<ServiceResult<Map<String, StationPrices>>> getPrices(
    List<String> ids,
  ) async {
    return emptyPricesResult(ServiceSource.greeceApi);
  }

  // ──────────────────────────────────────────────────────────────────────
  // Helpers
  // ──────────────────────────────────────────────────────────────────────

  /// Order the prefectures so the nearest ones come first. Keeps us
  /// from fanning out to the entire country when the user is standing
  /// in one prefecture.
  List<_GreekPrefecture> _prefecturesForQuery(SearchParams params) {
    final ordered = List<_GreekPrefecture>.from(_prefectures)
      ..sort((a, b) {
        final da = roundedDistance(params.lat, params.lng, a.lat, a.lng);
        final db = roundedDistance(params.lat, params.lng, b.lat, b.lng);
        return da.compareTo(db);
      });
    // Fetch the four closest prefectures. Covers the mainland /
    // island cases without making 8 serial HTTP calls per search.
    return ordered.take(4).toList();
  }

  Map<FuelType, double> _parsePrices(dynamic rawData) {
    final out = <FuelType, double>{};
    if (rawData is! List) return out;
    for (final row in rawData) {
      if (row is! Map) continue;
      final key = row['fuel_type']?.toString() ?? '';
      if (key.isEmpty) continue;
      final fuel = _fuelForObservatoryKey[key.toLowerCase()];
      if (fuel == null) continue; // unknown / intentionally dropped
      final price = _parseEuroPerLitre(row['price']);
      if (price == null) continue;
      out[fuel] = price;
    }
    return out;
  }

  /// Observatory prices are EUR per litre with up to three decimals
  /// (e.g. `1.721`). Accepts `num` and numeric strings. Rejects zero
  /// and negative values.
  double? _parseEuroPerLitre(dynamic raw) {
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

  List? _coerceList(dynamic data) {
    if (data is List) return data;
    return null;
  }
}

/// Internal representation of a Greek prefecture used as a virtual
/// station. Kept private — callers only ever see fully-built
/// [Station] objects.
class _GreekPrefecture {
  final String apiName;
  final String id;
  final String displayName;
  final String place;
  final double lat;
  final double lng;

  const _GreekPrefecture({
    required this.apiName,
    required this.id,
    required this.displayName,
    required this.place,
    required this.lat,
    required this.lng,
  });
}
