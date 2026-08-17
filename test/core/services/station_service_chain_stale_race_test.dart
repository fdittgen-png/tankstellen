// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/cache/cache_manager.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/error/exceptions.dart';
import 'package:tankstellen/core/domain/search_params.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/services/station_service.dart';
import 'package:tankstellen/core/services/station_service_chain.dart';

import '../../helpers/silence_error_logger.dart';

/// #3668 — the stale tier is a LATENCY fallback, not only a failure
/// fallback. When a servable stale entry exists, a fetch slower than
/// [StationServiceChain.stalePaintDeadline] must NOT hold the first
/// paint: the stale entry is served (`isStale: true`) and the fetch
/// finishes in the background, caching its result for the next read.
///
/// Field case this pins: FR legacy polling on weak 4G held the search
/// skeleton >10 s (worst case ~90 s) with yesterday's results sitting
/// in Hive the whole time.
///
/// No wall-clock reads here (wall-clock ratchet #3660): staleness is
/// driven by the fake cache's `freshEnabled` switch, not by entry age.
class _GatedService implements StationService {
  _GatedService(this.stations);

  final List<Station> stations;

  /// When non-null, [searchStations] parks on this until completed.
  Completer<void>? gate;

  /// When non-null, thrown instead of returning.
  Object? failure;

  int callCount = 0;

  @override
  Future<ServiceResult<List<Station>>> searchStations(
    SearchParams params, {
    CancelToken? cancelToken,
  }) async {
    callCount++;
    final g = gate;
    if (g != null) await g.future;
    final f = failure;
    if (f != null) throw f; // ignore: only_throw_errors
    return ServiceResult(
      data: stations,
      source: ServiceSource.tankerkoenigApi,
      fetchedAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  @override
  Future<ServiceResult<StationDetail>> getStationDetail(
    String id, {
    CancelToken? cancelToken,
  }) =>
      throw UnimplementedError();

  @override
  Future<ServiceResult<Map<String, StationPrices>>> getPrices(
    List<String> ids, {
    CancelToken? cancelToken,
  }) =>
      throw UnimplementedError();
}

/// In-memory cache whose FRESH tier can be switched off, so a stored
/// entry is visible only to the stale tier — exactly the state a
/// past-TTL startup finds on disk.
class _StaleCache implements CacheStrategy {
  final Map<String, CacheEntry> _store = {};
  bool freshEnabled = true;
  int putCount = 0;

  @override
  Future<void> put(
    String key,
    Map<String, dynamic> data, {
    required Duration ttl,
    required ServiceSource source,
  }) async {
    putCount++;
    _store[key] = CacheEntry(
      payload: data,
      storedAt: DateTime.fromMillisecondsSinceEpoch(0),
      originalSource: source,
      ttl: ttl,
    );
  }

  @override
  CacheEntry? get(String key) => _store[key];

  @override
  CacheEntry? getFresh(String key) => freshEnabled ? _store[key] : null;
}

SearchParams _params() => const SearchParams(
      lat: 48.85,
      lng: 2.35,
      radiusKm: 5,
      fuelType: FuelType.all,
    );

Station _station(String id) => Station(
      id: id,
      name: 'S$id',
      brand: 'B',
      street: '',
      place: '',
      postCode: '',
      lat: 48.85,
      lng: 2.35,
      dist: 0.1,
      isOpen: true,
    );

void main() {
  silenceErrorLoggerSpool();

  late _GatedService service;
  late _StaleCache cache;
  late StationServiceChain chain;

  setUp(() {
    StationServiceChain.stalePaintDeadline = const Duration(milliseconds: 80);
    StationServiceChain.transientRetryDelay = const Duration(milliseconds: 1);
    service = _GatedService([_station('fresh-1')]);
    cache = _StaleCache();
    chain = StationServiceChain(service, cache, countryCode: 'FR');
  });

  tearDown(() {
    StationServiceChain.stalePaintDeadline = const Duration(seconds: 2);
    StationServiceChain.transientRetryDelay =
        const Duration(milliseconds: 500);
  });

  /// Seed the cache through the chain itself so the stale payload uses
  /// the real codec, then flip the fresh tier off.
  Future<void> seedStale() async {
    final seeded = await chain.searchStations(_params());
    expect(seeded.isStale, isFalse);
    cache.freshEnabled = false;
  }

  group('stale-first paint deadline race (#3668)', () {
    test('a fetch slower than the deadline serves the stale entry — and '
        'the background fetch still lands in the cache', () async {
      await seedStale();
      final putsAfterSeed = cache.putCount;

      // Second search: fetch parks on the gate — slower than the 80 ms
      // deadline.
      service.gate = Completer<void>();
      final result = await chain.searchStations(_params());

      expect(result.isStale, isTrue,
          reason: 'the stale entry must be served at the deadline');
      expect(result.source, ServiceSource.cache);
      expect(result.data.map((s) => s.id), contains('fresh-1'));

      // Release the fetch: its result must still be cached so the NEXT
      // read is fresh.
      service.gate!.complete();
      await pumpEventQueue();
      expect(cache.putCount, greaterThan(putsAfterSeed),
          reason: 'the background fetch must cache its result');
    });

    test('a fetch faster than the deadline returns FRESH data', () async {
      await seedStale();
      final result = await chain.searchStations(_params());
      expect(result.isStale, isFalse);
      expect(result.source, ServiceSource.tankerkoenigApi);
    });

    test('with NO stale entry the chain waits out a slow fetch', () async {
      service.gate = Completer<void>();
      final pending = chain.searchStations(_params());
      var done = false;
      unawaited(pending.then((_) => done = true));

      // Well past the deadline: still waiting — nothing to serve instead.
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(done, isFalse,
          reason: 'with no fallback there is nothing to race against');

      service.gate!.complete();
      final result = await pending;
      expect(result.isStale, isFalse);
    });

    test('a fetch that FAILS fast falls through to stale with the error '
        'attached (pre-#3668 contract preserved)', () async {
      await seedStale();
      service.failure =
          const ApiException(message: 'boom', statusCode: 500);

      final result = await chain.searchStations(_params());
      expect(result.isStale, isTrue);
      expect(result.errors, isNotEmpty);
    });
  });
}
