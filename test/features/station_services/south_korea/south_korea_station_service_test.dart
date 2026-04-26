import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/country/country_config.dart';
import 'package:tankstellen/core/error/exceptions.dart';
import 'package:tankstellen/features/station_services/south_korea/south_korea_station_service.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/services/station_service.dart';
import 'package:tankstellen/features/search/data/models/search_params.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

import '../../../mocks/mocks.dart';

/// A single OPINET `RESULT.OIL[]` entry as returned by the developer
/// portal's `aroundAll.do` endpoint. KRW prices are integer strings.
Map<String, dynamic> _opinetStation({
  String uniId = 'A0010684',
  String brandCode = 'SKE',
  String name = 'SK에너지 강남주유소',
  String address = '서울특별시 강남구 테헤란로 152',
  double lng = 127.0287, // GIS_X_COOR
  double lat = 37.4997, // GIS_Y_COOR
  int? priceWon = 1689,
  num? distanceMeters = 382,
}) {
  return <String, dynamic>{
    'UNI_ID': uniId,
    'POLL_DIV_CD': brandCode,
    'OS_NM': name,
    'NEW_ADR': address,
    'GIS_X_COOR': lng.toString(),
    'GIS_Y_COOR': lat.toString(),
    if (priceWon != null) 'PRICE': priceWon.toString(),
    if (distanceMeters != null) 'DISTANCE': distanceMeters.toString(),
  };
}

Map<String, dynamic> _envelope(List<Map<String, dynamic>> oil) =>
    <String, dynamic>{
      'RESULT': <String, dynamic>{
        'OIL': oil,
      },
    };

void main() {
  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  late MockDio mockDio;
  late SouthKoreaStationService service;

  setUp(() {
    mockDio = MockDio();
    service = SouthKoreaStationService(apiKey: 'test-key', dio: mockDio);
  });

  Response<dynamic> response(dynamic data) => Response<dynamic>(
        requestOptions: RequestOptions(),
        statusCode: 200,
        data: data,
      );

  group('SouthKoreaStationService', () {
    test('implements StationService', () {
      expect(service, isA<StationService>());
    });

    test('country registered as KR with KRW currency', () {
      final kr = Countries.byCode('KR');
      expect(kr, isNotNull);
      expect(kr!.currency, 'KRW');
      expect(kr.requiresApiKey, isTrue);
      expect(kr.apiProvider, contains('OPINET'));
    });

    group('fuel product-code mapping', () {
      test('B027 Gasoline → e5', () {
        expect(SouthKoreaStationService.fuelForProductCode('B027'),
            FuelType.e5);
      });

      test('B034 Premium Gasoline → e98', () {
        expect(SouthKoreaStationService.fuelForProductCode('B034'),
            FuelType.e98);
      });

      test('D047 Diesel → diesel', () {
        expect(SouthKoreaStationService.fuelForProductCode('D047'),
            FuelType.diesel);
      });

      test('K015 LPG → lpg', () {
        expect(SouthKoreaStationService.fuelForProductCode('K015'),
            FuelType.lpg);
      });

      test('Kerosene (C004) is intentionally unmapped until an enum lands',
          () {
        expect(SouthKoreaStationService.fuelForProductCode('C004'), isNull);
      });
    });

    group('searchStations', () {
      test('throws when no API key is configured', () async {
        final noKey = SouthKoreaStationService(apiKey: '', dio: mockDio);
        const params = SearchParams(lat: 37.5, lng: 127.0, radiusKm: 5.0);
        await expectLater(
          () => noKey.searchStations(params),
          throwsA(isA<ApiException>()),
        );
      });

      test('fetches every product code and merges prices by UNI_ID',
          () async {
        // OPINET returns one product per call; the service fires four
        // requests (e5, e98, diesel, lpg) and merges results by station.
        when(() => mockDio.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
              cancelToken: any(named: 'cancelToken'),
            )).thenAnswer((invocation) async {
          final qp = invocation.namedArguments[#queryParameters]
              as Map<String, dynamic>;
          switch (qp['prodcd'] as String) {
            case 'B027': // gasoline
              return response(_envelope([_opinetStation(priceWon: 1689)]));
            case 'B034': // premium gasoline
              return response(_envelope([_opinetStation(priceWon: 1999)]));
            case 'D047': // diesel
              return response(_envelope([_opinetStation(priceWon: 1520)]));
            case 'K015': // lpg
              return response(_envelope([_opinetStation(priceWon: 1050)]));
            default:
              return response(_envelope([]));
          }
        });

        const params = SearchParams(lat: 37.4997, lng: 127.0287, radiusKm: 5.0);
        final result = await service.searchStations(params);

        expect(result.source, ServiceSource.openinetApi);
        expect(result.data, hasLength(1));

        final s = result.data.first;
        expect(s.id, 'kr-A0010684');
        expect(s.brand, 'SK에너지');
        expect(s.name, 'SK에너지 강남주유소');
        expect(s.street, contains('테헤란로'));
        expect(s.lat, closeTo(37.4997, 0.001));
        expect(s.lng, closeTo(127.0287, 0.001));
        expect(s.e5, closeTo(1689, 0.001));
        expect(s.e98, closeTo(1999, 0.001));
        expect(s.diesel, closeTo(1520, 0.001));
        expect(s.lpg, closeTo(1050, 0.001));
        // DISTANCE 382 m → 0.4 km (rounded to 1 decimal).
        expect(s.dist, closeTo(0.4, 0.1));
      });

      test('sends API key and coordinates in query parameters', () async {
        when(() => mockDio.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
              cancelToken: any(named: 'cancelToken'),
            )).thenAnswer((_) async => response(_envelope([])));

        const params = SearchParams(lat: 37.5, lng: 127.0, radiusKm: 5.0);
        await service.searchStations(params);

        final captured = verify(() => mockDio.get(
              any(),
              queryParameters: captureAny(named: 'queryParameters'),
              cancelToken: any(named: 'cancelToken'),
            )).captured;
        // Four calls (one per product).
        expect(captured, hasLength(4));
        for (final qp in captured) {
          final m = qp as Map<String, dynamic>;
          expect(m['code'], 'test-key');
          // OPINET uses x=lng, y=lat (WGS84).
          expect(m['x'], 127.0);
          expect(m['y'], 37.5);
          expect(m['radius'], 5000);
          expect(m['out'], 'json');
        }
      });

      test('clamps absurdly large radius to 50 km', () async {
        when(() => mockDio.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
              cancelToken: any(named: 'cancelToken'),
            )).thenAnswer((_) async => response(_envelope([])));

        const params = SearchParams(lat: 37.5, lng: 127.0, radiusKm: 10000);
        await service.searchStations(params);

        final captured = verify(() => mockDio.get(
              any(),
              queryParameters: captureAny(named: 'queryParameters'),
              cancelToken: any(named: 'cancelToken'),
            )).captured.first as Map<String, dynamic>;
        expect(captured['radius'], 50000);
      });

      test('empty radius search → empty list, not an error', () async {
        when(() => mockDio.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
              cancelToken: any(named: 'cancelToken'),
            )).thenAnswer((_) async => response(_envelope([])));

        const params = SearchParams(lat: 37.5, lng: 127.0, radiusKm: 5.0);
        final result = await service.searchStations(params);
        expect(result.data, isEmpty);
        expect(result.source, ServiceSource.openinetApi);
      });

      test('HTTP 401 is re-raised as ApiException with clear message',
          () async {
        when(() => mockDio.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
              cancelToken: any(named: 'cancelToken'),
            )).thenThrow(DioException(
          requestOptions: RequestOptions(),
          response: Response(
            requestOptions: RequestOptions(),
            statusCode: 401,
          ),
          type: DioExceptionType.badResponse,
        ));

        const params = SearchParams(lat: 37.5, lng: 127.0, radiusKm: 5.0);
        try {
          await service.searchStations(params);
          fail('Expected ApiException');
        } on ApiException catch (e) {
          expect(e.statusCode, 401);
          expect(e.message, contains('OPINET'));
        }
      });

      test('HTTP 403 is re-raised as ApiException', () async {
        when(() => mockDio.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
              cancelToken: any(named: 'cancelToken'),
            )).thenThrow(DioException(
          requestOptions: RequestOptions(),
          response: Response(
            requestOptions: RequestOptions(),
            statusCode: 403,
          ),
          type: DioExceptionType.badResponse,
        ));

        const params = SearchParams(lat: 37.5, lng: 127.0, radiusKm: 5.0);
        await expectLater(
          () => service.searchStations(params),
          throwsA(isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 403)),
        );
      });

      test('network timeout is re-raised as ApiException', () async {
        when(() => mockDio.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
              cancelToken: any(named: 'cancelToken'),
            )).thenThrow(DioException(
          type: DioExceptionType.connectionTimeout,
          requestOptions: RequestOptions(),
        ));

        const params = SearchParams(lat: 37.5, lng: 127.0, radiusKm: 5.0);
        await expectLater(
          () => service.searchStations(params),
          throwsA(isA<ApiException>()),
        );
      });

      test('every parsed station id starts with `kr-`', () async {
        when(() => mockDio.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
              cancelToken: any(named: 'cancelToken'),
            )).thenAnswer((_) async => response(_envelope([
              _opinetStation(uniId: 'A0010001'),
              _opinetStation(uniId: 'A0010002'),
              _opinetStation(uniId: 'A0010003'),
            ])));

        const params = SearchParams(lat: 37.5, lng: 127.0, radiusKm: 5.0);
        final result = await service.searchStations(params);

        expect(result.data, isNotEmpty);
        expect(
          result.data.every((s) => s.id.startsWith('kr-')),
          isTrue,
          reason: 'Every KR station id must carry the kr- prefix so '
              'the favorites currency lookup finds it.',
        );
      });
    });

    group('parseSingleProductResponse', () {
      test('maps OPINET KRW integer strings to numeric prices', () {
        final stations = service.parseSingleProductResponse(
          _envelope([_opinetStation(priceWon: 1689)]),
          FuelType.e5,
          fromLat: 37.4997,
          fromLng: 127.0287,
        );
        expect(stations, hasLength(1));
        expect(stations.first.e5, closeTo(1689, 0.001));
      });

      test('Kerosene-like entries would be dropped at the call site (no '
          'product code mapping)', () {
        // The service never issues a call for an unmapped product, so the
        // parser itself doesn't need to drop anything — we verify that the
        // mapping returns null for C004 at the product-code boundary.
        expect(SouthKoreaStationService.fuelForProductCode('C004'), isNull);
      });

      test('skips entries with missing coordinates', () {
        final stations = service.parseSingleProductResponse(
          <String, dynamic>{
            'RESULT': <String, dynamic>{
              'OIL': [
                <String, dynamic>{
                  'UNI_ID': 'X01',
                  // no lat/lng
                  'POLL_DIV_CD': 'SKE',
                  'OS_NM': 'no-coords',
                  'PRICE': '1600',
                },
                _opinetStation(uniId: 'Y01'),
              ],
            },
          },
          FuelType.e5,
          fromLat: 37.5,
          fromLng: 127.0,
        );
        expect(stations, hasLength(1));
        expect(stations.first.id, 'kr-Y01');
      });

      test('skips entries with 0/0 coords (bad upstream data)', () {
        final stations = service.parseSingleProductResponse(
          <String, dynamic>{
            'RESULT': <String, dynamic>{
              'OIL': [
                _opinetStation(uniId: 'Z01', lat: 0, lng: 0),
                _opinetStation(uniId: 'Z02'),
              ],
            },
          },
          FuelType.e5,
          fromLat: 37.5,
          fromLng: 127.0,
        );
        expect(stations, hasLength(1));
        expect(stations.first.id, 'kr-Z02');
      });

      test('returns empty list for empty OIL array', () {
        final stations = service.parseSingleProductResponse(
          _envelope([]),
          FuelType.e5,
          fromLat: 37.5,
          fromLng: 127.0,
        );
        expect(stations, isEmpty);
      });

      test('tolerates missing RESULT wrapper (empty envelope)', () {
        final stations = service.parseSingleProductResponse(
          <String, dynamic>{},
          FuelType.e5,
          fromLat: 37.5,
          fromLng: 127.0,
        );
        expect(stations, isEmpty);
      });

      test('tolerates non-numeric price strings (drops the price only)', () {
        final stations = service.parseSingleProductResponse(
          _envelope([_opinetStation(uniId: 'X1')])
            ..['RESULT']!['OIL'][0]['PRICE'] = 'N/A',
          FuelType.diesel,
          fromLat: 37.5,
          fromLng: 127.0,
        );
        expect(stations, hasLength(1));
        expect(stations.first.diesel, isNull);
      });

      test('unparseable top-level body raises ApiException', () {
        expect(
          () => service.parseSingleProductResponse(
            'garbage',
            FuelType.e5,
            fromLat: 37.5,
            fromLng: 127.0,
          ),
          throwsA(isA<ApiException>()),
        );
      });

      test('OPINET ERROR field raises ApiException', () {
        expect(
          () => service.parseSingleProductResponse(
            <String, dynamic>{'ERROR': 'invalid key'},
            FuelType.e5,
            fromLat: 37.5,
            fromLng: 127.0,
          ),
          throwsA(isA<ApiException>().having(
            (e) => e.message,
            'message',
            contains('OPINET'),
          )),
        );
      });

      test('maps POLL_DIV_CD to localized brand labels', () {
        final skStations = service.parseSingleProductResponse(
          _envelope([_opinetStation(uniId: '1', brandCode: 'SKE')]),
          FuelType.e5,
          fromLat: 37.5,
          fromLng: 127.0,
        );
        final gsStations = service.parseSingleProductResponse(
          _envelope([_opinetStation(uniId: '2', brandCode: 'GSC')]),
          FuelType.e5,
          fromLat: 37.5,
          fromLng: 127.0,
        );
        final unknownStations = service.parseSingleProductResponse(
          _envelope([_opinetStation(uniId: '3', brandCode: 'ETC')]),
          FuelType.e5,
          fromLat: 37.5,
          fromLng: 127.0,
        );
        expect(skStations.first.brand, 'SK에너지');
        expect(gsStations.first.brand, 'GS칼텍스');
        expect(unknownStations.first.brand, 'Independent');
      });
    });

    group('getStationDetail', () {
      test('throws ApiException (detail not available)', () {
        expect(
          () => service.getStationDetail('kr-123'),
          throwsA(isA<ApiException>()),
        );
      });

      test('error message mentions OPINET', () async {
        try {
          await service.getStationDetail('kr-test');
          fail('expected ApiException');
        } on ApiException catch (e) {
          expect(e.message, contains('OPINET'));
        }
      });
    });

    group('getPrices', () {
      test('returns empty map (no batch refresh)', () async {
        final result = await service.getPrices(['kr-1', 'kr-2']);
        expect(result.data, isEmpty);
        expect(result.source, ServiceSource.openinetApi);
      });

      test('returns empty map for empty id list', () async {
        final result = await service.getPrices([]);
        expect(result.data, isEmpty);
      });
    });

    group('station id prefix routing', () {
      test('Countries.countryCodeForStationId resolves kr- → KR', () {
        expect(
          Countries.countryCodeForStationId('kr-A0010684'),
          'KR',
        );
      });

      test('Countries.countryForStationId returns the KR config', () {
        final c = Countries.countryForStationId('kr-A0010684');
        expect(c, isNotNull);
        expect(c!.code, 'KR');
        expect(c.currency, 'KRW');
      });
    });
  });
}
