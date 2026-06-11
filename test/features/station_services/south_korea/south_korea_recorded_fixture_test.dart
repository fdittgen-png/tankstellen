// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3197 — South Korea pinned by an EVIDENCE-BASED fixture (NOT
// live-recorded): OPINET requires a per-user API key this project does
// not carry, so the `aroundAll.do` response cannot be recorded from this
// environment. `test/fixtures/kr_opinet_around_all_slice.json` is
// constructed strictly from documented evidence:
//  - the `RESULT.OIL[]` envelope + field names (UNI_ID / POLL_DIV_CD /
//    OS_NM / NEW_ADR / GIS_X_COOR / GIS_Y_COOR / PRICE / DISTANCE, all
//    string-typed) per the OPINET developer-portal contract captured in
//    the [SouthKoreaStationService] doc comment (#597/#3176);
//  - KATEC-metre coordinates (#3192): the A0010684 pair is the
//    PROJ-9-derived KATEC projection of WGS84 (37.4997, 127.0287) near
//    Gangnam recorded 2026-06-10 in `katec_converter_test.dart`; the
//    A0001234 pair is offset a few hundred metres on the same grid.
// One top-level key per `prodcd` (B027/B034/D047/K015); each value is one
// response body in the real envelope shape. No fields the real API does
// not send were invented. Replace with a live capture if a key lands.
//
// The tests drive the REAL [SouthKoreaStationService.searchStations] —
// all four product calls, the UNI_ID merge, and the KATEC→WGS84
// conversion run for real.

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/search/data/models/search_params.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';
import 'package:tankstellen/features/station_services/south_korea/south_korea_station_service.dart';

/// Answers each `aroundAll.do` call with the body recorded for its
/// `prodcd` query parameter.
class _ProdcdAdapter implements HttpClientAdapter {
  _ProdcdAdapter(this.bodyByProdcd);
  final Map<String, String> bodyByProdcd;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final prodcd = options.uri.queryParameters['prodcd'];
    final body = bodyByProdcd[prodcd];
    if (body == null) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.unknown,
        error: 'no fixture body for prodcd=$prodcd',
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

  setUpAll(() async {
    final slices = jsonDecode(
      File('test/fixtures/kr_opinet_around_all_slice.json')
          .readAsStringSync(),
    ) as Map<String, dynamic>;
    final dio = Dio()
      ..httpClientAdapter = _ProdcdAdapter({
        for (final e in slices.entries) e.key: jsonEncode(e.value),
      });
    final service = SouthKoreaStationService(apiKey: 'test-key', dio: dio);
    final result = await service.searchStations(
      // Gangnam — the WGS84 origin of the fixture's KATEC pair.
      const SearchParams(lat: 37.4997, lng: 127.0287, radiusKm: 5),
    );
    stations = result.data;
  });

  Station byId(String id) => stations.firstWhere((s) => s.id == id);

  group(
      'evidence-based OPINET aroundAll slice through the REAL service '
      '(#3197)', () {
    test('the four product calls merge by UNI_ID into 2 stations', () {
      expect(stations, hasLength(2));
      expect(stations.map((s) => s.id),
          containsAll(['kr-A0010684', 'kr-A0001234']));
    });

    test('per-product prices land in the right slots (KRW int strings)', () {
      final ske = byId('kr-A0010684');
      expect(ske.e5, 1689, reason: 'B027 gasoline → e5');
      expect(ske.e98, 1985, reason: 'B034 premium → e98');
      expect(ske.diesel, 1589, reason: 'D047 diesel → diesel');
      expect(ske.lpg, isNull, reason: 'no K015 row for this station');

      final gsc = byId('kr-A0001234');
      expect(gsc.e5, 1705);
      expect(gsc.e98, isNull, reason: 'no B034 row for this station');
      expect(gsc.diesel, 1612);
      expect(gsc.lpg, 1045, reason: 'K015 LPG → lpg');
    });

    test('KATEC metre coordinates convert back to WGS84 (#3192)', () {
      // GIS_X/Y_COOR are 6-digit KATEC metres in the fixture — exactly
      // what put every station ~400 km off when parsed as degrees.
      final ske = byId('kr-A0010684');
      expect(ske.lat, closeTo(37.4997, 1e-4));
      expect(ske.lng, closeTo(127.0287, 1e-4));
      final gsc = byId('kr-A0001234');
      expect(gsc.lat, inInclusiveRange(37.4, 37.6));
      expect(gsc.lng, inInclusiveRange(126.9, 127.1));
    });

    test('name/brand/address map from the documented fields', () {
      final ske = byId('kr-A0010684');
      expect(ske.name, 'SK에너지 강남주유소');
      expect(ske.brand, 'SK에너지', reason: 'POLL_DIV_CD SKE');
      expect(ske.street, '서울특별시 강남구 테헤란로 152');
      final gsc = byId('kr-A0001234');
      expect(gsc.brand, 'GS칼텍스', reason: 'POLL_DIV_CD GSC');
    });

    test('DISTANCE metres become km; isOpen stays honest unknown (#3198)',
        () {
      expect(byId('kr-A0010684').dist, 0.4);
      expect(byId('kr-A0001234').dist, 0.9);
      expect(stations.map((s) => s.isOpen), everyElement(isNull));
    });
  });
}
