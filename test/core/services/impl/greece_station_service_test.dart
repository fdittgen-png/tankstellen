import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/country/country_config.dart';
import 'package:tankstellen/core/error/exceptions.dart';
import 'package:tankstellen/core/services/impl/greece_station_service.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/services/station_service.dart';
import 'package:tankstellen/features/search/data/models/search_params.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';

import '../../../mocks/mocks.dart';

/// Build a synthetic daily-price row in the shape `fuelpricesgr`
/// returns. Mirrors the Pydantic `PriceData` model:
/// `{ "fuel_type": "UNLEADED_95", "price": 1.721 }`.
Map<String, dynamic> _priceRow(String fuelType, double price) =>
    <String, dynamic>{'fuel_type': fuelType, 'price': price};

/// Build a `PriceResponse`-shaped envelope for a given date.
Map<String, dynamic> _priceResponse({
  String date = '2026-04-21',
  List<Map<String, dynamic>>? rows,
}) {
  return <String, dynamic>{
    'date': date,
    'data': rows ??
        <Map<String, dynamic>>[
          _priceRow('UNLEADED_95', 1.721),
          _priceRow('UNLEADED_100', 1.969),
          _priceRow('DIESEL', 1.528),
          _priceRow('DIESEL_HEATING', 1.165),
          _priceRow('GAS', 0.978),
        ],
  };
}

/// The community API returns `list[PriceResponse]`. Wrap a single
/// response (or several) in a list for the happy path.
List<Map<String, dynamic>> _envelope(List<Map<String, dynamic>> responses) =>
    responses;

void main() {
  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  late MockDio mockDio;
  late GreeceStationService service;

  setUp(() {
    mockDio = MockDio();
    service = GreeceStationService(dio: mockDio, baseUrl: 'https://test/api');
  });

  Response<dynamic> response(dynamic data) => Response<dynamic>(
        requestOptions: RequestOptions(),
        statusCode: 200,
        data: data,
      );

  group('GreeceStationService', () {
    test('implements StationService', () {
      expect(service, isA<StationService>());
    });

    test('country registered as GR with EUR currency', () {
      final gr = Countries.byCode('GR');
      expect(gr, isNotNull);
      expect(gr!.currency, 'EUR');
      expect(gr.requiresApiKey, isFalse,
          reason: 'Greek community API is free / open — no key required');
      expect(gr.apiProvider, contains('Paratiritirio'));
    });

    group('fuel observatory-key mapping', () {
      test('UNLEADED_95 → e5', () {
        expect(
          GreeceStationService.fuelForObservatoryKey('UNLEADED_95'),
          FuelType.e5,
        );
      });

      test('UNLEADED_100 → e98', () {
        expect(
          GreeceStationService.fuelForObservatoryKey('UNLEADED_100'),
          FuelType.e98,
        );
      });

      test('DIESEL → diesel', () {
        expect(
          GreeceStationService.fuelForObservatoryKey('DIESEL'),
          FuelType.diesel,
        );
      });

      test('GAS (Υγραέριο) → lpg', () {
        expect(
          GreeceStationService.fuelForObservatoryKey('GAS'),
          FuelType.lpg,
        );
      });

      test('DIESEL_HEATING is intentionally unmapped (not motoring fuel)', () {
        expect(
          GreeceStationService.fuelForObservatoryKey('DIESEL_HEATING'),
          isNull,
        );
        expect(
          GreeceStationService.droppedObservatoryKeys,
          contains('diesel_heating'),
        );
      });

      test('SUPER is intentionally unmapped (leaded, phased out)', () {
        expect(
          GreeceStationService.fuelForObservatoryKey('SUPER'),
          isNull,
        );
        expect(
          GreeceStationService.droppedObservatoryKeys,
          contains('super'),
        );
      });

      test('mapping is case-insensitive', () {
        expect(
          GreeceStationService.fuelForObservatoryKey('unleaded_95'),
          FuelType.e5,
        );
        expect(
          GreeceStationService.fuelForObservatoryKey('Unleaded_95'),
          FuelType.e5,
        );
      });
    });

    group('searchStations', () {
      test('builds stations for the nearest prefectures from Athens',
          () async {
        when(() => mockDio.get(
              any(),
              cancelToken: any(named: 'cancelToken'),
            )).thenAnswer((_) async => response(_envelope([_priceResponse()])));

        // Athens → should hit ATTICA first; we fetch the 4 nearest.
        const params = SearchParams(lat: 37.98, lng: 23.73, radiusKm: 500);
        final result = await service.searchStations(params);

        expect(result.source, ServiceSource.greeceApi);
        expect(result.data, isNotEmpty);

        // Every station id carries the `gr-` prefix.
        expect(
          result.data.every((s) => s.id.startsWith('gr-')),
          isTrue,
          reason: 'Every GR station id must carry the gr- prefix so the '
              'favorites currency lookup finds it.',
        );

        // Prices must map correctly onto the Station slots.
        final attica =
            result.data.firstWhere((s) => s.id == 'gr-attica');
        expect(attica.e5, closeTo(1.721, 0.0001));
        expect(attica.e98, closeTo(1.969, 0.0001));
        expect(attica.diesel, closeTo(1.528, 0.0001));
        expect(attica.lpg, closeTo(0.978, 0.0001));
      });

      test('fetches exactly 4 closest prefectures (not all 8)', () async {
        when(() => mockDio.get(
              any(),
              cancelToken: any(named: 'cancelToken'),
            )).thenAnswer((_) async => response(_envelope([_priceResponse()])));

        const params = SearchParams(lat: 37.98, lng: 23.73, radiusKm: 500);
        await service.searchStations(params);

        verify(() => mockDio.get(
              any(),
              cancelToken: any(named: 'cancelToken'),
            )).called(4);
      });

      test('targets the /data/daily/prefecture/{name} path', () async {
        when(() => mockDio.get(
              any(),
              cancelToken: any(named: 'cancelToken'),
            )).thenAnswer((_) async => response(_envelope([_priceResponse()])));

        const params = SearchParams(lat: 37.98, lng: 23.73, radiusKm: 500);
        await service.searchStations(params);

        final captured = verify(() => mockDio.get(
              captureAny(),
              cancelToken: any(named: 'cancelToken'),
            )).captured;
        expect(
          captured.every((url) =>
              (url as String).startsWith('https://test/api/data/daily/prefecture/')),
          isTrue,
          reason:
              'Every GR call must hit /data/daily/prefecture/<PREFECTURE>.',
        );
      });

      test('HTTP 401 is re-raised as ApiException', () async {
        when(() => mockDio.get(
              any(),
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
              .having((e) => e.statusCode, 'statusCode', 401)),
        );
      });

      test('HTTP 403 is re-raised as ApiException', () async {
        when(() => mockDio.get(
              any(),
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
              .having((e) => e.statusCode, 'statusCode', 403)),
        );
      });

      test(
          'network timeout on every prefecture surfaces ApiException to '
          'the fallback chain', () async {
        when(() => mockDio.get(
              any(),
              cancelToken: any(named: 'cancelToken'),
            )).thenThrow(DioException(
          type: DioExceptionType.connectionTimeout,
          requestOptions: RequestOptions(),
        ));

        const params = SearchParams(lat: 37.98, lng: 23.73, radiusKm: 500);
        await expectLater(
          () => service.searchStations(params),
          throwsA(isA<ApiException>()),
        );
      });

      test(
          'partial failures (some prefectures up, some down) still return '
          'data with accumulated errors', () async {
        var callCount = 0;
        when(() => mockDio.get(
              any(),
              cancelToken: any(named: 'cancelToken'),
            )).thenAnswer((_) async {
          callCount += 1;
          if (callCount.isEven) {
            throw DioException(
              type: DioExceptionType.connectionTimeout,
              requestOptions: RequestOptions(),
            );
          }
          return response(_envelope([_priceResponse()]));
        });

        const params = SearchParams(lat: 37.98, lng: 23.73, radiusKm: 500);
        final result = await service.searchStations(params);

        expect(result.data, isNotEmpty);
        expect(result.errors, isNotEmpty,
            reason: 'Errors from the failed fetches should accumulate.');
      });

      test('empty list for a prefecture drops that entry silently', () async {
        when(() => mockDio.get(
              any(),
              cancelToken: any(named: 'cancelToken'),
            )).thenAnswer((_) async => response(<Map<String, dynamic>>[]));

        const params = SearchParams(lat: 37.98, lng: 23.73, radiusKm: 500);
        final result = await service.searchStations(params);

        // All four prefectures returned empty → no stations, but no
        // errors either (empty list is a valid response).
        expect(result.data, isEmpty);
        expect(result.errors, isEmpty);
      });
    });

    group('parsePrefectureResponse', () {
      const attica = {
        'stationId': 'gr-attica',
        'displayName': 'Αττική / Attica',
        'place': 'Αθήνα',
        'lat': 37.9838,
        'lng': 23.7275,
      };

      Station? parse(dynamic body) => service.parsePrefectureResponse(
            body,
            stationId: attica['stationId']! as String,
            displayName: attica['displayName']! as String,
            place: attica['place']! as String,
            prefectureLat: attica['lat']! as double,
            prefectureLng: attica['lng']! as double,
            fromLat: 37.98,
            fromLng: 23.73,
          );

      test('happy path parses all four supported fuels', () {
        final s = parse(_envelope([_priceResponse()]));
        expect(s, isNotNull);
        expect(s!.id, 'gr-attica');
        expect(s.e5, closeTo(1.721, 0.0001));
        expect(s.e98, closeTo(1.969, 0.0001));
        expect(s.diesel, closeTo(1.528, 0.0001));
        expect(s.lpg, closeTo(0.978, 0.0001));
        // Diesel heating is dropped — no dedicated slot on Station,
        // but confirm no fuel slot accidentally absorbed it.
        expect(s.dieselPremium, isNull);
      });

      test('picks the newest entry when multiple dates are returned', () {
        final s = parse(_envelope([
          _priceResponse(date: '2026-04-20', rows: [
            _priceRow('UNLEADED_95', 1.700),
          ]),
          _priceResponse(date: '2026-04-21', rows: [
            _priceRow('UNLEADED_95', 1.721),
          ]),
        ]));
        expect(s, isNotNull);
        expect(s!.e5, closeTo(1.721, 0.0001));
      });

      test('empty list → null station', () {
        expect(parse(const <Map<String, dynamic>>[]), isNull);
      });

      test('non-list body raises ApiException', () {
        expect(
          () => parse(<String, dynamic>{'oops': 'not a list'}),
          throwsA(isA<ApiException>()),
        );
      });

      test('DIESEL_HEATING is silently dropped', () {
        final s = parse(_envelope([
          _priceResponse(rows: [
            _priceRow('DIESEL', 1.528),
            _priceRow('DIESEL_HEATING', 1.165), // dropped
          ]),
        ]));
        expect(s, isNotNull);
        expect(s!.diesel, closeTo(1.528, 0.0001));
        // No dieselPremium on Station for GR.
      });

      test('SUPER (leaded) is silently dropped', () {
        final s = parse(_envelope([
          _priceResponse(rows: [
            _priceRow('DIESEL', 1.528),
            _priceRow('SUPER', 1.950),
          ]),
        ]));
        expect(s, isNotNull);
        expect(s!.diesel, closeTo(1.528, 0.0001));
        expect(s.e5, isNull);
        expect(s.e98, isNull);
      });

      test('stationId is threaded through unchanged (gr- prefix preserved)',
          () {
        final s = parse(_envelope([_priceResponse()]));
        expect(s, isNotNull);
        expect(s!.id, startsWith('gr-'));
      });

      test('prefecture with zero mappable rows returns null', () {
        final s = parse(_envelope([
          _priceResponse(rows: [
            _priceRow('DIESEL_HEATING', 1.165),
            _priceRow('SUPER', 1.950),
          ]),
        ]));
        expect(s, isNull,
            reason: 'No recognised motoring fuels → no synthetic pin.');
      });

      test('non-numeric price is dropped (price slot stays null)', () {
        final s = parse(_envelope([
          _priceResponse(rows: [
            _priceRow('UNLEADED_95', 1.721),
            <String, dynamic>{'fuel_type': 'DIESEL', 'price': 'N/A'},
          ]),
        ]));
        expect(s, isNotNull);
        expect(s!.e5, closeTo(1.721, 0.0001));
        expect(s.diesel, isNull);
      });

      test('zero or negative prices are rejected', () {
        final s = parse(_envelope([
          _priceResponse(rows: [
            _priceRow('UNLEADED_95', 0),
            _priceRow('DIESEL', -1.0),
            _priceRow('GAS', 0.978),
          ]),
        ]));
        expect(s, isNotNull);
        expect(s!.e5, isNull);
        expect(s.diesel, isNull);
        expect(s.lpg, closeTo(0.978, 0.0001));
      });

      test('numeric price strings are accepted', () {
        final s = parse(_envelope([
          _priceResponse(rows: [
            <String, dynamic>{'fuel_type': 'UNLEADED_95', 'price': '1.721'},
          ]),
        ]));
        expect(s, isNotNull);
        expect(s!.e5, closeTo(1.721, 0.0001));
      });

      test('updatedAt reflects the newest response date', () {
        final s = parse(_envelope([
          _priceResponse(date: '2026-04-21'),
        ]));
        expect(s, isNotNull);
        expect(s!.updatedAt, '2026-04-21');
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
