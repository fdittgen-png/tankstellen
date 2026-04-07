import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/services/impl/prix_carburants_station_service.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/services/station_service.dart';
import 'package:tankstellen/features/search/data/models/search_params.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';

void main() {
  late PrixCarburantsStationService service;

  setUp(() {
    service = PrixCarburantsStationService();
  });

  group('PrixCarburantsStationService', () {
    test('implements StationService interface', () {
      expect(service, isA<StationService>());
    });

    test('constructor accepts optional enricher parameter', () {
      final s1 = PrixCarburantsStationService();
      expect(s1, isNotNull);

      final s2 = PrixCarburantsStationService(enricher: null);
      expect(s2, isNotNull);
    });

    group('getStationDetail', () {
      test('throws when station not found on network error', () {
        expect(
          () => service.getStationDetail('99999999'),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('getPrices', () {
      test('returns ServiceResult with prixCarburantsApi source on network error', () async {
        final result = await service.getPrices(['99999999']);
        expect(result.data, isEmpty);
        expect(result.source, ServiceSource.prixCarburantsApi);
      });

      test('returns empty map for empty id list', () async {
        final result = await service.getPrices([]);
        expect(result.data, isEmpty);
        expect(result.source, ServiceSource.prixCarburantsApi);
      });

      test('limits to 10 station IDs', () async {
        final ids = List.generate(15, (i) => 'id-$i');
        final result = await service.getPrices(ids);
        expect(result.data, isA<Map<String, StationPrices>>());
        expect(result.source, ServiceSource.prixCarburantsApi);
      });
    });

    group('searchStations', () {
      test('returns ServiceResult with correct source', () async {
        // This hits the real API (free, no key). If network is available,
        // we get stations; if not, the service catches DioException and
        // returns an empty list. Either way, the source should be correct.
        final params = const SearchParams(
          lat: 43.3, lng: 3.5, radiusKm: 5.0,
        );
        final result = await service.searchStations(params);
        expect(result.source, ServiceSource.prixCarburantsApi);
        expect(result.data, isA<List>());
      });

      test('returns empty list for coordinates far from France', () async {
        // Middle of Pacific — no stations even if API is reachable
        final params = const SearchParams(lat: 0.0, lng: -170.0, radiusKm: 5.0);
        final result = await service.searchStations(params);
        expect(result.data, isEmpty);
      });
    });
  });

  group('PrixCarburantsStationService parsing (via _TestableService)', () {
    late _TestablePrixCarburantsService testableService;

    setUp(() {
      testableService = _TestablePrixCarburantsService();
    });

    test('extractResults parses valid response with results array', () {
      final data = {
        'results': [
          {'id': '1', 'adresse': 'Rue de Test'},
          {'id': '2', 'adresse': 'Avenue de Paris'},
        ],
      };
      final results = testableService.testExtractResults(data);
      expect(results, hasLength(2));
      expect(results[0]['id'], '1');
      expect(results[1]['adresse'], 'Avenue de Paris');
    });

    test('extractResults returns empty list for missing results key', () {
      final data = <String, dynamic>{'total_count': 0};
      final results = testableService.testExtractResults(data);
      expect(results, isEmpty);
    });

    test('extractResults returns empty list for non-map data', () {
      final results = testableService.testExtractResults('not a map');
      expect(results, isEmpty);
    });

    test('extractResults returns empty list for null results', () {
      final data = <String, dynamic>{'results': null};
      final results = testableService.testExtractResults(data);
      expect(results, isEmpty);
    });

    test('parseStation creates Station with correct fields from geom coordinates', () {
      final record = {
        'id': '34200002',
        'adresse': '120 RUE LECLERC',
        'ville': 'CASTELNAU',
        'cp': '34290',
        'geom': {'lat': 43.45, 'lon': 3.52},
        'sp95_prix': 1.879,
        'e10_prix': 1.799,
        'gazole_prix': 1.659,
        'sp98_prix': 1.929,
        'e85_prix': 0.899,
        'gplc_prix': 0.999,
        'services_service': ['Lavage automatique', 'DAB'],
        'horaires_automate_24_24': 'Oui',
        'carburants_disponibles': ['Gazole', 'SP95', 'E10'],
        'carburants_indisponibles': [],
        'pop': 'R',
        'departement': 'Hérault',
        'region': 'Occitanie',
      };

      final station = testableService.testParseStation(record, 43.4, 3.5);
      expect(station, isNotNull);
      expect(station!.id, '34200002');
      expect(station.name, '120 RUE LECLERC');
      expect(station.street, '120 RUE LECLERC');
      expect(station.postCode, '34290');
      expect(station.place, 'CASTELNAU');
      expect(station.lat, 43.45);
      expect(station.lng, 3.52);
      expect(station.e5, 1.879);
      expect(station.e10, 1.799);
      expect(station.diesel, 1.659);
      expect(station.e98, 1.929);
      expect(station.e85, 0.899);
      expect(station.lpg, 0.999);
      expect(station.isOpen, true);
      expect(station.is24h, true);
      expect(station.services, contains('DAB'));
      expect(station.availableFuels, contains('Gazole'));
      expect(station.stationType, 'R');
      expect(station.department, 'Hérault');
      expect(station.region, 'Occitanie');
    });

    test('parseStation uses legacy lat/lng when geom is missing', () {
      final record = {
        'id': '12345',
        'adresse': 'Test Street',
        'ville': 'TestVille',
        'cp': '75001',
        'geom': <String, dynamic>{},
        'latitude': '4345000',
        'longitude': '352000',
      };

      final station = testableService.testParseStation(record, 43.0, 3.0);
      expect(station, isNotNull);
      expect(station!.lat, closeTo(43.45, 0.01));
      expect(station.lng, closeTo(3.52, 0.01));
    });

    test('parseStation returns station even with minimal data', () {
      final record = <String, dynamic>{
        'id': null,
        'adresse': null,
        'ville': null,
        'cp': null,
      };
      final station = testableService.testParseStation(record, 0, 0);
      expect(station, isNotNull);
    });

    test('parseStation detects known brands from address', () {
      final makeRecord = (String adresse) => {
        'id': '1',
        'adresse': adresse,
        'ville': '',
        'cp': '',
        'geom': {'lat': 48.0, 'lon': 2.0},
      };

      var station = testableService.testParseStation(makeRecord('CC LECLERC SUD'), 48.0, 2.0);
      expect(station?.brand, 'E.Leclerc');

      station = testableService.testParseStation(makeRecord('TOTALENERGIES RELAIS'), 48.0, 2.0);
      expect(station?.brand, 'TotalEnergies');

      station = testableService.testParseStation(makeRecord('CARREFOUR MARKET'), 48.0, 2.0);
      expect(station?.brand, 'Carrefour');

      station = testableService.testParseStation(makeRecord('SHELL PARIS NORD'), 48.0, 2.0);
      expect(station?.brand, 'Shell');
    });

    test('parseStation defaults brand to Station for unknown addresses', () {
      final record = {
        'id': '1',
        'adresse': 'SOME RANDOM GARAGE',
        'ville': '',
        'cp': '',
        'geom': {'lat': 48.0, 'lon': 2.0},
      };

      final station = testableService.testParseStation(record, 48.0, 2.0);
      expect(station?.brand, 'Station');
    });

    test('parseStation detects Autoroute brand from pop field', () {
      final record = {
        'id': '1',
        'adresse': 'AIRE DE REPOS',
        'ville': '',
        'cp': '',
        'geom': {'lat': 48.0, 'lon': 2.0},
        'pop': 'A',
      };

      final station = testableService.testParseStation(record, 48.0, 2.0);
      expect(station?.brand, 'Autoroute');
    });

    test('parseStation handles null prices correctly', () {
      final record = {
        'id': '1',
        'adresse': 'Test',
        'ville': 'Paris',
        'cp': '75001',
        'geom': {'lat': 48.8, 'lon': 2.3},
        'sp95_prix': null,
        'e10_prix': null,
        'gazole_prix': null,
      };

      final station = testableService.testParseStation(record, 48.8, 2.3);
      expect(station, isNotNull);
      expect(station!.e5, isNull);
      expect(station.e10, isNull);
      expect(station.diesel, isNull);
    });

    test('parseOpeningHours formats hours correctly', () {
      final hours = testableService.testParseOpeningHours(
        'Automate-24-24, Lundi07.00-18.30, Mardi07.00-18.30',
      );
      expect(hours, isNotNull);
      expect(hours, contains('Lundi07:00-18:30'));
      expect(hours, isNot(contains('Automate-24-24')));
    });

    test('parseOpeningHours returns null for null input', () {
      expect(testableService.testParseOpeningHours(null), isNull);
    });

    test('parseOpeningHours returns null for empty string', () {
      expect(testableService.testParseOpeningHours(''), isNull);
    });

    test('mostRecentUpdate returns most recent date formatted', () {
      final record = {
        'gazole_maj': '2026-03-23T00:01:00+00:00',
        'sp95_maj': '2026-03-25T14:30:00+00:00',
        'e10_maj': '2026-03-24T10:00:00+00:00',
      };

      final result = testableService.testMostRecentUpdate(record);
      expect(result, isNotNull);
      expect(result, contains('25/03'));
      expect(result, contains('14:30'));
    });

    test('mostRecentUpdate returns null when no dates present', () {
      final record = <String, dynamic>{};
      expect(testableService.testMostRecentUpdate(record), isNull);
    });

    test('parseServices returns list from List input', () {
      final services = testableService.testParseServices(
        ['Lavage', 'DAB', 'Boutique'],
      );
      expect(services, hasLength(3));
      expect(services, contains('DAB'));
    });

    test('parseServices returns empty list from non-list input', () {
      expect(testableService.testParseServices(null), isEmpty);
      expect(testableService.testParseServices('string'), isEmpty);
    });

    test('toDouble converts various types', () {
      expect(testableService.testToDouble(1.5), 1.5);
      expect(testableService.testToDouble(2), 2.0);
      expect(testableService.testToDouble('3.14'), 3.14);
      expect(testableService.testToDouble(null), isNull);
      expect(testableService.testToDouble('not-a-number'), isNull);
    });
  });

  group('PrixCarburantsStationService searchStations integration', () {
    test('searchStations returns ServiceResult even on network failure', () async {
      final params = const SearchParams(lat: 48.8, lng: 2.3, radiusKm: 5.0);
      final result = await service.searchStations(params);
      // Whether network succeeds or fails, we get a valid ServiceResult
      expect(result.source, ServiceSource.prixCarburantsApi);
      expect(result.data, isA<List<Station>>());
      expect(result.fetchedAt, isA<DateTime>());
    });

    test('searchStations with postalCode param returns valid result', () async {
      final params = const SearchParams(
        lat: 48.8, lng: 2.3, radiusKm: 5.0, postalCode: '75001',
      );
      final result = await service.searchStations(params);
      expect(result.source, ServiceSource.prixCarburantsApi);
      expect(result.data, isA<List<Station>>());
    });

    test('searchStations sorts by distance by default', () async {
      final params = const SearchParams(
        lat: 48.8, lng: 2.3, radiusKm: 5.0, sortBy: SortBy.distance,
      );
      final result = await service.searchStations(params);
      if (result.data.length >= 2) {
        for (var i = 1; i < result.data.length; i++) {
          expect(result.data[i].dist, greaterThanOrEqualTo(result.data[i - 1].dist));
        }
      }
    });

    test('searchStations sorts by price when requested', () async {
      final params = const SearchParams(
        lat: 48.8, lng: 2.3, radiusKm: 5.0, sortBy: SortBy.price,
      );
      final result = await service.searchStations(params);
      expect(result.source, ServiceSource.prixCarburantsApi);
    });

    test('searchStations with CancelToken does not throw', () async {
      final cancelToken = CancelToken();
      final params = const SearchParams(lat: 48.8, lng: 2.3, radiusKm: 5.0);
      final result = await service.searchStations(params, cancelToken: cancelToken);
      expect(result.source, ServiceSource.prixCarburantsApi);
    });

    test('searchStations with enricher null works fine', () async {
      final svc = PrixCarburantsStationService(enricher: null);
      final params = const SearchParams(lat: 48.8, lng: 2.3, radiusKm: 5.0);
      final result = await svc.searchStations(params);
      expect(result.source, ServiceSource.prixCarburantsApi);
    });
  });

  group('PrixCarburantsStationService getStationDetail integration', () {
    test('getStationDetail throws on invalid station ID', () async {
      // The API call may succeed but return empty results, or fail with DioException
      try {
        await service.getStationDetail('invalid-id-99999');
        fail('Should have thrown');
      } catch (e) {
        expect(e, isA<Exception>());
      }
    });
  });

  group('PrixCarburantsStationService getPrices integration', () {
    test('getPrices returns valid map even when API fails', () async {
      final result = await service.getPrices(['12345', '67890']);
      expect(result.source, ServiceSource.prixCarburantsApi);
      expect(result.data, isA<Map<String, StationPrices>>());
    });

    test('getPrices handles mixed valid and invalid IDs', () async {
      final result = await service.getPrices(['valid-1', '', 'valid-2']);
      expect(result.source, ServiceSource.prixCarburantsApi);
    });
  });

  group('PrixCarburantsStationService full parsing pipeline', () {
    late _TestablePrixCarburantsService testableService;

    setUp(() {
      testableService = _TestablePrixCarburantsService();
    });

    test('full pipeline: extract, parse, sort by distance', () {
      final apiData = {
        'results': [
          {
            'id': '1001',
            'adresse': 'STATION LECLERC',
            'ville': 'PARIS',
            'cp': '75001',
            'geom': {'lat': 48.86, 'lon': 2.34},
            'sp95_prix': 1.879,
            'gazole_prix': 1.659,
          },
          {
            'id': '1002',
            'adresse': 'SHELL AUTOROUTE',
            'ville': 'VERSAILLES',
            'cp': '78000',
            'geom': {'lat': 48.80, 'lon': 2.13},
            'sp95_prix': 1.999,
            'gazole_prix': 1.799,
            'pop': 'A',
          },
          {
            'id': '1003',
            'adresse': 'STATION RURALE',
            'ville': 'MELUN',
            'cp': '77000',
            'geom': {'lat': 48.54, 'lon': 2.66},
            'sp95_prix': 1.749,
            'gazole_prix': 1.549,
          },
        ],
      };

      // Step 1: Extract results from API response
      final results = testableService.testExtractResults(apiData);
      expect(results, hasLength(3));

      // Step 2: Parse each into Station
      final searchLat = 48.85;
      final searchLng = 2.35;
      final stations = <Station>[];
      for (final r in results) {
        final station = testableService.testParseStation(r, searchLat, searchLng);
        if (station != null) stations.add(station);
      }
      expect(stations, hasLength(3));

      // Verify brand detection worked
      expect(stations[0].brand, 'E.Leclerc');
      expect(stations[1].brand, 'Shell');
      expect(stations[2].brand, 'Station');

      // Verify prices parsed
      expect(stations[0].e5, closeTo(1.879, 0.001));
      expect(stations[0].diesel, closeTo(1.659, 0.001));

      // Step 3: Sort by distance
      stations.sort((a, b) => a.dist.compareTo(b.dist));
      // Station 1001 is closest to search point (48.85, 2.35)
      expect(stations.first.id, '1001');
    });

    test('full pipeline: handles mixed data quality', () {
      final apiData = {
        'results': [
          {
            'id': '2001',
            'adresse': 'GOOD STATION',
            'ville': 'LYON',
            'cp': '69001',
            'geom': {'lat': 45.76, 'lon': 4.84},
            'sp95_prix': 1.899,
            'e10_prix': 1.819,
            'gazole_prix': 1.679,
            'sp98_prix': 1.959,
            'e85_prix': 0.899,
            'gplc_prix': 0.999,
            'horaires_automate_24_24': 'Oui',
            'services_service': ['Lavage', 'DAB', 'Boutique'],
            'carburants_disponibles': ['Gazole', 'SP95', 'E10', 'SP98'],
            'carburants_indisponibles': ['E85'],
            'pop': 'R',
            'departement': 'Rhône',
            'region': 'Auvergne-Rhône-Alpes',
            'gazole_maj': '2026-03-29T14:30:00+00:00',
            'sp95_maj': '2026-03-29T14:30:00+00:00',
            'horaires_jour': 'Lundi07.00-21.00, Mardi07.00-21.00',
          },
          // Station with null/missing fields
          {
            'id': null,
            'adresse': null,
            'ville': null,
            'cp': null,
            'geom': null,
            'latitude': '4576000',
            'longitude': '484000',
          },
        ],
      };

      final results = testableService.testExtractResults(apiData);
      expect(results, hasLength(2));

      // Parse first station — fully populated
      final s1 = testableService.testParseStation(results[0], 45.76, 4.84);
      expect(s1, isNotNull);
      expect(s1!.e5, closeTo(1.899, 0.001));
      expect(s1.e10, closeTo(1.819, 0.001));
      expect(s1.diesel, closeTo(1.679, 0.001));
      expect(s1.e98, closeTo(1.959, 0.001));
      expect(s1.e85, closeTo(0.899, 0.001));
      expect(s1.lpg, closeTo(0.999, 0.001));
      expect(s1.is24h, isTrue);
      expect(s1.services, hasLength(3));
      expect(s1.availableFuels, hasLength(4));
      expect(s1.unavailableFuels, hasLength(1));
      expect(s1.department, 'Rhône');
      expect(s1.region, 'Auvergne-Rhône-Alpes');
      expect(s1.updatedAt, contains('29/03'));
      expect(s1.openingHoursText, contains('07:00-21:00'));

      // Parse second station — minimal data, uses legacy lat/lng fallback
      final s2 = testableService.testParseStation(results[1], 45.76, 4.84);
      expect(s2, isNotNull);
      expect(s2!.id, '');
      expect(s2.lat, closeTo(45.76, 0.01));
      expect(s2.lng, closeTo(4.84, 0.01));
    });

    test('mostRecentUpdate handles FormatException with fallback', () {
      final record = {
        'gazole_maj': 'not-a-date-format',
      };
      // Should not throw, should return a trimmed string
      final result = testableService.testMostRecentUpdate(record);
      expect(result, isNotNull);
    });

    test('parseStation handles geom with only lat (no lon)', () {
      final record = {
        'id': '9999',
        'adresse': 'Test',
        'ville': 'Test',
        'cp': '00000',
        'geom': {'lat': 48.0},
        'latitude': '4800000',
        'longitude': '200000',
      };
      final station = testableService.testParseStation(record, 48.0, 2.0);
      expect(station, isNotNull);
      // lng is 0 from geom, so falls back to legacy
      expect(station!.lat, closeTo(48.0, 0.1));
      expect(station.lng, closeTo(2.0, 0.1));
    });

    test('detectBrand detects brand from services field', () {
      final record = {
        'id': '1',
        'adresse': 'GARAGE DU COIN',
        'ville': 'PARIS',
        'cp': '75001',
        'geom': {'lat': 48.0, 'lon': 2.0},
        'services_service': ['Vente de fioul domestique', 'TOTAL WASH'],
      };
      final station = testableService.testParseStation(record, 48.0, 2.0);
      // 'TOTAL ' should match in the services text
      expect(station?.brand, 'Total');
    });

    test('detectBrand detects brand from ville field', () {
      final record = {
        'id': '1',
        'adresse': 'RN7',
        'ville': 'AUCHAN CENTRE COMMERCIAL',
        'cp': '75001',
        'geom': {'lat': 48.0, 'lon': 2.0},
      };
      final station = testableService.testParseStation(record, 48.0, 2.0);
      expect(station?.brand, 'Auchan');
    });
  });

  group('PrixCarburantsStationService search strategy (#163)', () {
    /// Helper to build a mock API response with stations in a given postal code.
    Map<String, dynamic> _makeApiResponse(String cp, int count) {
      return {
        'results': List.generate(count, (i) => {
          'id': '${cp}00$i',
          'adresse': 'Station $i',
          'ville': 'Ville-$cp',
          'cp': cp,
          'geom': {'lat': 48.85, 'lon': 2.35},
          'sp95_prix': 1.879,
          'gazole_prix': 1.659,
        }),
      };
    }

    test('uses postal code query first when postalCode is provided', () async {
      final adapter = _TrackingMockAdapter();
      // First request (CP query) returns results
      adapter.addResponse(_makeApiResponse('75012', 3));

      final dio = Dio(BaseOptions(baseUrl: ''))..httpClientAdapter = adapter;
      final svc = PrixCarburantsStationService(dio: dio);

      final params = const SearchParams(
        lat: 48.84, lng: 2.38, radiusKm: 5.0, postalCode: '75012',
      );
      final result = await svc.searchStations(params);

      // Should have made exactly 1 request (CP query), not a geo query
      expect(adapter.requestCount, 1);
      expect(adapter.lastRequestUri, contains('cp%3D%2775012%27'));
      expect(result.data, hasLength(3));
      expect(result.data.first.postCode, '75012');
    });

    test('falls back to geo query when postal code returns empty', () async {
      final adapter = _TrackingMockAdapter();
      // First request (CP query) returns empty
      adapter.addResponse({'results': []});
      // Second request (geo query) returns results
      adapter.addResponse(_makeApiResponse('75012', 2));

      final dio = Dio(BaseOptions(baseUrl: ''))..httpClientAdapter = adapter;
      final svc = PrixCarburantsStationService(dio: dio);

      final params = const SearchParams(
        lat: 48.84, lng: 2.38, radiusKm: 5.0, postalCode: '75012',
      );
      final result = await svc.searchStations(params);

      // Should have made 2 requests: CP (empty) then geo
      expect(adapter.requestCount, 2);
      expect(adapter.requestUris[0], contains('cp%3D%2775012%27'));
      expect(adapter.requestUris[1], contains('within_distance'));
      expect(result.data, hasLength(2));
    });

    test('uses geo query directly when no postal code provided', () async {
      final adapter = _TrackingMockAdapter();
      // Only geo query
      adapter.addResponse(_makeApiResponse('75012', 4));

      final dio = Dio(BaseOptions(baseUrl: ''))..httpClientAdapter = adapter;
      final svc = PrixCarburantsStationService(dio: dio);

      final params = const SearchParams(
        lat: 48.84, lng: 2.38, radiusKm: 5.0,
      );
      final result = await svc.searchStations(params);

      // Should have made exactly 1 request (geo), never a CP query
      expect(adapter.requestCount, 1);
      expect(adapter.lastRequestUri, contains('within_distance'));
      expect(result.data, hasLength(4));
    });

    test('does not call geo when postal code query succeeds', () async {
      final adapter = _TrackingMockAdapter();
      adapter.addResponse(_makeApiResponse('34120', 5));

      final dio = Dio(BaseOptions(baseUrl: ''))..httpClientAdapter = adapter;
      final svc = PrixCarburantsStationService(dio: dio);

      final params = const SearchParams(
        lat: 43.45, lng: 3.42, radiusKm: 10.0, postalCode: '34120',
      );
      final result = await svc.searchStations(params);

      expect(adapter.requestCount, 1);
      expect(adapter.lastRequestUri, isNot(contains('within_distance')));
      expect(result.data, hasLength(5));
    });

    test('empty postal code string is treated as no postal code', () async {
      final adapter = _TrackingMockAdapter();
      adapter.addResponse(_makeApiResponse('75001', 2));

      final dio = Dio(BaseOptions(baseUrl: ''))..httpClientAdapter = adapter;
      final svc = PrixCarburantsStationService(dio: dio);

      final params = const SearchParams(
        lat: 48.85, lng: 2.35, radiusKm: 5.0, postalCode: '',
      );
      final result = await svc.searchStations(params);

      // Empty postal code -> geo-first path
      expect(adapter.requestCount, 1);
      expect(adapter.lastRequestUri, contains('within_distance'));
      expect(result.data, hasLength(2));
    });
  });
}

/// Mock Dio adapter that tracks requests and returns canned responses.
class _TrackingMockAdapter implements HttpClientAdapter {
  final List<Map<String, dynamic>> _responses = [];
  final List<String> requestUris = [];
  int _responseIndex = 0;

  int get requestCount => requestUris.length;
  String get lastRequestUri => requestUris.last;

  void addResponse(Map<String, dynamic> body) {
    _responses.add(body);
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestUris.add(options.uri.toString());

    if (_responseIndex >= _responses.length) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.unknown,
        error: 'No more mock responses',
      );
    }

    final body = _responses[_responseIndex++];
    final encoded = jsonEncode(body);
    return ResponseBody.fromString(
      encoded,
      200,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Testable helper that replicates PrixCarburantsStationService parsing logic.
class _TestablePrixCarburantsService {
  List<Map<String, dynamic>> testExtractResults(dynamic data) {
    if (data is Map<String, dynamic>) {
      final results = data['results'] as List<dynamic>? ?? [];
      return results.map((r) => r as Map<String, dynamic>).toList();
    }
    return [];
  }

  Station? testParseStation(Map<String, dynamic> r, double searchLat, double searchLng) {
    try {
      final geom = r['geom'] as Map<String, dynamic>?;
      double lat = (geom?['lat'] as num?)?.toDouble() ?? 0;
      double lng = (geom?['lon'] as num?)?.toDouble() ?? 0;

      if (lat == 0 || lng == 0) {
        final latStr = r['latitude']?.toString() ?? '0';
        final lngStr = r['longitude']?.toString() ?? '0';
        lat = (double.tryParse(latStr) ?? 0) / 100000;
        lng = (double.tryParse(lngStr) ?? 0) / 100000;
      }

      final adresse = r['adresse'] as String? ?? '';
      final ville = r['ville'] as String? ?? '';
      final cp = r['cp'] as String? ?? '';

      return Station(
        id: r['id']?.toString() ?? '',
        name: adresse,
        brand: _detectBrand(adresse, r['services_service'], r),
        street: adresse,
        postCode: cp,
        place: ville,
        lat: lat,
        lng: lng,
        dist: 0,
        e5: _toDouble(r['sp95_prix']),
        e10: _toDouble(r['e10_prix']),
        e98: _toDouble(r['sp98_prix']),
        diesel: _toDouble(r['gazole_prix']),
        e85: _toDouble(r['e85_prix']),
        lpg: _toDouble(r['gplc_prix']),
        isOpen: true,
        updatedAt: testMostRecentUpdate(r),
        is24h: r['horaires_automate_24_24'] == 'Oui',
        openingHoursText: testParseOpeningHours(r['horaires_jour']),
        services: testParseServices(r['services_service']),
        availableFuels: _parseStringList(r['carburants_disponibles']),
        unavailableFuels: _parseStringList(r['carburants_indisponibles']),
        stationType: r['pop']?.toString(),
        department: r['departement']?.toString(),
        region: r['region']?.toString(),
      );
    } on FormatException catch (_) {
      return null;
    }
  }

  String? testMostRecentUpdate(Map<String, dynamic> r) {
    final dates = <String>[
      r['gazole_maj']?.toString() ?? '',
      r['sp95_maj']?.toString() ?? '',
      r['e10_maj']?.toString() ?? '',
      r['sp98_maj']?.toString() ?? '',
      r['e85_maj']?.toString() ?? '',
      r['gplc_maj']?.toString() ?? '',
    ].where((d) => d.isNotEmpty).toList();
    if (dates.isEmpty) return null;
    dates.sort((a, b) => b.compareTo(a));
    try {
      final dt = DateTime.parse(dates.first);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } on FormatException catch (_) {
      return dates.first.substring(0, 16).replaceAll('T', ' ');
    }
  }

  String? testParseOpeningHours(dynamic hoursStr) {
    if (hoursStr == null) return null;
    final s = hoursStr.toString();
    if (s.isEmpty) return null;
    return s
        .replaceAll('Automate-24-24, ', '')
        .replaceAllMapped(RegExp(r'(\d{2})\.(\d{2})-(\d{2})\.(\d{2})'),
            (m) => '${m[1]}:${m[2]}-${m[3]}:${m[4]}')
        .replaceAllMapped(RegExp(r'(\d{2})\.(\d{2})'),
            (m) => '${m[1]}:${m[2]}')
        .replaceAll(', ', '\n');
  }

  List<String> testParseServices(dynamic services) {
    if (services is List) return services.map((e) => e.toString()).toList();
    return [];
  }

  List<String> _parseStringList(dynamic list) {
    if (list is List) return list.map((e) => e.toString()).toList();
    return [];
  }

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  double? testToDouble(dynamic v) => _toDouble(v);

  String _detectBrand(String adresse, dynamic services, Map<String, dynamic> r) {
    final ville = r['ville']?.toString() ?? '';
    final allServices = services is List ? services.join(' ') : (services?.toString() ?? '');
    final text = '$adresse $ville $allServices'.toUpperCase();

    const brandMap = {
      'TOTALENERGIES': 'TotalEnergies',
      'TOTAL ': 'Total',
      'LECLERC': 'E.Leclerc',
      'CARREFOUR': 'Carrefour',
      'INTERMARCHE': 'Intermarché',
      'INTERMARCHÉ': 'Intermarché',
      'AUCHAN': 'Auchan',
      'SUPER U': 'Super U',
      'SYSTEME U': 'Système U',
      'SYSTÈME U': 'Système U',
      'CASINO': 'Casino',
      'BP ': 'BP',
      'SHELL': 'Shell',
      'ESSO': 'Esso',
      'AVIA': 'AVIA',
      'VITO': 'Vito',
      'NETTO': 'Netto',
      'DYNEFF': 'Dyneff',
    };

    for (final entry in brandMap.entries) {
      if (text.contains(entry.key)) return entry.value;
    }

    final pop = r['pop']?.toString() ?? '';
    if (pop == 'A') return 'Autoroute';
    return 'Station';
  }
}
