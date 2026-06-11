// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3197 — Mexico pinned by RECORDED live CRE payloads.
//
// Fixtures `test/fixtures/mx_cre_places_slice.xml` /
// `mx_cre_prices_slice.xml` were recorded 2026-06-11 from
// `https://publicacionexterna.azurewebsites.net/publicaciones/places` and
// `…/prices`, trimmed to 15 CDMX-area stations (matching place_ids in both
// feeds), structure untouched — see the comment header inside each file.
//
// These tests drive the REAL [MexicoStationService] over both XML feeds
// (the #2776 / feedback_fake_services_false_green lesson: the old
// synthetic `_placesXml()` builder emitted whatever shape the parser
// expected — it could never catch a real-feed drift like nested
// `<gas_price>` or a renamed attribute).

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/search/data/models/search_params.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';
import 'package:tankstellen/features/station_services/mexico/mexico_station_service.dart';

/// Routes the CRE `/places` and `/prices` endpoints to the recorded slices.
class _CreRouteAdapter implements HttpClientAdapter {
  _CreRouteAdapter({required this.placesXml, required this.pricesXml});
  final String placesXml;
  final String pricesXml;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.uri.path;
    final body = path.endsWith('/places')
        ? placesXml
        : path.endsWith('/prices')
            ? pricesXml
            : null;
    if (body == null) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.unknown,
        error: 'no recorded route for $path',
      );
    }
    return ResponseBody.fromString(body, 200, headers: {
      'content-type': ['application/xml; charset=utf-8'],
    });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late List<Station> stations;

  setUpAll(() async {
    final dio = Dio()
      ..httpClientAdapter = _CreRouteAdapter(
        placesXml: File('test/fixtures/mx_cre_places_slice.xml')
            .readAsStringSync(),
        pricesXml: File('test/fixtures/mx_cre_prices_slice.xml')
            .readAsStringSync(),
      );
    final service = MexicoStationService(dio: dio);
    final result = await service.searchStations(
      // CDMX centre — every recorded station sits within ~7 km.
      const SearchParams(lat: 19.43, lng: -99.13, radiusKm: 10),
    );
    stations = result.data;
  });

  Station byId(String id) => stations.firstWhere((s) => s.id == id);

  group('recorded CRE CDMX slice through the REAL service (#3197)', () {
    test('all 15 recorded place↔price pairs join by place_id', () {
      expect(stations, hasLength(15));
      expect(stations.map((s) => s.id), everyElement(startsWith('mx-')));
    });

    test('real grade mapping: regular→e5, premium→e98, diesel→diesel', () {
      // place_id 2807 carries all three grades in the recorded /prices feed.
      final s = byId('mx-2807');
      expect(s.e5, 23.99);
      expect(s.e98, 29.19);
      expect(s.diesel, 27);
    });

    test('a station the real feed prices without diesel keeps diesel null',
        () {
      // place_id 2267 (PETROMAX): regular + premium only — the recorded
      // feed proves diesel-less stations are common; nothing may invent one.
      final s = byId('mx-2267');
      expect(s.e5, 24.49);
      expect(s.e98, 29.69);
      expect(s.diesel, isNull);
    });

    test('the real <name> is the full company name and is never truncated '
        '(#2704)', () {
      final s = byId('mx-2267');
      expect(s.name, 'PETROMAX SA DE CV');
      // CRE publishes no brand/address — brand stays empty, name mirrors
      // into street so the card fallback renders the full name.
      expect(s.brand, isEmpty);
      expect(s.street, s.name);
    });

    test('x→lng / y→lat from the real <location> envelope', () {
      final s = byId('mx-2267');
      expect(s.lat, closeTo(19.47922, 1e-6));
      expect(s.lng, closeTo(-99.10912, 1e-6));
    });

    test('CRE publishes no open/closed signal — isOpen stays unknown (#3198)',
        () {
      expect(stations.map((s) => s.isOpen), everyElement(isNull));
    });
  });
}
