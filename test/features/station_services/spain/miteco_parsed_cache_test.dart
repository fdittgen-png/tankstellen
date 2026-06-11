// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3156 — Spain used to cache the RAW province rows and re-parse every one of
// them on every search, including a regex opening-hours pass per row (a dense
// province re-paid 800-2500 row parses per repeat search). The service now
// caches the parsed Station templates per province via the shared
// KeyedCachedDatasetMixin, so a repeat search re-parses NOTHING — while the
// per-search values (dist, schedule-derived isOpen) are still stamped fresh.

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/search_params.dart';
import 'package:tankstellen/features/station_services/spain/miteco_station_service.dart';
import 'package:tankstellen/features/station_services/spain/spain_opening_hours_adapter.dart';

import '../support/real_service_search.dart';

/// One realistic MITECO row near the Madrid search centre, with a schedule
/// (`L-D: 06:00-22:00`) so both the opening-hours parse and the per-search
/// open-now stamping are exercised.
Map<String, dynamic> _repsolMadrid() => {
      'IDEESS': '1234',
      'Rótulo': 'REPSOL',
      'Dirección': 'CALLE MAYOR 1',
      'Localidad': 'MADRID',
      'C.P.': '28001',
      'Latitud': '40,416775',
      'Longitud (WGS84)': '-3,703790',
      'Precio Gasolina 95 E5': '1,649',
      'Precio Gasoleo A': '1,459',
      'Horario': 'L-D: 06:00-22:00',
    };

Map<String, dynamic> _cepsaMadrid() => {
      'IDEESS': '5678',
      'Rótulo': 'CEPSA',
      'Dirección': 'GRAN VIA 2',
      'Localidad': 'MADRID',
      'C.P.': '28013',
      'Latitud': '40,420000',
      'Longitud (WGS84)': '-3,705000',
      'Precio Gasoleo A': '1,479',
      'Horario': 'L-D: 24H',
    };

const _madrid = SearchParams(lat: 40.4168, lng: -3.7038, radiusKm: 5);

void main() {
  group('ES parsed-Station per-province cache (#3156)', () {
    test('a repeat search does NOT re-run the opening-hours parse', () async {
      var parses = 0;
      final dio = Dio()
        ..httpClientAdapter =
            FixedJsonAdapter(mitecoEnvelope([_repsolMadrid(), _cepsaMadrid()]));
      final service = MitecoStationService(
        dio: dio,
        now: () => DateTime(2026, 6, 10, 12, 0),
        // The #3156 parse-count seam: same real adapter, counted.
        parseOpeningHours: (horario) {
          parses++;
          return const SpainOpeningHoursAdapter().parse(horario);
        },
      );

      final first = await service.searchStations(_madrid);
      expect(first.data.map((s) => s.id), contains('es-1234'),
          reason: 'precondition: the first search parses + returns the row');
      final parsesAfterFirst = parses;
      expect(parsesAfterFirst, greaterThan(0),
          reason: 'precondition: the first (cold) search runs the parser');

      final second = await service.searchStations(_madrid);
      expect(second.data.map((s) => s.id), contains('es-1234'),
          reason: 'the cached templates must serve the same stations');
      expect(parses, parsesAfterFirst,
          reason: 'the second search must be served from the parsed '
              'per-province Station cache — zero re-parses (#3156)');
    });

    test('isOpen is still recomputed per search from the cached schedule',
        () async {
      // Same service, same cached province — only the clock moves. Caching
      // the parsed stations must NOT pin the open flag for the 6 h TTL.
      var now = DateTime(2026, 6, 10, 12, 0); // Wed noon — inside 06:00-22:00
      final dio = Dio()
        ..httpClientAdapter =
            FixedJsonAdapter(mitecoEnvelope([_repsolMadrid()]));
      final service = MitecoStationService(dio: dio, now: () => now);

      final atNoon = await service.searchStations(_madrid);
      expect(atNoon.data.singleWhere((s) => s.id == 'es-1234').isOpen, isTrue);

      now = DateTime(2026, 6, 10, 3, 0); // Wed 03:00 — outside the schedule
      final atNight = await service.searchStations(_madrid);
      expect(atNight.data.singleWhere((s) => s.id == 'es-1234').isOpen, isFalse,
          reason: 'the cached parsed station must not pin a stale isOpen — '
              'the open state is stamped per search (#3189 semantics kept)');
    });

    test('dist is stamped per search centre, not frozen into the cache',
        () async {
      final dio = Dio()
        ..httpClientAdapter =
            FixedJsonAdapter(mitecoEnvelope([_repsolMadrid()]));
      final service =
          MitecoStationService(dio: dio, now: () => DateTime(2026, 6, 10, 12));

      final atStation = await service.searchStations(
        const SearchParams(lat: 40.416775, lng: -3.703790, radiusKm: 5),
      );
      expect(atStation.data.single.dist, 0.0);

      // ~5.5 km north of the station — the SAME cached template must carry a
      // recomputed distance for the new centre.
      final north = await service.searchStations(
        const SearchParams(lat: 40.466775, lng: -3.703790, radiusKm: 10),
      );
      expect(north.data.single.dist, greaterThan(4.0));
    });
  });
}
