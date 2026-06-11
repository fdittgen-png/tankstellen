// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/country/country_config.dart';
import 'package:tankstellen/core/error/exceptions.dart';
import 'package:tankstellen/features/station_services/luxembourg/luxembourg_station_service.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/services/station_service.dart';
import 'package:tankstellen/features/search/data/models/search_params.dart';
import '../../../helpers/silence_error_logger.dart';

import '../../../mocks/mocks.dart';

/// #3195 — Luxembourg's decree prices come live from LUSTAT (STATEC's
/// official SDMX API) instead of compile-time constants.
///
/// `test/fixtures/lu_lustat_essence_slice.json` and
/// `lu_lustat_diesel_slice.json` are **unmodified real responses**
/// recorded live on 2026-06-10 from
/// `GET https://lustat.statec.lu/rest/data/LU1,DSD_PRIX_ESSENCE@DF_E530{1,2},1.0/
///  all?lastNObservations=1&dimensionAtObservation=AllDimensions&format=jsondata`
/// — petrol decree of 2026-06-05 (SP95 1.720 / SP98 1.848 EUR/L) and the
/// road-diesel decree of 2026-06-03 (DIE 1.782 EUR/L).
dynamic _fixture(String name) => jsonDecode(
      File('test/fixtures/$name').readAsStringSync(),
    );

void main() {
  silenceErrorLoggerSpool();

  late MockDio mockDio;
  late LuxembourgStationService service;

  Response<dynamic> response(dynamic data) => Response<dynamic>(
        requestOptions: RequestOptions(),
        statusCode: 200,
        data: data,
      );

  /// Stub the two LUSTAT dataflow calls with the recorded fixtures.
  void stubLiveLustat() {
    when(() => mockDio.get(
          any(),
          cancelToken: any(named: 'cancelToken'),
        )).thenAnswer((invocation) async {
      final url = invocation.positionalArguments.first as String;
      if (url.contains(LuxembourgStationService.essenceFlow)) {
        return response(_fixture('lu_lustat_essence_slice.json'));
      }
      if (url.contains(LuxembourgStationService.dieselFlow)) {
        return response(_fixture('lu_lustat_diesel_slice.json'));
      }
      fail('unexpected LUSTAT URL: $url');
    });
  }

  void stubLustatDown() {
    when(() => mockDio.get(
          any(),
          cancelToken: any(named: 'cancelToken'),
        )).thenThrow(DioException(
      type: DioExceptionType.connectionTimeout,
      requestOptions: RequestOptions(),
    ));
  }

  setUp(() {
    mockDio = MockDio();
    service = LuxembourgStationService(dio: mockDio);
  });

  group('LuxembourgStationService', () {
    test('implements StationService interface', () {
      expect(service, isA<StationService>());
    });

    group('live LUSTAT decree prices (#3195, recorded fixtures)', () {
      setUp(stubLiveLustat);

      test('stations carry the recorded decree figures, not the stale '
          'constants', () async {
        const params = SearchParams(lat: 49.6116, lng: 6.1319, radiusKm: 50);
        final result = await service.searchStations(params);

        expect(result.source, ServiceSource.luxembourgApi);
        expect(result.isStale, isFalse);
        expect(result.errors, isEmpty);
        expect(result.data, isNotEmpty);

        final s = result.data.first;
        // Real recorded decree values (2026-06-05 / 2026-06-03).
        expect(s.e5, closeTo(1.720, 0.0001));
        expect(s.e10, closeTo(1.720, 0.0001),
            reason: 'the decree publishes one 95-octane figure');
        expect(s.e98, closeTo(1.848, 0.0001));
        expect(s.diesel, closeTo(1.782, 0.0001));
        // No daily LUSTAT flow exists for LPG — it must not be served
        // from a constant on the live path.
        expect(s.lpg, isNull);
      });

      test('the decree effective date is surfaced as updatedAt', () async {
        const params = SearchParams(lat: 49.6116, lng: 6.1319, radiusKm: 50);
        final result = await service.searchStations(params);
        // Newest decree among the fuels used: petrol on 2026-06-05.
        expect(result.data.first.updatedAt, '2026-06-05');
      });

      test('every station carries identical prices (uniform regulation)',
          () async {
        const params =
            SearchParams(lat: 49.6116, lng: 6.1319, radiusKm: 100.0);
        final result = await service.searchStations(params);

        expect(result.data, hasLength(greaterThan(1)),
            reason: 'Multiple virtual stations at a large radius');
        expect(result.data.map((s) => s.e5).toSet(), hasLength(1));
        expect(result.data.map((s) => s.e10).toSet(), hasLength(1));
        expect(result.data.map((s) => s.e98).toSet(), hasLength(1));
        expect(result.data.map((s) => s.diesel).toSet(), hasLength(1));
      });

      test('every station id is prefixed with "lu-"', () async {
        const params =
            SearchParams(lat: 49.6116, lng: 6.1319, radiusKm: 100.0);
        final result = await service.searchStations(params);
        for (final s in result.data) {
          expect(s.id, startsWith('lu-'),
              reason: 'Station ids must be prefixed so '
                  'Countries.countryForStationId dispatches to LU');
        }
      });

      test('lu- prefix dispatches to Luxembourg via country_config',
          () async {
        const params = SearchParams(lat: 49.6116, lng: 6.1319, radiusKm: 50);
        final result = await service.searchStations(params);
        expect(result.data, isNotEmpty);
        expect(
            Countries.countryCodeForStationId(result.data.first.id), 'LU');
      });

      test('distance is calculated from the query point', () async {
        const params =
            SearchParams(lat: 49.6116, lng: 6.1319, radiusKm: 100.0);
        final result = await service.searchStations(params);
        final ville =
            result.data.firstWhere((s) => s.name == 'Luxembourg-Ville');
        expect(ville.dist, closeTo(0.0, 1.0));
      });

      test('stations are sorted by distance when SortBy.distance is used',
          () async {
        const params = SearchParams(
          lat: 49.6116,
          lng: 6.1319,
          radiusKm: 100.0,
          sortBy: SortBy.distance,
        );
        final result = await service.searchStations(params);
        for (var i = 1; i < result.data.length; i++) {
          expect(result.data[i].dist,
              greaterThanOrEqualTo(result.data[i - 1].dist));
        }
      });

      test('radius filter narrows results near a single city', () async {
        // 5 km around Luxembourg-Ville should hit only the city itself.
        const params = SearchParams(lat: 49.6116, lng: 6.1319, radiusKm: 5.0);
        final result = await service.searchStations(params);
        expect(result.data, hasLength(1));
        expect(result.data.first.name, 'Luxembourg-Ville');
      });

      test('coordinates fall inside the LU bounding box', () async {
        const params =
            SearchParams(lat: 49.6116, lng: 6.1319, radiusKm: 100.0);
        final result = await service.searchStations(params);
        for (final s in result.data) {
          expect(s.lat, inInclusiveRange(49.4, 50.25));
          expect(s.lng, inInclusiveRange(5.7, 6.55));
        }
      });

      test('all stations report isOpen: true', () async {
        const params =
            SearchParams(lat: 49.6116, lng: 6.1319, radiusKm: 100.0);
        final result = await service.searchStations(params);
        for (final s in result.data) {
          expect(s.isOpen, isTrue);
        }
      });

      test('prices are plausible EUR/L values (0.3 <= p <= 3.0)', () async {
        const params = SearchParams(lat: 49.6116, lng: 6.1319, radiusKm: 50);
        final result = await service.searchStations(params);
        final s = result.data.first;
        expect(s.e5, inInclusiveRange(0.3, 3.0));
        expect(s.e10, inInclusiveRange(0.3, 3.0));
        expect(s.e98, inInclusiveRange(0.3, 3.0));
        expect(s.diesel, inInclusiveRange(0.3, 3.0));
      });
    });

    group('stale constant fallback when LUSTAT is down (#3195)', () {
      setUp(stubLustatDown);

      test('serves the fallback constants marked isStale with a '
          'ServiceError — never throws', () async {
        const params = SearchParams(lat: 49.6116, lng: 6.1319, radiusKm: 50);
        final result = await service.searchStations(params);

        expect(result.isStale, isTrue,
            reason: 'compile-time constants must be visibly stale');
        expect(result.errors, hasLength(1));
        expect(result.errors.single.message, contains('#3195'));
        expect(result.data, isNotEmpty);

        final s = result.data.first;
        expect(s.e5, isNotNull);
        expect(s.e10, isNotNull);
        expect(s.e98, isNotNull);
        expect(s.diesel, isNotNull);
        // LPG only exists on the fallback (no daily LUSTAT flow).
        expect(s.lpg, isNotNull);
        expect(s.lpg, inInclusiveRange(0.3, 2.0));
        // No decree date — the constants are not a decree.
        expect(s.updatedAt, isNull);
      });

      test('unparseable LUSTAT body also degrades to the stale fallback',
          () async {
        when(() => mockDio.get(
              any(),
              cancelToken: any(named: 'cancelToken'),
            )).thenAnswer((_) async => response('<html>maintenance</html>'));

        const params = SearchParams(lat: 49.6116, lng: 6.1319, radiusKm: 50);
        final result = await service.searchStations(params);
        expect(result.isStale, isTrue);
        expect(result.data, isNotEmpty);
      });
    });

    group('parseLustatLatest (recorded fixtures)', () {
      test('extracts SP95/SP98 with the decree date from the essence flow',
          () {
        final latest = service.parseLustatLatest(
          _fixture('lu_lustat_essence_slice.json'),
        );
        expect(latest['SP95']!.value, closeTo(1.720, 0.0001));
        expect(latest['SP98']!.value, closeTo(1.848, 0.0001));
        expect(latest['SP95']!.period, '2026-06-05');
      });

      test('extracts DIE from the diesel flow', () {
        final latest = service.parseLustatLatest(
          _fixture('lu_lustat_diesel_slice.json'),
        );
        expect(latest['DIE']!.value, closeTo(1.782, 0.0001));
        expect(latest['DIE']!.period, '2026-06-03');
      });

      test('merges flows via the shared accumulator', () {
        final latest = service.parseLustatLatest(
          _fixture('lu_lustat_essence_slice.json'),
        );
        service.parseLustatLatest(
          _fixture('lu_lustat_diesel_slice.json'),
          into: latest,
        );
        expect(latest.keys, containsAll(['SP95', 'SP98', 'DIE']));
      });

      test('raises ApiException on a non-SDMX body', () {
        expect(
          () => service.parseLustatLatest('garbage'),
          throwsA(isA<ApiException>()),
        );
        expect(
          () => service.parseLustatLatest(<String, dynamic>{'data': 42}),
          throwsA(isA<ApiException>()),
        );
      });
    });

    group('getStationDetail', () {
      test('throws ApiException (detail not supported for uniform prices)',
          () {
        expect(
          () => service.getStationDetail('lu-luxembourg-ville'),
          throwsA(isA<ApiException>()),
        );
      });

      test('error message mentions Luxembourg', () async {
        try {
          await service.getStationDetail('lu-luxembourg-ville');
          fail('Should have thrown');
        } on ApiException catch (e) {
          expect(e.message, contains('Luxembourg'));
        }
      });
    });

    group('getPrices', () {
      test('returns empty map with Luxembourg source', () async {
        final result = await service.getPrices(['lu-1', 'lu-2']);
        expect(result.data, isEmpty);
        expect(result.source, ServiceSource.luxembourgApi);
      });

      test('returns empty map for empty id list', () async {
        final result = await service.getPrices([]);
        expect(result.data, isEmpty);
      });

      test('result has correct metadata', () async {
        final result = await service.getPrices(['lu-anything']);
        expect(result.source, ServiceSource.luxembourgApi);
        expect(result.fetchedAt, isA<DateTime>());
        expect(result.isStale, isFalse);
      });
    });
  });
}
