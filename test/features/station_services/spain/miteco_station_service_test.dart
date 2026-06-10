// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #2780 (Epic #2776 D4) — every parse assertion here drives the REAL
// [MitecoStationService.searchStations] through a fixed Dio (see
// `support/real_service_search.dart`). It used to lean on a `_TestableMitecoParser`
// copy that re-implemented the parse but never set the structured
// `Station.openingHours` nor the `es-` id prefix — so it proved the *copy*, not
// the production path a real Spanish search tap takes (the #2776 false-green
// lesson). The new ES search-path opening-hours group is the regression guard
// the matrix lacked: Spain "works today" only incidentally, with NO test.

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/error/exceptions.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/services/station_service.dart';
import 'package:tankstellen/core/services/station_service_chain_codec.dart';
import 'package:tankstellen/features/station_detail/domain/opening_hours.dart';
import 'package:tankstellen/features/station_services/spain/miteco_station_service.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';

import '../support/real_service_search.dart';

/// A single realistic MITECO `ListaEESSPrecio` row (REPSOL Madrid, full fuel
/// slate, `L-D: 06:00-22:00` schedule) near the Madrid search centre.
Map<String, dynamic> repsolMadrid({
  String id = '1234',
  String horario = 'L-D: 06:00-22:00',
}) =>
    {
      'IDEESS': id,
      'Rótulo': 'REPSOL',
      'Dirección': 'CALLE MAYOR 1',
      'Localidad': 'MADRID',
      'C.P.': '28001',
      'Latitud': '40,416775',
      'Longitud (WGS84)': '-3,703790',
      'Precio Gasolina 95 E5': '1,649',
      'Precio Gasolina 95 E10': '1,599',
      'Precio Gasolina 98 E5': '1,829',
      'Precio Gasoleo A': '1,459',
      'Precio Gasoleo Premium': '1,529',
      'Precio Gasolina 95 E85': '1,099',
      'Precio Gases licuados del petróleo': '0,899',
      'Precio Gas Natural Comprimido': '1,199',
      'Horario': horario,
      'Margen': 'D',
    };

void main() {
  group('MitecoStationService contract', () {
    final service = MitecoStationService();

    test('implements StationService interface', () {
      expect(service, isA<StationService>());
    });

    test('getStationDetail throws ApiException mentioning MITECO', () async {
      expect(
        () => service.getStationDetail('es-123'),
        throwsA(isA<ApiException>()),
      );
      try {
        await service.getStationDetail('es-test');
        fail('Should have thrown');
      } on ApiException catch (e) {
        expect(e.message, contains('MITECO'));
      }
    });

    test('getPrices returns an empty map with MITECO metadata', () async {
      final result = await service.getPrices(['es-1', 'es-2']);
      expect(result.data, isEmpty);
      expect(result.source, ServiceSource.mitecoApi);
      expect(result.fetchedAt, isA<DateTime>());
      expect(result.isStale, isFalse);

      expect((await service.getPrices([])).data, isEmpty);
    });
  });

  // The headline #2780 coverage: Spain has structured opening hours in its
  // search payload, but no test ever proved they reach the screen on the
  // dominant tap. These drive the REAL search parse, then the two codecs a
  // real tap round-trips through.
  group('ES search-path opening hours (#2780)', () {
    test('REAL search parse populates structured Station.openingHours',
        () async {
      final stations = await searchMitecoStations(
        [repsolMadrid(horario: 'L-V: 06:00-22:00; S-D: 08:00-22:00')],
      );

      final s = stations.firstWhere((s) => s.id == 'es-1234');
      expect(s.openingHours, isNotNull,
          reason: 'the REAL MITECO parse must build structured weekly hours '
              'from the Horario string');
      expect(s.openingHours!.availability,
          isNot(OpeningHoursAvailability.notProvided));
      // Mon (a weekday) carries the 06:00-22:00 range.
      expect(s.openingHours!.dayFor(OpeningDay.mon)?.state, DayState.openRanges);
      // The legacy string is still carried for back-compat.
      expect(s.openingHoursText, 'L-V: 06:00-22:00; S-D: 08:00-22:00');
    });

    test('structured hours survive the search-list cache codec round-trip',
        () async {
      // Cache-HIT path: StationServiceChain Step 1 persists the search list via
      // serializeStationList and rehydrates via deserializeStationList. Before
      // #2777 this dropped the @JsonKey-excluded openingHours → empty hours.
      final fresh = (await searchMitecoStations([repsolMadrid()]))
          .firstWhere((s) => s.id == 'es-1234');
      expect(fresh.openingHours, isNotNull, reason: 'precondition');

      final restored =
          deserializeStationList(serializeStationList([fresh]))!.single;
      expect(restored.openingHours, isNotNull,
          reason: 'structured hours must survive the cache round-trip — the '
              'detail fast path serves StationDetail(openingHours: '
              'station.openingHours)');
      expect(restored.openingHours!.dayFor(OpeningDay.mon)?.state,
          DayState.openRanges);
    });

    test(
        'structured hours survive the favorite/widget Station.toJson round-trip',
        () async {
      // Favorites + widget rows persist a Station via `Station.toJson()` and
      // rehydrate via `Station.fromJson()` (FavoriteStations.build /
      // saveFavoriteStationData). A cold favorite tap on an ES station with no
      // search state must still show hours from that round-trip.
      final fresh = (await searchMitecoStations([repsolMadrid()]))
          .firstWhere((s) => s.id == 'es-1234');

      final restored = Station.fromJson(fresh.toJson());
      expect(restored.openingHours, isNotNull,
          reason: 'a cold favorite/widget tap rehydrates the persisted Station '
              'and must keep its structured hours');
      expect(restored.openingHours!.dayFor(OpeningDay.mon)?.state,
          DayState.openRanges);
    });

    test('a Cerrado (fully-closed) schedule survives the codec round-trip',
        () async {
      final fresh = (await searchMitecoStations(
        [repsolMadrid(horario: 'Cerrado')],
      ))
          .firstWhere((s) => s.id == 'es-1234');
      expect(fresh.isOpen, isFalse);
      // "Cerrado" is full structured data (every day closed), not "no data".
      expect(fresh.openingHours, isNotNull);
      expect(fresh.openingHours!.dayFor(OpeningDay.mon)?.state,
          DayState.closed);

      final restored =
          deserializeStationList(serializeStationList([fresh]))!.single;
      expect(restored.openingHours, isNotNull,
          reason: 'a closed week is real data and must round-trip, not vanish');
      expect(restored.openingHours!.dayFor(OpeningDay.mon)?.state,
          DayState.closed);
    });

    test('a station with no Horario round-trips as null (back-compat)',
        () async {
      final fresh = (await searchMitecoStations([
        {
          'IDEESS': '88',
          'Rótulo': 'NOHOURS',
          'Dirección': 'St',
          'Localidad': 'MADRID',
          'C.P.': '28001',
          'Latitud': '40,42',
          'Longitud (WGS84)': '-3,70',
          'Precio Gasolina 95 E5': '1,5',
          'Horario': '',
        },
      ]))
          .firstWhere((s) => s.id == 'es-88');
      final restored =
          deserializeStationList(serializeStationList([fresh]))!.single;
      expect(
        restored.openingHours == null ||
            restored.openingHours!.availability ==
                OpeningHoursAvailability.notProvided,
        isTrue,
      );
    });
  });

  group('MITECO REAL search parse (via the real service + fixed Dio)', () {
    test('parses a full station record incl. the es- id prefix (#753)',
        () async {
      // #3189 — isOpen is schedule-derived now; fix the clock inside the
      // L-D: 06:00-22:00 window so the assertion is deterministic.
      final stations = await searchMitecoStations(
        [repsolMadrid()],
        now: () => DateTime(2026, 6, 10, 12, 0),
      );
      final s = stations.firstWhere((s) => s.id == 'es-1234');

      // #753 — the real parse prefixes the bare IDEESS with `es-`; the divergent
      // copy never did, which is exactly the kind of drift this test catches.
      expect(s.id, 'es-1234');
      expect(s.name, 'REPSOL');
      expect(s.brand, 'REPSOL');
      expect(s.street, 'CALLE MAYOR 1');
      expect(s.place, 'MADRID');
      expect(s.postCode, '28001');
      expect(s.lat, closeTo(40.416775, 0.001));
      expect(s.lng, closeTo(-3.703790, 0.001));
      expect(s.e5, closeTo(1.649, 0.001));
      expect(s.e10, closeTo(1.599, 0.001));
      expect(s.e98, closeTo(1.829, 0.001));
      expect(s.diesel, closeTo(1.459, 0.001));
      expect(s.dieselPremium, closeTo(1.529, 0.001));
      expect(s.e85, closeTo(1.099, 0.001));
      expect(s.lpg, closeTo(0.899, 0.001));
      expect(s.cng, closeTo(1.199, 0.001));
      expect(s.isOpen, isTrue);
      expect(s.openingHoursText, 'L-D: 06:00-22:00');
      // #3189 — Margen (road side D/I/N) is no longer mapped: it violated
      // the stationType R/A contract.
      expect(s.stationType, isNull);
    });

    test('drops records with missing coordinates', () async {
      final stations = await searchMitecoStations([
        repsolMadrid(),
        {
          'IDEESS': '9',
          'Rótulo': 'NoLat',
          'Dirección': 'St',
          'Localidad': 'Madrid',
          'C.P.': '28001',
          'Latitud': '',
          'Longitud (WGS84)': '-3,7',
          'Horario': '24H',
        },
      ]);
      expect(stations.map((s) => s.id), contains('es-1234'));
      expect(stations.map((s) => s.id), isNot(contains('es-9')));
    });

    test('marks station closed when Horario is Cerrado', () async {
      final stations = await searchMitecoStations(
        [repsolMadrid(horario: 'Cerrado')],
      );
      final s = stations.firstWhere((s) => s.id == 'es-1234');
      expect(s.isOpen, isFalse);
      expect(s.openingHoursText, 'Cerrado');
      // Even a closed station keeps its prices.
      expect(s.e5, closeTo(1.649, 0.001));
    });

    test('Spanish comma-decimal prices parse correctly', () async {
      final stations = await searchMitecoStations([
        repsolMadrid(),
        {
          'IDEESS': '5',
          'Rótulo': 'BIO',
          'Dirección': 'BIO ROAD 1',
          'Localidad': 'MADRID',
          'C.P.': '28002',
          'Latitud': '40,42',
          'Longitud (WGS84)': '-3,70',
          'Precio Gasolina 95 E85': '1,099',
          'Horario': 'L-D: 00:00-24:00',
        },
      ]);
      final bio = stations.firstWhere((s) => s.id == 'es-5');
      expect(bio.e85, closeTo(1.099, 0.001));
      expect(bio.e5, isNull);
    });

    test('uses address as name when brand is empty', () async {
      final stations = await searchMitecoStations([
        {
          'IDEESS': '7',
          'Rótulo': '',
          'Dirección': 'CALLE MAYOR',
          'Localidad': 'MADRID',
          'C.P.': '28001',
          'Latitud': '40,42',
          'Longitud (WGS84)': '-3,70',
          'Horario': 'L-V: 08:00-20:00',
        },
      ]);
      expect(stations.single.name, 'CALLE MAYOR');
    });

    test('search limits to the nearest 50 stations', () async {
      // 60 distinct stations spread just north of Madrid — all within radius.
      final records = List.generate(60, (i) {
        final lat = 40.42 + i * 0.001;
        return {
          'IDEESS': '$i',
          'Rótulo': 'Station $i',
          'Dirección': 'St $i',
          'Localidad': 'MADRID',
          'C.P.': '28001',
          'Latitud': lat.toStringAsFixed(6).replaceAll('.', ','),
          'Longitud (WGS84)': '-3,700000',
          'Precio Gasolina 95 E5': '1,649',
          'Horario': '24H',
        };
      });
      final stations = await searchMitecoStations(records);
      expect(stations.length, 50);
    });
  });
}
