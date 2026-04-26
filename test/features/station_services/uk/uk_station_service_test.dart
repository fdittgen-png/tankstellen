import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/error/exceptions.dart';
import 'package:tankstellen/features/station_services/uk/uk_station_service.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/services/station_service.dart';
import 'package:tankstellen/features/search/data/models/search_params.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';

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
String _cmaFeed({
  required String siteId,
  required String brand,
  required String name,
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
        'site_name': name,
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
          name: 'BP Victoria',
          lat: 51.4975,
          lng: -0.1357,
        ),
        tescoUrl: _cmaFeed(
          siteId: 'TES1',
          brand: 'Tesco',
          name: 'Tesco Extra',
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
          name: 'BP Victoria',
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
          name: 'Good Station',
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
        name: 'Shared Station',
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
            'site_name': 'London',
            'location': {'latitude': 51.5, 'longitude': -0.12},
            'prices': <String, dynamic>{},
          },
          {
            'site_id': 'EDI',
            'brand': 'BP',
            'site_name': 'Edinburgh',
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
      expect(result.data.first.name, 'London');
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
          'site_name': 'BP Victoria Street',
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
      expect(s.name, 'BP Victoria Street');
      expect(s.brand, 'BP');
      expect(s.street, '123 Victoria Street');
      expect(s.postCode, 'SW1E 6DE');
      expect(s.place, 'London');
      expect(s.e10, closeTo(1.459, 0.0001));
      expect(s.e5, closeTo(1.559, 0.0001));
      expect(s.diesel, closeTo(1.529, 0.0001));
      expect(s.isOpen, isTrue);
    });

    test('keeps prices under 10 as-is (already in pounds)', () {
      final stations = parse([
        {
          'site_id': 1,
          'site_name': 'Already pounds',
          'brand': 'Shell',
          'location': {'latitude': 51.5, 'longitude': -0.12},
          'prices': {'E10': 1.459, 'B7': 1.529},
        },
      ]);

      expect(stations.first.e10, 1.459);
      expect(stations.first.diesel, 1.529);
    });

    test('supports alternate field names (lat/lng, unleaded, super_unleaded)',
        () {
      final stations = parse(
        [
          {
            'site_id': 'SITE42',
            'site_name': 'Tesco Extra',
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
              'super_unleaded': 158.9,
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
      expect(s.e98, closeTo(1.589, 0.0001));
    });

    test('skips stations with missing coordinates', () {
      final stations = parse([
        {'site_id': 1, 'site_name': 'No coords', 'prices': <String, dynamic>{}},
        {
          'site_id': 2,
          'site_name': 'With coords',
          'location': {'latitude': 51.5, 'longitude': -0.12},
          'prices': <String, dynamic>{},
        },
      ]);
      expect(stations, hasLength(1));
      expect(stations.first.name, 'With coords');
    });

    test('sorts stations by distance ascending', () {
      final stations = parse([
        {
          'site_id': 'FAR',
          'site_name': 'Far',
          'location': {'latitude': 51.52, 'longitude': -0.12},
          'prices': <String, dynamic>{},
        },
        {
          'site_id': 'NEAR',
          'site_name': 'Near',
          'location': {'latitude': 51.5001, 'longitude': -0.12},
          'prices': <String, dynamic>{},
        },
      ]);
      expect(stations, hasLength(2));
      expect(stations.first.name, 'Near');
      expect(stations.last.name, 'Far');
    });

    test('caps results at 50 stations', () {
      final list = List<Map<String, dynamic>>.generate(
        120,
        (i) => {
          'site_id': 'S$i',
          'site_name': 'S$i',
          'location': {'latitude': 51.5 + i * 0.0001, 'longitude': -0.12},
          'prices': <String, dynamic>{},
        },
      );

      final stations = parse(list, radiusKm: 500);
      expect(stations.length, 50);
    });

    test('dedupes by site_id within a single payload', () {
      final stations = parse([
        {
          'site_id': 'DUP',
          'site_name': 'First',
          'location': {'latitude': 51.5, 'longitude': -0.12},
          'prices': <String, dynamic>{},
        },
        {
          'site_id': 'DUP',
          'site_name': 'Second',
          'location': {'latitude': 51.5, 'longitude': -0.12},
          'prices': <String, dynamic>{},
        },
      ]);
      expect(stations, hasLength(1));
      expect(stations.first.name, 'First');
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
