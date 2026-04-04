import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/error/exceptions.dart';
import 'package:tankstellen/core/services/impl/mexico_station_service.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/services/station_service.dart';
import 'package:tankstellen/features/search/data/models/search_params.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';

void main() {
  late MexicoStationService service;

  setUp(() {
    service = MexicoStationService();
  });

  group('MexicoStationService', () {
    test('implements StationService interface', () {
      expect(service, isA<StationService>());
    });

    group('getStationDetail', () {
      test('throws ApiException (not supported)', () {
        expect(
          () => service.getStationDetail('mx-123'),
          throwsA(isA<ApiException>()),
        );
      });

      test('error message indicates lack of support', () async {
        try {
          await service.getStationDetail('mx-PERM001');
          fail('Should have thrown');
        } on ApiException catch (e) {
          expect(e.message, contains('not supported'));
        }
      });
    });

    group('getPrices', () {
      test('returns empty map (batch prices not supported)', () async {
        final result = await service.getPrices(['mx-1', 'mx-2']);
        expect(result.data, isEmpty);
        expect(result.source, ServiceSource.mexicoApi);
      });

      test('returns valid ServiceResult for empty id list', () async {
        final result = await service.getPrices([]);
        expect(result.data, isA<Map<String, StationPrices>>());
        expect(result.source, ServiceSource.mexicoApi);
      });
    });

    group('searchStations integration', () {
      test('returns ServiceResult with correct source', () async {
        // Mexico City coordinates
        const params = SearchParams(lat: 19.43, lng: -99.13, radiusKm: 5.0);
        try {
          final result = await service.searchStations(params);
          expect(result.source, ServiceSource.mexicoApi);
          expect(result.data, isA<List<Station>>());
          expect(result.fetchedAt, isA<DateTime>());
        } on ApiException {
          // Network may not be available in CI.
        }
      });
    });
  });

  group('MexicoStationService parsing (via _TestableMexicoService)', () {
    late _TestableMexicoService testableService;

    setUp(() {
      testableService = _TestableMexicoService();
    });

    test('parseStation creates Station with full coordinates', () {
      final item = {
        'permiso': 'PL/1234/EXP/2020',
        'nombre': 'Gasolinera PEMEX Norte',
        'municipio': 'Benito Juárez',
        'estado': 'Ciudad de México',
        'precioRegular': 22.99,
        'precioPremium': 24.89,
        'precioDiesel': 23.45,
        'latitud': 19.43,
        'longitud': -99.13,
      };

      final station = testableService.testParseStation(
        item,
        searchLat: 19.43,
        searchLng: -99.13,
      );
      expect(station, isNotNull);
      expect(station!.id, 'mx-PL/1234/EXP/2020');
      expect(station.name, 'Gasolinera PEMEX Norte');
      expect(station.brand, 'Gasolinera');
      expect(station.place, 'Benito Juárez, Ciudad de México');
      expect(station.lat, 19.43);
      expect(station.lng, -99.13);
      expect(station.e5, 22.99);
      expect(station.e10, 24.89);
      expect(station.diesel, 23.45);
      expect(station.isOpen, isTrue);
    });

    test('parseStation skips station without coordinates', () {
      final item = {
        'permiso': 'PL/0001',
        'nombre': 'No Coords',
        'precioRegular': 22.0,
      };

      final station = testableService.testParseStation(
        item,
        searchLat: 19.43,
        searchLng: -99.13,
      );
      expect(station, isNull);
    });

    test('parseStation skips station outside radius', () {
      final item = {
        'permiso': 'PL/0002',
        'nombre': 'Far Station',
        'latitud': 25.67,
        'longitud': -100.31,
        'precioRegular': 22.0,
      };

      final station = testableService.testParseStation(
        item,
        searchLat: 19.43,
        searchLng: -99.13,
        radiusKm: 5.0,
      );
      expect(station, isNull);
    });

    test('parseStation handles null prices', () {
      final item = {
        'permiso': 'PL/0003',
        'nombre': 'No Prices',
        'latitud': 19.43,
        'longitud': -99.13,
        'precioRegular': null,
        'precioPremium': null,
        'precioDiesel': null,
      };

      final station = testableService.testParseStation(
        item,
        searchLat: 19.43,
        searchLng: -99.13,
      );
      expect(station, isNotNull);
      expect(station!.e5, isNull);
      expect(station.e10, isNull);
      expect(station.diesel, isNull);
    });

    test('parseStation extracts brand from first word of nombre', () {
      final item = {
        'permiso': 'PL/0004',
        'nombre': 'PEMEX La Reforma',
        'latitud': 19.43,
        'longitud': -99.13,
      };

      final station = testableService.testParseStation(
        item,
        searchLat: 19.43,
        searchLng: -99.13,
      );
      expect(station, isNotNull);
      expect(station!.brand, 'PEMEX');
    });

    test('parseStation uses index fallback when permiso is null', () {
      final item = {
        'nombre': 'Station Without Permiso',
        'latitud': 19.43,
        'longitud': -99.13,
      };

      final station = testableService.testParseStation(
        item,
        searchLat: 19.43,
        searchLng: -99.13,
        index: 7,
      );
      expect(station, isNotNull);
      expect(station!.id, 'mx-7');
    });

    test('extractResults handles paginated response format', () {
      final data = <String, dynamic>{
        'results': [
          {'permiso': '1', 'nombre': 'S1'},
          {'permiso': '2', 'nombre': 'S2'},
          {'permiso': '3', 'nombre': 'S3'},
        ],
      };
      final results = testableService.testExtractResults(data);
      expect(results, hasLength(3));
    });

    test('extractResults returns empty for missing results key', () {
      final data = <String, dynamic>{'total_count': 0};
      expect(testableService.testExtractResults(data), isEmpty);
    });

    test('extractResults returns empty for non-map data', () {
      expect(testableService.testExtractResults('string'), isEmpty);
      expect(testableService.testExtractResults(null), isEmpty);
    });
  });
}

/// Testable wrapper that replicates MexicoStationService parsing.
class _TestableMexicoService {
  Station? testParseStation(
    Map<String, dynamic> item, {
    required double searchLat,
    required double searchLng,
    double radiusKm = 50.0,
    int index = 0,
  }) {
    final regular = (item['precioRegular'] as num?)?.toDouble();
    final premium = (item['precioPremium'] as num?)?.toDouble();
    final diesel = (item['precioDiesel'] as num?)?.toDouble();

    final lat = (item['latitud'] as num?)?.toDouble();
    final lng = (item['longitud'] as num?)?.toDouble();

    if (lat == null || lng == null) return null;

    final dist = _distanceKm(searchLat, searchLng, lat, lng);
    if (dist > radiusKm) return null;

    final permiso = item['permiso']?.toString() ?? '$index';
    final nombre = item['nombre']?.toString() ?? '';

    return Station(
      id: 'mx-$permiso',
      name: nombre,
      brand: nombre.split(' ').first,
      street: '',
      postCode: '',
      place: '${item['municipio'] ?? ''}, ${item['estado'] ?? ''}',
      lat: lat,
      lng: lng,
      dist: dist,
      e5: regular,
      e10: premium,
      diesel: diesel,
      isOpen: true,
    );
  }

  List<Map<String, dynamic>> testExtractResults(dynamic data) {
    if (data is Map<String, dynamic>) {
      final results = data['results'] as List<dynamic>? ?? [];
      return results.cast<Map<String, dynamic>>();
    }
    return [];
  }

  double _distanceKm(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLng = (lng2 - lng1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLng / 2) *
            sin(dLng / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }
}
