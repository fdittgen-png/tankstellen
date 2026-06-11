// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/error/exceptions.dart';
import 'package:tankstellen/core/logging/error_logger.dart';
import 'package:tankstellen/features/station_services/uk/uk_station_service.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/services/station_service.dart';
import 'package:tankstellen/features/search/data/models/search_params.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';
import '../../../helpers/silence_error_logger.dart';

/// Fake HTTP adapter that returns a canned response per URL.
///
/// `responses` maps each URL to either a full JSON string (served with
/// status 200) or a status code (served with an empty body). Unmapped
/// URLs behave as-if the retailer were offline (status 404).
class _FakeAdapter implements HttpClientAdapter {
  final Map<String, Object> responses;
  final List<String> requestedUrls = [];

  _FakeAdapter(this.responses);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestedUrls.add(options.uri.toString());
    final reply = responses[options.uri.toString()];

    if (reply is String) {
      return ResponseBody.fromString(
        reply,
        200,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }
    if (reply is int) {
      return ResponseBody.fromString('', reply);
    }
    // Unmapped URLs simulate a dead retailer feed.
    return ResponseBody.fromString('', 404);
  }

  @override
  void close({bool force = false}) {}
}

Dio _dioWith(Map<String, Object> responses) {
  final dio = Dio();
  dio.httpClientAdapter = _FakeAdapter(responses);
  return dio;
}

/// Standard CMA-format feed payload for the given site.
///
/// #3191 — the schema mirrors the REAL feeds (see
/// `test/fixtures/uk_asda_cma_slice.json`): there is NO `site_name` field
/// (the old fixture invented one, making the name tests false-green); the
/// display name falls back to `brand`.
String _cmaFeed({
  required String siteId,
  required String brand,
  required double lat,
  required double lng,
  double e5 = 155.9,
  double e10 = 145.9,
  double diesel = 152.9,
  String postcode = 'SW1E 6DE',
  String address = '1 Victoria St',
}) {
  return jsonEncode({
    'last_updated': '2025-01-01 08:00:00',
    'stations': [
      {
        'site_id': siteId,
        'brand': brand,
        'address': address,
        'postcode': postcode,
        'town': 'London',
        'location': {'latitude': lat, 'longitude': lng},
        'prices': {'E5': e5, 'E10': e10, 'B7': diesel},
      },
    ],
  });
}

const _searchParams = SearchParams(lat: 51.5, lng: -0.12, radiusKm: 50);

void main() {
  // #2301 — per-feed DioException failures now route through errorLogger
  // (release-safe breadcrumb). Hive isn't initialised in tests, so silence
  // the spool to keep the fire-and-forget log from failing the test.
  silenceErrorLoggerSpool();

  group('UkStationService (public surface)', () {
    test('implements StationService interface', () {
      expect(UkStationService(), isA<StationService>());
    });

    test('getStationDetail throws ApiException', () {
      expect(
        () => UkStationService().getStationDetail('uk-123'),
        throwsA(isA<Exception>()),
      );
    });

    test('getPrices returns empty map with correct source', () async {
      final result = await UkStationService().getPrices(['uk-1']);
      expect(result.data, isEmpty);
      expect(result.source, ServiceSource.ukApi);
      expect(result.isStale, isFalse);
    });

    test('default feed list is non-empty', () {
      expect(UkStationService.defaultCmaFeedUrls, isNotEmpty);
    });
  });

  group('searchStations (aggregated CMA feeds)', () {
    test('aggregates stations from multiple retailer feeds', () async {
      const bpUrl = 'https://bp.example/feed.json';
      const tescoUrl = 'https://tesco.example/feed.json';

      final dio = _dioWith({
        bpUrl: _cmaFeed(
          siteId: 'BP1',
          brand: 'BP',
          lat: 51.4975,
          lng: -0.1357,
        ),
        tescoUrl: _cmaFeed(
          siteId: 'TES1',
          brand: 'Tesco',
          lat: 51.5001,
          lng: -0.12,
          e5: 150.0,
          e10: 140.0,
          diesel: 148.0,
        ),
      });

      final service = UkStationService(
        dio: dio,
        feedUrls: const [bpUrl, tescoUrl],
      );

      final result = await service.searchStations(_searchParams);
      expect(result.source, ServiceSource.ukApi);
      expect(result.data, hasLength(2));
      final ids = result.data.map((s) => s.id).toSet();
      expect(ids, containsAll(<String>['uk-BP1', 'uk-TES1']));
    });

    test('tolerates a 404 from one retailer while returning others', () async {
      const bpUrl = 'https://bp.example/feed.json';
      const deadUrl = 'https://dead.example/feed.json';

      final dio = _dioWith({
        bpUrl: _cmaFeed(
          siteId: 'BP1',
          brand: 'BP',
          lat: 51.4975,
          lng: -0.1357,
        ),
        deadUrl: 404,
      });

      final service = UkStationService(
        dio: dio,
        feedUrls: const [bpUrl, deadUrl],
      );

      final result = await service.searchStations(_searchParams);
      expect(result.data, hasLength(1));
      expect(result.data.first.brand, 'BP');
    });

    test('throws ApiException when ALL feeds fail', () async {
      const a = 'https://a.example/feed.json';
      const b = 'https://b.example/feed.json';

      final dio = _dioWith({a: 404, b: 404});
      final service = UkStationService(dio: dio, feedUrls: const [a, b]);

      expect(
        () => service.searchStations(_searchParams),
        throwsA(isA<ApiException>()),
      );
    });

    test('tolerates retailer-level 5xx without killing the whole search',
        () async {
      const good = 'https://good.example/feed.json';
      const brokenUrl = 'https://broken.example/feed.json';

      // 5xx from one retailer bubbles up as a Dio exception which we
      // catch per-feed. The good feed should still return data.
      final dio = _dioWith({
        good: _cmaFeed(
          siteId: 'G1',
          brand: 'Good',
          lat: 51.5,
          lng: -0.12,
        ),
        brokenUrl: 502,
      });

      final service = UkStationService(
        dio: dio,
        feedUrls: const [good, brokenUrl],
      );

      final result = await service.searchStations(_searchParams);
      expect(result.data, hasLength(1));
      expect(result.data.first.brand, 'Good');
    });

    test('dedupes stations that appear in multiple feeds by site_id',
        () async {
      const feedA = 'https://a.example/feed.json';
      const feedB = 'https://b.example/feed.json';

      // Same site_id served from two different feeds — only one wins.
      final payload = _cmaFeed(
        siteId: 'DUPLICATE',
        brand: 'Shared',
        lat: 51.5,
        lng: -0.12,
      );

      final dio = _dioWith({feedA: payload, feedB: payload});
      final service = UkStationService(
        dio: dio,
        feedUrls: const [feedA, feedB],
      );

      final result = await service.searchStations(_searchParams);
      expect(result.data, hasLength(1));
      expect(result.data.first.id, 'uk-DUPLICATE');
    });

    test('filters stations outside the search radius', () async {
      const feed = 'https://a.example/feed.json';

      final payload = jsonEncode({
        'stations': [
          {
            'site_id': 'LON',
            'brand': 'BP',
            'location': {'latitude': 51.5, 'longitude': -0.12},
            'prices': <String, dynamic>{},
          },
          {
            'site_id': 'EDI',
            'brand': 'BP',
            'location': {'latitude': 55.9533, 'longitude': -3.1883},
            'prices': <String, dynamic>{},
          },
        ],
      });

      final dio = _dioWith({feed: payload});
      final service =
          UkStationService(dio: dio, feedUrls: const [feed]);

      final result = await service.searchStations(
        const SearchParams(lat: 51.5, lng: -0.12, radiusKm: 20),
      );
      expect(result.data, hasLength(1));
      expect(result.data.first.id, 'uk-LON');
    });

    test('logs per-feed DioException failures (release breadcrumb #2301)',
        () async {
      // The previous implementation used debugPrint, which is stripped in
      // release — with 14 parallel feeds a partial failure left no trace.
      // Capture spool enqueues to prove the failure is now logged.
      final logged = <Map<String, dynamic>?>[];
      errorLogger.spoolEnqueueOverride = ({
        required String isolateTaskName,
        required Object error,
        StackTrace? stack,
        Map<String, dynamic>? contextMap,
        DateTime? timestamp,
      }) async {
        logged.add(contextMap);
      };
      addTearDown(errorLogger.resetForTest);

      const good = 'https://good.example/feed.json';
      const brokenUrl = 'https://broken.example/feed.json';
      final dio = _dioWith({
        good: _cmaFeed(
          siteId: 'G1',
          brand: 'Good',
          lat: 51.5,
          lng: -0.12,
        ),
        brokenUrl: 502, // 502 ≥ 500 → bubbles as a DioException per-feed.
      });
      final service = UkStationService(
        dio: dio,
        feedUrls: const [good, brokenUrl],
      );

      final result = await service.searchStations(_searchParams);
      // Good feed still resolves.
      expect(result.data, hasLength(1));
      // The broken feed left a breadcrumb instead of failing silently.
      expect(logged, isNotEmpty,
          reason: 'a per-feed DioException must be logged (#2301)');
      expect(
        logged.any((c) => c?['where'] == 'UK feed' && c?.containsKey('type') == true),
        isTrue,
        reason: 'breadcrumb must carry where=UK feed and the Dio error type',
      );
    });
  });

  group('parseCmaStations (CMA payload parser)', () {
    List<Station> parse(
      dynamic items, {
      double lat = 51.5,
      double lng = -0.12,
      double radiusKm = 50,
    }) {
      return UkStationService.parseCmaStations(
        items is List ? items : [items],
        lat: lat,
        lng: lng,
        radiusKm: radiusKm,
      );
    }

    test('parses a well-formed station with prices in pence', () {
      final stations = parse([
        {
          'site_id': 'ABC123',
          'brand': 'BP',
          'address': '123 Victoria Street',
          'postcode': 'SW1E 6DE',
          'town': 'London',
          'location': {'latitude': 51.4975, 'longitude': -0.1357},
          'prices': {'E10': 145.9, 'E5': 155.9, 'B7': 152.9},
        },
      ]);

      expect(stations, hasLength(1));
      final s = stations.first;
      expect(s.id, 'uk-ABC123');
      // #3191 — no site_name in the real schema: the name is the brand.
      expect(s.name, 'BP');
      expect(s.brand, 'BP');
      expect(s.street, '123 Victoria Street');
      expect(s.postCode, 'SW1E 6DE');
      expect(s.place, 'London');
      expect(s.e10, closeTo(1.459, 0.0001));
      expect(s.e5, closeTo(1.559, 0.0001));
      expect(s.diesel, closeTo(1.529, 0.0001));
      // #3198 — the CMA feed carries no open/closed signal: honest unknown.
      expect(s.isOpen, isNull);
    });

    test('keeps prices under 10 as-is (already in pounds)', () {
      final stations = parse([
        {
          'site_id': 1,
          'brand': 'Shell',
          'location': {'latitude': 51.5, 'longitude': -0.12},
          'prices': {'E10': 1.459, 'B7': 1.529},
        },
      ]);

      expect(stations.first.e10, 1.459);
      expect(stations.first.diesel, 1.529);
    });

    test('supports alternate field names (lat/lng, unleaded, diesel) and '
        'maps SDV to dieselPremium (#3191)', () {
      final stations = parse(
        [
          {
            'site_id': 'SITE42',
            'brand': 'Tesco',
            'address': 'Retail Park',
            'postcode': 'M1 1AA',
            'locality': 'Manchester',
            'lat': 53.4808,
            'lng': -2.2426,
            'prices': {
              'unleaded': 144.9,
              'E10': 142.9,
              'diesel': 151.9,
              'SDV': 158.9,
              // #3191 — `super_unleaded` exists in NO live CMA feed and must
              // no longer be mapped (it used to land in e98).
              'super_unleaded': 199.9,
            },
          },
        ],
        lat: 53.4808,
        lng: -2.2426,
      );

      expect(stations, hasLength(1));
      final s = stations.first;
      expect(s.id, 'uk-SITE42');
      expect(s.place, 'Manchester');
      expect(s.e5, closeTo(1.449, 0.0001));
      expect(s.e10, closeTo(1.429, 0.0001));
      expect(s.diesel, closeTo(1.519, 0.0001));
      expect(s.dieselPremium, closeTo(1.589, 0.0001));
      expect(s.e98, isNull);
    });

    test('skips stations with missing coordinates', () {
      final stations = parse([
        {'site_id': 1, 'prices': <String, dynamic>{}},
        {
          'site_id': 2,
          'location': {'latitude': 51.5, 'longitude': -0.12},
          'prices': <String, dynamic>{},
        },
      ]);
      expect(stations, hasLength(1));
      expect(stations.first.id, 'uk-2');
    });

    test('sorts stations by distance ascending', () {
      final stations = parse([
        {
          'site_id': 'FAR',
          'location': {'latitude': 51.52, 'longitude': -0.12},
          'prices': <String, dynamic>{},
        },
        {
          'site_id': 'NEAR',
          'location': {'latitude': 51.5001, 'longitude': -0.12},
          'prices': <String, dynamic>{},
        },
      ]);
      expect(stations, hasLength(2));
      expect(stations.first.id, 'uk-NEAR');
      expect(stations.last.id, 'uk-FAR');
    });

    test('caps results at 50 stations', () {
      final list = List<Map<String, dynamic>>.generate(
        120,
        (i) => {
          'site_id': 'S$i',
          'location': {'latitude': 51.5 + i * 0.0001, 'longitude': -0.12},
          'prices': <String, dynamic>{},
        },
      );

      final stations = parse(list, radiusKm: 500);
      expect(stations.length, 50);
    });

    test('dedupes by site_id within a single payload (first record wins)', () {
      final stations = parse([
        {
          'site_id': 'DUP',
          'brand': 'First',
          'location': {'latitude': 51.5, 'longitude': -0.12},
          'prices': <String, dynamic>{},
        },
        {
          'site_id': 'DUP',
          'brand': 'Second',
          'location': {'latitude': 51.5, 'longitude': -0.12},
          'prices': <String, dynamic>{},
        },
      ]);
      expect(stations, hasLength(1));
      expect(stations.first.brand, 'First');
    });

    // #2199 — SafeJsonAccessors regression coverage. These pin the
    // observable behaviour after migrating the raw `as num?` / `as Map`
    // casts to getDouble / getMap so a future change cannot silently
    // alter which records parse.
    test('parses string-typed coordinates via getDouble (robustness gain)',
        () {
      // Before #2199 a String latitude threw a CastError that the per-item
      // catch swallowed into a skipped station; getDouble parses it instead.
      final stations = parse([
        {
          'site_id': 'STR',
          'brand': 'BP',
          'location': {'latitude': '51.5', 'longitude': '-0.12'},
          'prices': {'E5': 145.9},
        },
      ]);
      expect(stations, hasLength(1));
      expect(stations.first.lat, closeTo(51.5, 0.0001));
      expect(stations.first.lng, closeTo(-0.12, 0.0001));
    });

    test('still skips records with non-numeric coordinate strings', () {
      // getDouble('abc') -> null, same as the old cast outcome (skipped).
      final stations = parse([
        {
          'site_id': 'BAD',
          'location': {'latitude': 'not-a-number', 'longitude': '-0.12'},
          'prices': <String, dynamic>{},
        },
      ]);
      expect(stations, isEmpty);
    });

    test('degrades to empty prices when prices is not a map', () {
      // getMap returns null for a non-map value -> `?? {}` -> no prices,
      // identical to the previous `is Map ? ... : {}` guard.
      final stations = parse([
        {
          'site_id': 'NOPRICE',
          'location': {'latitude': 51.5, 'longitude': -0.12},
          'prices': 'not a map',
        },
      ]);
      expect(stations, hasLength(1));
      expect(stations.first.e5, isNull);
      expect(stations.first.e10, isNull);
      expect(stations.first.diesel, isNull);
    });

    test('parsePenceForTest — null, non-numeric, pence, and pounds', () {
      expect(UkStationService.parsePenceForTest(null), isNull);
      expect(UkStationService.parsePenceForTest('abc'), isNull);
      expect(
        UkStationService.parsePenceForTest(145.9),
        closeTo(1.459, 0.0001),
      );
      expect(UkStationService.parsePenceForTest('155'), closeTo(1.55, 0.0001));
      expect(UkStationService.parsePenceForTest(1.459), 1.459);
      expect(UkStationService.parsePenceForTest('2.5'), 2.5);
    });
  });
}
