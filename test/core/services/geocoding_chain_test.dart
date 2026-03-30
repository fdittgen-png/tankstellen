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
