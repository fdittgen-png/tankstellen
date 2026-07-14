// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3549 — the SELF-PUBLISHED Greek price source pinned by a REAL run of
// the publisher pipeline.
//
// `test/fixtures/gr_selfpublished_latest.json` is the actual output of
// `tool/gr_fuel/publish_gr_fuel.py` run 2026-07-14 against the live
// ministry bulletins (306 rows: 51 prefectures × 6 business days,
// 2026-07-08 … 2026-07-13). Its 2026-07-13 rows were verified EQUAL to
// the emvouvakis mirror's rows for the same day (51/51 prefectures, all
// four fuel columns) — the shape-parity contract that lets
// [GreeceStationService] consume both sources through one codec.
//
// These tests drive the REAL service:
//  * primary path — the self-published body parses to virtual stations
//    with NO mirror request at all;
//  * staleness gate — an asset whose newest DATE predates the lookback
//    window is rejected and the mirror takes over.

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/search_params.dart';
import 'package:tankstellen/features/station_services/greece/greece_station_service.dart';

/// Serves [selfPublishedBody] for `latest.json` and [mirrorBody] for
/// `/data`, recording every request.
class _TwoSourceAdapter implements HttpClientAdapter {
  _TwoSourceAdapter({required this.selfPublishedBody, this.mirrorBody});
  final String selfPublishedBody;
  final String? mirrorBody;
  final List<Uri> requestedUris = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestedUris.add(options.uri);
    if (options.uri.path.endsWith('latest.json')) {
      return ResponseBody.fromString(selfPublishedBody, 200, headers: {
        'content-type': ['application/json'],
      });
    }
    final mirror = mirrorBody;
    if (options.uri.path.endsWith('/data') && mirror != null) {
      return ResponseBody.fromString(mirror, 200, headers: {
        'content-type': ['application/json'],
      });
    }
    throw DioException(
      requestOptions: options,
      type: DioExceptionType.unknown,
      error: 'unexpected route ${options.uri.path}',
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  final selfPublishedBody =
      File('test/fixtures/gr_selfpublished_latest.json').readAsStringSync();
  final mirrorBody =
      File('test/fixtures/gr_emvouvakis_v2_data_day.json').readAsStringSync();

  GreeceStationService service(_TwoSourceAdapter adapter, DateTime now) =>
      GreeceStationService(
        dio: Dio()..httpClientAdapter = adapter,
        selfPublishedUrl: 'https://releases.example/fuel-gr/latest.json',
        baseUrl: 'https://mirror.example/v2',
        apiKey: 'test-key',
        now: () => now,
      );

  group('self-published primary (#3549)', () {
    test('fresh asset parses to virtual stations with ZERO mirror requests',
        () async {
      final adapter = _TwoSourceAdapter(selfPublishedBody: selfPublishedBody);
      final result = await service(adapter, DateTime(2026, 7, 14))
          .searchStations(
              const SearchParams(lat: 37.9838, lng: 23.7275, radiusKm: 25));

      expect(adapter.requestedUris, hasLength(1),
          reason: 'a fresh self-published asset must satisfy the search '
              'without touching the mirror');
      expect(adapter.requestedUris.single.path, endsWith('latest.json'));

      final attica = result.data.single;
      expect(attica.id, 'gr-attica');
      // The newest self-published day (2026-07-13, verified equal to the
      // ministry bulletin) wins over the five older days in the asset.
      expect(attica.updatedAt, '2026-07-13');
      expect(attica.e5, 1.956, reason: 'UNLEADED_95_Octane → e5');
      expect(attica.diesel, 1.839, reason: 'AUTOMOTIVE_DIESEL → diesel');
    });

    test('every kGreekPrefectures REGION code occurs in the publisher output',
        () {
      final regions = (jsonDecode(selfPublishedBody) as List)
          .map((r) => (r as Map)['REGION'].toString())
          .toSet();
      for (final apiName in const [
        'N. ATHINON', 'N. THESSALONIKIS', 'N. ACHAIAS', 'N. LARISAS',
        'N. IRAKLIOU', 'N. IOANNINON', 'N. DODEKANISON', 'N. CHANION',
      ]) {
        expect(regions, contains(apiName),
            reason: 'publisher REGION mapping must cover $apiName');
      }
    });

    test('a STALE asset is rejected and the mirror takes over', () async {
      final adapter = _TwoSourceAdapter(
        selfPublishedBody: selfPublishedBody,
        mirrorBody: mirrorBody,
      );
      // Far future: every self-published DATE predates the 7-day lookback
      // — the freshness gate must fall through to the mirror. (The mirror
      // fixture is equally old, but the mirror path trusts its ranged
      // query; only the self-published side carries the staleness gate.)
      final result = await service(adapter, DateTime(2027, 1, 10))
          .searchStations(
              const SearchParams(lat: 37.9838, lng: 23.7275, radiusKm: 25));

      expect(adapter.requestedUris, hasLength(2));
      expect(adapter.requestedUris.first.path, endsWith('latest.json'));
      expect(adapter.requestedUris[1].path, endsWith('/data'),
          reason: 'stale self-published rows must not silently serve — '
              'the mirror is the fallback');
      expect(result.data.single.updatedAt, '2026-07-09',
          reason: 'the served prices come from the mirror fixture');
    });
  });
}
