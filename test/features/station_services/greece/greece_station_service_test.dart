// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3539 — Greece rewritten from the dead per-prefecture fuelpricesgr
// API (#3194 NXDOMAIN) to the emvouvakis FuelPricesGreeceAPI mirror:
// ONE ranged `GET {base}/data` request returns a flat country-wide row
// list (one row per prefecture per day, one COLUMN per fuel).

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/country/country_config.dart';
import 'package:tankstellen/core/error/exceptions.dart';
import 'package:tankstellen/features/station_services/greece/greece_station_service.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/services/station_service.dart';
import 'package:tankstellen/core/domain/search_params.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/station.dart';
import '../../../helpers/silence_error_logger.dart';

import '../../../mocks/mocks.dart';

/// Build one prefecture-day row in the shape the emvouvakis mirror
/// returns: `{ "DATE": ..., "REGION": ..., "<FUEL_COLUMN>": <num|null> }`.
Map<String, dynamic> _row({
  String date = '2026-07-09',
  String region = 'N. ATHINON',
  Map<String, dynamic> fuels = const <String, dynamic>{
    'UNLEADED_95_Octane': 1.943,
    'UNLEADED_100_OCTANE': 2.16,
    'AUTOMOTIVE_DIESEL': 1.787,
    'AUTOGAS': 0.907,
    'HOME_HEATING_DIESEL': null,
    'Super': null,
  },
}) =>
    <String, dynamic>{'DATE': date, 'REGION': region, ...fuels};

void main() {
  silenceErrorLoggerSpool();
  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(Options());
  });

  /// The REAL recorded /data response (51 rows, one per prefecture,
  /// DATE 2026-07-09) — drives the searchStations happy path.
  final recordedRows = jsonDecode(
    File('test/fixtures/gr_emvouvakis_v2_data_day.json').readAsStringSync(),
  ) as List<dynamic>;

  late MockDio mockDio;
  late GreeceStationService service;

  setUp(() {
    mockDio = MockDio();
    service = GreeceStationService(
      dio: mockDio,
      baseUrl: 'https://test/api',
      apiKey: 'test-key',
      now: () => DateTime(2026, 7, 11),
    );
  });

  Response<dynamic> response(dynamic data) => Response<dynamic>(
        requestOptions: RequestOptions(),
        statusCode: 200,
        data: data,
      );

  void stubGet(dynamic data) {
    when(() => mockDio.get<dynamic>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
        )).thenAnswer((_) async => response(data));
  }

  group('GreeceStationService', () {
    test('implements StationService', () {
      expect(service, isA<StationService>());
    });

    test('country registered as GR with EUR currency', () {
      final gr = Countries.byCode('GR');
      expect(gr, isNotNull);
      expect(gr!.currency, 'EUR');
      expect(gr.requiresApiKey, isFalse,
          reason: 'The mirror ships its own PUBLIC shared key — the user '
              'never has to supply one');
      expect(gr.apiProvider, contains('Paratiritirio'));
    });

    group('fuel observatory-column mapping', () {
      test('UNLEADED_95_Octane → e5', () {
        expect(
          GreeceStationService.fuelForObservatoryKey('UNLEADED_95_Octane'),
          FuelType.e5,
        );
      });

      test('UNLEADED_100_OCTANE → e98', () {
        expect(
          GreeceStationService.fuelForObservatoryKey('UNLEADED_100_OCTANE'),
          FuelType.e98,
        );
      });

      test('AUTOMOTIVE_DIESEL → diesel', () {
        expect(
          GreeceStationService.fuelForObservatoryKey('AUTOMOTIVE_DIESEL'),
          FuelType.diesel,
        );
      });

      test('AUTOGAS (Υγραέριο) → lpg', () {
        expect(
          GreeceStationService.fuelForObservatoryKey('AUTOGAS'),
          FuelType.lpg,
        );
      });

      test('HOME_HEATING_DIESEL is intentionally unmapped (not motoring '
          'fuel)', () {
        expect(
          GreeceStationService.fuelForObservatoryKey('HOME_HEATING_DIESEL'),
          isNull,
        );
        expect(
          GreeceStationService.droppedObservatoryKeys,
          contains('home_heating_diesel'),
        );
      });

      test('Super is intentionally unmapped (leaded, phased out)', () {
        expect(
          GreeceStationService.fuelForObservatoryKey('Super'),
          isNull,
        );
        expect(
          GreeceStationService.droppedObservatoryKeys,
          contains('super'),
        );
      });

      test('DATE / REGION envelope columns are dropped, not fuels', () {
        expect(GreeceStationService.fuelForObservatoryKey('DATE'), isNull);
        expect(GreeceStationService.fuelForObservatoryKey('REGION'), isNull);
        expect(
          GreeceStationService.droppedObservatoryKeys,
          containsAll(<String>['date', 'region']),
        );
      });

      test('mapping is case-insensitive', () {
        expect(
          GreeceStationService.fuelForObservatoryKey('unleaded_95_octane'),
          FuelType.e5,
        );
        expect(
          GreeceStationService.fuelForObservatoryKey('UNLEADED_95_OCTANE'),
          FuelType.e5,
        );
        expect(
          GreeceStationService.fuelForObservatoryKey('autogas'),
          FuelType.lpg,
        );
      });
    });

    group('searchStations', () {
      test('builds stations for the nearest prefectures from Athens off '
          'the recorded country-wide row list', () async {
        stubGet(recordedRows);

        // Athens → ATTICA first; the 4 nearest prefectures surface.
        const params = SearchParams(lat: 37.98, lng: 23.73, radiusKm: 500);
        final result = await service.searchStations(params);

        expect(result.source, ServiceSource.greeceApi);
        expect(result.data, isNotEmpty);
        expect(result.errors, isEmpty);

        // Every station id carries the `gr-` prefix.
        expect(
          result.data.every((s) => s.id.startsWith('gr-')),
          isTrue,
          reason: 'Every GR station id must carry the gr- prefix so the '
              'favorites currency lookup finds it.',
        );

        // The recorded N. ATHINON row must map onto the Station slots.
        final attica = result.data.firstWhere((s) => s.id == 'gr-attica');
        expect(attica.e5, closeTo(1.943, 0.0001));
        expect(attica.e98, closeTo(2.16, 0.0001));
        expect(attica.diesel, closeTo(1.787, 0.0001));
        expect(attica.lpg, closeTo(0.907, 0.0001));
        expect(attica.updatedAt, '2026-07-09');
        expect(attica.isOpen, isNull,
            reason: 'Prefecture-level virtual stations have no open/closed '
                'notion (#3198).');
      });

      test('makes exactly ONE HTTP call regardless of candidate count',
          () async {
        stubGet(recordedRows);

        const params = SearchParams(lat: 37.98, lng: 23.73, radiusKm: 500);
        await service.searchStations(params);

        verify(() => mockDio.get<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
              options: any(named: 'options'),
              cancelToken: any(named: 'cancelToken'),
            )).called(1);
      });

      test('targets /data with the ranged start_date/end_date/offset '
          'params and the x-api-key header', () async {
        stubGet(recordedRows);

        const params = SearchParams(lat: 37.98, lng: 23.73, radiusKm: 500);
        await service.searchStations(params);

        final captured = verify(() => mockDio.get<dynamic>(
              captureAny(),
              queryParameters: captureAny(named: 'queryParameters'),
              options: captureAny(named: 'options'),
              cancelToken: any(named: 'cancelToken'),
            )).captured;

        expect(captured[0], 'https://test/api/data');

        final query = captured[1] as Map<String, dynamic>;
        // now = 2026-07-11, lookback = 7 days.
        expect(query['start_date'], '2026-07-04');
        expect(query['end_date'], '2026-07-11');
        expect(query['offset'], 0);

        final options = captured[2] as Options;
        expect(options.headers?['x-api-key'], 'test-key');
      });

      test('HTTP 401 is re-raised as ApiException mentioning the key',
          () async {
        when(() => mockDio.get<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
              options: any(named: 'options'),
              cancelToken: any(named: 'cancelToken'),
            )).thenThrow(DioException(
          requestOptions: RequestOptions(),
          response: Response(
            requestOptions: RequestOptions(),
            statusCode: 401,
          ),
          type: DioExceptionType.badResponse,
        ));

        const params = SearchParams(lat: 37.98, lng: 23.73, radiusKm: 500);
        await expectLater(
          () => service.searchStations(params),
          throwsA(isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 401)
              .having((e) => e.message, 'message', contains('key'))),
        );
      });

      test('HTTP 403 is re-raised as ApiException mentioning the key',
          () async {
        when(() => mockDio.get<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
              options: any(named: 'options'),
              cancelToken: any(named: 'cancelToken'),
            )).thenThrow(DioException(
          requestOptions: RequestOptions(),
          response: Response(
            requestOptions: RequestOptions(),
            statusCode: 403,
          ),
          type: DioExceptionType.badResponse,
        ));

        const params = SearchParams(lat: 37.98, lng: 23.73, radiusKm: 500);
        await expectLater(
          () => service.searchStations(params),
          throwsA(isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 403)
              .having((e) => e.message, 'message', contains('key'))),
        );
      });

      test('network timeout surfaces ApiException (unreachable) to the '
          'fallback chain', () async {
        when(() => mockDio.get<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
              options: any(named: 'options'),
              cancelToken: any(named: 'cancelToken'),
            )).thenThrow(DioException(
          type: DioExceptionType.connectionTimeout,
          requestOptions: RequestOptions(),
        ));

        const params = SearchParams(lat: 37.98, lng: 23.73, radiusKm: 500);
        await expectLater(
          () => service.searchStations(params),
          throwsA(isA<ApiException>()
              .having((e) => e.message, 'message', contains('unreachable'))),
        );
      });

      test('non-list body raises ApiException', () async {
        stubGet(<String, dynamic>{'oops': 'not a list'});

        const params = SearchParams(lat: 37.98, lng: 23.73, radiusKm: 500);
        await expectLater(
          () => service.searchStations(params),
          throwsA(isA<ApiException>()),
        );
      });

      test('empty row list → empty result without errors', () async {
        stubGet(<dynamic>[]);

        const params = SearchParams(lat: 37.98, lng: 23.73, radiusKm: 500);
        final result = await service.searchStations(params);

        // No recent data is a valid response — no stations, no errors.
        expect(result.data, isEmpty);
        expect(result.errors, isEmpty);
      });
    });

    group('parsePrefectureResponse', () {
      Station? parse(dynamic body, {String regionKey = 'N. ATHINON'}) =>
          service.parsePrefectureResponse(
            body,
            regionKey: regionKey,
            stationId: 'gr-attica',
            displayName: 'Αττική / Attica',
            place: 'Αθήνα',
            prefectureLat: 37.9838,
            prefectureLng: 23.7275,
            fromLat: 37.98,
            fromLng: 23.73,
          );

      test('happy path parses all four supported fuels from the region row',
          () {
        final s = parse(<dynamic>[_row()]);
        expect(s, isNotNull);
        expect(s!.id, 'gr-attica');
        expect(s.e5, closeTo(1.943, 0.0001));
        expect(s.e98, closeTo(2.16, 0.0001));
        expect(s.diesel, closeTo(1.787, 0.0001));
        expect(s.lpg, closeTo(0.907, 0.0001));
        // Heating diesel is dropped — confirm no fuel slot absorbed it.
        expect(s.dieselPremium, isNull);
      });

      test('picks the newest DATE when the ranged window returns several '
          'rows for the region', () {
        final s = parse(<dynamic>[
          _row(date: '2026-07-08', fuels: {'UNLEADED_95_Octane': 1.900}),
          _row(date: '2026-07-09', fuels: {'UNLEADED_95_Octane': 1.943}),
          _row(date: '2026-07-07', fuels: {'UNLEADED_95_Octane': 1.890}),
        ]);
        expect(s, isNotNull);
        expect(s!.e5, closeTo(1.943, 0.0001));
        expect(s.updatedAt, '2026-07-09');
      });

      test('rows for OTHER regions are ignored — no matching row → null',
          () {
        final s = parse(<dynamic>[
          _row(region: 'N. THESSALONIKIS'),
          _row(region: 'N. CHANION'),
        ]);
        expect(s, isNull);
      });

      test('empty list → null station', () {
        expect(parse(const <dynamic>[]), isNull);
      });

      test('non-list body raises ApiException', () {
        expect(
          () => parse(<String, dynamic>{'oops': 'not a list'}),
          throwsA(isA<ApiException>()),
        );
      });

      test('HOME_HEATING_DIESEL and Super columns are silently dropped',
          () {
        final s = parse(<dynamic>[
          _row(fuels: {
            'AUTOMOTIVE_DIESEL': 1.787,
            'HOME_HEATING_DIESEL': 1.165, // dropped
            'Super': 1.950, // dropped
          }),
        ]);
        expect(s, isNotNull);
        expect(s!.diesel, closeTo(1.787, 0.0001));
        expect(s.e5, isNull);
        expect(s.e98, isNull);
        expect(s.lpg, isNull);
        expect(s.dieselPremium, isNull);
      });

      test('region with zero recognised positive-price fuel columns '
          'returns null', () {
        final s = parse(<dynamic>[
          _row(fuels: {
            'HOME_HEATING_DIESEL': 1.165,
            'Super': 1.950,
            'UNLEADED_95_Octane': null,
          }),
        ]);
        expect(s, isNull,
            reason: 'No recognised motoring fuels → no synthetic pin.');
      });

      test('non-numeric price is dropped (that slot stays null)', () {
        final s = parse(<dynamic>[
          _row(fuels: {
            'UNLEADED_95_Octane': 1.943,
            'AUTOMOTIVE_DIESEL': 'N/A',
          }),
        ]);
        expect(s, isNotNull);
        expect(s!.e5, closeTo(1.943, 0.0001));
        expect(s.diesel, isNull);
      });

      test('zero or negative prices are rejected per column', () {
        final s = parse(<dynamic>[
          _row(fuels: {
            'UNLEADED_95_Octane': 0,
            'AUTOMOTIVE_DIESEL': -1.0,
            'AUTOGAS': 0.907,
          }),
        ]);
        expect(s, isNotNull);
        expect(s!.e5, isNull);
        expect(s.diesel, isNull);
        expect(s.lpg, closeTo(0.907, 0.0001));
      });

      test('numeric price strings are accepted', () {
        final s = parse(<dynamic>[
          _row(fuels: {'UNLEADED_95_Octane': '1.943'}),
        ]);
        expect(s, isNotNull);
        expect(s!.e5, closeTo(1.943, 0.0001));
      });

      test('stationId is threaded through unchanged (gr- prefix preserved)',
          () {
        final s = parse(<dynamic>[_row()]);
        expect(s, isNotNull);
        expect(s!.id, startsWith('gr-'));
      });

      test('updatedAt is stamped from the winning row DATE', () {
        final s = parse(<dynamic>[_row(date: '2026-07-09')]);
        expect(s, isNotNull);
        expect(s!.updatedAt, '2026-07-09');
      });

      test('isOpen is honest-unknown (null) — prefecture granularity has '
          'no open/closed notion (#3198)', () {
        final s = parse(<dynamic>[_row()]);
        expect(s, isNotNull);
        expect(s!.isOpen, isNull);
      });
    });

    group('getStationDetail', () {
      test('throws ApiException (detail not available)', () {
        expect(
          () => service.getStationDetail('gr-attica'),
          throwsA(isA<ApiException>()),
        );
      });

      test('error message mentions Paratiritirio', () async {
        try {
          await service.getStationDetail('gr-attica');
          fail('expected ApiException');
        } on ApiException catch (e) {
          expect(e.message, contains('Paratiritirio'));
        }
      });
    });

    group('getPrices', () {
      test('returns empty map (no batch refresh)', () async {
        final result = await service.getPrices(['gr-attica', 'gr-chania']);
        expect(result.data, isEmpty);
        expect(result.source, ServiceSource.greeceApi);
      });

      test('returns empty map for empty id list', () async {
        final result = await service.getPrices([]);
        expect(result.data, isEmpty);
      });
    });

    group('station id prefix routing', () {
      test('Countries.countryCodeForStationId resolves gr- → GR', () {
        expect(
          Countries.countryCodeForStationId('gr-attica'),
          'GR',
        );
      });

      test('Countries.countryForStationId returns the GR config', () {
        final c = Countries.countryForStationId('gr-attica');
        expect(c, isNotNull);
        expect(c!.code, 'GR');
        expect(c.currency, 'EUR');
      });
    });
  });
}
