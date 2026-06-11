// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/domain/search_params.dart';
import '../../../core/domain/station.dart';
import '../../../core/error/exceptions.dart';
import '../../../core/services/impl/osm_brand_enricher.dart';
import 'france_opening_hours_adapter.dart';
import 'prix_carburants_parsers.dart' as parser;
import '../../../core/network/dio_offline.dart';
import '../../../core/telemetry/collectors/breadcrumb_collector.dart';
import '../../../core/services/dio_factory.dart';
import '../../../core/services/mixins/station_service_helpers.dart';
import '../../../core/services/service_result.dart';
import '../../../core/services/station_service.dart';
import '../../../core/logging/error_logger.dart';

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
  final String _baseUrl;

  PrixCarburantsStationService({
    OsmBrandEnricher? enricher,
    Dio? dio,
    String? baseUrl,
  })  : _enricher = enricher,
        _dio = dio ?? DioFactory.create(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
        _baseUrl = baseUrl ?? defaultBaseUrl;

  static const String defaultBaseUrl =
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
      final response = await _dio.get<dynamic>(_baseUrl, queryParameters: {
        'where': "cp='$cp'",
        'limit': 50,
      }, cancelToken: cancelToken);
      return parser.extractPrixCarburantsResults(response.data);
    } on DioException catch (e, st) {
      // #2524 — an OFFLINE failure (no network) is expected and already
      // handled (returns []), so it must NOT pollute the user error spool.
      // Drop it to a debugPrint; only a real API error (4xx/5xx, malformed
      // response) is worth an ERROR trace.
      if (_isOffline(e)) {
        debugPrint('Prix-Carburants ZIP fetch skipped — offline ($e)');
        return [];
      }
      unawaited(errorLogger.log(ErrorLayer.other, e, st, context: const {'where': 'Prix-Carburants ZIP fetch failed'}));
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
    // #2966 — order the corridor server-side by distance so the `limit: 50`
    // slice keeps the NEAREST 50, not an arbitrary 50. Without it a dense
    // corridor (e.g. 140 stations within 10 km of central Paris) returns an
    // un-distance-ordered subset and the genuinely-nearest forecourt can be
    // truncated out entirely — the server-side root cause behind the radar /
    // closeness / in-trip "missing nearest station" symptoms (deferred #2813
    // dense case; #2806 / #2965 in-radius merges become belt-and-braces). The
    // old `distance()` "0 results" note was the metres form; the validated v2.1
    // ODSQL `order_by=distance(geom,geom'POINT(lon lat)')` form (lon-lat order)
    // is accepted live and returns rows nearest-first — it changes only the
    // ordering / cap survival, never which stations are in-radius (still gated
    // by the unchanged `within_distance` filter).
    final point = "geom'POINT($lng $lat)'";
    try {
      final response = await _dio.get<dynamic>(_baseUrl, queryParameters: {
        'where': 'within_distance(geom,$point,${radiusStr}km)',
        'order_by': 'distance(geom,$point)',
        'limit': 50,
      }, cancelToken: cancelToken);
      return parser.extractPrixCarburantsResults(response.data);
    } on DioException catch (e, st) {
      // #2524 — see [_queryByPostalCode]: an offline failure is expected and
      // swallowed (returns []); only a real API error gets an ERROR trace.
      if (_isOffline(e)) {
        // #2745 — the field trace #1 was a `DioException[unknown]` wrapping
        // an `HttpException('Software caused connection abort')` from
        // data.economie.gouv.fr while the device was offline. Drop it to a
        // diagnostic breadcrumb (still triageable from any surviving trace)
        // instead of an ERROR — it is an expected no-network condition.
        BreadcrumbCollector.add(
          'Prix-Carburants geo fetch skipped — offline',
          detail: 'lat=$lat lng=$lng type=${e.type}',
        );
        debugPrint('Prix-Carburants geo fetch skipped — offline ($e)');
        return [];
      }
      unawaited(errorLogger.log(ErrorLayer.other, e, st, context: const {'where': 'Prix-Carburants geo fetch failed'}));
      return [];
    }
  }

  /// Whether [e] is an offline / no-network failure rather than a real
  /// API error (#2524). Delegates to the shared [isOfflineError] classifier
  /// (#2703/#2745) so this and the trace-recorder de-noise gate classify
  /// offline transients identically and can't drift. #2745 broadened from
  /// [isOfflineDioException] to [isOfflineError] so a `DioException[unknown]`
  /// wrapping an `HttpException` connection-abort (the field trace #1) is
  /// recognised as offline at the call site too.
  static bool _isOffline(DioException e) => isOfflineError(e);

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
    // #753 — strip the `fr-` prefix before sending it to Prix-Carburants
    // (the upstream only knows the bare numeric id). Tolerant of legacy
    // unprefixed favorites.
    final upstreamId =
        stationId.startsWith('fr-') ? stationId.substring(3) : stationId;
    final response = await _dio.get<dynamic>(_baseUrl, queryParameters: {
      'where': 'id=$upstreamId',
      'limit': 1,
    });

    final results = parser.extractPrixCarburantsResults(response.data);
    // #2763 — an empty feed slice is a TRANSIENT condition (the every-10-min
    // bulk feed occasionally drops a record between refreshes), NOT a
    // permanent 404. Throw a typed [ApiException] with [FailureKind.network]
    // so the chain's `_callWithTransientRetry` does ONE 500ms retry and
    // carries the kind into the accumulated `ServiceError` — instead of the
    // plain `Exception` that bypassed the `on ApiException` retry gate and
    // re-ran the whole chain 8× (one ERROR trace per provider/retry tap). A
    // genuine Dio `badResponse` 404 still maps to [FailureKind.notFound]
    // (terminal, not retried) via `throwApiException`.
    if (results.isEmpty) {
      throw ApiException(
        message: 'Station $stationId not found (empty feed slice)',
        kind: FailureKind.network,
      );
    }

    final r = results[0];
    final station = parser.parsePrixCarburantsStation(r, 0, 0);
    if (station == null) throw Exception('Failed to parse station');

    // #2599 — apply the SAME OSM brand enrichment the search path uses
    // (`searchStations` above). The Prix-Carburants feed publishes no
    // `brand` column, so a single-station re-fetch only carries the
    // address-heuristic brand (often the "independent" sentinel). Without
    // this, a cold notification deep-link (search cache empty → provider
    // falls back to this re-fetch) opened a brand-less station: the detail
    // header dropped to the street + "Independent station", while the same
    // station opened from search results showed its real brand (e.g.
    // "Intermarché"). Enriching here makes the deep-link path render
    // identically — and reuses the enricher's persisted `brand_<id>` cache,
    // so a station the user already saw in search resolves instantly (and
    // offline). Best-effort: a null enricher or a failed lookup leaves the
    // heuristic brand untouched, so the sentinel still shows ONLY when the
    // brand is genuinely absent in the source data.
    final enriched = _enricher != null
        ? (await _enricher.enrich([station])).first
        : station;

    // #2710/#3219 — structured weekly schedule from the FR adapter (Epic C3),
    // fed the SAME resolved hours input the search parse uses (derived
    // `horaires_jour` column with the structured-`horaires` fallback), so the
    // detail path can never disagree with the search path about a schedule.
    final hoursInput = parser.parsePrixCarburantsHoursInput(r);
    final is24h = hoursInput['horaires_automate_24_24'] == 'Oui';
    const openingHoursAdapter = FranceOpeningHoursAdapter();
    final openingHours = openingHoursAdapter.parse(hoursInput);

    return ServiceResult(
      data: StationDetail(
        station: enriched,
        wholeDay: is24h,
        openingHours: openingHours,
      ),
      source: ServiceSource.prixCarburantsApi,
      fetchedAt: DateTime.now(),
    );
  }

  @override
  Future<ServiceResult<Map<String, StationPrices>>> getPrices(
    List<String> ids,
  ) async {
    final prices = <String, StationPrices>{};
    final batch = ids.take(10).toList();
    if (batch.isEmpty) {
      return ServiceResult(
        data: prices,
        source: ServiceSource.prixCarburantsApi,
        fetchedAt: DateTime.now(),
      );
    }

    // #2301 — the previous implementation issued one serial `id=<n>` GET per
    // favorite (up to 10), turning a favorites refresh into up to ~150 s
    // worst case. Collapse the fan-out into a single OR-batched ODSQL query
    // (`id=1 OR id=2 OR …`, limit 10) so the refresh costs one round-trip.
    //
    // #753 — the upstream id is bare numeric; favorites/alerts store the
    // canonical `fr-<id>` form. We strip the prefix for the query, then map
    // each returned record back to the caller's original id via its own `id`
    // field — never by response position — so a missing/reordered record can
    // never assign prices to the wrong station (per-station isolation).
    final originalForUpstream = <String, String>{};
    final whereClauses = <String>[];
    for (final id in batch) {
      final upstreamId = id.startsWith('fr-') ? id.substring(3) : id;
      if (upstreamId.isEmpty) continue;
      originalForUpstream[upstreamId] = id;
      whereClauses.add('id=$upstreamId');
    }

    if (whereClauses.isEmpty) {
      return ServiceResult(
        data: prices,
        source: ServiceSource.prixCarburantsApi,
        fetchedAt: DateTime.now(),
      );
    }

    try {
      final response = await _dio.get<dynamic>(_baseUrl, queryParameters: {
        'where': whereClauses.join(' OR '),
        'limit': batch.length,
      });
      final results = parser.extractPrixCarburantsResults(response.data);
      for (final r in results) {
        final recordId = r['id']?.toString() ?? '';
        final originalId = originalForUpstream[recordId];
        if (originalId == null) continue; // unrequested / unmatched record
        prices[originalId] = StationPrices(
          e5: _toDouble(r['sp95_prix']),
          e10: _toDouble(r['e10_prix']),
          // #2249 — France's feed also carries SP98, E85 and GPLc; surface
          // them so a favorites/alerts refresh keeps the full fuel set.
          e98: _toDouble(r['sp98_prix']),
          diesel: _toDouble(r['gazole_prix']),
          e85: _toDouble(r['e85_prix']),
          lpg: _toDouble(r['gplc_prix']),
          status: 'open',
        );
      }
    } on DioException catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.other, e, st,
          context: const {'where': 'Prix-Carburants batch prices fetch failed'}));
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
