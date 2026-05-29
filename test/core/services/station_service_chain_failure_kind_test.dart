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
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';

import '../../helpers/silence_error_logger.dart';

/// Throws a scripted sequence, then succeeds.
class _ScriptedService implements StationService {
  _ScriptedService({required this.script, this.stations = const []});
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
    if (step != null) throw step;
    return ServiceResult(
      data: stations,
      source: ServiceSource.tankerkoenigApi,
      fetchedAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  @override
  Future<ServiceResult<StationDetail>> getStationDetail(String id) =>
      throw UnimplementedError();

  @override
  Future<ServiceResult<Map<String, StationPrices>>> getPrices(
          List<String> ids) =>
      throw UnimplementedError();
}

class _MemCache implements CacheStrategy {
  final _store = <String, CacheEntry>{};
  @override
  Future<void> put(String key, Map<String, dynamic> data,
      {required Duration ttl, required ServiceSource source}) async {
    _store[key] = CacheEntry(
        payload: data,
        storedAt: DateTime.now(),
        originalSource: source,
        ttl: ttl);
  }

  @override
  CacheEntry? get(String key) => _store[key];
  @override
  CacheEntry? getFresh(String key) => _store[key];
}

SearchParams _params() =>
    const SearchParams(lat: 48.85, lng: 2.35, radiusKm: 5, fuelType: FuelType.e5);

const _station = Station(
  id: 's1',
  name: 'T',
  brand: 'B',
  street: '',
  postCode: '',
  place: '',
  lat: 48.85,
  lng: 2.35,
  isOpen: true,
);

void main() {
  silenceErrorLoggerSpool();
  setUp(() {
    StationServiceChain.transientRetryDelay = const Duration(milliseconds: 1);
  });
  tearDown(() {
    StationServiceChain.transientRetryDelay = const Duration(milliseconds: 500);
  });

  group('StationServiceChain routes transience by FailureKind (#2255)', () {
    for (final kind in const [
      FailureKind.network,
      FailureKind.timeout,
      FailureKind.rateLimited,
    ]) {
      test('$kind is transient → one retry, recovers on the 2nd attempt',
          () async {
        final fake = _ScriptedService(
          script: [ApiException(message: 'x', kind: kind), null],
          stations: const [_station],
        );
        final chain = StationServiceChain(fake, _MemCache());
        final result = await chain.searchStations(_params());
        expect(fake.callCount, 2, reason: '$kind must trigger the retry');
        expect(result.data, hasLength(1));
      });
    }

    for (final kind in const [
      FailureKind.auth,
      FailureKind.notFound,
      FailureKind.parse,
      FailureKind.unsupported,
      FailureKind.unknown,
    ]) {
      test('$kind is terminal → no retry, chain gives up', () async {
        final fake = _ScriptedService(
          script: [ApiException(message: 'x', kind: kind)],
        );
        final chain = StationServiceChain(fake, _MemCache());
        await expectLater(
          chain.searchStations(_params()),
          throwsA(isA<ServiceChainExhaustedException>()),
        );
        expect(fake.callCount, 1, reason: '$kind must not be retried');
      });
    }

    test('the accumulated ServiceError carries the typed kind + retryAfter',
        () async {
      final fake = _ScriptedService(
        script: [
          const ApiException(
            message: 'rate limited',
            statusCode: 429,
            kind: FailureKind.rateLimited,
            retryAfter: Duration(seconds: 4),
          ),
          const ApiException(
            message: 'rate limited',
            statusCode: 429,
            kind: FailureKind.rateLimited,
            retryAfter: Duration(seconds: 4),
          ),
        ],
      );
      final chain = StationServiceChain(fake, _MemCache());
      try {
        await chain.searchStations(_params());
        fail('expected ServiceChainExhaustedException');
      } on ServiceChainExhaustedException catch (e) {
        final err = e.errors.whereType<ServiceError>().first;
        expect(err.kind, FailureKind.rateLimited);
        expect(err.statusCode, 429);
        expect(err.retryAfter, const Duration(seconds: 4));
      }
    });
  });

  group('legacy ApiException (no kind) is still classified (regression)', () {
    test('5xx status with kind=unknown is still transient', () async {
      final fake = _ScriptedService(
        script: [
          const ApiException(message: 'badResponse: 503', statusCode: 503),
          null,
        ],
        stations: const [_station],
      );
      final chain = StationServiceChain(fake, _MemCache());
      await chain.searchStations(_params());
      expect(fake.callCount, 2);
    });

    test('connectionTimeout message with kind=unknown is still transient',
        () async {
      final fake = _ScriptedService(
        script: [
          const ApiException(message: 'connectionTimeout: 20s (path: /x)'),
          null,
        ],
        stations: const [_station],
      );
      final chain = StationServiceChain(fake, _MemCache());
      await chain.searchStations(_params());
      expect(fake.callCount, 2);
    });

    test('404 status with kind=unknown is still terminal', () async {
      final fake = _ScriptedService(
        script: [
          const ApiException(message: 'badResponse: 404', statusCode: 404),
        ],
      );
      final chain = StationServiceChain(fake, _MemCache());
      await expectLater(
        chain.searchStations(_params()),
        throwsA(isA<ServiceChainExhaustedException>()),
      );
      expect(fake.callCount, 1);
    });
  });
}
