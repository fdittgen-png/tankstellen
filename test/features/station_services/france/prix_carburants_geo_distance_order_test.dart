// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/search/data/models/search_params.dart';
import 'package:tankstellen/features/station_services/france/prix_carburants_station_service.dart';

import '../../../helpers/silence_error_logger.dart';

/// #2966 — the FR geo corridor (`_queryByGeo`) was hard-capped at `limit: 50`
/// with NO distance `order_by`, so in a dense area the returned 50-row slice is
/// an arbitrary, un-distance-ordered subset of the `within_distance` corridor —
/// the genuinely-NEAREST forecourt can be truncated out entirely.
///
/// These fixtures are RECORDED REAL Opendatasoft v2.1 responses for a DENSE
/// French area (central Paris: 140 stations within 10 km of 2.3522,48.8566),
/// not an echoing fake (per the `feedback_fake_services_false_green` memory):
///
///   - `prix_carburants_paris_geo_unordered.json` — the live query WITHOUT
///     `order_by` (exactly what master fetches). Its nearest in-slice station
///     is `75013024` at ~2.4 km; the genuinely-nearest `75001003` (~954 m) is
///     ABSENT from the slice — truncated by the cap.
///   - `prix_carburants_paris_geo_ordered.json` — the live query WITH the
///     validated `order_by=distance(geom,geom'POINT(lon lat)')`. Its first row
///     is `75001003` (~954 m): the nearest survives the cap.
///
/// The injected adapter is REQUEST-AWARE: it serves the ordered fixture only
/// when the request carries the distance `order_by` (the fix), else the
/// unordered fixture (master). So the SAME test is:
///   RED on master  — geo URL has no `order_by` → unordered fixture →
///                     `fr-75001003` is absent from results.
///   GREEN after fix — geo URL carries `order_by=distance` → ordered fixture →
///                     `fr-75001003` is the nearest returned station.
void main() {
  silenceErrorLoggerSpool();

  // Recorded-fixture anchor (the live query point used to capture both files).
  const anchorLat = 48.8566;
  const anchorLng = 2.3522;
  // The genuinely-nearest forecourt (~954 m) in the DENSE corpus. The parser
  // prefixes upstream ids with `fr-` for global uniqueness (#753).
  const nearestId = 'fr-75001003';

  late Map<String, dynamic> unordered;
  late Map<String, dynamic> ordered;

  setUpAll(() {
    unordered = jsonDecode(
      File('test/fixtures/prix_carburants_paris_geo_unordered.json')
          .readAsStringSync(),
    ) as Map<String, dynamic>;
    ordered = jsonDecode(
      File('test/fixtures/prix_carburants_paris_geo_ordered.json')
          .readAsStringSync(),
    ) as Map<String, dynamic>;
  });

  PrixCarburantsStationService buildService(_GeoOrderAdapter adapter) {
    final dio = Dio(BaseOptions(baseUrl: ''))..httpClientAdapter = adapter;
    return PrixCarburantsStationService(dio: dio);
  }

  group('FR _queryByGeo distance ordering (#2966)', () {
    test(
        'serves the distance-ordered corridor so the genuinely-nearest dense-area '
        'station survives the limit:50 cap (RED on master: truncated)', () async {
      final adapter = _GeoOrderAdapter(ordered: ordered, unordered: unordered);
      final service = buildService(adapter);

      // Radius wide enough to keep every recorded fixture station in-radius,
      // so the ONLY thing that decides whether the nearest appears is which
      // 50-row slice the server returned (ordered vs arbitrary) — i.e. the fix.
      final result = await service.searchStations(const SearchParams(
        lat: anchorLat,
        lng: anchorLng,
        radiusKm: 10.0,
        sortBy: SortBy.distance,
      ));

      // Sanity: a dense slice came back.
      expect(result.data.length, greaterThan(40),
          reason: 'the dense Paris corridor should return a full slice');

      // The fix issues the distance order_by, so the adapter served the
      // ordered fixture and the genuinely-nearest forecourt is present …
      final ids = result.data.map((s) => s.id).toSet();
      expect(ids, contains(nearestId),
          reason:
              'the ~954 m station $nearestId must survive the cap once the '
              'corridor is distance-ordered (#2966)');

      // … and it is the NEAREST returned station (results are distance-sorted).
      expect(result.data.first.id, nearestId,
          reason:
              'with server-side distance ordering the nearest forecourt is the '
              'first result, not truncated out of an arbitrary 50');
    });

    test(
        'the recorded master (un-ordered) slice genuinely TRUNCATES the nearest '
        '— proving the RED precondition is real, not a fixture artefact',
        () async {
      // Drive the service against the un-ordered slice ONLY (what master's
      // query returns). The nearest forecourt is simply not in the 50 rows, so
      // no amount of client-side sorting can recover it: the fetch was wrong.
      final adapter = _GeoOrderAdapter(ordered: unordered, unordered: unordered);
      final service = buildService(adapter);

      final result = await service.searchStations(const SearchParams(
        lat: anchorLat,
        lng: anchorLng,
        radiusKm: 10.0,
        sortBy: SortBy.distance,
      ));

      final ids = result.data.map((s) => s.id).toSet();
      expect(ids, isNot(contains(nearestId)),
          reason:
              'the un-ordered (master) slice does NOT contain the genuinely-'
              'nearest station — the limit:50 cap truncated it');
      // The best the un-ordered slice can offer is ~2.4 km away.
      expect(result.data.first.dist, greaterThan(2.0),
          reason:
              'the un-ordered slice\'s nearest in-slice station is ~2.4 km, far '
              'from the genuine ~954 m nearest');
    });

    test('the geo request carries the validated v2.1 distance order_by', () async {
      final adapter = _GeoOrderAdapter(ordered: ordered, unordered: unordered);
      final service = buildService(adapter);

      await service.searchStations(const SearchParams(
        lat: anchorLat,
        lng: anchorLng,
        radiusKm: 10.0,
      ));

      final uri = adapter.lastGeoUri;
      expect(uri, isNotNull, reason: 'a geo query must have been issued');
      // The exact live-validated form: order_by=distance(geom,geom'POINT(...)').
      expect(uri, contains('order_by'),
          reason: 'the geo query must order the corridor by distance (#2966)');
      expect(uri, contains('distance'),
          reason: 'order_by must use the ODSQL distance() function');
      // The within_distance corridor filter is UNCHANGED — ordering must not
      // alter which stations are in-radius, only their order / cap survival.
      expect(uri, contains('within_distance'),
          reason: 'the within_distance corridor filter must be preserved');
    });
  });
}

/// Request-aware mock adapter (#2966). Returns the distance-ordered fixture for
/// a geo query that carries the `order_by` distance clause (the fix), and the
/// arbitrary, un-ordered fixture otherwise (master) — modelling the live
/// server's behaviour difference between the two queries. Non-geo requests
/// (none here) get an empty body.
class _GeoOrderAdapter implements HttpClientAdapter {
  _GeoOrderAdapter({required this.ordered, required this.unordered});

  final Map<String, dynamic> ordered;
  final Map<String, dynamic> unordered;

  String? lastGeoUri;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final uri = options.uri.toString();
    final isGeo = uri.contains('within_distance');
    final body = <String, dynamic>{};
    if (isGeo) {
      lastGeoUri = uri;
      // The live server returns nearest-first ONLY when the distance order_by
      // is present; master omits it and gets an arbitrary slice.
      final isOrdered = uri.contains('order_by');
      body.addAll(isOrdered ? ordered : unordered);
    } else {
      body['results'] = const <dynamic>[];
    }
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
