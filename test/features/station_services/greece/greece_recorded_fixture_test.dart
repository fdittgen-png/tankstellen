// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3197 — Greece pinned by an EVIDENCE-BASED fixture (NOT live-recorded).
//
// The default host (`fuelpricesgr.com`) is NXDOMAIN (#3194, live-verified
// 2026-06-10) and the upstream community wrapper
// (github.com/mavroprovato/fuelpricesgr) has no public deployment — there
// is nothing to record. `test/fixtures/gr_fuelpricesgr_daily_prefecture_slice.json`
// is therefore constructed strictly from the documented evidence: the
// upstream FastAPI `PriceResponse` schema as captured in the
// [GreeceStationService] endpoint-contract doc comment (`date` +
// `data[{fuel_type, price}]`, fuel keys UNLEADED_95 / UNLEADED_100 /
// DIESEL / DIESEL_HEATING / GAS). No fields the real API does not send
// were invented. If a self-hosted deployment ever becomes recordable,
// replace this slice with a live capture.
//
// The tests drive the REAL [GreeceStationService.searchStations] with a
// self-hosted baseUrl (the #3194 short-circuit only guards the dead
// default host) — the full fetch→parse→virtual-station path runs.

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/search_params.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/features/station_services/greece/greece_station_service.dart';

/// Answers every `/data/daily/prefecture/{name}` route with the fixture.
class _PrefectureAdapter implements HttpClientAdapter {
  _PrefectureAdapter(this.body);
  final String body;
  final List<String> requestedPaths = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.uri.path;
    requestedPaths.add(path);
    if (!path.contains('/data/daily/prefecture/')) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.unknown,
        error: 'unexpected route $path',
      );
    }
    return ResponseBody.fromString(body, 200, headers: {
      'content-type': ['application/json'],
    });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late List<Station> stations;
  late _PrefectureAdapter adapter;

  setUpAll(() async {
    adapter = _PrefectureAdapter(
      File('test/fixtures/gr_fuelpricesgr_daily_prefecture_slice.json')
          .readAsStringSync(),
    );
    final dio = Dio()..httpClientAdapter = adapter;
    final service = GreeceStationService(
      dio: dio,
      baseUrl: 'https://self-hosted.example/api',
    );
    final result = await service.searchStations(
      // Athens city centre — resolves to the ATTICA prefecture.
      const SearchParams(lat: 37.9838, lng: 23.7275, radiusKm: 25),
    );
    stations = result.data;
  });

  group(
      'evidence-based Paratiritirio daily slice through the REAL service '
      '(#3197)', () {
    test('the documented PriceResponse list parses to the virtual '
        'prefecture station', () {
      expect(stations, hasLength(1));
      final attica = stations.single;
      expect(attica.id, 'gr-attica');
      expect(attica.brand, 'Paratiritirio');
      // The service fans out to the 4 nearest prefectures; ATTICA must be
      // among them and is the only one whose virtual station survives the
      // 25 km radius filter.
      expect(adapter.requestedPaths, hasLength(4));
      expect(adapter.requestedPaths,
          contains(endsWith('/prefecture/ATTICA')));
    });

    test('observatory fuel keys map per the documented contract', () {
      final attica = stations.single;
      expect(attica.e5, 1.721, reason: 'UNLEADED_95 → e5');
      expect(attica.e98, 1.969, reason: 'UNLEADED_100 → e98');
      expect(attica.diesel, 1.528, reason: 'DIESEL → diesel');
      expect(attica.lpg, 0.978, reason: 'GAS (Υγραέριο) → lpg');
      // DIESEL_HEATING is in the fixture but is not a motoring fuel —
      // it must not leak into any slot (1.165 appears nowhere).
      for (final p in [attica.e5, attica.e98, attica.e10, attica.diesel]) {
        expect(p, isNot(1.165));
      }
    });

    test('the newest date entry wins and stamps updatedAt', () {
      // The fixture lists 2026-06-09 first and 2026-06-08 second; the
      // parser must pick by date, not by position.
      final attica = stations.single;
      expect(attica.updatedAt, '2026-06-09');
      expect(attica.e5, isNot(1.724), reason: 'older entry must not win');
    });

    test('prefecture granularity: no open/closed notion (#3198)', () {
      expect(stations.single.isOpen, isNull);
    });
  });
}
