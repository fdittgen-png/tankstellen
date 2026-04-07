import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/cache/cache_manager.dart';
import 'package:tankstellen/core/error/exceptions.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/services/station_service.dart';
import 'package:tankstellen/core/services/station_service_chain.dart';
import 'package:tankstellen/features/search/data/models/search_params.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';

class MockStationService extends Mock implements StationService {}

class MockCacheManager extends Mock implements CacheManager {}

class FakeSearchParams extends Fake implements SearchParams {}

void main() {
  late MockStationService mockPrimary;
  late MockCacheManager mockCache;
  late StationServiceChain chain;

  const testParams = SearchParams(
    lat: 52.52,
    lng: 13.41,
    radiusKm: 10,
    fuelType: FuelType.e10,
  );

  const testStation = Station(
    id: 'abc-123',
    name: 'Test Station',
    brand: 'TEST',
    street: 'Teststr.',
    postCode: '10115',
    place: 'Berlin',
    lat: 52.52,
    lng: 13.41,
    isOpen: true,
    e10: 1.459,
  );

  final cacheKey = CacheKey.stationSearch(
    testParams.lat,
    testParams.lng,
    testParams.radiusKm,
    testParams.fuelType.apiValue,
  );

  final freshApiResult = ServiceResult<List<Station>>(
    data: [testStation],
    source: ServiceSource.tankerkoenigApi,
    fetchedAt: DateTime.now(),
  );

  setUpAll(() {
    registerFallbackValue(FakeSearchParams());
    registerFallbackValue(ServiceSource.tankerkoenigApi);
    registerFallbackValue(const Duration(minutes: 5));
  });

  setUp(() {
    mockPrimary = MockStationService();
    mockCache = MockCacheManager();
    chain = StationServiceChain(mockPrimary, mockCache);
  });

  group('StationServiceChain.searchStations', () {
    test('returns fresh cache without calling API', () async {
      final freshEntry = CacheEntry(
        payload: {
          'stations': [testStation.toJson()],
        },
        storedAt: DateTime.now(),
        originalSource: ServiceSource.tankerkoenigApi,
        ttl: CacheTtl.stationSearch,
      );

      when(() => mockCache.getFresh(cacheKey)).thenReturn(freshEntry);

      final result = await chain.searchStations(testParams);

      expect(result.data.length, 1);
      expect(result.data.first.id, 'abc-123');
      expect(result.source, ServiceSource.tankerkoenigApi);
      expect(result.isStale, false);
      verifyNever(() => mockPrimary.searchStations(any()));
    });

    test('calls API when cache miss, caches result', () async {
      when(() => mockCache.getFresh(cacheKey)).thenReturn(null);
      when(() => mockPrimary.searchStations(any()))
          .thenAnswer((_) async => freshApiResult);
      when(() => mockCache.put(
            any(),
            any(),
            ttl: any(named: 'ttl'),
            source: any(named: 'source'),
          )).thenAnswer((_) async {});

      final result = await chain.searchStations(testParams);

      expect(result.data.length, 1);
      expect(result.source, ServiceSource.tankerkoenigApi);
      verify(() => mockPrimary.searchStations(any())).called(1);
      verify(() => mockCache.put(
            cacheKey,
            any(),
            ttl: CacheTtl.stationSearch,
            source: ServiceSource.tankerkoenigApi,
          )).called(1);
    });

    test('falls back to stale cache on API error', () async {
      final staleEntry = CacheEntry(
        payload: {
          'stations': [testStation.toJson()],
        },
        storedAt: DateTime.now().subtract(const Duration(hours: 1)),
        originalSource: ServiceSource.tankerkoenigApi,
        ttl: CacheTtl.stationSearch,
      );

      when(() => mockCache.getFresh(cacheKey)).thenReturn(null);
      when(() => mockPrimary.searchStations(any()))
          .thenThrow(const ApiException(message: 'server down'));
      when(() => mockCache.get(cacheKey)).thenReturn(staleEntry);

      final result = await chain.searchStations(testParams);

      expect(result.data.length, 1);
      expect(result.data.first.id, 'abc-123');
      expect(result.source, ServiceSource.cache);
      expect(result.isStale, true);
      expect(result.errors, isNotEmpty);
      expect(result.errors.first.source, ServiceSource.tankerkoenigApi);
    });

    test('throws ServiceChainExhaustedException when all fail', () async {
      when(() => mockCache.getFresh(cacheKey)).thenReturn(null);
      when(() => mockPrimary.searchStations(any()))
          .thenThrow(const ApiException(message: 'server down'));
      when(() => mockCache.get(cacheKey)).thenReturn(null);

      expect(
        () => chain.searchStations(testParams),
        throwsA(isA<ServiceChainExhaustedException>()),
      );
    });

    test('in-flight deduplication: two concurrent calls result in one API call',
        () async {
      when(() => mockCache.getFresh(cacheKey)).thenReturn(null);
      when(() => mockPrimary.searchStations(any()))
          .thenAnswer((_) async => freshApiResult);
      when(() => mockCache.put(
            any(),
            any(),
            ttl: any(named: 'ttl'),
            source: any(named: 'source'),
          )).thenAnswer((_) async {});

      // Fire two concurrent searches for the same params
      final futures = [
        chain.searchStations(testParams),
        chain.searchStations(testParams),
      ];
      final results = await Future.wait(futures);

      expect(results[0].data.length, 1);
      expect(results[1].data.length, 1);
      // The primary API should only have been called once due to coalescing
      verify(() => mockPrimary.searchStations(any())).called(1);
    });
  });
}
