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
import 'greece_parsers.dart' as parser;

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
/// Fuel-type mapping used by [parser.fuelForObservatoryKey]:
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
///
/// **Split (#563)**: the JSON parsing + per-prefecture → [Station]
/// mapping, the fuel-key map, and the prefecture catalog all live in
/// `greece_parsers.dart` so they can be tested as pure functions
/// without Dio. This shell keeps only the [StationService]
/// implementation: HTTP via Dio, [ServiceResult] plumbing, and error
/// classification.
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

  /// Keys the parser deliberately drops because no [FuelType] exists.
  /// Re-exported from the parser for tests that pin the MVP policy
  /// without crossing into the parser's namespace.
  static const Set<String> droppedObservatoryKeys =
      parser.droppedObservatoryKeys;

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
        final s = parser.parsePrefectureResponse(
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
  /// [Station]. Thin delegate over [parser.parsePrefectureResponse];
  /// kept on the service so existing tests + any external callers
  /// continue to work after the #563 split.
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
  }) =>
      parser.parsePrefectureResponse(
        data,
        stationId: stationId,
        displayName: displayName,
        place: place,
        prefectureLat: prefectureLat,
        prefectureLng: prefectureLng,
        fromLat: fromLat,
        fromLng: fromLng,
      );

  /// Single source of truth for the observatory fuel-key → [FuelType]
  /// mapping. Delegates to the parser; kept on the service for legacy
  /// callers that import [GreeceStationService] directly.
  @visibleForTesting
  static FuelType? fuelForObservatoryKey(String key) =>
      parser.fuelForObservatoryKey(key);

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
  List<parser.GreekPrefecture> _prefecturesForQuery(SearchParams params) {
    final ordered = List<parser.GreekPrefecture>.from(parser.greekPrefectures)
      ..sort((a, b) {
        final da = roundedDistance(params.lat, params.lng, a.lat, a.lng);
        final db = roundedDistance(params.lat, params.lng, b.lat, b.lng);
        return da.compareTo(db);
      });
    // Fetch the four closest prefectures. Covers the mainland /
    // island cases without making 8 serial HTTP calls per search.
    return ordered.take(4).toList();
  }
}
