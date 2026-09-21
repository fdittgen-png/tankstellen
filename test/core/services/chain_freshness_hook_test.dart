// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/cache/cache_manager.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/search_params.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/core/services/provider_capability.dart';
import 'package:tankstellen/core/services/provider_freshness_monitor.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/services/station_service.dart';
import 'package:tankstellen/core/services/station_service_chain.dart';
import 'package:tankstellen/core/time/app_clock.dart';

import '../../fakes/fake_storage_repository.dart';
import '../../helpers/silence_error_logger.dart';

/// #4171 — proves the freshness monitor is actually WIRED.
///
/// `provider_freshness_monitor_test.dart` drives the monitor directly and
/// passes whether or not anything ever calls it. That is the gap this
/// file closes: these cases go through a real [StationServiceChain], so a
/// hook that is missing, mis-guarded, or attached to the wrong branch
/// fails here rather than shipping inert.
///
/// The distinction the hook exists to make is upstream-vs-cache: a cached
/// answer says nothing about whether the provider is still publishing, so
/// it must record nothing.
void main() {
  silenceErrorLoggerSpool();

  // Mid-month Wednesday, per the AppClock seam's guidance.
  final now = DateTime(2026, 3, 11, 14, 30);

  /// 24-hour promise with per-row stamps — the AR / GR shape.
  const daily = ProviderCapability(
    stationIdentity: false,
    price: true,
    priceTimestamp: true,
    expectedFreshness: Duration(hours: 24),
    coverage: ProviderCoverage.national,
  );

  Station stationAged(Duration age) => Station(
        id: 'fr-s1',
        name: 'T',
        brand: 'B',
        street: '',
        postCode: '',
        place: '',
        lat: 48.85,
        lng: 2.35,
        isOpen: true,
        priceUpdatedAt: now.subtract(age),
      );

  SearchParams params() => const SearchParams(
      lat: 48.85, lng: 2.35, radiusKm: 5, fuelType: FuelType.all);

  /// The monitor's write is fire-and-forget so the network path is never
  /// slowed by storage; let the microtask land before reading it back.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  ({
    StationServiceChain chain,
    ProviderFreshnessMonitor monitor,
    _CountingService primary,
  }) build({required Duration age}) {
    final storage = FakeStorageRepository();
    final monitor = ProviderFreshnessMonitor(
      storage,
      clock: FixedClock(now),
      capabilityFor: (_) => daily,
    );
    final primary = _CountingService(stationAged(age), now);
    final chain = StationServiceChain(
      primary,
      _MemCache(now),
      countryCode: 'FR',
      freshness: monitor,
    );
    return (chain: chain, monitor: monitor, primary: primary);
  }

  test('a stale UPSTREAM response is recorded against the country', () async {
    // 4 days against a 24 h promise — past the x3 violation factor.
    final t = build(age: const Duration(days: 4));

    await t.chain.searchStations(params());
    await settle();

    expect(t.primary.calls, 1, reason: 'the upstream must actually be hit');
    expect(t.monitor.staleStreak('FR'), 1,
        reason: 'the hook is wired: a successful upstream response reaches '
            'the monitor');
  });

  test('a fresh UPSTREAM response leaves the streak at zero', () async {
    final t = build(age: const Duration(hours: 2));

    await t.chain.searchStations(params());
    await settle();

    expect(t.primary.calls, 1);
    expect(t.monitor.staleStreak('FR'), 0,
        reason: 'the monitor must judge the stamps, not merely count calls — '
            'otherwise this test would pass on a hook that records '
            'unconditionally');
  });

  test('a CACHE HIT records nothing — it says nothing about the provider',
      () async {
    final t = build(age: const Duration(days: 4));

    await t.chain.searchStations(params()); // upstream → records 1
    await settle();
    expect(t.monitor.staleStreak('FR'), 1);

    await t.chain.searchStations(params()); // served from cache
    await settle();

    expect(t.primary.calls, 1,
        reason: 'the second search must be served from cache');
    expect(t.monitor.staleStreak('FR'), 1,
        reason: 'a cached answer is not evidence about the upstream, so the '
            'streak must not move');
  });

  test('no monitor wired is harmless (legacy / unit-test call sites)',
      () async {
    final primary = _CountingService(stationAged(const Duration(days: 4)), now);
    final chain = StationServiceChain(primary, _MemCache(now), countryCode: 'FR');

    await chain.searchStations(params());
    await settle();

    expect(primary.calls, 1, reason: 'a null monitor must not break the chain');
  });
}

/// Primary that counts upstream hits, so a cache-served search is provable.
class _CountingService implements StationService {
  _CountingService(this.station, this.fetchedAt);

  final Station station;

  /// The pinned instant, not the wall clock: `wall_clock_test` holds
  /// `test/` to the same rule as `lib/`, and a time-sensitive test has no
  /// business reading the real clock anyway.
  final DateTime fetchedAt;
  int calls = 0;

  @override
  Future<ServiceResult<List<Station>>> searchStations(SearchParams params,
      {CancelToken? cancelToken}) async {
    calls++;
    return ServiceResult(
      data: [station],
      source: ServiceSource.tankerkoenigApi,
      fetchedAt: fetchedAt,
    );
  }

  @override
  Future<ServiceResult<StationDetail>> getStationDetail(String id) async =>
      throw UnimplementedError();

  @override
  Future<ServiceResult<Map<String, StationPrices>>> getPrices(
          List<String> ids) async =>
      throw UnimplementedError();
}

/// In-memory [CacheStrategy] — `getFresh` returns the stored entry, so a
/// repeated search is served from cache without touching the primary.
class _MemCache implements CacheStrategy {
  _MemCache(this.storedAt);

  final DateTime storedAt;
  final _store = <String, CacheEntry>{};

  @override
  Future<void> put(String key, Map<String, dynamic> data,
      {required Duration ttl, required ServiceSource source}) async {
    _store[key] = CacheEntry(
      payload: data,
      storedAt: storedAt,
      originalSource: source,
      ttl: ttl,
    );
  }

  @override
  CacheEntry? get(String key) => _store[key];

  @override
  CacheEntry? getFresh(String key) => _store[key];
}
