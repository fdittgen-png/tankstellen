import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/error/exceptions.dart';
import 'package:tankstellen/core/services/impl/tankerkoenig_station_service.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/features/search/data/models/search_params.dart';

import '../../../mocks/mocks.dart';

void main() {
  late MockDio mockDio;
  late TankerkoenigStationService service;

  setUp(() {
    mockDio = MockDio();
    service = TankerkoenigStationService(mockDio);
  });

  group('searchStations', () {
    test('parses valid response with stations', () async {
      when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters'), cancelToken: any(named: 'cancelToken')))
          .thenAnswer((_) async => Response(
                requestOptions: RequestOptions(),
                statusCode: 200,
                data: {
                  'ok': true,
                  'stations': [
                    {
                      'id': '51d4b477-a095-1aa0-e100-80009459e03a',
                      'name': 'STAR TANKSTELLE',
                      'brand': 'STAR',
                      'street': 'Musterstraße',
                      'postCode': 10115,
                      'place': 'Berlin',
                      'lat': 52.52,
                      'lng': 13.405,
                      'dist': 2.5,
                      'isOpen': true,
                      'e5': 1.859,
                      'e10': 1.799,
                      'diesel': 1.659,
                    },
                  ],
                },
              ));

      const params = SearchParams(lat: 52.52, lng: 13.405, radiusKm: 10.0);
      final result = await service.searchStations(params);

      expect(result.data, hasLength(1));
      expect(result.data.first.brand, 'STAR');
      expect(result.data.first.e10, 1.799);
      expect(result.source, ServiceSource.tankerkoenigApi);
    });

    test('returns empty list for empty stations array', () async {
      when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters'), cancelToken: any(named: 'cancelToken')))
          .thenAnswer((_) async => Response(
                requestOptions: RequestOptions(),
                data: {'ok': true, 'stations': []},
              ));

      const params = SearchParams(lat: 52.52, lng: 13.405, radiusKm: 10.0);
      final result = await service.searchStations(params);

      expect(result.data, isEmpty);
    });

    test('throws ApiException when ok is false', () async {
      when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters'), cancelToken: any(named: 'cancelToken')))
          .thenAnswer((_) async => Response(
                requestOptions: RequestOptions(),
                data: {'ok': false, 'message': 'Invalid API key'},
              ));

      const params = SearchParams(lat: 52.52, lng: 13.405, radiusKm: 10.0);
      expect(
        () => service.searchStations(params),
        throwsA(isA<ApiException>()),
      );
    });

    test('throws on DioException', () async {
      when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters'), cancelToken: any(named: 'cancelToken')))
          .thenThrow(DioException(
            type: DioExceptionType.connectionTimeout,
            requestOptions: RequestOptions(),
          ));

      const params = SearchParams(lat: 52.52, lng: 13.405, radiusKm: 10.0);
      expect(
        () => service.searchStations(params),
        throwsA(isA<AppException>()),
      );
    });
  });

  group('getStationDetail', () {
    test('parses valid detail response', () async {
      when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters')))
          .thenAnswer((_) async => Response(
                requestOptions: RequestOptions(),
                data: {
                  'ok': true,
                  'station': {
                    'id': 'test-id',
                    'name': 'ARAL',
                    'brand': 'ARAL',
                    'street': 'Hauptstr.',
                    'postCode': '10115',
                    'place': 'Berlin',
                    'lat': 52.52,
                    'lng': 13.405,
                    'isOpen': true,
                    'e5': 1.859,
                    'e10': 1.799,
                    'diesel': 1.659,
                    'openingTimes': [
                      {'text': 'Mo-Fr', 'start': '06:00:00', 'end': '22:00:00'},
                    ],
                    'overrides': ['Geschlossen am 25.12.'],
                    'wholeDay': false,
                    'state': 'Berlin',
                  },
                },
              ));

      final result = await service.getStationDetail('test-id');

      expect(result.data.station.brand, 'ARAL');
      expect(result.data.openingTimes, hasLength(1));
      expect(result.data.overrides, hasLength(1));
      expect(result.data.wholeDay, false);
      expect(result.data.state, 'Berlin');
    });

    test('handles missing openingTimes gracefully', () async {
      when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters')))
          .thenAnswer((_) async => Response(
                requestOptions: RequestOptions(),
                data: {
                  'ok': true,
                  'station': {
                    'id': 'test-id',
                    'name': 'Shell',
                    'brand': 'Shell',
                    'street': 'Test',
                    'postCode': '10115',
                    'place': 'Berlin',
                    'lat': 52.52,
                    'lng': 13.405,
                    'isOpen': true,
                  },
                },
              ));

      final result = await service.getStationDetail('test-id');

      expect(result.data.openingTimes, isEmpty);
      expect(result.data.overrides, isEmpty);
    });
  });

  group('getPrices', () {
    test('returns empty map for empty ids', () async {
      final result = await service.getPrices([]);
      expect(result.data, isEmpty);
      expect(result.source, ServiceSource.tankerkoenigApi);
    });

    test('parses valid prices response', () async {
      when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters')))
          .thenAnswer((_) async => Response(
                requestOptions: RequestOptions(),
                data: {
                  'ok': true,
                  'prices': {
                    'id-1': {'e5': 1.859, 'e10': 1.799, 'diesel': 1.659, 'status': 'open'},
                    'id-2': {'status': 'closed'},
                  },
                },
              ));

      final result = await service.getPrices(['id-1', 'id-2']);

      expect(result.data, hasLength(2));
      expect(result.data['id-1']!.e10, 1.799);
      expect(result.data['id-2']!.status, 'closed');
    });

    test('handles empty prices map', () async {
      when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters')))
          .thenAnswer((_) async => Response(
                requestOptions: RequestOptions(),
                data: <String, dynamic>{'ok': true, 'prices': <String, dynamic>{}},
              ));

      final result = await service.getPrices(['id-1']);
      expect(result.data, isEmpty);
    });
  });
}
