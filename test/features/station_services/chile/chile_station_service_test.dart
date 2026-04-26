import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/country/country_config.dart';
import 'package:tankstellen/core/error/exceptions.dart';
import 'package:tankstellen/features/station_services/chile/chile_station_service.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/services/station_service.dart';
import 'package:tankstellen/features/search/data/models/search_params.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

import '../../../mocks/mocks.dart';

/// One `data[]` entry from the CNE Bencina en Línea envelope. Mirrors
/// the documented shape (see [ChileStationService] docstring).
Map<String, dynamic> _cneStation({
  String codigo = '123456',
  String distribuidor = 'Copec',
  String name = 'Copec Providencia',
  String calle = 'Av. Providencia',
  String numero = '1234',
  String comuna = 'Providencia',
  double lat = -33.4254,
  double lng = -70.6115,
  Map<String, dynamic>? precios,
  String horario = '24_horas',
}) {
  return <String, dynamic>{
    'codigo': codigo,
    'distribuidor': <String, dynamic>{'nombre': distribuidor},
    'nombre_fantasia': name,
    'direccion_calle': calle,
    'direccion_numero': numero,
    'nombre_comuna': comuna,
    'ubicacion': <String, dynamic>{'latitud': lat, 'longitud': lng},
    'precios': precios ??
        <String, dynamic>{
          'gasolina_93': 1290.0,
          'gasolina_95': 1310.0,
          'gasolina_97': 1340.0,
          'diesel': 1150.0,
          'glp': 820.0,
          'kerosene': 1050.0,
        },
    'horario_atencion': horario,
  };
}

Map<String, dynamic> _envelope(List<Map<String, dynamic>> data) =>
    <String, dynamic>{'data': data};

void main() {
  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  late MockDio mockDio;
  late ChileStationService service;

  setUp(() {
    mockDio = MockDio();
    service = ChileStationService(apiKey: 'test-key', dio: mockDio);
  });

  Response<dynamic> response(dynamic data) => Response<dynamic>(
        requestOptions: RequestOptions(),
        statusCode: 200,
        data: data,
      );

  group('ChileStationService', () {
    test('implements StationService', () {
      expect(service, isA<StationService>());
    });

    test('country registered as CL with CLP currency', () {
      final cl = Countries.byCode('CL');
      expect(cl, isNotNull);
      expect(cl!.currency, 'CLP');
      expect(cl.requiresApiKey, isTrue);
      expect(cl.apiProvider, contains('CNE'));
    });

    group('fuel product-key mapping', () {
      test('gasolina_93 → e5', () {
        expect(
          ChileStationService.fuelForProductKey('gasolina_93'),
          FuelType.e5,
        );
      });

      test('gasolina_95 → e5', () {
        expect(
          ChileStationService.fuelForProductKey('gasolina_95'),
          FuelType.e5,
        );
      });

      test('gasolina_97 → e98', () {
        expect(
          ChileStationService.fuelForProductKey('gasolina_97'),
          FuelType.e98,
        );
      });

      test('diesel → diesel', () {
        expect(
          ChileStationService.fuelForProductKey('diesel'),
          FuelType.diesel,
        );
      });

      test('glp → lpg', () {
        expect(
          ChileStationService.fuelForProductKey('glp'),
          FuelType.lpg,
        );
      });

      test('gas_licuado (alternate spelling) → lpg', () {
        expect(
          ChileStationService.fuelForProductKey('gas_licuado'),
          FuelType.lpg,
        );
      });

      test('kerosene is intentionally unmapped until an enum lands', () {
        expect(
          ChileStationService.fuelForProductKey('kerosene'),
          isNull,
        );
        expect(
          ChileStationService.droppedProductKeys,
          contains('kerosene'),
        );
      });

      test('mapping is case-insensitive', () {
        expect(
          ChileStationService.fuelForProductKey('GASOLINA_93'),
          FuelType.e5,
        );
      });
    });

    group('searchStations', () {
      test('throws when no API key is configured', () async {
        final noKey = ChileStationService(apiKey: '', dio: mockDio);
        const params = SearchParams(lat: -33.45, lng: -70.67, radiusKm: 5.0);
        await expectLater(
          () => noKey.searchStations(params),
          throwsA(isA<ApiException>()),
        );
      });

      test('sends API key as a query parameter', () async {
        when(() => mockDio.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
              cancelToken: any(named: 'cancelToken'),
            )).thenAnswer((_) async => response(_envelope([])));

        const params = SearchParams(lat: -33.45, lng: -70.67, radiusKm: 5.0);
        await service.searchStations(params);

        final captured = verify(() => mockDio.get(
              any(),
              queryParameters: captureAny(named: 'queryParameters'),
              cancelToken: any(named: 'cancelToken'),
            )).captured.single as Map<String, dynamic>;
        expect(captured['token'], 'test-key');
      });

      test('parses the CNE envelope into Stations with cl- prefix', () async {
        when(() => mockDio.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
              cancelToken: any(named: 'cancelToken'),
            )).thenAnswer((_) async => response(_envelope([_cneStation()])));

        const params = SearchParams(lat: -33.4254, lng: -70.6115, radiusKm: 5);
        final result = await service.searchStations(params);

        expect(result.source, ServiceSource.chileApi);
        expect(result.data, hasLength(1));

        final s = result.data.first;
        expect(s.id, 'cl-123456');
        expect(s.brand, 'Copec');
        expect(s.name, 'Copec Providencia');
        expect(s.street, contains('Providencia'));
        expect(s.place, 'Providencia');
        expect(s.lat, closeTo(-33.4254, 0.0001));
        expect(s.lng, closeTo(-70.6115, 0.0001));

        // Gasolina 95 should win over 93 for the e5 slot.
        expect(s.e5, closeTo(1310.0, 0.001));
        expect(s.e98, closeTo(1340.0, 0.001));
        expect(s.diesel, closeTo(1150.0, 0.001));
        expect(s.lpg, closeTo(820.0, 0.001));
      });

      test('empty data → empty list, not an error', () async {
        when(() => mockDio.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
              cancelToken: any(named: 'cancelToken'),
            )).thenAnswer((_) async => response(_envelope([])));

        const params = SearchParams(lat: -33.45, lng: -70.67, radiusKm: 5.0);
        final result = await service.searchStations(params);
        expect(result.data, isEmpty);
        expect(result.source, ServiceSource.chileApi);
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

        const params = SearchParams(lat: -33.45, lng: -70.67, radiusKm: 5.0);
        try {
          await service.searchStations(params);
          fail('Expected ApiException');
        } on ApiException catch (e) {
          expect(e.statusCode, 401);
          expect(e.message, contains('CNE'));
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

        const params = SearchParams(lat: -33.45, lng: -70.67, radiusKm: 5.0);
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

        const params = SearchParams(lat: -33.45, lng: -70.67, radiusKm: 5.0);
        await expectLater(
          () => service.searchStations(params),
          throwsA(isA<ApiException>()),
        );
      });

      test('every parsed station id starts with `cl-`', () async {
        when(() => mockDio.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
              cancelToken: any(named: 'cancelToken'),
            )).thenAnswer((_) async => response(_envelope([
              _cneStation(codigo: '000001'),
              _cneStation(codigo: '000002'),
              _cneStation(codigo: '000003'),
            ])));

        const params = SearchParams(lat: -33.45, lng: -70.67, radiusKm: 10.0);
        final result = await service.searchStations(params);

        expect(result.data, isNotEmpty);
        expect(
          result.data.every((s) => s.id.startsWith('cl-')),
          isTrue,
          reason: 'Every CL station id must carry the cl- prefix so the '
              'favorites currency lookup finds it.',
        );
      });

      test('codigo already prefixed `cl-` is not double-prefixed', () async {
        when(() => mockDio.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
              cancelToken: any(named: 'cancelToken'),
            )).thenAnswer((_) async => response(_envelope([
              _cneStation(codigo: 'cl-987654'),
            ])));

        const params = SearchParams(lat: -33.45, lng: -70.67, radiusKm: 10.0);
        final result = await service.searchStations(params);
        expect(result.data.single.id, 'cl-987654');
      });
    });

    group('parseStationsResponse', () {
      test('drops kerosene silently (MVP: no FuelType enum)', () {
        final stations = service.parseStationsResponse(
          _envelope([
            _cneStation(precios: <String, dynamic>{
              'diesel': 1150.0,
              'kerosene': 1050.0, // dropped
            }),
          ]),
          fromLat: -33.45,
          fromLng: -70.67,
        );
        expect(stations, hasLength(1));
        final s = stations.first;
        expect(s.diesel, closeTo(1150.0, 0.001));
        // No kerosene slot exists on Station — just assert the known
        // slots remain null.
        expect(s.e5, isNull);
        expect(s.e98, isNull);
        expect(s.lpg, isNull);
      });

      test('93 alone fills the e5 slot', () {
        final stations = service.parseStationsResponse(
          _envelope([
            _cneStation(precios: <String, dynamic>{'gasolina_93': 1250.0}),
          ]),
          fromLat: -33.45,
          fromLng: -70.67,
        );
        expect(stations.single.e5, closeTo(1250.0, 0.001));
      });

      test('95 wins over 93 when both are quoted', () {
        final stations = service.parseStationsResponse(
          _envelope([
            _cneStation(precios: <String, dynamic>{
              'gasolina_93': 1250.0,
              'gasolina_95': 1299.0,
            }),
          ]),
          fromLat: -33.45,
          fromLng: -70.67,
        );
        expect(stations.single.e5, closeTo(1299.0, 0.001));
      });

      test('skips entries with missing coordinates', () {
        final stations = service.parseStationsResponse(
          <String, dynamic>{
            'data': [
              <String, dynamic>{
                'codigo': 'X01',
                'distribuidor': 'Shell',
                'nombre_fantasia': 'no-coords',
                // no ubicacion
                'precios': <String, dynamic>{'diesel': 1100.0},
              },
              _cneStation(codigo: 'Y01'),
            ],
          },
          fromLat: -33.45,
          fromLng: -70.67,
        );
        expect(stations, hasLength(1));
        expect(stations.first.id, 'cl-Y01');
      });

      test('skips entries with 0/0 coords (bad upstream data)', () {
        final stations = service.parseStationsResponse(
          _envelope([
            _cneStation(codigo: 'Z01', lat: 0, lng: 0),
            _cneStation(codigo: 'Z02'),
          ]),
          fromLat: -33.45,
          fromLng: -70.67,
        );
        expect(stations, hasLength(1));
        expect(stations.first.id, 'cl-Z02');
      });

      test('returns empty list for empty data array', () {
        final stations = service.parseStationsResponse(
          _envelope([]),
          fromLat: -33.45,
          fromLng: -70.67,
        );
        expect(stations, isEmpty);
      });

      test('tolerates missing data wrapper (empty envelope)', () {
        final stations = service.parseStationsResponse(
          <String, dynamic>{},
          fromLat: -33.45,
          fromLng: -70.67,
        );
        expect(stations, isEmpty);
      });

      test('tolerates non-numeric price strings (drops the price only)', () {
        final stations = service.parseStationsResponse(
          _envelope([
            _cneStation(precios: <String, dynamic>{
              'diesel': 'N/A',
              'gasolina_95': 1299.0,
            }),
          ]),
          fromLat: -33.45,
          fromLng: -70.67,
        );
        expect(stations, hasLength(1));
        expect(stations.first.diesel, isNull);
        expect(stations.first.e5, closeTo(1299.0, 0.001));
      });

      test('unparseable top-level body raises ApiException', () {
        expect(
          () => service.parseStationsResponse(
            'garbage',
            fromLat: -33.45,
            fromLng: -70.67,
          ),
          throwsA(isA<ApiException>()),
        );
      });

      test('CNE error field without data raises ApiException', () {
        expect(
          () => service.parseStationsResponse(
            <String, dynamic>{'error': 'invalid token'},
            fromLat: -33.45,
            fromLng: -70.67,
          ),
          throwsA(isA<ApiException>().having(
            (e) => e.message,
            'message',
            contains('CNE'),
          )),
        );
      });

      test('distribuidor can be a flat string (older payloads)', () {
        final stations = service.parseStationsResponse(
          <String, dynamic>{
            'data': [
              <String, dynamic>{
                'codigo': 'A1',
                'distribuidor': 'Petrobras',
                'nombre_fantasia': 'Petrobras Las Condes',
                'ubicacion': <String, dynamic>{
                  'latitud': -33.40,
                  'longitud': -70.55,
                },
                'precios': <String, dynamic>{'diesel': 1160.0},
              },
            ],
          },
          fromLat: -33.45,
          fromLng: -70.67,
        );
        expect(stations.single.brand, 'Petrobras');
      });

      test('flat latitud/longitud on the station is accepted', () {
        final stations = service.parseStationsResponse(
          <String, dynamic>{
            'data': [
              <String, dynamic>{
                'codigo': 'A2',
                'latitud': -33.40,
                'longitud': -70.55,
                'precios': <String, dynamic>{'diesel': 1160.0},
              },
            ],
          },
          fromLat: -33.45,
          fromLng: -70.67,
        );
        expect(stations, hasLength(1));
        expect(stations.first.lat, closeTo(-33.40, 0.0001));
      });
    });

    group('getStationDetail', () {
      test('throws ApiException (detail not available)', () {
        expect(
          () => service.getStationDetail('cl-123'),
          throwsA(isA<ApiException>()),
        );
      });

      test('error message mentions CNE', () async {
        try {
          await service.getStationDetail('cl-test');
          fail('expected ApiException');
        } on ApiException catch (e) {
          expect(e.message, contains('CNE'));
        }
      });
    });

    group('getPrices', () {
      test('returns empty map (no batch refresh)', () async {
        final result = await service.getPrices(['cl-1', 'cl-2']);
        expect(result.data, isEmpty);
        expect(result.source, ServiceSource.chileApi);
      });

      test('returns empty map for empty id list', () async {
        final result = await service.getPrices([]);
        expect(result.data, isEmpty);
      });
    });

    group('station id prefix routing', () {
      test('Countries.countryCodeForStationId resolves cl- → CL', () {
        expect(
          Countries.countryCodeForStationId('cl-123456'),
          'CL',
        );
      });

      test('Countries.countryForStationId returns the CL config', () {
        final c = Countries.countryForStationId('cl-123456');
        expect(c, isNotNull);
        expect(c!.code, 'CL');
        expect(c.currency, 'CLP');
      });
    });
  });
}
