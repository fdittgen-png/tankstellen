// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/cache/cache_manager.dart';
import 'package:tankstellen/core/error/exceptions.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/services/station_service.dart';
import 'package:tankstellen/core/services/station_service_chain.dart';
import 'package:tankstellen/core/domain/search_params.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/station.dart';

import '../../helpers/silence_error_logger.dart';

class MockStationService extends Mock implements StationService {}

class MockCacheManager extends Mock implements CacheManager {}

class FakeSearchParams extends Fake implements SearchParams {}

void main() {
  silenceErrorLoggerSpool();
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

  group('searchStations hard-fuel-filter (#2926)', () {
    // Esso sells no E85 (e85 null); Total does (0.84). The maintainer's chosen
    // semantic: a SPECIFIC fuel must hard-filter to stations that sell it, so
    // search and the radar return the same set. RED before #2926 (the chain
    // returned BOTH, leaving Esso to render a "--" E85 row).
    const esso = Station(
      id: 'esso',
      name: 'Esso',
      brand: 'Esso',
      street: '1 rue A',
      postCode: '34120',
      place: 'Pézenas',
      lat: 43.46,
      lng: 3.42,
      isOpen: true,
      e10: 1.75,
      diesel: 1.60,
    );
    const total = Station(
      id: 'total',
      name: 'Total',
      brand: 'Total',
      street: '2 rue B',
      postCode: '34120',
      place: 'Pézenas',
      lat: 43.47,
      lng: 3.43,
      isOpen: true,
      e10: 1.77,
      diesel: 1.62,
      e85: 0.84,
    );

    const e85Params = SearchParams(
      lat: 43.46,
      lng: 3.42,
      radiusKm: 10,
      fuelType: FuelType.e85,
    );
    final e85Key = CacheKey.stationSearch(
      e85Params.lat, e85Params.lng, e85Params.radiusKm,
      e85Params.fuelType.apiValue,
    );

    test('a specific fuel keeps ONLY stations that sell it', () async {
      when(() => mockCache.getFresh(e85Key)).thenReturn(null);
      when(() => mockPrimary.searchStations(any())).thenAnswer(
        (_) async => ServiceResult<List<Station>>(
          data: const [esso, total],
          source: ServiceSource.prixCarburantsApi,
          fetchedAt: DateTime.now(),
        ),
      );
      when(() => mockCache.put(any(), any(),
          ttl: any(named: 'ttl'),
          source: any(named: 'source'))).thenAnswer((_) async {});

      final result = await chain.searchStations(e85Params);

      expect(result.data.map((s) => s.id), ['total'],
          reason: 'Esso has no E85 → dropped; Total sells E85 → kept');
    });

    test('the CACHE stores the FULL set — the filter is at the return boundary',
        () async {
      when(() => mockCache.getFresh(e85Key)).thenReturn(null);
      when(() => mockPrimary.searchStations(any())).thenAnswer(
        (_) async => ServiceResult<List<Station>>(
          data: const [esso, total],
          source: ServiceSource.prixCarburantsApi,
          fetchedAt: DateTime.now(),
        ),
      );
      final captured = <Map<String, dynamic>>[];
      when(() => mockCache.put(any(), captureAny(),
          ttl: any(named: 'ttl'),
          source: any(named: 'source'))).thenAnswer((invocation) async {
        captured.add(
            invocation.positionalArguments[1] as Map<String, dynamic>);
      });

      await chain.searchStations(e85Params);

      // The persisted payload must carry BOTH stations (honest, fuel-agnostic
      // cache) even though the returned set is filtered to Total.
      final stored = captured.single['stations'] as List<dynamic>;
      expect(stored, hasLength(2),
          reason: 'cache keeps the full in-radius set, keyed per fuel');
    });

    test('FuelType.all returns every station (no filter, both directions)',
        () async {
      const allParams = SearchParams(
        lat: 43.46,
        lng: 3.42,
        radiusKm: 10,
        fuelType: FuelType.all,
      );
      final allKey = CacheKey.stationSearch(
        allParams.lat, allParams.lng, allParams.radiusKm,
        allParams.fuelType.apiValue,
      );
      when(() => mockCache.getFresh(allKey)).thenReturn(null);
      when(() => mockPrimary.searchStations(any())).thenAnswer(
        (_) async => ServiceResult<List<Station>>(
          data: const [esso, total],
          source: ServiceSource.prixCarburantsApi,
          fetchedAt: DateTime.now(),
        ),
      );
      when(() => mockCache.put(any(), any(),
          ttl: any(named: 'ttl'),
          source: any(named: 'source'))).thenAnswer((_) async {});

      final result = await chain.searchStations(allParams);

      expect(result.data.map((s) => s.id), ['esso', 'total'],
          reason: 'the all wildcard shows every station');
    });
  });
}
