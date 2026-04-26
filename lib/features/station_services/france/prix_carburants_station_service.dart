import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../search/data/models/search_params.dart';
import '../../search/domain/entities/station.dart';
import '../../../core/services/impl/osm_brand_enricher.dart';
import 'prix_carburants_parsers.dart' as parser;
import '../../../core/services/dio_factory.dart';
import '../../../core/services/mixins/station_service_helpers.dart';
import '../../../core/services/service_result.dart';
import '../../../core/services/station_service.dart';

/// Real French fuel price data from Prix-Carburants (gouv.fr).
/// Free, no API key, no registration. Updated every 10 minutes.
///
/// Strategy: when a postal code is provided, query the native CP filter
/// first (100% accurate), then fall back to geo. For GPS searches without
/// a postal code, query by geo (within_distance) directly.
///
/// **Split (#563)**: the JSON parsing + record → [Station] mapping,
/// brand detection, and small string-shape coercions all live in
/// `prix_carburants_parsers.dart` so they can be tested as pure
/// functions without Dio. This shell keeps only the [StationService]
/// implementation: HTTP via Dio, [ServiceResult] plumbing, dedupe, and
/// post-fetch radius filtering.
class PrixCarburantsStationService with StationServiceHelpers implements StationService {
  final OsmBrandEnricher? _enricher;
  final Dio _dio;

  PrixCarburantsStationService({OsmBrandEnricher? enricher, Dio? dio})
      : _enricher = enricher,
        _dio = dio ?? DioFactory.create(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        );

  static const _baseUrl =
      'https://data.economie.gouv.fr/api/explore/v2.1/catalog/datasets'
      '/prix-des-carburants-en-france-flux-instantane-v2/records';

  @override
  Future<ServiceResult<List<Station>>> searchStations(
    SearchParams params, {
    CancelToken? cancelToken,
  }) async {
    List<Map<String, dynamic>> allResults = [];

    final hasPostalCode = params.postalCode != null && params.postalCode!.isNotEmpty;
    final hasValidCoords = params.lat != 0 && params.lng != 0;

    if (hasPostalCode) {
      // Postal code search strategy:
      // 1. Run the native CP filter first — fast, 100% accurate for the
      //    target postal code, and returns stations even when geocoding
      //    is unreliable (e.g., Paris arrondissements).
      // 2. ALSO run the geo query when valid coordinates are present, so
      //    that neighboring postal codes are included when the user picks
      //    a wider radius. Without this, a GPS search from a rural village
      //    (which auto-attaches its postal code via reverse geocoding) would
      //    cap results at the village's own ~5 stations regardless of
      //    radius — bug #315.
      // 3. Merge and dedupe by station id.
      final cpResults = await _queryByPostalCode(params.postalCode!, cancelToken: cancelToken);

      if (hasValidCoords) {
        final geoResults = await _queryByGeo(params.lat, params.lng, params.radiusKm, cancelToken: cancelToken);
        allResults = _mergeById(cpResults, geoResults);
      } else {
        allResults = cpResults;
      }

      // Final fallback: if both queries returned nothing (e.g., invalid CP
      // and no coordinates), give up gracefully.
      if (allResults.isEmpty && !hasValidCoords) {
        allResults = const [];
      }
    } else {
      // GPS / coordinate search: geo query is the only option
      allResults = await _queryByGeo(params.lat, params.lng, params.radiusKm, cancelToken: cancelToken);
    }

    // Parse all results into Station objects
    final parsed = <Station>[];
    for (final r in allResults) {
      final station = parser.parsePrixCarburantsStation(r, params.lat, params.lng);
      if (station != null) parsed.add(station);
    }

    // Filter by radius. The postal-code query (`cp='...'`) returns every
    // station sharing that code regardless of distance, so without this
    // post-filter the `radiusKm` parameter would be silently ignored on
    // the CP path — bug #298.
    final stations = filterByRadius(parsed, params.radiusKm);

    // Sort
    sortStations(stations, params);

    if (stations.isEmpty) {
      // Return empty result instead of throwing — route searches
      // query many sample points and empty results at rural points
      // are expected, not errors.
      return ServiceResult(
        data: const [],
        source: ServiceSource.prixCarburantsApi,
        fetchedAt: DateTime.now(),
      );
    }

    // Enrich with brand names from OpenStreetMap (best-effort)
    final enriched = _enricher != null
        ? await _enricher.enrich(stations, cancelToken: cancelToken)
        : stations;

    return ServiceResult(
      data: enriched,
      source: ServiceSource.prixCarburantsApi,
      fetchedAt: DateTime.now(),
    );
  }

  Future<List<Map<String, dynamic>>> _queryByPostalCode(String cp, {CancelToken? cancelToken}) async {
    try {
      final response = await _dio.get(_baseUrl, queryParameters: {
        'where': "cp='$cp'",
        'limit': 50,
      }, cancelToken: cancelToken);
      return parser.extractPrixCarburantsResults(response.data);
    } on DioException catch (e, st) {
      debugPrint('Prix-Carburants ZIP fetch failed: $e\n$st');
      return [];
    }
  }


  Future<List<Map<String, dynamic>>> _queryByGeo(
    double lat, double lng, double radiusKm, {CancelToken? cancelToken}
  ) async {
    // Use within_distance with km unit — the distance() function with meters
    // is unreliable on this API and often returns 0 results. Preserve one
    // decimal of precision so sub-km radius selections aren't silently
    // rounded to the nearest integer.
    final radiusStr = radiusKm.toStringAsFixed(1);
    try {
      final response = await _dio.get(_baseUrl, queryParameters: {
        'where':
            "within_distance(geom,geom'POINT($lng $lat)',${radiusStr}km)",
        'limit': 50,
      }, cancelToken: cancelToken);
      return parser.extractPrixCarburantsResults(response.data);
    } on DioException catch (e, st) {
      debugPrint('Prix-Carburants geo fetch failed: $e\n$st');
      return [];
    }
  }

  /// Merge two raw API result lists, deduplicating by station id.
  /// Stations from [primary] win when an id collides.
  List<Map<String, dynamic>> _mergeById(
    List<Map<String, dynamic>> primary,
    List<Map<String, dynamic>> secondary,
  ) {
    final seen = <String>{};
    final merged = <Map<String, dynamic>>[];
    for (final r in primary) {
      final id = r['id']?.toString() ?? '';
      if (id.isNotEmpty && seen.add(id)) {
        merged.add(r);
      } else if (id.isEmpty) {
        merged.add(r);
      }
    }
    for (final r in secondary) {
      final id = r['id']?.toString() ?? '';
      if (id.isNotEmpty && seen.add(id)) {
        merged.add(r);
      } else if (id.isEmpty) {
        merged.add(r);
      }
    }
    return merged;
  }

  @override
  Future<ServiceResult<StationDetail>> getStationDetail(
    String stationId,
  ) async {
    final response = await _dio.get(_baseUrl, queryParameters: {
      'where': 'id=$stationId',
      'limit': 1,
    });

    final results = parser.extractPrixCarburantsResults(response.data);
    if (results.isEmpty) throw Exception('Station $stationId not found');

    final r = results[0];
    final station = parser.parsePrixCarburantsStation(r, 0, 0);
    if (station == null) throw Exception('Failed to parse station');

    final is24h = r['horaires_automate_24_24'] == 'Oui';

    return ServiceResult(
      data: StationDetail(station: station, wholeDay: is24h),
      source: ServiceSource.prixCarburantsApi,
      fetchedAt: DateTime.now(),
    );
  }

  @override
  Future<ServiceResult<Map<String, StationPrices>>> getPrices(
    List<String> ids,
  ) async {
    final prices = <String, StationPrices>{};
    for (final id in ids.take(10)) {
      try {
        final response = await _dio.get(_baseUrl, queryParameters: {
          'where': 'id=$id',
          'limit': 1,
        });
        final results = parser.extractPrixCarburantsResults(response.data);
        if (results.isNotEmpty) {
          final r = results[0];
          prices[id] = StationPrices(
            e5: _toDouble(r['sp95_prix']),
            e10: _toDouble(r['e10_prix']),
            diesel: _toDouble(r['gazole_prix']),
            status: 'open',
          );
        }
      } on DioException catch (e, st) { debugPrint('Prix-Carburants detail fetch failed: $e\n$st'); }
    }
    return ServiceResult(
      data: prices,
      source: ServiceSource.prixCarburantsApi,
      fetchedAt: DateTime.now(),
    );
  }

  /// Local copy of the `_toDouble` coercion. Used only by [getPrices]
  /// where we map raw record fields directly into [StationPrices]
  /// without going through the full [parser.parsePrixCarburantsStation]
  /// path. Kept here to avoid widening the parser module's surface for
  /// a one-line helper.
  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }
}
