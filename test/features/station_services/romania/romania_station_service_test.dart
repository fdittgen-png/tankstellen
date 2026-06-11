// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/country/country_config.dart';
import 'package:tankstellen/core/error/exceptions.dart';
import 'package:tankstellen/features/station_services/romania/romania_station_service.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/services/station_service.dart';
import 'package:tankstellen/features/search/data/models/search_params.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import '../../../helpers/silence_error_logger.dart';

import '../../../mocks/mocks.dart';

/// #3193 — Romania rebased on the official Monitorul Prețurilor
/// observatory (monitorulpreturilor.info).
///
/// The fixtures `test/fixtures/ro_monitorul_benzina_standard_slice.json`
/// and `ro_monitorul_motorina_standard_slice.json` are **trimmed copies
/// of real responses** recorded live on 2026-06-10 from
/// `GET /pmonsvc/Gas/GetGasItemsByLatLon?lon=26.10&lat=44.43&buffer=5000
///  &CSVGasCatalogProductIds=<11|21>&OrderBy=dist`
/// (3 of 50 stations kept, structure untouched). They replace the
/// hand-crafted fixture for an invented `pretcarburant.ro` schema that
/// no live service ever served — the false-green pattern this issue
/// kills.
dynamic _fixture(String name) => jsonDecode(
      File('test/fixtures/$name').readAsStringSync(),
    );

void main() {
  silenceErrorLoggerSpool();
  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  late MockDio mockDio;
  late RomaniaStationService service;

  setUp(() {
    mockDio = MockDio();
    when(() => mockDio.options)
        .thenReturn(BaseOptions(headers: <String, dynamic>{}));
    service = RomaniaStationService(dio: mockDio, baseUrl: 'https://test');
  });

  Response<dynamic> response(dynamic data) => Response<dynamic>(
        requestOptions: RequestOptions(),
        statusCode: 200,
        data: data,
      );

  // Bucharest city centre — the point the fixtures were recorded from.
  const params = SearchParams(lat: 44.43, lng: 26.10, radiusKm: 5.0);

  group('RomaniaStationService', () {
    test('implements StationService', () {
      expect(service, isA<StationService>());
    });

    test('country registered as RO with RON currency', () {
      final ro = Countries.byCode('RO');
      expect(ro, isNotNull);
      expect(ro!.currency, 'RON');
      expect(ro.requiresApiKey, isFalse);
    });

    test('default base URL targets the official observatory host', () {
      expect(RomaniaStationService.defaultBaseUrl,
          contains('monitorulpreturilor.info'));
      // The dead third-party host must never come back (#3193).
      expect(RomaniaStationService.defaultBaseUrl,
          isNot(contains('pretcarburant')));
    });

    group('searchStations', () {
      test('fans out one call per catalog product and merges by station id',
          () async {
        when(() => mockDio.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
              cancelToken: any(named: 'cancelToken'),
            )).thenAnswer((invocation) async {
          final qp = invocation.namedArguments[#queryParameters]
              as Map<String, dynamic>;
          switch (qp['CSVGasCatalogProductIds'] as String) {
            case '11':
              return response(
                  _fixture('ro_monitorul_benzina_standard_slice.json'));
            case '21':
              return response(
                  _fixture('ro_monitorul_motorina_standard_slice.json'));
            default:
              // The backend answers an envelope with empty arrays when a
              // product has no rows in the buffer.
              return response(<String, dynamic>{
                'Stations': <dynamic>[],
                'Products': <dynamic>[],
              });
          }
        });

        final result = await service.searchStations(params);

        expect(result.source, ServiceSource.romaniaApi);
        // Five calls, one per catalog product id.
        final captured = verify(() => mockDio.get(
              any(),
              queryParameters: captureAny(named: 'queryParameters'),
              cancelToken: any(named: 'cancelToken'),
            )).captured;
        expect(captured, hasLength(5));
        final requestedIds = captured
            .map((qp) =>
                (qp as Map<String, dynamic>)['CSVGasCatalogProductIds'])
            .toSet();
        expect(requestedIds, {'11', '12', '21', '22', '31'});
        for (final qp in captured) {
          final m = qp as Map<String, dynamic>;
          expect(m['lon'], 26.10);
          expect(m['lat'], 44.43);
          expect(m['buffer'], 5000);
          expect(m['OrderBy'], 'dist');
        }

        // 3 stations in the slice, each with petrol AND diesel merged.
        expect(result.data, hasLength(3));
        final vulcan =
            result.data.singleWhere((s) => s.id == 'ro-041B11');
        expect(vulcan.name, 'Vulcan Judetu (Bucuresti)');
        expect(vulcan.brand, 'Rompetrol');
        expect(vulcan.lat, closeTo(44.421467, 0.0001));
        expect(vulcan.lng, closeTo(26.136633, 0.0001));
        expect(vulcan.street, contains('Mihai Bravu'));
        expect(vulcan.place, 'Bucuresti');
        expect(vulcan.e5, closeTo(8.88, 0.001));
        expect(vulcan.diesel, isNotNull);
        expect(vulcan.updatedAt, isNotNull);
      });

      test('every station id carries the ro- prefix for currency routing',
          () async {
        when(() => mockDio.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
              cancelToken: any(named: 'cancelToken'),
            )).thenAnswer((_) async => response(
                _fixture('ro_monitorul_benzina_standard_slice.json')));

        final result = await service.searchStations(params);
        expect(result.data, isNotEmpty);
        expect(result.data.every((s) => s.id.startsWith('ro-')), isTrue);
      });

      test('clamps an absurd radius to the 30 km buffer ceiling', () async {
        when(() => mockDio.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
              cancelToken: any(named: 'cancelToken'),
            )).thenAnswer((_) async => response(<String, dynamic>{
              'Stations': <dynamic>[],
              'Products': <dynamic>[],
            }));

        const huge = SearchParams(lat: 44.43, lng: 26.10, radiusKm: 10000);
        await service.searchStations(huge);

        final captured = verify(() => mockDio.get(
              any(),
              queryParameters: captureAny(named: 'queryParameters'),
              cancelToken: any(named: 'cancelToken'),
            )).captured.first as Map<String, dynamic>;
        expect(captured['buffer'], 30000);
      });

      test('bare empty-list body (live-verified backend quirk) → empty '
          'result, not an error', () async {
        when(() => mockDio.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
              cancelToken: any(named: 'cancelToken'),
            )).thenAnswer((_) async => response(<dynamic>[]));

        final result = await service.searchStations(params);
        expect(result.data, isEmpty);
        expect(result.source, ServiceSource.romaniaApi);
      });

      test('backend exception envelope raises ApiException', () async {
        // Live-recorded WebAPI error shape (Npgsql error, 2026-06-10).
        when(() => mockDio.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
              cancelToken: any(named: 'cancelToken'),
            )).thenAnswer((_) async => response(<String, dynamic>{
              'Message': 'An error has occurred.',
              'ExceptionMessage':
                  '22P02: invalid input syntax for type integer: "11,21"',
              'ExceptionType': 'Npgsql.PostgresException',
            }));

        await expectLater(
          () => service.searchStations(params),
          throwsA(isA<ApiException>().having(
            (e) => e.message,
            'message',
            contains('Monitorul'),
          )),
        );
      });

      test('network failure is re-raised as ApiException', () async {
        when(() => mockDio.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
              cancelToken: any(named: 'cancelToken'),
            )).thenThrow(DioException(
          type: DioExceptionType.connectionTimeout,
          requestOptions: RequestOptions(),
        ));

        await expectLater(
          () => service.searchStations(params),
          throwsA(isA<ApiException>()),
        );
      });

      test('HTTP 404 surfaces the status code (the failure mode that '
          'killed the old endpoint)', () async {
        when(() => mockDio.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
              cancelToken: any(named: 'cancelToken'),
            )).thenThrow(DioException(
          requestOptions: RequestOptions(),
          response: Response(
            requestOptions: RequestOptions(),
            statusCode: 404,
          ),
          type: DioExceptionType.badResponse,
        ));

        await expectLater(
          () => service.searchStations(params),
          throwsA(isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 404)),
        );
      });
    });

    group('parseSingleProductResponse (recorded fixture)', () {
      test('parses the real benzina-standard slice', () {
        final stations = service.parseSingleProductResponse(
          _fixture('ro_monitorul_benzina_standard_slice.json'),
          FuelType.e5,
          fromLat: 44.43,
          fromLng: 26.10,
        );

        expect(stations, hasLength(3));
        final byId = {for (final s in stations) s.id: s};
        expect(byId.keys,
            containsAll(['ro-041B11', 'ro-J012', 'ro-R1009']));
        // Real recorded prices.
        expect(byId['ro-R1009']!.e5, closeTo(9.12, 0.001));
        expect(byId['ro-041B11']!.e5, closeTo(8.88, 0.001));
        expect(byId['ro-J012']!.e5, closeTo(9.18, 0.001));
        // No other fuel may be stamped from a single-product call.
        expect(byId['ro-R1009']!.diesel, isNull);
        expect(byId['ro-R1009']!.lpg, isNull);
      });

      test('parses the real motorina-standard slice onto the diesel slot',
          () {
        final stations = service.parseSingleProductResponse(
          _fixture('ro_monitorul_motorina_standard_slice.json'),
          FuelType.diesel,
          fromLat: 44.43,
          fromLng: 26.10,
        );
        expect(stations, hasLength(3));
        expect(stations.every((s) => s.diesel != null), isTrue);
        expect(stations.every((s) => s.e5 == null), isTrue);
      });

      test('station without any recognised price is dropped', () {
        final stations = service.parseSingleProductResponse(
          <String, dynamic>{
            'Stations': [
              <String, dynamic>{
                'id': 'X1',
                'name': 'No prices here',
                'addr': <String, dynamic>{
                  'location': <String, dynamic>{'Lat': 44.4, 'Lon': 26.1},
                },
              },
            ],
            'Products': <dynamic>[],
          },
          FuelType.e5,
          fromLat: 44.43,
          fromLng: 26.10,
        );
        expect(stations, isEmpty);
      });

      test('station with missing coordinates is dropped', () {
        final stations = service.parseSingleProductResponse(
          <String, dynamic>{
            'Stations': [
              <String, dynamic>{'id': 'X1', 'name': 'no coords'},
            ],
            'Products': [
              <String, dynamic>{'stationid': 'X1', 'price': 7.5},
            ],
          },
          FuelType.e5,
          fromLat: 44.43,
          fromLng: 26.10,
        );
        expect(stations, isEmpty);
      });

      test('name falls back to the network brand — no hardcoded literal',
          () {
        final stations = service.parseSingleProductResponse(
          <String, dynamic>{
            'Stations': [
              <String, dynamic>{
                'id': 'X1',
                'network': <String, dynamic>{'id': 'MOL', 'name': 'MOL'},
                'addr': <String, dynamic>{
                  'location': <String, dynamic>{'Lat': 44.4, 'Lon': 26.1},
                },
              },
            ],
            'Products': [
              <String, dynamic>{'stationid': 'X1', 'price': 7.5},
            ],
          },
          FuelType.e5,
          fromLat: 44.43,
          fromLng: 26.10,
        );
        expect(stations, hasLength(1));
        expect(stations.first.name, 'MOL');
      });

      test('zero / junk prices are filtered out', () {
        final stations = service.parseSingleProductResponse(
          <String, dynamic>{
            'Stations': [
              <String, dynamic>{
                'id': 'X1',
                'name': 'Zero price',
                'addr': <String, dynamic>{
                  'location': <String, dynamic>{'Lat': 44.4, 'Lon': 26.1},
                },
              },
            ],
            'Products': [
              <String, dynamic>{'stationid': 'X1', 'price': 0},
            ],
          },
          FuelType.e5,
          fromLat: 44.43,
          fromLng: 26.10,
        );
        expect(stations, isEmpty);
      });

      test('unparseable top-level body raises ApiException', () {
        expect(
          () => service.parseSingleProductResponse(
            'garbage',
            FuelType.e5,
            fromLat: 44.43,
            fromLng: 26.10,
          ),
          throwsA(isA<ApiException>()),
        );
      });
    });

    group('fuelForCatalogProductId', () {
      test('delegates to RomaniaObservatoryKeys', () {
        expect(RomaniaStationService.fuelForCatalogProductId('11'),
            FuelType.e5);
        expect(RomaniaStationService.fuelForCatalogProductId('41'), isNull);
      });
    });

    group('getStationDetail', () {
      test('throws ApiException (detail not available)', () {
        expect(
          () => service.getStationDetail('ro-123'),
          throwsA(isA<ApiException>()),
        );
      });
    });

    group('getPrices', () {
      test('returns empty map', () async {
        final result = await service.getPrices(['ro-1']);
        expect(result.data, isEmpty);
        expect(result.source, ServiceSource.romaniaApi);
      });
    });

    group('station id prefix routing', () {
      test('Countries.countryCodeForStationId resolves ro- → RO', () {
        expect(Countries.countryCodeForStationId('ro-041B11'), 'RO');
      });
    });
  });
}
