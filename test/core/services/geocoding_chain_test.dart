import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/cache/cache_manager.dart';
import 'package:tankstellen/core/error/exceptions.dart';
import 'package:tankstellen/core/services/geocoding_chain.dart';
import 'package:tankstellen/core/services/geocoding_provider.dart';
import 'package:tankstellen/core/services/service_result.dart';

class MockCacheManager extends Mock implements CacheManager {}

class MockGeocodingProvider extends Mock implements GeocodingProvider {}

void main() {
  late MockCacheManager mockCache;
  late MockGeocodingProvider providerA;
  late MockGeocodingProvider providerB;
  late GeocodingChain chain;

  setUpAll(() {
    registerFallbackValue(const Duration(seconds: 1));
    registerFallbackValue(ServiceSource.cache);
  });

  setUp(() {
    mockCache = MockCacheManager();
    providerA = MockGeocodingProvider();
    providerB = MockGeocodingProvider();
    chain = GeocodingChain([providerA, providerB], mockCache);

    // Default: both providers are available
    when(() => providerA.isAvailable).thenReturn(true);
    when(() => providerB.isAvailable).thenReturn(true);
    when(() => providerA.source).thenReturn(ServiceSource.nativeGeocoding);
    when(() => providerB.source).thenReturn(ServiceSource.nominatimGeocoding);
  });

  group('zipCodeToCoordinates', () {
    test('returns fresh cache hit without calling providers', () async {
      when(() => mockCache.getFresh('geo:zip:10115')).thenReturn(CacheEntry(
        payload: {'lat': 52.52, 'lng': 13.41},
        storedAt: DateTime.now(),
        originalSource: ServiceSource.nominatimGeocoding,
        ttl: CacheTtl.geocode,
      ));

      final result = await chain.zipCodeToCoordinates('10115');

      expect(result.data.lat, 52.52);
      expect(result.data.lng, 13.41);
      expect(result.source, ServiceSource.nominatimGeocoding);
      verifyNever(() => providerA.zipCodeToCoordinates(any()));
      verifyNever(() => providerB.zipCodeToCoordinates(any()));
    });

    test('tries first available provider on cache miss', () async {
      when(() => mockCache.getFresh('geo:zip:10115')).thenReturn(null);
      when(() => providerA.zipCodeToCoordinates('10115'))
          .thenAnswer((_) async => (lat: 52.52, lng: 13.41));
      when(() => mockCache.put(
            any(),
            any(),
            ttl: any(named: 'ttl'),
            source: any(named: 'source'),
          )).thenAnswer((_) async {});

      final result = await chain.zipCodeToCoordinates('10115');

      expect(result.data.lat, 52.52);
      expect(result.source, ServiceSource.nativeGeocoding);
      verify(() => providerA.zipCodeToCoordinates('10115')).called(1);
    });

    test('falls back to second provider when first fails', () async {
      when(() => mockCache.getFresh('geo:zip:10115')).thenReturn(null);
      when(() => providerA.zipCodeToCoordinates('10115'))
          .thenThrow(Exception('Native geocoding unavailable'));
      when(() => providerB.zipCodeToCoordinates('10115'))
          .thenAnswer((_) async => (lat: 52.52, lng: 13.41));
      when(() => mockCache.put(
            any(),
            any(),
            ttl: any(named: 'ttl'),
            source: any(named: 'source'),
          )).thenAnswer((_) async {});

      final result = await chain.zipCodeToCoordinates('10115');

      expect(result.data.lat, 52.52);
      expect(result.source, ServiceSource.nominatimGeocoding);
      expect(result.errors.length, 1);
      expect(result.errors.first.source, ServiceSource.nativeGeocoding);
    });

    test('skips unavailable providers', () async {
      when(() => providerA.isAvailable).thenReturn(false);
      when(() => mockCache.getFresh('geo:zip:10115')).thenReturn(null);
      when(() => providerB.zipCodeToCoordinates('10115'))
          .thenAnswer((_) async => (lat: 52.52, lng: 13.41));
      when(() => mockCache.put(
            any(),
            any(),
            ttl: any(named: 'ttl'),
            source: any(named: 'source'),
          )).thenAnswer((_) async {});

      final result = await chain.zipCodeToCoordinates('10115');

      expect(result.source, ServiceSource.nominatimGeocoding);
      verifyNever(() => providerA.zipCodeToCoordinates(any()));
    });

    test('falls back to stale cache when all providers fail', () async {
      when(() => mockCache.getFresh('geo:zip:10115')).thenReturn(null);
      when(() => providerA.zipCodeToCoordinates('10115'))
          .thenThrow(Exception('fail'));
      when(() => providerB.zipCodeToCoordinates('10115'))
          .thenThrow(Exception('fail'));
      when(() => mockCache.get('geo:zip:10115')).thenReturn(CacheEntry(
        payload: {'lat': 52.52, 'lng': 13.41},
        storedAt: DateTime.now().subtract(const Duration(hours: 48)),
        originalSource: ServiceSource.nominatimGeocoding,
        ttl: CacheTtl.geocode,
      ));

      final result = await chain.zipCodeToCoordinates('10115');

      expect(result.data.lat, 52.52);
      expect(result.isStale, true);
      expect(result.source, ServiceSource.cache);
      expect(result.errors.length, 2);
    });

    test('throws ServiceChainExhaustedException when all fail and no cache',
        () async {
      when(() => mockCache.getFresh('geo:zip:10115')).thenReturn(null);
      when(() => providerA.zipCodeToCoordinates('10115'))
          .thenThrow(Exception('fail'));
      when(() => providerB.zipCodeToCoordinates('10115'))
          .thenThrow(Exception('fail'));
      when(() => mockCache.get('geo:zip:10115')).thenReturn(null);

      expect(
        () => chain.zipCodeToCoordinates('10115'),
        throwsA(isA<ServiceChainExhaustedException>()),
      );
    });

    test('handles invalid cache data gracefully', () async {
      when(() => mockCache.getFresh('geo:zip:10115')).thenReturn(CacheEntry(
        payload: {'lat': 'invalid', 'lng': 'data'},
        storedAt: DateTime.now(),
        originalSource: ServiceSource.cache,
        ttl: CacheTtl.geocode,
      ));
      // Invalid cache should be skipped, providers called
      when(() => providerA.zipCodeToCoordinates('10115'))
          .thenAnswer((_) async => (lat: 52.52, lng: 13.41));
      when(() => mockCache.put(
            any(),
            any(),
            ttl: any(named: 'ttl'),
            source: any(named: 'source'),
          )).thenAnswer((_) async {});

      final result = await chain.zipCodeToCoordinates('10115');

      expect(result.data.lat, 52.52);
    });

    test('caches result on provider success', () async {
      when(() => mockCache.getFresh('geo:zip:10115')).thenReturn(null);
      when(() => providerA.zipCodeToCoordinates('10115'))
          .thenAnswer((_) async => (lat: 52.52, lng: 13.41));
      when(() => mockCache.put(
            any(),
            any(),
            ttl: any(named: 'ttl'),
            source: any(named: 'source'),
          )).thenAnswer((_) async {});

      await chain.zipCodeToCoordinates('10115');

      verify(() => mockCache.put(
            'geo:zip:10115',
            {'lat': 52.52, 'lng': 13.41},
            ttl: CacheTtl.geocode,
            source: ServiceSource.nativeGeocoding,
          )).called(1);
    });
  });

  group('zipCodeToCoordinates — bounding box validation', () {
    late GeocodingChain deChain;
    late GeocodingChain frChain;
    late GeocodingChain gbChain;

    setUp(() {
      deChain = GeocodingChain([providerA, providerB], mockCache, countryCode: 'DE');
      frChain = GeocodingChain([providerA, providerB], mockCache, countryCode: 'FR');
      gbChain = GeocodingChain([providerA, providerB], mockCache, countryCode: 'GB');
    });

    test('accepts coordinates within Germany bounding box', () async {
      when(() => mockCache.getFresh('geo:zip:10115')).thenReturn(null);
      when(() => providerA.zipCodeToCoordinates('10115'))
          .thenAnswer((_) async => (lat: 52.52, lng: 13.41)); // Berlin
      when(() => mockCache.put(
            any(), any(),
            ttl: any(named: 'ttl'), source: any(named: 'source'),
          )).thenAnswer((_) async {});

      final result = await deChain.zipCodeToCoordinates('10115');

      expect(result.data.lat, 52.52);
      expect(result.data.lng, 13.41);
      expect(result.errors, isEmpty);
    });

    test('rejects coordinates outside Germany and tries next provider', () async {
      when(() => mockCache.getFresh('geo:zip:10115')).thenReturn(null);
      // Provider A returns Paris coordinates (outside DE)
      when(() => providerA.zipCodeToCoordinates('10115'))
          .thenAnswer((_) async => (lat: 48.86, lng: 2.35));
      // Provider B returns correct Berlin coordinates
      when(() => providerB.zipCodeToCoordinates('10115'))
          .thenAnswer((_) async => (lat: 52.52, lng: 13.41));
      when(() => mockCache.put(
            any(), any(),
            ttl: any(named: 'ttl'), source: any(named: 'source'),
          )).thenAnswer((_) async {});

      final result = await deChain.zipCodeToCoordinates('10115');

      expect(result.data.lat, 52.52);
      expect(result.data.lng, 13.41);
      expect(result.source, ServiceSource.nominatimGeocoding);
      expect(result.errors.length, 1);
      expect(result.errors.first.message, contains('outside DE bounds'));
    });

    test('rejects coordinates from ocean for France', () async {
      when(() => mockCache.getFresh('geo:zip:75012')).thenReturn(null);
      // Provider A returns ocean coordinates
      when(() => providerA.zipCodeToCoordinates('75012'))
          .thenAnswer((_) async => (lat: 0.0, lng: 0.0));
      // Provider B returns correct Paris coordinates
      when(() => providerB.zipCodeToCoordinates('75012'))
          .thenAnswer((_) async => (lat: 48.84, lng: 2.39));
      when(() => mockCache.put(
            any(), any(),
            ttl: any(named: 'ttl'), source: any(named: 'source'),
          )).thenAnswer((_) async {});

      final result = await frChain.zipCodeToCoordinates('75012');

      expect(result.data.lat, 48.84);
      expect(result.data.lng, 2.39);
      expect(result.errors.length, 1);
    });

    test('rejects coordinates from wrong country for UK', () async {
      when(() => mockCache.getFresh('geo:zip:SW1A 1AA')).thenReturn(null);
      // Provider A returns Sydney coordinates (wrong hemisphere!)
      when(() => providerA.zipCodeToCoordinates('SW1A 1AA'))
          .thenAnswer((_) async => (lat: -33.87, lng: 151.21));
      // Provider B returns correct London coordinates
      when(() => providerB.zipCodeToCoordinates('SW1A 1AA'))
          .thenAnswer((_) async => (lat: 51.50, lng: -0.14));
      when(() => mockCache.put(
            any(), any(),
            ttl: any(named: 'ttl'), source: any(named: 'source'),
          )).thenAnswer((_) async {});

      final result = await gbChain.zipCodeToCoordinates('SW1A 1AA');

      expect(result.data.lat, 51.50);
      expect(result.data.lng, -0.14);
      expect(result.errors.length, 1);
      expect(result.errors.first.message, contains('outside GB bounds'));
    });

    test('throws when all providers return out-of-bounds coordinates', () async {
      when(() => mockCache.getFresh('geo:zip:10115')).thenReturn(null);
      // Both providers return coordinates outside Germany
      when(() => providerA.zipCodeToCoordinates('10115'))
          .thenAnswer((_) async => (lat: 48.86, lng: 2.35)); // Paris
      when(() => providerB.zipCodeToCoordinates('10115'))
          .thenAnswer((_) async => (lat: -34.60, lng: -58.38)); // Buenos Aires
      when(() => mockCache.get('geo:zip:10115')).thenReturn(null);

      expect(
        () => deChain.zipCodeToCoordinates('10115'),
        throwsA(isA<ServiceChainExhaustedException>()),
      );
    });

    test('rejects stale cache with out-of-bounds coordinates', () async {
      when(() => mockCache.getFresh('geo:zip:10115')).thenReturn(null);
      when(() => providerA.zipCodeToCoordinates('10115'))
          .thenThrow(Exception('fail'));
      when(() => providerB.zipCodeToCoordinates('10115'))
          .thenThrow(Exception('fail'));
      // Stale cache has coordinates from wrong country
      when(() => mockCache.get('geo:zip:10115')).thenReturn(CacheEntry(
        payload: {'lat': 48.86, 'lng': 2.35}, // Paris, not Germany
        storedAt: DateTime.now().subtract(const Duration(hours: 48)),
        originalSource: ServiceSource.nominatimGeocoding,
        ttl: CacheTtl.geocode,
      ));

      expect(
        () => deChain.zipCodeToCoordinates('10115'),
        throwsA(isA<ServiceChainExhaustedException>()),
      );
    });

    test('rejects fresh cache with out-of-bounds coordinates and re-geocodes', () async {
      // Fresh cache has wrong coordinates
      when(() => mockCache.getFresh('geo:zip:10115')).thenReturn(CacheEntry(
        payload: {'lat': 48.86, 'lng': 2.35}, // Paris, not Germany
        storedAt: DateTime.now(),
        originalSource: ServiceSource.nominatimGeocoding,
        ttl: CacheTtl.geocode,
      ));
      // Provider returns correct coordinates
      when(() => providerA.zipCodeToCoordinates('10115'))
          .thenAnswer((_) async => (lat: 52.52, lng: 13.41));
      when(() => mockCache.put(
            any(), any(),
            ttl: any(named: 'ttl'), source: any(named: 'source'),
          )).thenAnswer((_) async {});

      final result = await deChain.zipCodeToCoordinates('10115');

      expect(result.data.lat, 52.52);
      verify(() => providerA.zipCodeToCoordinates('10115')).called(1);
    });

    test('no validation when countryCode is null', () async {
      // Chain without country code (original behavior)
      final noCountryChain = GeocodingChain([providerA], mockCache);

      when(() => mockCache.getFresh('geo:zip:10115')).thenReturn(null);
      // Returns coordinates from wrong continent — accepted without validation
      when(() => providerA.zipCodeToCoordinates('10115'))
          .thenAnswer((_) async => (lat: -33.87, lng: 151.21));
      when(() => mockCache.put(
            any(), any(),
            ttl: any(named: 'ttl'), source: any(named: 'source'),
          )).thenAnswer((_) async {});

      final result = await noCountryChain.zipCodeToCoordinates('10115');

      expect(result.data.lat, -33.87);
      expect(result.errors, isEmpty);
    });

    test('no validation for unknown country code', () async {
      final unknownChain = GeocodingChain([providerA], mockCache, countryCode: 'ZZ');

      when(() => mockCache.getFresh('geo:zip:12345')).thenReturn(null);
      when(() => providerA.zipCodeToCoordinates('12345'))
          .thenAnswer((_) async => (lat: 0.0, lng: 0.0));
      when(() => mockCache.put(
            any(), any(),
            ttl: any(named: 'ttl'), source: any(named: 'source'),
          )).thenAnswer((_) async {});

      final result = await unknownChain.zipCodeToCoordinates('12345');

      expect(result.data.lat, 0.0);
      expect(result.errors, isEmpty);
    });
  });

  group('coordinatesToAddress', () {
    test('returns fresh cache hit', () async {
      when(() => mockCache.getFresh(any())).thenReturn(CacheEntry(
        payload: {'address': '10115 Berlin'},
        storedAt: DateTime.now(),
        originalSource: ServiceSource.nominatimGeocoding,
        ttl: CacheTtl.geocode,
      ));

      final result = await chain.coordinatesToAddress(52.52, 13.41);

      expect(result.data, '10115 Berlin');
      expect(result.source, ServiceSource.nominatimGeocoding);
    });

    test('tries providers on cache miss', () async {
      when(() => mockCache.getFresh(any())).thenReturn(null);
      when(() => providerA.coordinatesToAddress(52.52, 13.41))
          .thenAnswer((_) async => '10115 Berlin');
      when(() => mockCache.put(
            any(),
            any(),
            ttl: any(named: 'ttl'),
            source: any(named: 'source'),
          )).thenAnswer((_) async {});

      final result = await chain.coordinatesToAddress(52.52, 13.41);

      expect(result.data, '10115 Berlin');
      expect(result.source, ServiceSource.nativeGeocoding);
    });

    test('returns coordinate string when all fail and no cache', () async {
      when(() => mockCache.getFresh(any())).thenReturn(null);
      when(() => providerA.coordinatesToAddress(52.52, 13.41))
          .thenThrow(Exception('fail'));
      when(() => providerB.coordinatesToAddress(52.52, 13.41))
          .thenThrow(Exception('fail'));
      when(() => mockCache.get(any())).thenReturn(null);

      final result = await chain.coordinatesToAddress(52.52, 13.41);

      expect(result.data, '52.52, 13.41');
      expect(result.isStale, true);
      expect(result.errors.length, 2);
    });

    test('returns stale cache when providers fail', () async {
      when(() => mockCache.getFresh(any())).thenReturn(null);
      when(() => providerA.coordinatesToAddress(52.52, 13.41))
          .thenThrow(Exception('fail'));
      when(() => providerB.coordinatesToAddress(52.52, 13.41))
          .thenThrow(Exception('fail'));
      when(() => mockCache.get(any())).thenReturn(CacheEntry(
        payload: {'address': '10115 Berlin'},
        storedAt: DateTime.now().subtract(const Duration(hours: 48)),
        originalSource: ServiceSource.nominatimGeocoding,
        ttl: CacheTtl.geocode,
      ));

      final result = await chain.coordinatesToAddress(52.52, 13.41);

      expect(result.data, '10115 Berlin');
      expect(result.isStale, true);
    });
  });

  group('coordinatesToCountryCode', () {
    test('returns cached country code', () async {
      when(() => mockCache.getFresh(any())).thenReturn(CacheEntry(
        payload: {'countryCode': 'DE'},
        storedAt: DateTime.now(),
        originalSource: ServiceSource.nominatimGeocoding,
        ttl: CacheTtl.geocode,
      ));

      final result = await chain.coordinatesToCountryCode(52.52, 13.41);

      expect(result, 'DE');
    });

    test('tries providers when no cache', () async {
      when(() => mockCache.getFresh(any())).thenReturn(null);
      when(() => providerA.coordinatesToCountryCode(52.52, 13.41))
          .thenAnswer((_) async => 'DE');
      when(() => mockCache.put(
            any(),
            any(),
            ttl: any(named: 'ttl'),
            source: any(named: 'source'),
          )).thenAnswer((_) async {});

      final result = await chain.coordinatesToCountryCode(52.52, 13.41);

      expect(result, 'DE');
    });

    test('returns null when all providers return null', () async {
      when(() => mockCache.getFresh(any())).thenReturn(null);
      when(() => providerA.coordinatesToCountryCode(52.52, 13.41))
          .thenAnswer((_) async => null);
      when(() => providerB.coordinatesToCountryCode(52.52, 13.41))
          .thenAnswer((_) async => null);

      final result = await chain.coordinatesToCountryCode(52.52, 13.41);

      expect(result, isNull);
    });

    test('skips unavailable providers', () async {
      when(() => providerA.isAvailable).thenReturn(false);
      when(() => mockCache.getFresh(any())).thenReturn(null);
      when(() => providerB.coordinatesToCountryCode(52.52, 13.41))
          .thenAnswer((_) async => 'FR');
      when(() => mockCache.put(
            any(),
            any(),
            ttl: any(named: 'ttl'),
            source: any(named: 'source'),
          )).thenAnswer((_) async {});

      final result = await chain.coordinatesToCountryCode(52.52, 13.41);

      expect(result, 'FR');
    });
  });
}
