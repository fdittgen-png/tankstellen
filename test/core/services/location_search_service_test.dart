import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/cache/cache_manager.dart';
import 'package:tankstellen/core/country/country_config.dart';
import 'package:tankstellen/core/services/location_search_service.dart';
import 'package:tankstellen/core/services/service_result.dart';

class MockCacheManager extends Mock implements CacheManager {}

void main() {
  late MockCacheManager mockCache;
  late LocationSearchService service;

  setUp(() {
    mockCache = MockCacheManager();
    service = LocationSearchService(mockCache);
  });

  group('detectInputType', () {
    test('returns gps for empty string', () {
      expect(
        service.detectInputType('', Countries.germany),
        equals(LocationInputType.gps),
      );
    });

    test('returns gps for whitespace-only string', () {
      expect(
        service.detectInputType('   ', Countries.germany),
        equals(LocationInputType.gps),
      );
    });

    test('returns zip for all-digit input', () {
      expect(
        service.detectInputType('10115', Countries.germany),
        equals(LocationInputType.zip),
      );
    });

    test('returns zip for short digit input', () {
      expect(
        service.detectInputType('1010', Countries.austria),
        equals(LocationInputType.zip),
      );
    });

    test('returns zip for single digit', () {
      expect(
        service.detectInputType('5', Countries.germany),
        equals(LocationInputType.zip),
      );
    });

    test('returns city for alphabetic input', () {
      expect(
        service.detectInputType('Berlin', Countries.germany),
        equals(LocationInputType.city),
      );
    });

    test('returns city for mixed alphanumeric input', () {
      expect(
        service.detectInputType('Berlin 10115', Countries.germany),
        equals(LocationInputType.city),
      );
    });

    test('returns city for input with special characters', () {
      expect(
        service.detectInputType('München', Countries.germany),
        equals(LocationInputType.city),
      );
    });

    test('returns city for input with hyphen', () {
      expect(
        service.detectInputType('Saint-Denis', Countries.france),
        equals(LocationInputType.city),
      );
    });

    test('trims input before detecting', () {
      expect(
        service.detectInputType('  10115  ', Countries.germany),
        equals(LocationInputType.zip),
      );
      expect(
        service.detectInputType('  Berlin  ', Countries.germany),
        equals(LocationInputType.city),
      );
    });
  });

  group('searchCities', () {
    test('returns empty list for query shorter than 2 characters', () async {
      final results = await service.searchCities('a');
      expect(results, isEmpty);
    });

    test('returns empty list for empty query', () async {
      final results = await service.searchCities('');
      expect(results, isEmpty);
    });

    test('returns empty list for single-space query', () async {
      final results = await service.searchCities(' ');
      expect(results, isEmpty);
    });

    test('returns cached results when cache has fresh entry', () async {
      // Set up mock to return a fresh cache entry with location data
      when(() => mockCache.getFresh(any())).thenReturn(
        CacheEntry(
          payload: {
            'locations': [
              {
                'name': 'Berlin, Germany',
                'lat': 52.52,
                'lng': 13.405,
                'postcode': '10115',
              },
            ],
          },
          storedAt: DateTime.now(),
          originalSource: ServiceSource.nominatimGeocoding,
          ttl: CacheTtl.citySearch,
        ),
      );

      final results = await service.searchCities('Berlin', countryCodes: ['de']);
      expect(results, hasLength(1));
      expect(results.first.name, equals('Berlin, Germany'));
      expect(results.first.lat, equals(52.52));
      expect(results.first.lng, equals(13.405));
      expect(results.first.postcode, equals('10115'));
    });
  });

  group('ResolvedLocation', () {
    test('stores all fields correctly', () {
      const loc = ResolvedLocation(
        name: 'Paris, France',
        lat: 48.856,
        lng: 2.352,
        postcode: '75001',
      );
      expect(loc.name, equals('Paris, France'));
      expect(loc.lat, equals(48.856));
      expect(loc.lng, equals(2.352));
      expect(loc.postcode, equals('75001'));
    });

    test('postcode is optional', () {
      const loc = ResolvedLocation(
        name: 'Somewhere',
        lat: 0.0,
        lng: 0.0,
      );
      expect(loc.postcode, isNull);
    });
  });

  group('LocationInputType', () {
    test('has three values', () {
      expect(LocationInputType.values.length, equals(3));
    });

    test('values are gps, zip, city', () {
      expect(
        LocationInputType.values,
        containsAll([
          LocationInputType.gps,
          LocationInputType.zip,
          LocationInputType.city,
        ]),
      );
    });
  });
}
