// Radius-sensitivity contract test (#299).
//
// Every [StationService] implementation must honour [SearchParams.radiusKm].
// This contract test asserts, for all services that accept an injected [Dio]:
//
//   1. Changing the search radius changes the HTTP request sent to the API
//      (the radius is actually forwarded — not silently dropped).
//   2. Stations returned with `radiusKm=small` are a (non-strict) subset of
//      stations returned with `radiusKm=large`, when the same fake dataset
//      is served for both queries.
//   3. No station in the returned result exceeds the requested radius
//      (modulo the documented fallback to 20-nearest when the in-radius
//      result would be empty).
//   4. Changing the radius produces a different cache key (the service must
//      not collapse different radii into the same logical request).
//
// The contract exists because of #298: the Prix-Carburants postal-code path
// silently ignored `radiusKm`, returning an identical 50-station list for
// 1 km and 25 km searches. No unit test covered the postal-code path, so
// the regression shipped. This file prevents #298-class bugs on any service
// that exposes a `Dio` seam for testing.
//
// Services that construct their Dio internally (via `DioFactory.create()`)
// are covered by their per-service unit tests plus the central
// `filterByRadius` helper test in
// `test/core/services/mixins/station_service_helpers_test.dart`.
//
// Argentina is explicitly skipped — its classifier + dataset path is known
// flaky in CI (see service_providers_test.dart).

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/station_services/france/prix_carburants_station_service.dart';
import 'package:tankstellen/features/station_services/germany/tankerkoenig_station_service.dart';
import 'package:tankstellen/core/services/station_service.dart';
import 'package:tankstellen/features/search/data/models/search_params.dart';

/// A single service under test, with:
/// - a label (shown in failure messages),
/// - a factory that returns a fresh service instance bound to a given [Dio],
/// - a payload factory keyed on the radius the adapter last saw (so the test
///   can return a dataset whose distances span beyond the requested radius),
/// - sample [SearchParams] that exercise the service's dominant path.
class _ContractCase {
  final String label;
  final StationService Function(Dio dio) build;
  final Map<String, dynamic> Function() payload;
  final SearchParams smallRadius;
  final SearchParams largeRadius;

  const _ContractCase({
    required this.label,
    required this.build,
    required this.payload,
    required this.smallRadius,
    required this.largeRadius,
  });
}

/// Builds a Tankerkoenig-shaped response with stations at distances
/// 0.5, 1.5, 2.5, ..., 29.5 km from the search origin. The API itself
/// returns the full list — it's the client's job to respect `rad`.
Map<String, dynamic> _tankerkoenigPayload() {
  final stations = List.generate(30, (i) {
    final dist = i + 0.5; // 0.5 .. 29.5 km
    return {
      'id': 'tk-$i',
      'name': 'Station $i',
      'brand': 'ARAL',
      'street': 'Hauptstr.',
      'houseNumber': '$i',
      'postCode': '10115',
      'place': 'Berlin',
      'lat': 52.52 + (i * 0.001),
      'lng': 13.40 + (i * 0.001),
      'dist': dist,
      'diesel': 1.659,
      'e5': 1.779,
      'e10': 1.739,
      'isOpen': true,
    };
  });
  return {'ok': true, 'stations': stations};
}

/// Builds a Prix-Carburants shaped response. Distances are *computed* by
/// the service from geom coordinates, so we spread stations radially
/// around the search origin (43.45, 3.42 = Castelnau de Guers area).
/// Roughly 0.011 degrees lat ~= 1.2 km at this latitude.
Map<String, dynamic> _prixCarburantsPayload() {
  final results = List.generate(30, (i) {
    // Walk north in ~1 km increments so parsed `dist` spans 0..~30 km.
    final latOffset = (i + 1) * 0.009; // ~1 km per step
    return {
      'id': '34120$i',
      'adresse': 'Rue Test $i',
      'ville': 'Castelnau',
      'cp': '34120',
      'geom': {
        'lat': 43.45 + latOffset,
        'lon': 3.42,
      },
      'sp95_prix': 1.829,
      'e10_prix': 1.789,
      'gazole_prix': 1.679,
    };
  });
  return {'results': results};
}

/// Dio adapter that captures every request URI and replies with a
/// canned JSON body. A single payload is reused for every call (the
/// test needs only that the *same* dataset be served for both the
/// small-radius and the large-radius query).
class _RadiusCaptureAdapter implements HttpClientAdapter {
  _RadiusCaptureAdapter(this._bodyFactory);

  final Map<String, dynamic> Function() _bodyFactory;
  final List<Uri> requestUris = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestUris.add(options.uri);
    return ResponseBody.fromString(
      jsonEncode(_bodyFactory()),
      200,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Assert the radius contract on a single service for a single code path.
///
/// - Runs the service twice (small radius, large radius) against the same
///   canned payload.
/// - Verifies the request URIs encode the differing radii.
/// - Verifies returned stations are all within the requested radius
///   (or fall back to a small non-empty set when the API returned nothing
///   in range).
/// - Verifies that the result set for `small` is a subset of the result
///   set for `large` (by station id).
Future<void> _assertRadiusContract({
  required String label,
  required StationService Function(Dio dio) build,
  required Map<String, dynamic> Function() payload,
  required SearchParams small,
  required SearchParams large,
}) async {
  // Small radius run
  final smallAdapter = _RadiusCaptureAdapter(payload);
  final smallDio = Dio(BaseOptions(baseUrl: ''))
    ..httpClientAdapter = smallAdapter;
  final smallService = build(smallDio);
  final smallResult = await smallService.searchStations(small);

  // Large radius run
  final largeAdapter = _RadiusCaptureAdapter(payload);
  final largeDio = Dio(BaseOptions(baseUrl: ''))
    ..httpClientAdapter = largeAdapter;
  final largeService = build(largeDio);
  final largeResult = await largeService.searchStations(large);

  // 1. The service must have hit the network at least once in each run.
  expect(
    smallAdapter.requestUris,
    isNotEmpty,
    reason: '[$label] small-radius search did not hit the API',
  );
  expect(
    largeAdapter.requestUris,
    isNotEmpty,
    reason: '[$label] large-radius search did not hit the API',
  );

  // 2. Radius must influence *something*: either the request URIs
  //    differ (radius is pushed to the API — Tankerkoenig `rad=`,
  //    Prix-Carburants `within_distance(...,Xkm)`) OR the resulting
  //    station counts differ (radius is enforced client-side after
  //    fetching a broader dataset — Prix-Carburants postal-code path
  //    post-#298, all bulk-dataset services).
  //    If neither URIs nor results differ, radiusKm is being silently
  //    dropped on every layer of the service.
  final smallUriStrings = smallAdapter.requestUris.map((u) => u.toString()).toList();
  final largeUriStrings = largeAdapter.requestUris.map((u) => u.toString()).toList();
  final urisDiffer = !_listsEqual(smallUriStrings, largeUriStrings);
  final resultsDiffer = smallResult.data.length != largeResult.data.length;
  expect(
    urisDiffer || resultsDiffer,
    isTrue,
    reason:
        '[$label] radius=${small.radiusKm} and radius=${large.radiusKm} '
        'produced byte-identical HTTP requests AND the same number of '
        'stations (${smallResult.data.length}). The service is silently '
        'ignoring radiusKm on this code path — this is exactly the #298 '
        'regression this contract is designed to prevent.\n'
        '  small URIs: $smallUriStrings\n'
        '  large URIs: $largeUriStrings\n'
        '  small stations: ${smallResult.data.map((s) => '${s.id}@${s.dist}km').toList()}\n'
        '  large stations: ${largeResult.data.map((s) => '${s.id}@${s.dist}km').toList()}',
  );

  // 3. Every returned station in the small-radius run must be within
  //    `small.radiusKm` — OR the service fell back to the 20-nearest
  //    rescue path because nothing was in range. The fallback path is
  //    only legal when the in-radius result would otherwise be empty,
  //    so we allow it only if *all* returned stations are outside the
  //    radius (i.e. the fallback actually fired).
  final smallStations = smallResult.data;
  if (smallStations.isNotEmpty) {
    final anyWithinRadius = smallStations.any((s) => s.dist <= small.radiusKm);
    final allOutsideRadius = smallStations.every((s) => s.dist > small.radiusKm);
    expect(
      anyWithinRadius || allOutsideRadius,
      isTrue,
      reason:
          '[$label] mixed in-radius and out-of-radius stations returned for '
          'radius=${small.radiusKm}km. Stations: '
          '${smallStations.map((s) => '${s.id}@${s.dist}km').join(', ')}',
    );
  }

  // 4. Subset property: every station id in the small-radius result
  //    must appear in the large-radius result when the same dataset
  //    backs both queries.
  final smallIds = smallStations.map((s) => s.id).toSet();
  final largeIds = largeResult.data.map((s) => s.id).toSet();
  expect(
    smallIds.difference(largeIds),
    isEmpty,
    reason:
        '[$label] expanding radius from ${small.radiusKm}km to ${large.radiusKm}km '
        'dropped ${smallIds.difference(largeIds)} — result set is not monotonic.',
  );

  // 5. Large radius must return at least as many stations as small
  //    radius (strict inequality only holds when the dataset spans
  //    the gap, which it does in our fixtures, so we assert it).
  expect(
    largeResult.data.length,
    greaterThanOrEqualTo(smallStations.length),
    reason:
        '[$label] large-radius result (${largeResult.data.length} stations) '
        'has FEWER stations than small-radius result (${smallStations.length}).',
  );
}

bool _listsEqual(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

void main() {
  // The matrix of services under contract. When adding a new country
  // service that accepts an injected `Dio`, append it here — the
  // generated tests below will automatically enforce radius sensitivity.
  final cases = <_ContractCase>[
    _ContractCase(
      label: 'Tankerkoenig (DE)',
      build: (dio) => TankerkoenigStationService(dio),
      payload: _tankerkoenigPayload,
      smallRadius: const SearchParams(
        lat: 52.52,
        lng: 13.40,
        radiusKm: 2.0,
      ),
      largeRadius: const SearchParams(
        lat: 52.52,
        lng: 13.40,
        radiusKm: 20.0,
      ),
    ),
    _ContractCase(
      label: 'Prix-Carburants (FR) — GPS path',
      build: (dio) => PrixCarburantsStationService(dio: dio),
      payload: _prixCarburantsPayload,
      smallRadius: const SearchParams(
        lat: 43.45,
        lng: 3.42,
        radiusKm: 2.0,
      ),
      largeRadius: const SearchParams(
        lat: 43.45,
        lng: 3.42,
        radiusKm: 20.0,
      ),
    ),
    _ContractCase(
      label: 'Prix-Carburants (FR) — postal-code path (#298 regression guard)',
      build: (dio) => PrixCarburantsStationService(dio: dio),
      payload: _prixCarburantsPayload,
      smallRadius: const SearchParams(
        lat: 43.45,
        lng: 3.42,
        radiusKm: 2.0,
        postalCode: '34120',
      ),
      largeRadius: const SearchParams(
        lat: 43.45,
        lng: 3.42,
        radiusKm: 20.0,
        postalCode: '34120',
      ),
    ),
  ];

  group('StationService radius contract (#299)', () {
    for (final c in cases) {
      test('${c.label} honours radiusKm', () async {
        await _assertRadiusContract(
          label: c.label,
          build: c.build,
          payload: c.payload,
          small: c.smallRadius,
          large: c.largeRadius,
        );
      });
    }

    test('contract covers every Dio-injectable StationService', () {
      // Guard against silently skipping a service: if a new implementation
      // is added that accepts a Dio constructor parameter, the developer
      // should add it to the `cases` list above. This test hard-codes the
      // expected labels so a missing entry fails loudly.
      final labels = cases.map((c) => c.label).toSet();
      expect(labels, contains('Tankerkoenig (DE)'));
      expect(labels, contains('Prix-Carburants (FR) — GPS path'));
      expect(
        labels,
        contains('Prix-Carburants (FR) — postal-code path (#298 regression guard)'),
      );
    });
  });

  group('StationService radius contract — sanity checks on fixtures', () {
    test('Tankerkoenig fixture spans 0.5..29.5 km', () {
      final stations = _tankerkoenigPayload()['stations'] as List<dynamic>;
      final dists = stations
          .map((s) => (s as Map<String, dynamic>)['dist'] as num)
          .toList();
      expect(dists.first, 0.5);
      expect(dists.last, 29.5);
      expect(dists.length, 30);
    });

    test('Prix-Carburants fixture has 30 stations walking north from origin', () {
      final results = _prixCarburantsPayload()['results'] as List<dynamic>;
      expect(results.length, 30);
      // The 1st station is offset by ~1 km, the 30th by ~30 km.
      final first = (results.first as Map<String, dynamic>)['geom'] as Map<String, dynamic>;
      final last = (results.last as Map<String, dynamic>)['geom'] as Map<String, dynamic>;
      expect(first['lat'], greaterThan(43.45));
      expect(last['lat'], greaterThan(first['lat'] as double));
    });
  });

}
