// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3189 — ES e85 / isOpen / Margen fixes, driven by RECORDED REAL MITECO
// payloads:
//   - test/fixtures/miteco_santiago_15.json (captured 2026-06-10) carries the
//     one live station selling E85 — its price lives in 'Precio Bioetanol'
//     (the row's '% BioEtanol' is '85,0') while the 'Precio Gasolina 95 E85'
//     column the old parser read is EMPTY for it.
//   - isOpen used to be horario-string-non-empty, so a "L-V: 06:00-23:00"
//     station showed open at 3 AM; it is now computed from the parsed
//     [WeeklyOpeningHours] via an injectable clock.
//   - MITECO 'Margen' (D/I/N: road side) was stuffed into `stationType`,
//     whose contract is R/A — it is no longer mapped.

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/search/data/models/search_params.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';
import 'package:tankstellen/features/station_services/spain/miteco_station_service.dart';

import '../support/real_service_search.dart';

Future<List<Station>> _searchSantiago(
  String fixture, {
  required DateTime now,
}) async {
  final dio = Dio()..httpClientAdapter = FixedJsonAdapter(fixture);
  final service = MitecoStationService(dio: dio, now: () => now);
  final result = await service.searchStations(
    // Santiago de Compostela — the recorded slice's home.
    const SearchParams(lat: 42.918, lng: -8.527, radiusKm: 25),
  );
  return result.data;
}

void main() {
  late String fixture;

  setUpAll(() {
    fixture =
        File('test/fixtures/miteco_santiago_15.json').readAsStringSync();
  });

  // A Wednesday at 10:00 — inside every recorded schedule.
  final wedMorning = DateTime(2026, 6, 10, 10, 0);
  // A Wednesday at 03:00 — outside L-V: 06:00-23:00 and L-D: 07:00-23:00.
  final wedNight = DateTime(2026, 6, 10, 3, 0);

  group('ES e85 from Precio Bioetanol (#3189)', () {
    test('the recorded STAROIL E85 station surfaces its Bioetanol price',
        () async {
      final stations = await _searchSantiago(fixture, now: wedMorning);
      final s = stations.singleWhere((s) => s.id == 'es-9699');
      expect(s.e85, closeTo(2.399, 0.0001),
          reason: "E85 lives in 'Precio Bioetanol'; the old parser read the "
              "empty 'Precio Gasolina 95 E85' column and dropped it");
      expect(s.e5, closeTo(1.529, 0.0001));
      expect(s.diesel, closeTo(1.588, 0.0001));
    });

    test("the legacy 'Precio Gasolina 95 E85' column still works as fallback",
        () async {
      // A couple of live stations still populate the old column — keep them.
      final stations = await searchMitecoStations([
        {
          'IDEESS': '2035',
          'Rótulo': 'PETROMIRALLES',
          'Dirección': 'CTRA',
          'Localidad': 'IGUALADA',
          'C.P.': '08700',
          'Latitud': '40,42',
          'Longitud (WGS84)': '-3,70',
          'Precio Gasolina 95 E85': '1,850',
          'Horario': 'L-D: 24H',
        },
      ]);
      expect(stations.singleWhere((s) => s.id == 'es-2035').e85,
          closeTo(1.850, 0.0001));
    });
  });

  group('ES isOpen from parsed weekly hours (#3189)', () {
    test('a L-V: 06:00-23:00 station is CLOSED at 3 AM', () async {
      final stations = await _searchSantiago(fixture, now: wedNight);
      final staroil = stations.singleWhere((s) => s.id == 'es-9699');
      expect(staroil.isOpen, isFalse,
          reason: 'the old heuristic returned true for ANY non-empty '
              'horario');
      final repsol = stations.singleWhere((s) => s.id == 'es-593');
      expect(repsol.isOpen, isFalse,
          reason: 'L-D: 07:00-23:00 is closed at 03:00 too');
    });

    test('the same stations are OPEN mid-morning', () async {
      final stations = await _searchSantiago(fixture, now: wedMorning);
      expect(stations.singleWhere((s) => s.id == 'es-9699').isOpen, isTrue);
      expect(stations.singleWhere((s) => s.id == 'es-593').isOpen, isTrue);
    });

    test('a L-D: 24H station is open around the clock', () async {
      final stations = await _searchSantiago(fixture, now: wedNight);
      expect(stations.singleWhere((s) => s.id == 'es-12616').isOpen, isTrue);
    });

    test('an empty horario is honest unknown, not closed (#3198)',
        () async {
      final stations = await searchMitecoStations([
        {
          'IDEESS': '77',
          'Rótulo': 'NOHOURS',
          'Dirección': 'St',
          'Localidad': 'MADRID',
          'C.P.': '28001',
          'Latitud': '40,42',
          'Longitud (WGS84)': '-3,70',
          'Precio Gasolina 95 E5': '1,5',
          'Horario': '',
        },
      ]);
      expect(stations.singleWhere((s) => s.id == 'es-77').isOpen, isNull,
          reason: 'no hours data is unknown — neither open nor closed');
    });
  });

  group('ES Margen no longer leaks into stationType (#3189)', () {
    test('recorded D/I/N Margen values all map to a null stationType',
        () async {
      final stations = await _searchSantiago(fixture, now: wedMorning);
      expect(stations, hasLength(3));
      for (final s in stations) {
        expect(s.stationType, isNull,
            reason: '${s.id}: Margen (road side D/I/N) violates the '
                'stationType R/A contract and must not be mapped');
      }
    });
  });
}
