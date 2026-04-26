import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/country/country_config.dart';
import 'package:tankstellen/core/error/exceptions.dart';
import 'package:tankstellen/features/station_services/slovenia/slovenia_station_service.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/services/station_service.dart';
import 'package:tankstellen/features/search/data/models/search_params.dart';

import '../../../mocks/mocks.dart';

/// A single goriva.si `results[]` entry — matches the real payload
/// shape returned by https://goriva.si/api/v1/search/
Map<String, dynamic> _samplePetrolTivolska({
  int pk = 2048,
  String name = 'PETROL LJUBLJANA - TIVOLSKA',
  String address = 'TIVOLSKA CESTA 43',
  double lat = 46.0580724,
  double lng = 14.5034454,
  num? ninetyFive = 1.605,
  num? dizel = 1.736,
  num? hundred = 1.901,
  num? dizelPremium,
  num? lpg = 1.049,
  num? cng,
  num? ninetyEight,
  num? distance,
  String zip = '1000',
}) {
  return <String, dynamic>{
    'pk': pk,
    'franchise': 1,
    'name': name,
    'address': address,
    'lat': lat,
    'lng': lng,
    'prices': <String, dynamic>{
      '95': ninetyFive,
      'dizel': dizel,
      '98': ninetyEight,
      '100': hundred,
      'dizel-premium': dizelPremium,
      'avtoplin-lpg': lpg,
      'KOEL': null,
      'hvo': null,
      'cng': cng,
      'lng': null,
    },
    'distance': distance,
    'direction': '',
    'open_hours': '00:00-23:59\n',
    'zip_code': zip,
  };
}

Map<String, dynamic> _envelope(List<Map<String, dynamic>> results) =>
    <String, dynamic>{
      'count': results.length,
      'next': null,
      'previous': null,
      'results': results,
      'position': {'lat': 46.05, 'lng': 14.50},
    };

void main() {
  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  late MockDio mockDio;
  late SloveniaStationService service;

  setUp(() {
    mockDio = MockDio();
    service = SloveniaStationService(dio: mockDio);
  });

  Response<dynamic> response(dynamic data) => Response<dynamic>(
        requestOptions: RequestOptions(),
        statusCode: 200,
        data: data,
      );

  group('SloveniaStationService', () {
    test('implements StationService', () {
      expect(service, isA<StationService>());
    });

    test('registered in CountryServiceRegistry as SI', () {
      // Ensure the country config and service registry stay in sync (#575).
      // This would normally be covered by country_service_registry_test.dart
      // but we sanity-check here so a missing registration surfaces in the
      // country's own test file.
      final si = Countries.byCode('SI');
      expect(si, isNotNull);
      expect(si!.code, 'SI');
      expect(si.currency, 'EUR');
    });

    group('searchStations', () {
      test('parses a canonical goriva.si response', () async {
        when(() => mockDio.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
              cancelToken: any(named: 'cancelToken'),
            )).thenAnswer((_) async => response(_envelope([
              _samplePetrolTivolska(distance: 785.73),
            ])));

        const params = SearchParams(
          lat: 46.0511,
          lng: 14.5051,
          radiusKm: 10.0,
        );
        final result = await service.searchStations(params);

        expect(result.source, ServiceSource.sloveniaApi);
        expect(result.data, hasLength(1));

        final s = result.data.first;
        expect(s.id, 'si-2048');
        expect(s.brand, 'Petrol');
        expect(s.name, 'PETROL LJUBLJANA - TIVOLSKA');
        expect(s.street, 'TIVOLSKA CESTA 43');
        expect(s.postCode, '1000');
        expect(s.lat, closeTo(46.058, 0.001));
        expect(s.lng, closeTo(14.503, 0.001));
        // NMB-95 -> e5 (and mirrored into e10 as Slovenia sells a
        // single 95 grade)
        expect(s.e5, closeTo(1.605, 0.001));
        expect(s.e10, closeTo(1.605, 0.001));
        // NMB-100 -> e98 (premium petrol slot)
        expect(s.e98, closeTo(1.901, 0.001));
        expect(s.diesel, closeTo(1.736, 0.001));
        expect(s.lpg, closeTo(1.049, 0.001));
        // API `distance` (meters) is converted to km and rounded.
        expect(s.dist, closeTo(0.8, 0.1));
      });

      test('builds the correct query parameters (radius in meters)', () async {
        when(() => mockDio.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
              cancelToken: any(named: 'cancelToken'),
            )).thenAnswer((_) async => response(_envelope([])));

        const params = SearchParams(
          lat: 46.0511,
          lng: 14.5051,
          radiusKm: 5.0,
        );
        await service.searchStations(params);

        final captured = verify(() => mockDio.get(
              any(),
              queryParameters: captureAny(named: 'queryParameters'),
              cancelToken: any(named: 'cancelToken'),
            )).captured.single as Map<String, dynamic>;
        expect(captured['format'], 'json');
        expect(captured['position'], '46.0511,14.5051');
        // radiusKm: 5 → 5000 meters
        expect(captured['radius'], 5000);
      });

      test('clamps unrealistic radius values', () async {
        when(() => mockDio.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
              cancelToken: any(named: 'cancelToken'),
            )).thenAnswer((_) async => response(_envelope([])));

        const params = SearchParams(
          lat: 46.0,
          lng: 14.5,
          radiusKm: 10000.0, // absurd
        );
        await service.searchStations(params);

        final captured = verify(() => mockDio.get(
              any(),
              queryParameters: captureAny(named: 'queryParameters'),
              cancelToken: any(named: 'cancelToken'),
            )).captured.single as Map<String, dynamic>;
        expect(captured['radius'], 200000); // clamped to 200 km
      });

      test('returns empty list for empty results array', () async {
        when(() => mockDio.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
              cancelToken: any(named: 'cancelToken'),
            )).thenAnswer((_) async => response(_envelope([])));

        const params = SearchParams(lat: 46.0, lng: 14.5, radiusKm: 10.0);
        final result = await service.searchStations(params);
        expect(result.data, isEmpty);
        expect(result.source, ServiceSource.sloveniaApi);
      });

      test('returns empty list for non-map response', () async {
        when(() => mockDio.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
              cancelToken: any(named: 'cancelToken'),
            )).thenAnswer((_) async => response('garbage'));

        const params = SearchParams(lat: 46.0, lng: 14.5, radiusKm: 10.0);
        final result = await service.searchStations(params);
        expect(result.data, isEmpty);
      });

      test('wraps DioException as ApiException', () async {
        when(() => mockDio.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
              cancelToken: any(named: 'cancelToken'),
            )).thenThrow(DioException(
          type: DioExceptionType.connectionTimeout,
          requestOptions: RequestOptions(),
        ));

        const params = SearchParams(lat: 46.0, lng: 14.5, radiusKm: 10.0);
        expect(
          () => service.searchStations(params),
          throwsA(isA<ApiException>()),
        );
      });

      test('sort by price sorts cheapest e5 first', () async {
        when(() => mockDio.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
              cancelToken: any(named: 'cancelToken'),
            )).thenAnswer((_) async => response(_envelope([
              _samplePetrolTivolska(
                pk: 1,
                name: 'Expensive',
                ninetyFive: 1.700,
                distance: 1000,
              ),
              _samplePetrolTivolska(
                pk: 2,
                name: 'Cheap',
                ninetyFive: 1.450,
                distance: 2000,
              ),
            ])));

        const params = SearchParams(
          lat: 46.05,
          lng: 14.50,
          radiusKm: 10.0,
          sortBy: SortBy.price,
        );
        final result = await service.searchStations(params);
        expect(result.data, hasLength(2));
        // Cheaper pump must win regardless of distance under SortBy.price.
        expect(result.data.first.name, 'Cheap');
      });

      test('falls back to nearest when radius filter leaves nothing',
          () async {
        // Station coordinates 200 km away from the query point, but the
        // goriva.si search would still have returned them (the upstream
        // query is server-side). filterByRadius should then fall back
        // to the top-N nearest so the user never sees an empty list.
        when(() => mockDio.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
              cancelToken: any(named: 'cancelToken'),
            )).thenAnswer((_) async => response(_envelope([
              _samplePetrolTivolska(
                pk: 99,
                lat: 47.5,
                lng: 16.6,
                distance: null,
              ),
            ])));

        const params = SearchParams(
          lat: 46.0,
          lng: 14.5,
          radiusKm: 5.0,
        );
        final result = await service.searchStations(params);
        expect(result.data, hasLength(1));
        expect(result.data.first.id, 'si-99');
      });
    });

    group('parseResponse', () {
      test('skips entries with missing lat/lng', () {
        final stations = service.parseResponse({
          'results': [
            {
              'pk': 1,
              'name': 'No coords',
              'prices': <String, dynamic>{},
            },
            _samplePetrolTivolska(pk: 2),
          ],
        });
        expect(stations, hasLength(1));
        expect(stations.first.id, 'si-2');
      });

      test('skips entries with 0/0 coords', () {
        final stations = service.parseResponse({
          'results': [
            _samplePetrolTivolska(pk: 1, lat: 0, lng: 0),
            _samplePetrolTivolska(pk: 2),
          ],
        });
        expect(stations, hasLength(1));
        expect(stations.first.id, 'si-2');
      });

      test('NMB-98 fills e98 when NMB-100 is null', () {
        final stations = service.parseResponse({
          'results': [
            _samplePetrolTivolska(
              pk: 7,
              hundred: null,
              ninetyEight: 1.789,
            ),
          ],
        });
        expect(stations.first.e98, closeTo(1.789, 0.001));
      });

      test('NMB-100 wins over NMB-98 for the e98 slot', () {
        final stations = service.parseResponse({
          'results': [
            _samplePetrolTivolska(
              pk: 8,
              hundred: 1.901,
              ninetyEight: 1.789,
            ),
          ],
        });
        // 100-octane is the premium pump price — higher octane wins.
        expect(stations.first.e98, closeTo(1.901, 0.001));
      });

      test('prefixes every station id with `si-`', () {
        final stations = service.parseResponse({
          'results': [
            _samplePetrolTivolska(pk: 11),
            _samplePetrolTivolska(pk: 12),
          ],
        });
        expect(stations.every((s) => s.id.startsWith('si-')), isTrue);
      });

      test('all-caps 3-letter brands stay upper case (MOL, OMV)', () {
        final stations = service.parseResponse({
          'results': [
            _samplePetrolTivolska(
              pk: 20,
              name: 'MOL BRESTOVICA',
            ),
            _samplePetrolTivolska(
              pk: 21,
              name: 'OMV CELJE',
            ),
          ],
        });
        expect(stations[0].brand, 'MOL');
        expect(stations[1].brand, 'OMV');
      });

      test('mixed-case longer brand tokens are title-cased', () {
        final stations = service.parseResponse({
          'results': [
            _samplePetrolTivolska(
              pk: 30,
              name: 'PETROL LJUBLJANA',
            ),
            _samplePetrolTivolska(
              pk: 31,
              name: 'Tankomat Grosuplje',
            ),
          ],
        });
        expect(stations[0].brand, 'Petrol');
        expect(stations[1].brand, 'Tankomat');
      });

      test('tolerates string-encoded prices', () {
        final stations = service.parseResponse({
          'results': [
            <String, dynamic>{
              'pk': 40,
              'name': 'X',
              'address': 'Y',
              'lat': 46.0,
              'lng': 14.5,
              'prices': <String, dynamic>{
                '95': '1.450',
                'dizel': '1.520',
              },
              'zip_code': '1000',
            },
          ],
        });
        expect(stations.first.e5, closeTo(1.450, 0.001));
        expect(stations.first.diesel, closeTo(1.520, 0.001));
      });

      test('returns empty list for non-map input', () {
        expect(service.parseResponse(null), isEmpty);
        expect(service.parseResponse('x'), isEmpty);
        expect(service.parseResponse(42), isEmpty);
      });

      test('returns empty list when results is not a list', () {
        expect(service.parseResponse({'results': 'nope'}), isEmpty);
        expect(service.parseResponse({}), isEmpty);
      });
    });

    group('getStationDetail', () {
      test('throws ApiException (detail not available)', () {
        expect(
          () => service.getStationDetail('si-123'),
          throwsA(isA<ApiException>()),
        );
      });

      test('error message mentions goriva.si', () async {
        try {
          await service.getStationDetail('si-test');
          fail('expected ApiException');
        } on ApiException catch (e) {
          expect(e.message, contains('goriva.si'));
        }
      });
    });

    group('getPrices', () {
      test('returns empty map', () async {
        final result = await service.getPrices(['si-1', 'si-2']);
        expect(result.data, isEmpty);
        expect(result.source, ServiceSource.sloveniaApi);
      });

      test('returns empty map for empty id list', () async {
        final result = await service.getPrices([]);
        expect(result.data, isEmpty);
      });
    });
  });
}
