// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3539 — Greece pinned by a REAL recorded API response.
//
// `test/fixtures/gr_emvouvakis_v2_data_day.json` is a live capture of the
// emvouvakis FuelPricesGreeceAPI mirror's `GET /data` endpoint (recorded
// 2026-07-11): 51 rows, one per prefecture, DATE 2026-07-09 — the latest
// official Paratiritirio Timon bulletin at recording time. Fixture tests
// drive the REAL parser with the REAL upstream shape (never fakes that
// echo the request) so a column rename / REGION-code drift at upstream
// goes RED here first.
//
// Two layers:
//  * the full fetch→parse→virtual-station path through the REAL
//    [GreeceStationService.searchStations] behind a Dio adapter that
//    replays the recorded body, and
//  * [parsePrefectureResponse] driven directly with the recorded list —
//    including the proof that every [kGreekPrefectures] REGION code
//    actually occurs in the real feed.

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/search_params.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/features/station_services/greece/greece_prefectures.dart';
import 'package:tankstellen/features/station_services/greece/greece_station_service.dart';

/// Answers the single ranged `/data` request with the recorded body.
class _RecordedDataAdapter implements HttpClientAdapter {
  _RecordedDataAdapter(this.body);
  final String body;
  final List<Uri> requestedUris = [];
  final List<Map<String, dynamic>> requestedHeaders = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestedUris.add(options.uri);
    requestedHeaders.add(Map<String, dynamic>.from(options.headers));
    if (!options.uri.path.endsWith('/data')) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.unknown,
        error: 'unexpected route ${options.uri.path}',
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
  final fixtureBody =
      File('test/fixtures/gr_emvouvakis_v2_data_day.json').readAsStringSync();
  final recordedRows = jsonDecode(fixtureBody) as List<dynamic>;

  group(
      'recorded /data day through the REAL service '
      '(fetch→parse→virtual station, #3539)', () {
    late List<Station> stations;
    late _RecordedDataAdapter adapter;

    setUpAll(() async {
      adapter = _RecordedDataAdapter(fixtureBody);
      final dio = Dio()..httpClientAdapter = adapter;
      final service = GreeceStationService(
        dio: dio,
        baseUrl: 'https://self-hosted.example/api',
        apiKey: 'recorded-key',
        now: () => DateTime(2026, 7, 11),
      );
      final result = await service.searchStations(
        // Athens city centre — resolves to N. ATHINON.
        const SearchParams(lat: 37.9838, lng: 23.7275, radiusKm: 25),
      );
      stations = result.data;
    });

    test('exactly ONE ranged /data request with the x-api-key header', () {
      expect(adapter.requestedUris, hasLength(1));
      final uri = adapter.requestedUris.single;
      expect(uri.path, endsWith('/data'));
      expect(uri.queryParameters['start_date'], '2026-07-04');
      expect(uri.queryParameters['end_date'], '2026-07-11');
      expect(uri.queryParameters['offset'], '0');
      expect(adapter.requestedHeaders.single['x-api-key'], 'recorded-key');
    });

    test('the recorded row list parses to the Attica virtual station', () {
      expect(stations, hasLength(1),
          reason: 'Only Attica survives the 25 km radius filter.');
      final attica = stations.single;
      expect(attica.id, 'gr-attica');
      expect(attica.brand, 'Paratiritirio');
    });

    test('the recorded N. ATHINON columns map onto the fuel slots', () {
      final attica = stations.single;
      expect(attica.e5, 1.943, reason: 'UNLEADED_95_Octane → e5');
      expect(attica.e98, 2.16, reason: 'UNLEADED_100_OCTANE → e98');
      expect(attica.diesel, 1.787, reason: 'AUTOMOTIVE_DIESEL → diesel');
      expect(attica.lpg, 0.907, reason: 'AUTOGAS → lpg');
      expect(attica.updatedAt, '2026-07-09',
          reason: 'updatedAt is stamped from the row DATE');
    });

    test('prefecture granularity: no open/closed notion (#3198)', () {
      expect(stations.single.isOpen, isNull);
    });
  });

  group('parsePrefectureResponse against the recorded list (#3539)', () {
    final service = GreeceStationService(
      dio: Dio(),
      baseUrl: 'https://unused.example',
    );

    Station? parseFor(GreekPrefecture pref) => service.parsePrefectureResponse(
          recordedRows,
          regionKey: pref.apiName,
          stationId: pref.id,
          displayName: pref.displayName,
          place: pref.place,
          prefectureLat: pref.lat,
          prefectureLng: pref.lng,
          fromLat: pref.lat,
          fromLng: pref.lng,
        );

    test('the Athens row parses to all four fuels at the recorded values',
        () {
      final attica =
          parseFor(kGreekPrefectures.firstWhere((p) => p.id == 'gr-attica'));
      expect(attica, isNotNull);
      expect(attica!.e5, 1.943);
      expect(attica.e98, 2.16);
      expect(attica.diesel, 1.787);
      expect(attica.lpg, 0.907);
      expect(attica.updatedAt, '2026-07-09');
      expect(attica.isOpen, isNull);
    });

    test('a REGION key absent from the recorded feed → null', () {
      final s = service.parsePrefectureResponse(
        recordedRows,
        regionKey: 'N. ATLANTIS',
        stationId: 'gr-atlantis',
        displayName: 'Atlantis',
        place: 'Atlantis',
        prefectureLat: 36.0,
        prefectureLng: 25.0,
        fromLat: 36.0,
        fromLng: 25.0,
      );
      expect(s, isNull);
    });

    test('every kGreekPrefectures REGION code finds a row in the real feed '
        '(mapping table matches reality)', () {
      for (final pref in kGreekPrefectures) {
        final s = parseFor(pref);
        expect(s, isNotNull,
            reason: '${pref.apiName} has no row in the recorded /data '
                'response — the REGION code table has drifted from the '
                'real API.');
        expect(s!.id, pref.id);
      }
    });
  });
}
