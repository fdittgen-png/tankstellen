// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/cache/cache_manager.dart';
import 'package:tankstellen/core/error/exceptions.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/services/station_service.dart';
import 'package:tankstellen/core/services/station_service_chain.dart';
import 'package:tankstellen/features/search/data/models/search_params.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

import '../../helpers/silence_error_logger.dart';

/// Fake upstream that hands the caller a scripted sequence of outcomes —
/// throw on the first N calls, then return [stations]. Used to verify
/// that the chain retries transient errors exactly once and recovers
/// when the retry succeeds (#1954, #1955).
class _ScriptedService implements StationService {
  _ScriptedService({
    required this.script,
    this.stations = const [],
  });

  /// Each entry is either an [Object] (thrown on that call) or `null`
  /// (succeed and return [stations]). Consumed front-to-back.
  final List<Object?> script;
  final List<Station> stations;

  int callCount = 0;

  @override
  Future<ServiceResult<List<Station>>> searchStations(
    SearchParams params, {
    CancelToken? cancelToken,
  }) async {
    final i = callCount++;
    final step = i < script.length ? script[i] : null;
    if (step != null) {
      throw step;
    }
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

/// Trivial in-memory [CacheStrategy] — every key is a miss until [put]
/// stores something. The chain's stale-cache fallback never fires in
/// these tests because we only assert the retry / no-retry semantics
/// against a cold cache, which is the worst case the user reports the
/// "ServiceChainExhaustedException" snackbar from.
class _MemCache implements CacheStrategy {
  final Map<String, CacheEntry> _store = {};

  @override
  Future<void> put(
    String key,
    Map<String, dynamic> data, {
    required Duration ttl,
    required ServiceSource source,
  }) async {
    _store[key] = CacheEntry(
      payload: data,
      storedAt: DateTime.now(),
      originalSource: source,
      ttl: ttl,
    );
  }

  @override
  CacheEntry? get(String key) => _store[key];

  @override
  CacheEntry? getFresh(String key) => _store[key];
}

SearchParams _params() => const SearchParams(
      lat: 48.85,
      lng: 2.35,
      radiusKm: 5,
      fuelType: FuelType.e5,
    );

void main() {
  silenceErrorLoggerSpool();
  // Pin the retry delay near-zero so the test runs in milliseconds.
  // We're verifying the retry happens, not the wall-clock spacing.
  setUp(() {
    StationServiceChain.transientRetryDelay =
        const Duration(milliseconds: 1);
  });

  tearDown(() {
    StationServiceChain.transientRetryDelay =
        const Duration(milliseconds: 500);
  });

  group('StationServiceChain transient-error retry (#1954, #1955)', () {
    test('5xx on the first attempt → retries once and returns the '
        'second attempt\'s data', () async {
      final fake = _ScriptedService(
        script: [
          const ApiException(message: 'badResponse: 503', statusCode: 503),
          null,
        ],
        stations: const [
          Station(
            id: 's1',
            name: 'Test',
            brand: 'Brand',
            street: 'Rue X',
            postCode: '75001',
            place: 'Paris',
            lat: 48.85,
            lng: 2.35,
            isOpen: true,
          ),
        ],
      );
      final chain = StationServiceChain(fake, _MemCache(), countryCode: 'es');

      final result = await chain.searchStations(_params());

      expect(fake.callCount, 2,
          reason: 'one retry on transient 503 must hit the upstream twice');
      expect(result.data, hasLength(1));
    });

    test('connectionTimeout on the first attempt → retries once and '
        'recovers', () async {
      final fake = _ScriptedService(
        script: [
          const ApiException(
            message: 'connectionTimeout: took longer than 20s (path: /x)',
          ),
          null,
        ],
        stations: const [
          Station(
            id: 's2',
            name: 'AR test',
            brand: 'B',
            street: '',
            postCode: '',
            place: '',
            lat: 0,
            lng: 0,
            isOpen: true,
          ),
        ],
      );
      final chain = StationServiceChain(fake, _MemCache(), countryCode: 'ar');

      await chain.searchStations(_params());

      expect(fake.callCount, 2,
          reason: 'a Dio connectionTimeout must be classed as transient');
    });

    test('two consecutive transients → no third attempt, the chain '
        'gives up and throws ServiceChainExhaustedException',
        () async {
      final fake = _ScriptedService(
        script: [
          const ApiException(message: 'badResponse: 503', statusCode: 503),
          const ApiException(message: 'badResponse: 503', statusCode: 503),
        ],
      );
      final chain = StationServiceChain(fake, _MemCache(), countryCode: 'es');

      await expectLater(
        chain.searchStations(_params()),
        throwsA(isA<ServiceChainExhaustedException>()),
      );
      expect(fake.callCount, 2,
          reason: 'one retry only — the chain must not pile on a third '
              'attempt and stretch the user-visible latency');
    });

    test('non-transient errors (4xx, parse) skip the retry — exactly '
        'one upstream call before the chain gives up', () async {
      final fake = _ScriptedService(
        script: [
          const ApiException(message: 'badResponse: 404', statusCode: 404),
        ],
      );
      final chain = StationServiceChain(fake, _MemCache(), countryCode: 'es');

      await expectLater(
        chain.searchStations(_params()),
        throwsA(isA<ServiceChainExhaustedException>()),
      );
      expect(fake.callCount, 1,
          reason: 'a 404 is not transient — retrying it just wastes '
              'a request and adds latency');
    });

    test('receiveTimeout and sendTimeout messages are also classed '
        'as transient', () async {
      for (final msg in const [
        'receiveTimeout: server stalled (path: /foo)',
        'sendTimeout: write stalled (path: /foo)',
        'connectionError: socket reset (path: /foo)',
      ]) {
        final fake = _ScriptedService(
          script: [ApiException(message: msg), null],
        );
        final chain =
            StationServiceChain(fake, _MemCache(), countryCode: 'es');
        await chain.searchStations(_params());
        expect(fake.callCount, 2,
            reason: 'Dio "$msg" must be treated as a recoverable '
                'transient blip and trigger the one-shot retry');
      }
    });
  });
}
