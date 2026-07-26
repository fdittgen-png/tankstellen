// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3618 — the SWR peek must be a faithful, network-free TWIN of the
// chain's search read: same key construction, same codec, same #2926
// hard fuel filter. The round-trip test seeds the cache THROUGH a real
// chain search — if the peek's key construction ever drifts from the
// chain's, it stops finding what the chain just wrote and this fails.
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/cache/cache_manager.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/search_params.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/services/station_search_peek.dart';
import 'package:tankstellen/core/services/station_service.dart';
import 'package:tankstellen/core/services/station_service_chain.dart';

import '../../helpers/silence_error_logger.dart';

class MockStationService extends Mock implements StationService {}

class FakeSearchParams extends Fake implements SearchParams {}

/// Real envelope semantics over a plain map — enough for the chain to
/// write and the peek to read the SAME entry.
class _MemoryCache implements CacheStrategy {
  final map = <String, CacheEntry>{};

  @override
  Future<void> put(
    String key,
    Map<String, dynamic> data, {
    required Duration ttl,
    required ServiceSource source,
  }) async {
    map[key] = CacheEntry(
      payload: data,
      storedAt: DateTime.now(),
      originalSource: source,
      ttl: ttl,
    );
  }

  @override
  CacheEntry? get(String key) => map[key];

  @override
  CacheEntry? getFresh(String key) {
    final entry = map[key];
    return entry == null || entry.isExpired ? null : entry;
  }
}

void main() {
  silenceErrorLoggerSpool();

  const params = SearchParams(
    lat: 52.52,
    lng: 13.41,
    radiusKm: 10,
    fuelType: FuelType.e10,
  );

  const e10Station = Station(
    id: 'e10-1',
    name: 'E10 Station',
    brand: 'TEST',
    street: 'Teststr.',
    postCode: '10115',
    place: 'Berlin',
    lat: 52.52,
    lng: 13.41,
    isOpen: true,
    e10: 1.459,
  );
  const dieselOnlyStation = Station(
    id: 'diesel-1',
    name: 'Diesel Only',
    brand: 'TEST',
    street: 'Teststr.',
    postCode: '10115',
    place: 'Berlin',
    lat: 52.53,
    lng: 13.42,
    isOpen: true,
    diesel: 1.659,
  );

  setUpAll(() => registerFallbackValue(FakeSearchParams()));

  test(
      'ROUND-TRIP: what a real chain search cached, the peek finds — '
      'same key, same codec, same fuel filter', () async {
    final cache = _MemoryCache();
    final primary = MockStationService();
    when(() => primary.searchStations(any(),
        cancelToken: any(named: 'cancelToken'))).thenAnswer(
      (_) async => ServiceResult(
        data: const [e10Station, dieselOnlyStation],
        source: ServiceSource.tankerkoenigApi,
        fetchedAt: DateTime.now(),
      ),
    );
    final chain = StationServiceChain(primary, cache);

    final chainResult = await chain.searchStations(params);

    final peeked = peekCachedStationSearch(
      cache: cache,
      countryCode: '',
      params: params,
    );
    expect(peeked, isNotNull,
        reason: 'the peek must construct the exact key the chain wrote');
    expect(
      peeked!.data.map((s) => s.id),
      chainResult.data.map((s) => s.id),
      reason: 'peek output must equal the chain output — the full '
          'cached set re-passed through the #2926 fuel filter',
    );
    expect(peeked.data.map((s) => s.id), ['e10-1'],
        reason: 'the diesel-only station must not survive an e10 search');
    expect(peeked.isStale, isFalse,
        reason: 'a still-fresh entry peeks as not stale');
    expect(peeked.source, ServiceSource.cache);
  });

  test('an EXPIRED entry still peeks — flagged stale', () async {
    final cache = _MemoryCache();
    final primary = MockStationService();
    when(() => primary.searchStations(any(),
        cancelToken: any(named: 'cancelToken'))).thenAnswer(
      (_) async => ServiceResult(
        data: const [e10Station],
        source: ServiceSource.tankerkoenigApi,
        fetchedAt: DateTime.now(),
      ),
    );
    await StationServiceChain(primary, cache).searchStations(params);
    // Age the entry past its TTL.
    final key = cache.map.keys.single;
    final old = cache.map[key]!;
    cache.map[key] = CacheEntry(
      payload: old.payload,
      storedAt: DateTime.now().subtract(const Duration(hours: 7)),
      originalSource: old.originalSource,
      ttl: old.ttl,
    );

    final peeked = peekCachedStationSearch(
      cache: cache,
      countryCode: '',
      params: params,
    );
    expect(peeked, isNotNull,
        reason: 'ANY-age peek — hours-stale prices are the SWR premise');
    expect(peeked!.isStale, isTrue);
  });

  test('no cached entry → null (the caller keeps the shimmer)', () {
    expect(
      peekCachedStationSearch(
        cache: _MemoryCache(),
        countryCode: '',
        params: params,
      ),
      isNull,
    );
  });

  test('a BULK-file country → null: its searches local-filter the '
      'persisted dataset and never write per-key entries', () {
    final cache = _MemoryCache();
    expect(
      peekCachedStationSearch(
        cache: cache,
        countryCode: 'ES',
        params: params,
      ),
      isNull,
    );
  });
}
