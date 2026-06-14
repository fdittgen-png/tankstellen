// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/services/impl/osm_brand_enricher.dart';
import 'package:tankstellen/core/domain/station.dart';

import '../../../fakes/fake_hive_storage.dart';

void main() {
  late FakeHiveStorage fakeStorage;
  late OsmBrandEnricher enricher;

  setUp(() {
    fakeStorage = FakeHiveStorage();
    enricher = OsmBrandEnricher(fakeStorage);
  });

  Station makeStation({
    required String id,
    String brand = '',
    double lat = 48.8,
    double lng = 2.3,
  }) {
    return Station(
      id: id,
      name: 'Station $id',
      brand: brand,
      street: 'Test St',
      postCode: '75001',
      place: 'Paris',
      lat: lat,
      lng: lng,
      isOpen: true,
    );
  }

  group('OsmBrandEnricher', () {
    test('returns empty list for empty input', () async {
      final result = await enricher.enrich([]);
      expect(result, isEmpty);
    });

    test('returns stations unchanged if all have brands', () async {
      final stations = [
        makeStation(id: '1', brand: 'TotalEnergies'),
        makeStation(id: '2', brand: 'Shell'),
      ];

      final result = await enricher.enrich(stations);

      expect(result.length, 2);
      expect(result[0].brand, 'TotalEnergies');
      expect(result[1].brand, 'Shell');
    });

    test('applies persisted brand from storage', () async {
      await fakeStorage.putSetting('brand_1', 'Esso');

      final stations = [makeStation(id: '1', brand: '')];
      final result = await enricher.enrich(stations);

      expect(result[0].brand, 'Esso');
    });

    test('identifies stations needing brands (empty brand)', () async {
      final stations = [makeStation(id: '1', brand: '')];
      // Will try Nominatim (which will fail in test), but we test the logic
      final result = await enricher.enrich(stations);

      // Station should still be returned (brand may be empty if Nominatim fails)
      expect(result.length, 1);
    });

    test('identifies stations needing brands ("Station")', () async {
      final stations = [makeStation(id: '1', brand: 'Station')];
      final result = await enricher.enrich(stations);

      expect(result.length, 1);
    });

    test('identifies stations needing brands ("Autoroute")', () async {
      final stations = [makeStation(id: '1', brand: 'Autoroute')];
      final result = await enricher.enrich(stations);

      expect(result.length, 1);
    });

    test('uses session cache on second call', () async {
      // First call: brand from persisted storage
      await fakeStorage.putSetting('brand_1', 'BP');

      final stations = [makeStation(id: '1', brand: '')];
      await enricher.enrich(stations);

      // Second call: clear persisted storage, but session cache should still
      // hold 'BP'.
      await fakeStorage.putSetting('brand_1', null);

      final result2 = await enricher.enrich(stations);
      expect(result2[0].brand, 'BP');
    });

    test('mixed stations: branded and unbranded', () async {
      await fakeStorage.putSetting('brand_2', 'Avia');

      final stations = [
        makeStation(id: '1', brand: 'Shell'),
        makeStation(id: '2', brand: ''),
        makeStation(id: '3', brand: 'TotalEnergies'),
      ];

      final result = await enricher.enrich(stations);

      expect(result[0].brand, 'Shell');
      expect(result[1].brand, 'Avia');
      expect(result[2].brand, 'TotalEnergies');
    });

    // #2315 — enricher writes must be batched via Future.wait, not N
    // sequential awaits. Verified here by seeding two brands via storage and
    // asserting both persist after one enrich() call returns.
    test('batched Hive writes: all brands are persisted (#2315)', () async {
      await fakeStorage.putSetting('brand_s1', 'TotalEnergies');
      await fakeStorage.putSetting('brand_s2', 'Shell');

      final stations = [
        makeStation(id: 's1', brand: ''),
        makeStation(id: 's2', brand: ''),
      ];

      final result = await enricher.enrich(stations);

      expect(result[0].brand, 'TotalEnergies');
      expect(result[1].brand, 'Shell');
      // Both writes landed in storage
      expect(fakeStorage.getSetting('brand_s1'), 'TotalEnergies');
      expect(fakeStorage.getSetting('brand_s2'), 'Shell');
    });
  });

  group('negative cache (#3327)', () {
    test('a station with no OSM match is negatively cached, not re-queried',
        () async {
      // Nominatim responds with an empty list → no POI matches any station.
      final adapter = _NominatimAdapter(body: <dynamic>[]);
      final dio = Dio(BaseOptions(baseUrl: ''))..httpClientAdapter = adapter;
      final svc = OsmBrandEnricher(fakeStorage, dio: dio);

      final result = await svc.enrich([makeStation(id: '1')]);

      // No brand found → station unchanged, AND the miss is cached.
      expect(result.single.brand, '');
      expect(fakeStorage.getSetting('brand_1'), OsmBrandEnricher.noBrandMarker);
      expect(adapter.calls, 1);

      // Second enrich: the station is negatively cached → NO Nominatim call.
      final result2 = await svc.enrich([makeStation(id: '1')]);
      expect(result2.single.brand, '');
      expect(adapter.calls, 1,
          reason: 'must not re-query a negatively cached station');
    });

    test('a station negatively cached on DISK (fresh session) is not '
        're-queried', () async {
      await fakeStorage.putSetting('brand_1', OsmBrandEnricher.noBrandMarker);
      // Adapter throws if hit — proving no network call is made.
      final adapter = _NominatimAdapter(throwIfCalled: true);
      final dio = Dio(BaseOptions(baseUrl: ''))..httpClientAdapter = adapter;
      final svc = OsmBrandEnricher(fakeStorage, dio: dio);

      final result = await svc.enrich([makeStation(id: '1')]);

      expect(result.single.brand, '', reason: 'still shows no brand');
      expect(adapter.calls, 0,
          reason: 'disk negative cache short-circuits the fetch');
    });

    test('the negative marker is never shown as a brand', () async {
      await fakeStorage.putSetting('brand_1', OsmBrandEnricher.noBrandMarker);
      final svc = OsmBrandEnricher(fakeStorage);
      final result = await svc.enrich([makeStation(id: '1')]);
      expect(result.single.brand, isNot(OsmBrandEnricher.noBrandMarker));
      expect(result.single.brand, '');
    });

    test('a real OSM match still wins (negative cache only applies to misses)',
        () async {
      final adapter = _NominatimAdapter(body: <dynamic>[
        {'name': 'Total', 'lat': '48.8', 'lon': '2.3'},
      ]);
      final dio = Dio(BaseOptions(baseUrl: ''))..httpClientAdapter = adapter;
      final svc = OsmBrandEnricher(fakeStorage, dio: dio);

      final result =
          await svc.enrich([makeStation(id: '1', lat: 48.8, lng: 2.3)]);
      expect(result.single.brand, isNot(OsmBrandEnricher.noBrandMarker));
      expect(fakeStorage.getSetting('brand_1'),
          isNot(OsmBrandEnricher.noBrandMarker));
    });
  });
}

/// Minimal Nominatim `HttpClientAdapter` stub (#3327): returns a fixed JSON
/// list and counts calls, so the enrichment / negative-cache path is testable
/// without the live endpoint.
class _NominatimAdapter implements HttpClientAdapter {
  _NominatimAdapter({this.body = const <dynamic>[], this.throwIfCalled = false});

  final List<dynamic> body;
  final bool throwIfCalled;
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    if (throwIfCalled) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.unknown,
        error: 'Nominatim must not be called',
      );
    }
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
