// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3196 (SI) — surface the goriva.si `open_hours` text, driven by a
// RECORDED REAL search slice (test/fixtures/si_goriva_search_slice.json,
// captured 2026-06-10 around Ljubljana). The parser used to drop the field
// entirely while hard-coding `isOpen: true`.

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/search_params.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/features/station_services/slovenia/slovenia_station_service.dart';

class _FixtureAdapter implements HttpClientAdapter {
  _FixtureAdapter(this.body);
  final String body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async =>
      ResponseBody.fromString(body, 200, headers: {
        Headers.contentTypeHeader: ['application/json'],
      });

  @override
  void close({bool force = false}) {}
}

void main() {
  late List<Station> stations;

  setUpAll(() async {
    final fixture =
        File('test/fixtures/si_goriva_search_slice.json').readAsStringSync();
    final dio = Dio()..httpClientAdapter = _FixtureAdapter(fixture);
    final service = SloveniaStationService(dio: dio);
    final result = await service.searchStations(
      // Ljubljana centre — where the slice was recorded.
      const SearchParams(lat: 46.0569, lng: 14.5058, radiusKm: 10),
    );
    stations = result.data;
  });

  Station byId(String id) => stations.singleWhere((s) => s.id == id);

  group('SI open_hours surfaced as openingHoursText (#3196)', () {
    test('a 24h site carries its hours text and is flagged is24h', () {
      final s = byId('si-2048');
      expect(s.openingHoursText, '00:00-23:59');
      expect(s.is24h, isTrue);
    });

    test('a single daily range is carried verbatim', () {
      final s = byId('si-2049');
      expect(s.openingHoursText, '06:00-22:00');
      expect(s.is24h, isFalse);
    });

    test('a per-day-group block flattens to one line', () {
      final s = byId('si-2056');
      expect(
        s.openingHoursText,
        'Ponedeljek, Torek, Sreda, Četrtek, Petek 06:00-22:00; '
        'Sobota 07:00-21:00; '
        'Nedelja, Praznik 07:00-21:00',
      );
      expect(s.is24h, isFalse);
    });

    test('prices still parse alongside the hours', () {
      final s = byId('si-2048');
      expect(s.e5, isNotNull);
      expect(s.diesel, isNotNull);
    });
  });
}
