// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

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

/// #3743 (S-fix) — the chain's implementor-throw guard.
///
/// The [StationService] contract is dual by history: implementations
/// return [ServiceResult] or throw (ideally [ApiException] — but a
/// decode bug on drifted JSON throws a raw `Error` like [TypeError] /
/// [StateError]). The polled chain's catch used to be `on Exception`,
/// so an `Error` sailed straight out of [StationServiceChain] as a raw
/// crash instead of entering the errors → stale-cache →
/// [ServiceChainExhaustedException] ladder.
///
/// These tests inject a THROWING primary (both an `Error` and an
/// [ApiException]) and pin the guarded contract:
///   1. with no cache, the ONLY surfaced exception is
///      [ServiceChainExhaustedException], carrying the fault;
///   2. with a stale entry, the stale result is served and the fault
///      rides along on `result.errors` — nothing is thrown at all.
class _ThrowingService implements StationService {
  _ThrowingService(this.stations);

  final List<Station> stations;

  /// When non-null, thrown instead of returning (any object — the
  /// point of the guard is that `Error`s are absorbed too).
  Object? failure;

  @override
  Future<ServiceResult<List<Station>>> searchStations(
    SearchParams params, {
    CancelToken? cancelToken,
  }) async {
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

class _MemoryCache implements CacheStrategy {
  final Map<String, CacheEntry> _store = {};
  bool freshEnabled = true;

  @override
  Future<void> put(
    String key,
    Map<String, dynamic> data, {
    required Duration ttl,
    required ServiceSource source,
  }) async {
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

  late _ThrowingService service;
  late _MemoryCache cache;
  late StationServiceChain chain;

  setUp(() {
    StationServiceChain.transientRetryDelay = const Duration(milliseconds: 1);
    service = _ThrowingService([_station('a')]);
    cache = _MemoryCache();
    chain = StationServiceChain(service, cache, countryCode: 'FR');
  });

  tearDown(() {
    StationServiceChain.transientRetryDelay =
        const Duration(milliseconds: 500);
  });

  test('a thrown Error (not Exception) with no cache surfaces ONLY as '
      'ServiceChainExhaustedException carrying the fault', () async {
    service.failure = StateError('decode drift');

    await expectLater(
      chain.searchStations(_params()),
      throwsA(isA<ServiceChainExhaustedException>().having(
        (e) => e.errors.single.message,
        'captured fault',
        contains('decode drift'),
      )),
    );
  });

  test('a thrown Error with a stale entry in hand falls back to stale '
      '(nothing thrown, fault recorded on the result)', () async {
    // Seed through the chain itself so the payload uses the real codec.
    await chain.searchStations(_params());
    cache.freshEnabled = false; // entry now visible to the stale tier only
    service.failure = TypeError();

    final result = await chain.searchStations(_params());

    expect(result.isStale, isTrue);
    expect(result.data.single.id, 'a');
    expect(result.errors, isNotEmpty,
        reason: 'the absorbed implementor throw must ride along');
  });

  test('a thrown ApiException keeps its typed classification on the '
      'exhausted error', () async {
    service.failure = const ApiException(message: 'boom', statusCode: 503);

    await expectLater(
      chain.searchStations(_params()),
      throwsA(isA<ServiceChainExhaustedException>().having(
        (e) => e.errors.single.statusCode,
        'statusCode',
        503,
      )),
    );
  });
}
