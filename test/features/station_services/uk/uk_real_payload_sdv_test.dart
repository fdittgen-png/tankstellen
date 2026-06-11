// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3191 — UK SDV premium diesel + Shell feed + real-schema name fallback,
// driven by a RECORDED REAL ASDA CMA feed slice
// (test/fixtures/uk_asda_cma_slice.json, captured 2026-06-10 from
// storelocator.asda.com — Manchester area, incl. SDV-bearing stations).
//
// The CMA schema's premium diesel key is `SDV`; the old parser mapped the
// NON-EXISTENT `super_unleaded` / `E5_97` keys to e98 and dropped SDV
// entirely. The old tests fed a `site_name` field the schema doesn't have —
// false-green (the #2776 lesson): these tests run the REAL service over the
// recorded payload, where the name falls back to the brand.

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/search_params.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/features/station_services/uk/uk_station_service.dart';
import '../../../helpers/silence_error_logger.dart';

const _asdaUrl = 'https://storelocator.asda.com/fuel_prices_data.json';

/// Serves [body] for [_asdaUrl] with the given content type (the Shell feed's
/// Azure blob answers `application/octet-stream`, not `application/json`).
class _OneFeedAdapter implements HttpClientAdapter {
  _OneFeedAdapter(this.body, {this.contentType = 'application/json'});
  final String body;
  final String contentType;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async =>
      ResponseBody.fromString(body, 200, headers: {
        Headers.contentTypeHeader: [contentType],
      });

  @override
  void close({bool force = false}) {}
}

Future<List<Station>> _search(String body, {String contentType = 'application/json'}) async {
  final dio = Dio()
    ..httpClientAdapter = _OneFeedAdapter(body, contentType: contentType);
  final service = UkStationService(dio: dio, feedUrls: const [_asdaUrl]);
  final result = await service.searchStations(
    // Manchester — the recorded slice's home.
    const SearchParams(lat: 53.48, lng: -2.24, radiusKm: 15),
  );
  return result.data;
}

void main() {
  silenceErrorLoggerSpool();
  late String fixture;

  setUpAll(() {
    fixture =
        File('test/fixtures/uk_asda_cma_slice.json').readAsStringSync();
  });

  group('UK SDV premium diesel from the real CMA payload (#3191)', () {
    test('SDV lands in dieselPremium', () async {
      final stations = await _search(fixture);
      // gcw2m4fevefe: E10 163.9, E5 182.9, B7 189.9, SDV 208.9 (pence).
      final s = stations.singleWhere((s) => s.id == 'uk-gcw2m4fevefe');
      expect(s.dieselPremium, closeTo(2.089, 0.0001),
          reason: 'SDV is the CMA premium-diesel key; the old parser '
              'dropped it');
      expect(s.diesel, closeTo(1.899, 0.0001));
      expect(s.e5, closeTo(1.829, 0.0001));
      expect(s.e10, closeTo(1.639, 0.0001));
    });

    test('stations without SDV keep dieselPremium null', () async {
      final stations = await _search(fixture);
      final s = stations.singleWhere((s) => s.id == 'uk-gcw2q069jsyn');
      expect(s.dieselPremium, isNull);
      expect(s.diesel, closeTo(1.797, 0.0001));
    });

    test('no CMA feed carries a premium petrol key — e98 stays null',
        () async {
      // The old parser read `super_unleaded` / `E5_97`, keys NO CMA feed
      // publishes; this pins that nothing leaks into e98 from a real payload.
      final stations = await _search(fixture);
      expect(stations, hasLength(6));
      for (final s in stations) {
        expect(s.e98, isNull, reason: s.id);
      }
    });
  });

  group('UK real-schema name fallback (#3191)', () {
    test('the CMA schema has no site_name — name falls back to brand',
        () async {
      final stations = await _search(fixture);
      for (final s in stations) {
        expect(s.name, s.brand,
            reason: '${s.id}: the real payload carries only `brand`');
        // The recorded ASDA feed mixes Asda- and Esso-branded forecourts.
        expect(s.brand, isIn(['Asda', 'Esso']));
        expect(s.name, isNotEmpty);
      }
    });
  });

  group('UK Shell feed (#3191)', () {
    test('the Shell page URL is in the default CMA feed list', () {
      expect(
        UkStationService.defaultCmaFeedUrls,
        contains('https://www.shell.co.uk/fuel-prices-data.html'),
      );
    });

    test(
        'a feed served as application/octet-stream still parses (the Shell '
        'Azure blob does not declare application/json)', () async {
      final stations =
          await _search(fixture, contentType: 'application/octet-stream');
      expect(stations, hasLength(6),
          reason: 'Dio only auto-decodes JSON mime types; the service must '
              'decode a String body itself');
    });
  });
}
