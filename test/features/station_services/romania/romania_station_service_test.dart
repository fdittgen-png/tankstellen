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
import 'package:tankstellen/features/search/domain/entities/station.dart';

import '../../../mocks/mocks.dart';

/// Hand-crafted fixture mirroring the shape the upstream
/// `pretcarburant.ro` site *appears* to return (no documented API —
/// see service docstring). The parser is the contract; the URL is a
/// best-guess constant.
Map<String, dynamic> _petromBucharest({
  double lat = 44.478,
  double lng = 26.115,
  double? benzinaStandard = 7.25,
  double? benzinaPremium = 7.89,
  double? motorinaStandard = 7.45,
  double? motorinaPremium = 7.95,
  double? gpl = 3.85,
  String id = 'PETROM-00123',
  bool isOpen = true,
  String updatedAt = '2026-04-22T10:30:00Z',
}) {
  final prices = <String, dynamic>{};
  if (benzinaStandard != null) prices['benzina_standard'] = benzinaStandard;
  if (benzinaPremium != null) prices['benzina_premium'] = benzinaPremium;
  if (motorinaStandard != null) prices['motorina_standard'] = motorinaStandard;
  if (motorinaPremium != null) prices['motorina_premium'] = motorinaPremium;
  if (gpl != null) prices['gpl'] = gpl;
  return <String, dynamic>{
    'id': id,
    'brand': 'Petrom',
    'name': 'Petrom București Pipera',
    'address': 'Str. Dimitrie Pompeiu 1A',
    'postal_code': '020335',
    'city': 'București',
    'county': 'București',
    'lat': lat,
    'lng': lng,
    'is_open': isOpen,
    'updated_at': updatedAt,
    'prices': prices,
  };
}

List<Map<String, dynamic>> _envelope(List<Map<String, dynamic>> rows) => rows;

void main() {
  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  late MockDio mockDio;
  late RomaniaStationService service;

  setUp(() {
    mockDio = MockDio();
    when(() => mockDio.options).thenReturn(BaseOptions(headers: <String, dynamic>{}));
    service = RomaniaStationService(dio: mockDio, baseUrl: 'https://test');
  });

  Response<dynamic> response(dynamic data) => Response<dynamic>(
        requestOptions: RequestOptions(),
        statusCode: 200,
        data: data,
      );

  group('RomaniaStationService', () {
    test('implements StationService', () {
      expect(service, isA<StationService>());
    });

    test('country registered as RO with RON currency', () {
      final ro = Countries.byCode('RO');
      expect(ro, isNotNull);
      expect(ro!.currency, 'RON');
      expect(ro.currencySymbol, 'lei');
      expect(ro.requiresApiKey, isFalse,
          reason: 'pretcarburant.ro is public — no key required');
      expect(ro.apiProvider, contains('Monitorul'));
    });

    group('fuel observatory-key mapping', () {
      test('benzina_standard → e5', () {
        expect(
          RomaniaStationService.fuelForObservatoryKey('benzina_standard'),
          FuelType.e5,
        );
      });

      test('benzina_premium → e98', () {
        expect(
          RomaniaStationService.fuelForObservatoryKey('benzina_premium'),
          FuelType.e98,
        );
      });

      test('motorina_standard → diesel', () {
        expect(
          RomaniaStationService.fuelForObservatoryKey('motorina_standard'),
          FuelType.diesel,
        );
      });

      test('motorina_premium → dieselPremium', () {
        expect(
          RomaniaStationService.fuelForObservatoryKey('motorina_premium'),
          FuelType.dieselPremium,
        );
      });

      test('gpl → lpg', () {
        expect(
          RomaniaStationService.fuelForObservatoryKey('gpl'),
          FuelType.lpg,
        );
      });

      test('mapping is case-insensitive', () {
        expect(
          RomaniaStationService.fuelForObservatoryKey('BENZINA_STANDARD'),
          FuelType.e5,
        );
        expect(
          RomaniaStationService.fuelForObservatoryKey('Gpl'),
          FuelType.lpg,
        );
      });

      test('unknown key returns null', () {
        expect(
          RomaniaStationService.fuelForObservatoryKey('kerosene'),
          isNull,
        );
      });
    });

    group('searchStations', () {
      test('builds stations from the stations endpoint', () async {
        when(() => mockDio.get(
              any(),
              cancelToken: any(named: 'cancelToken'),
            )).thenAnswer(
          (_) async => response(_envelope([_petromBucharest()])),
        );

        // Bucharest query — the Petrom station sits right on top of it.
        const params = SearchParams(lat: 44.43, lng: 26.10, radiusKm: 25);
        final result = await service.searchStations(params);

        expect(result.source, ServiceSource.romaniaApi);
        expect(result.data, isNotEmpty);

        // Every station id carries the `ro-` prefix so the favorites
        // currency lookup finds it.
        expect(
          result.data.every((s) => s.id.startsWith('ro-')),
          isTrue,
          reason:
              'Every RO station id must carry the ro- prefix so favorites '
              'render prices in RON.',
        );

        // Prices map correctly onto Station slots.
        final first = result.data.first;
        expect(first.e5, closeTo(7.25, 0.0001));
        expect(first.e98, closeTo(7.89, 0.0001));
        expect(first.diesel, closeTo(7.45, 0.0001));
        expect(first.dieselPremium, closeTo(7.95, 0.0001));
        expect(first.lpg, closeTo(3.85, 0.0001));
      });

      test('targets the /api/stations path', () async {
        when(() => mockDio.get(
              any(),
              cancelToken: any(named: 'cancelToken'),
            )).thenAnswer(
          (_) async => response(_envelope([_petromBucharest()])),
        );

        const params = SearchParams(lat: 44.43, lng: 26.10, radiusKm: 25);
        await service.searchStations(params);

        final captured = verify(() => mockDio.get(
              captureAny(),
              cancelToken: any(named: 'cancelToken'),
            )).captured;
        expect(
          captured.every(
              (url) => (url as String) == 'https://test/api/stations'),
          isTrue,
          reason: 'RO service must hit /api/stations against the base URL.',
        );
      });

      test('HTTP 403 is surfaced as ApiException to the fallback chain',
          () async {
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

        const params = SearchParams(lat: 44.43, lng: 26.10, radiusKm: 25);
        await expectLater(
          () => service.searchStations(params),
          throwsA(isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 403)),
        );
      });

      test('network timeout surfaces ApiException', () async {
        when(() => mockDio.get(
              any(),
              cancelToken: any(named: 'cancelToken'),
            )).thenThrow(DioException(
          type: DioExceptionType.connectionTimeout,
          requestOptions: RequestOptions(),
        ));

        const params = SearchParams(lat: 44.43, lng: 26.10, radiusKm: 25);
        await expectLater(
          () => service.searchStations(params),
          throwsA(isA<ApiException>()),
        );
      });

      test('malformed body (not a list) raises ApiException', () async {
        when(() => mockDio.get(
              any(),
              cancelToken: any(named: 'cancelToken'),
            )).thenAnswer((_) async => response(<String, dynamic>{
                  'oops': 'not the expected shape',
                }));

        const params = SearchParams(lat: 44.43, lng: 26.10, radiusKm: 25);
        await expectLater(
          () => service.searchStations(params),
          throwsA(isA<ApiException>()),
        );
      });

      test('empty list → empty result, no errors', () async {
        when(() => mockDio.get(
              any(),
              cancelToken: any(named: 'cancelToken'),
            )).thenAnswer(
          (_) async => response(<Map<String, dynamic>>[]),
        );

        const params = SearchParams(lat: 44.43, lng: 26.10, radiusKm: 25);
        final result = await service.searchStations(params);
        expect(result.data, isEmpty);
        expect(result.errors, isEmpty);
      });
    });

    group('rate limit', () {
      test('service-level Dio rate limit is 500 ms (respectful scraping)',
          () async {
        // Build the service with its real Dio so we exercise the
        // DioFactory rate-limit interceptor wired up by the
        // constructor. Two back-to-back requests against a server
        // that returns immediately should still be at least 500 ms
        // apart because the interceptor gates them.
        final realService = RomaniaStationService(
          baseUrl: 'http://127.0.0.1:1', // unreachable — timeouts fast
        );

        final t0 = DateTime.now();
        try {
          await realService.searchStations(
            const SearchParams(lat: 44.43, lng: 26.10, radiusKm: 25),
          );
        } catch (_) {
          // expected — connection refused. All we care about is that
          // the interceptor gates the second request.
        }
        try {
          await realService.searchStations(
            const SearchParams(lat: 44.43, lng: 26.10, radiusKm: 25),
          );
        } catch (_) {
          // expected
        }
        final elapsed = DateTime.now().difference(t0);
        expect(
          elapsed.inMilliseconds >= 500,
          isTrue,
          reason:
              'Second RO request must be gated by the 500 ms rate limit '
              'interceptor. Elapsed: ${elapsed.inMilliseconds} ms',
        );
      }, timeout: const Timeout(Duration(seconds: 20)));
    });

    group('parseStationsResponse', () {
      List<Station> parse(dynamic body) => service.parseStationsResponse(
            body,
            fromLat: 44.43,
            fromLng: 26.10,
          );

      test('happy path parses all five supported fuels', () {
        final stations = parse(_envelope([_petromBucharest()]));
        expect(stations, hasLength(1));
        final s = stations.single;
        expect(s.id, startsWith('ro-'));
        expect(s.e5, closeTo(7.25, 0.0001));
        expect(s.e98, closeTo(7.89, 0.0001));
        expect(s.diesel, closeTo(7.45, 0.0001));
        expect(s.dieselPremium, closeTo(7.95, 0.0001));
        expect(s.lpg, closeTo(3.85, 0.0001));
        expect(s.place, 'București');
        expect(s.brand, 'Petrom');
      });

      test('empty list → no stations', () {
        expect(parse(const <Map<String, dynamic>>[]), isEmpty);
      });

      test('non-list body raises ApiException', () {
        expect(
          () => parse(<String, dynamic>{'oops': 'nope'}),
          throwsA(isA<ApiException>()),
        );
      });

      test('unknown fuel keys are silently dropped', () {
        final raw = _petromBucharest();
        (raw['prices'] as Map<String, dynamic>)['kerosene'] = 4.99;
        final stations = parse(_envelope([raw]));
        expect(stations, hasLength(1));
        // Known fuels still resolve; unknown one simply never lands.
        expect(stations.single.e5, closeTo(7.25, 0.0001));
      });

      test('station with only GPL still surfaces (partial coverage OK)', () {
        final raw = _petromBucharest(
          benzinaStandard: null,
          benzinaPremium: null,
          motorinaStandard: null,
          motorinaPremium: null,
        );
        final stations = parse(_envelope([raw]));
        expect(stations, hasLength(1));
        expect(stations.single.lpg, closeTo(3.85, 0.0001));
        expect(stations.single.e5, isNull);
      });

      test('station with no mappable prices is dropped', () {
        final raw = _petromBucharest(
          benzinaStandard: null,
          benzinaPremium: null,
          motorinaStandard: null,
          motorinaPremium: null,
          gpl: null,
        );
        expect(parse(_envelope([raw])), isEmpty,
            reason: 'No recognised motoring fuel → no synthetic pin.');
      });

      test('non-numeric price is dropped (slot stays null)', () {
        final raw = _petromBucharest();
        (raw['prices'] as Map<String, dynamic>)['benzina_standard'] = 'N/A';
        final stations = parse(_envelope([raw]));
        expect(stations, hasLength(1));
        expect(stations.single.e5, isNull);
        expect(stations.single.diesel, closeTo(7.45, 0.0001));
      });

      test('zero and negative prices are rejected', () {
        final raw = _petromBucharest();
        (raw['prices'] as Map<String, dynamic>)['benzina_standard'] = 0;
        (raw['prices'] as Map<String, dynamic>)['motorina_standard'] = -1.2;
        final stations = parse(_envelope([raw]));
        expect(stations, hasLength(1));
        expect(stations.single.e5, isNull);
        expect(stations.single.diesel, isNull);
        expect(stations.single.e98, closeTo(7.89, 0.0001));
      });

      test('numeric price strings are accepted', () {
        final raw = _petromBucharest();
        (raw['prices'] as Map<String, dynamic>)['benzina_standard'] = '7.25';
        final stations = parse(_envelope([raw]));
        expect(stations, hasLength(1));
        expect(stations.single.e5, closeTo(7.25, 0.0001));
      });

      test('station id is prefixed with ro- (and not double-prefixed)', () {
        final already = _petromBucharest(id: 'ro-PETROM-00123');
        final plain = _petromBucharest(id: 'OMV-00001');
        final stations = parse(_envelope([already, plain]));
        expect(stations, hasLength(2));
        expect(stations[0].id, 'ro-PETROM-00123',
            reason: 'Existing ro- prefix must not be doubled up.');
        expect(stations[1].id, 'ro-OMV-00001');
      });

      test('missing id is dropped', () {
        final raw = _petromBucharest();
        raw.remove('id');
        expect(parse(_envelope([raw])), isEmpty);
      });

      test('missing coordinates dropped', () {
        final raw = _petromBucharest();
        raw.remove('lat');
        expect(parse(_envelope([raw])), isEmpty);
      });

      test('updatedAt is propagated from the feed', () {
        final stations = parse(_envelope([_petromBucharest()]));
        expect(stations.single.updatedAt, '2026-04-22T10:30:00Z');
      });

      test('is_open boolean is propagated', () {
        final closed = _petromBucharest(isOpen: false);
        final stations = parse(_envelope([closed]));
        expect(stations.single.isOpen, isFalse);
      });
    });

    group('getStationDetail', () {
      test('throws ApiException (detail not available)', () {
        expect(
          () => service.getStationDetail('ro-PETROM-00123'),
          throwsA(isA<ApiException>()),
        );
      });

      test('error message mentions Monitorul', () async {
        try {
          await service.getStationDetail('ro-PETROM-00123');
          fail('expected ApiException');
        } on ApiException catch (e) {
          expect(e.message, contains('Monitorul'));
        }
      });
    });

    group('getPrices', () {
      test('returns empty map (no batch refresh)', () async {
        final result = await service.getPrices(['ro-PETROM-00123']);
        expect(result.data, isEmpty);
        expect(result.source, ServiceSource.romaniaApi);
      });

      test('returns empty map for empty id list', () async {
        final result = await service.getPrices([]);
        expect(result.data, isEmpty);
      });
    });

    group('station id prefix routing', () {
      test('Countries.countryCodeForStationId resolves ro- → RO', () {
        expect(
          Countries.countryCodeForStationId('ro-PETROM-00123'),
          'RO',
        );
      });

      test('Countries.countryForStationId returns the RO config', () {
        final c = Countries.countryForStationId('ro-PETROM-00123');
        expect(c, isNotNull);
        expect(c!.code, 'RO');
        expect(c.currency, 'RON');
      });
    });
  });
}
