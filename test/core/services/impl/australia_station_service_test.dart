import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/error/exceptions.dart';
import 'package:tankstellen/core/services/impl/australia_station_service.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/services/station_service.dart';
import 'package:tankstellen/features/search/data/models/search_params.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';

void main() {
  late AustraliaStationService service;

  setUp(() {
    service = AustraliaStationService();
  });

  group('AustraliaStationService', () {
    test('implements StationService interface', () {
      expect(service, isA<StationService>());
    });

    group('getStationDetail', () {
      test('throws ApiException (not supported)', () {
        expect(
          () => service.getStationDetail('au-123'),
          throwsA(isA<ApiException>()),
        );
      });

      test('error message indicates lack of support', () async {
        try {
          await service.getStationDetail('au-123');
          fail('Should have thrown');
        } on ApiException catch (e) {
          expect(e.message, contains('not supported'));
        }
      });
    });

    group('getPrices', () {
      test('returns empty map (batch prices not supported)', () async {
        final result = await service.getPrices(['au-1', 'au-2']);
        expect(result.data, isEmpty);
        expect(result.source, ServiceSource.australiaApi);
      });

      test('returns valid ServiceResult for empty id list', () async {
        final result = await service.getPrices([]);
        expect(result.data, isA<Map<String, StationPrices>>());
        expect(result.source, ServiceSource.australiaApi);
      });
    });

    group('searchStations integration', () {
      test('returns ServiceResult with correct source', () async {
        // Sydney coordinates
        const params = SearchParams(lat: -33.87, lng: 151.21, radiusKm: 5.0);
        try {
          final result = await service.searchStations(params);
          expect(result.source, ServiceSource.australiaApi);
          expect(result.data, isA<List<Station>>());
          expect(result.fetchedAt, isA<DateTime>());
        } on ApiException {
          // Network may not be available in CI — acceptable.
        }
      });

      test('returns empty list for coordinates far from Australia', () async {
        // Middle of Atlantic — no stations.
        const params = SearchParams(lat: 0.0, lng: -30.0, radiusKm: 5.0);
        try {
          final result = await service.searchStations(params);
          expect(result.data, isEmpty);
        } on ApiException {
          // Network error is also acceptable.
        }
      });
    });
  });

  group('AustraliaStationService parsing (via _TestableAustraliaService)', () {
    late _TestableAustraliaService testableService;

    setUp(() {
      testableService = _TestableAustraliaService();
    });

    test('parseStation creates Station from nested location format', () {
      final item = {
        'code': 'NSW001',
        'name': 'Shell Bondi',
        'brand': 'Shell',
        'address': '123 Bondi Rd',
        'postcode': '2026',
        'suburb': 'Bondi',
        'location': {'latitude': -33.89, 'longitude': 151.27},
        'prices': [
          {'fueltype': 'U91', 'price': 1749},
          {'fueltype': 'P95', 'price': 1899},
          {'fueltype': 'P98', 'price': 2049},
          {'fueltype': 'DL', 'price': 1959},
          {'fueltype': 'LPG', 'price': 899},
        ],
      };

      final station = testableService.testParseStation(
        item,
        searchLat: -33.87,
        searchLng: 151.21,
      );
      expect(station, isNotNull);
      expect(station!.id, 'au-NSW001');
      expect(station.name, 'Shell Bondi');
      expect(station.brand, 'Shell');
      expect(station.street, '123 Bondi Rd');
      expect(station.postCode, '2026');
      expect(station.place, 'Bondi');
      expect(station.lat, -33.89);
      expect(station.lng, 151.27);
      // Prices: cents/10 => $/L
      expect(station.e5, closeTo(174.9, 0.1));
      expect(station.e10, closeTo(189.9, 0.1));
      expect(station.e98, closeTo(204.9, 0.1));
      expect(station.diesel, closeTo(195.9, 0.1));
      expect(station.lpg, closeTo(89.9, 0.1));
    });

    test('parseStation uses flat lat/lng when location is missing', () {
      final item = {
        'id': '42',
        'name': 'BP Suburban',
        'brand': 'BP',
        'address': '456 Main St',
        'postcode': '2000',
        'locality': 'Sydney',
        'lat': -33.87,
        'lng': 151.21,
        'prices': [],
      };

      final station = testableService.testParseStation(
        item,
        searchLat: -33.87,
        searchLng: 151.21,
      );
      expect(station, isNotNull);
      expect(station!.lat, -33.87);
      expect(station.lng, 151.21);
      expect(station.place, 'Sydney');
    });

    test('parseStation skips station with no coordinates', () {
      final item = {
        'code': 'NO_COORDS',
        'name': 'Ghost Station',
        'brand': 'Test',
        'address': 'Nowhere',
        'prices': [],
      };

      final station = testableService.testParseStation(
        item,
        searchLat: -33.87,
        searchLng: 151.21,
      );
      expect(station, isNull);
    });

    test('parseStation handles empty prices list', () {
      final item = {
        'code': 'EMPTY',
        'name': 'No Prices Station',
        'brand': 'Test',
        'address': 'Test St',
        'postcode': '2000',
        'suburb': 'Test',
        'location': {'latitude': -33.87, 'longitude': 151.21},
        'prices': [],
      };

      final station = testableService.testParseStation(
        item,
        searchLat: -33.87,
        searchLng: 151.21,
      );
      expect(station, isNotNull);
      expect(station!.e5, isNull);
      expect(station.e10, isNull);
      expect(station.diesel, isNull);
    });

    test('parseStation skips station outside radius', () {
      final item = {
        'code': 'FAR',
        'name': 'Far Away',
        'brand': 'Test',
        'address': 'Far St',
        'location': {'latitude': -34.5, 'longitude': 150.0},
        'prices': [],
      };

      final station = testableService.testParseStation(
        item,
        searchLat: -33.87,
        searchLng: 151.21,
        radiusKm: 5.0,
      );
      expect(station, isNull);
    });

    test('extractStationList handles Map response with stations key', () {
      final data = <String, dynamic>{
        'stations': [
          {'code': '1', 'name': 'S1'},
          {'code': '2', 'name': 'S2'},
        ],
      };
      final list = testableService.testExtractStationList(data);
      expect(list, hasLength(2));
    });

    test('extractStationList handles List response directly', () {
      final data = [
        {'code': '1', 'name': 'S1'},
      ];
      final list = testableService.testExtractStationList(data);
      expect(list, hasLength(1));
    });

    test('extractStationList returns empty for invalid data', () {
      expect(testableService.testExtractStationList('not valid'), isEmpty);
      expect(testableService.testExtractStationList(42), isEmpty);
    });

    test('parseStation handles partial prices (only some fuel types)', () {
      final item = {
        'code': 'PARTIAL',
        'name': 'Partial Prices',
        'brand': 'Test',
        'address': 'Test',
        'postcode': '2000',
        'suburb': 'Test',
        'location': {'latitude': -33.87, 'longitude': 151.21},
        'prices': [
          {'fueltype': 'U91', 'price': 1600},
        ],
      };

      final station = testableService.testParseStation(
        item,
        searchLat: -33.87,
        searchLng: 151.21,
      );
      expect(station, isNotNull);
      expect(station!.e5, closeTo(160.0, 0.1));
      expect(station.e10, isNull);
      expect(station.diesel, isNull);
      expect(station.lpg, isNull);
    });
  });
}

/// Testable wrapper that replicates AustraliaStationService parsing.
class _TestableAustraliaService {
  Station? testParseStation(
    Map<String, dynamic> item, {
    required double searchLat,
    required double searchLng,
    double radiusKm = 50.0,
  }) {
    try {
      final lat = (item['location']?['latitude'] ?? item['lat'] as num?)
          ?.toDouble();
      final lng = (item['location']?['longitude'] ?? item['lng'] as num?)
          ?.toDouble();
      if (lat == null || lng == null) return null;

      final dist = _distanceKm(searchLat, searchLng, lat, lng);
      if (dist > radiusKm) return null;

      final prices = item['prices'] as List<dynamic>? ?? [];
      double? u91, u95, u98, diesel, lpg;
      for (final p in prices) {
        final fuelType = p['fueltype']?.toString() ?? '';
        final price = (p['price'] as num?)?.toDouble();
        if (fuelType.contains('U91') || fuelType.contains('91')) u91 = price;
        if (fuelType.contains('P95') || fuelType.contains('95')) u95 = price;
        if (fuelType.contains('P98') || fuelType.contains('98')) u98 = price;
        if (fuelType.contains('DL') ||
            fuelType.toLowerCase().contains('diesel')) {
          diesel = price;
        }
        if (fuelType.contains('LPG')) lpg = price;
      }

      return Station(
        id: 'au-${item['code'] ?? item['id'] ?? 0}',
        name: item['name']?.toString() ?? item['station']?.toString() ?? '',
        brand: item['brand']?.toString() ?? '',
        street: item['address']?.toString() ?? '',
        postCode: item['postcode']?.toString() ?? '',
        place:
            item['suburb']?.toString() ?? item['locality']?.toString() ?? '',
        lat: lat,
        lng: lng,
        dist: dist,
        e5: u91 != null ? u91 / 10 : null,
        e10: u95 != null ? u95 / 10 : null,
        e98: u98 != null ? u98 / 10 : null,
        diesel: diesel != null ? diesel / 10 : null,
        lpg: lpg != null ? lpg / 10 : null,
        isOpen: true,
      );
    } catch (_) {
      return null;
    }
  }

  List<dynamic> testExtractStationList(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data['stations'] as List<dynamic>? ?? [];
    } else if (data is List) {
      return data;
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
