// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/cache/cache_manager.dart';
import 'package:tankstellen/core/error/exceptions.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/services/station_service_chain.dart';
import 'package:tankstellen/features/station_services/france/prix_carburants_station_service.dart';

import '../../../helpers/silence_error_logger.dart';

/// #2763 — drive the REAL [StationServiceChain] wrapping the REAL
/// [PrixCarburantsStationService] (no request-echoing fake, per the
/// false-green-fakes lesson). Only the HTTP transport is stubbed.
///
/// Before the fix, an empty feed slice on `getStationDetail` threw a PLAIN
/// `Exception('Station … not found')`. The chain's `_callWithTransientRetry`
/// only catches `on ApiException`, so the plain exception bypassed transient
/// classification entirely and the whole detail screen re-ran the chain 8×
/// (one ERROR trace per provider / retry-tap). The fix throws a typed
/// `ApiException(kind: network)` so the chain does exactly ONE retry, then
/// surfaces a typed (not `unknown`) failure — and a genuine 404 stays terminal.

/// A Dio adapter that counts every fetch and returns a scripted response /
/// status for each call.
class _CountingAdapter implements HttpClientAdapter {
  _CountingAdapter({required this.body, required this.statusCode});

  /// JSON body to return (used for 2xx responses).
  final Object body;
  final int statusCode;
  int fetchCount = 0;

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<List<int>>? requestStream, Future<void>? cancelFuture) async {
    fetchCount++;
    return ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _MemCache implements CacheStrategy {
  final _store = <String, CacheEntry>{};
  @override
  Future<void> put(String key, Map<String, dynamic> data,
      {required Duration ttl, required ServiceSource source}) async {
    _store[key] = CacheEntry(
        payload: data, storedAt: DateTime.now(), originalSource: source, ttl: ttl);
  }

  @override
  CacheEntry? get(String key) => _store[key];
  @override
  CacheEntry? getFresh(String key) => _store[key];
}

({PrixCarburantsStationService service, _CountingAdapter adapter}) _wire({
  required Object body,
  required int statusCode,
}) {
  final adapter = _CountingAdapter(body: body, statusCode: statusCode);
  // Default validateStatus (only 2xx is "success"): a 404 therefore surfaces
  // as a Dio `badResponse` DioException — exactly as production sees it — so
  // the chain classifies it as a TERMINAL (non-ApiException) failure and does
  // not retry it, vs the empty-200-slice that becomes a typed transient.
  final dio = Dio(BaseOptions(baseUrl: 'https://data.economie.gouv.fr'));
  dio.httpClientAdapter = adapter;
  return (
    service: PrixCarburantsStationService(dio: dio, enricher: null),
    adapter: adapter,
  );
}

void main() {
  silenceErrorLoggerSpool();

  setUp(() {
    StationServiceChain.transientRetryDelay = const Duration(milliseconds: 1);
  });
  tearDown(() {
    StationServiceChain.transientRetryDelay = const Duration(milliseconds: 500);
  });

  group('PrixCarburants empty feed slice → typed transient (#2763)', () {
    test('an empty feed slice is retried EXACTLY ONCE — not 8× — and the '
        'surfaced failure is typed network, not unknown', () async {
      final wired = _wire(body: {'results': <dynamic>[]}, statusCode: 200);
      final chain = StationServiceChain(
        wired.service,
        _MemCache(),
        errorSource: ServiceSource.prixCarburantsApi,
      );

      try {
        await chain.getStationDetail('fr-11100013');
        fail('expected ServiceChainExhaustedException');
      } on ServiceChainExhaustedException catch (e) {
        final err = e.errors.whereType<ServiceError>().first;
        expect(err.kind, FailureKind.network,
            reason: 'the empty-slice transient must carry FailureKind.network, '
                'not unknown — that is what lets the chain class it as '
                'transient instead of a hard failure');
      }

      expect(wired.adapter.fetchCount, 2,
          reason: 'ONE transient retry on the empty slice — never the 8× '
              'storm the plain Exception caused');
    });

    test('a station that exists resolves on the first attempt (no retry)',
        () async {
      final wired = _wire(
        body: {
          'results': [
            {
              'id': '11100013',
              'adresse': '1 Rue du Test',
              'ville': 'Narbonne',
              'cp': '11100',
              'geom': {'lat': 43.18, 'lon': 3.0},
            }
          ],
        },
        statusCode: 200,
      );
      final chain = StationServiceChain(
        wired.service,
        _MemCache(),
        errorSource: ServiceSource.prixCarburantsApi,
      );

      final result = await chain.getStationDetail('fr-11100013');
      expect(result.data.station.id, 'fr-11100013');
      expect(wired.adapter.fetchCount, 1,
          reason: 'a present station must not be retried');
    });

    test('a genuine 404 is TERMINAL — not retried (transient/404 split)',
        () async {
      // A real "id not in the catalog" 404. The Dio badResponse is NOT an
      // ApiException, so the chain does not retry it — exactly one upstream
      // hit before the chain gives up (vs the empty slice's one retry).
      final wired = _wire(body: {'error': 'not found'}, statusCode: 404);
      final chain = StationServiceChain(
        wired.service,
        _MemCache(),
        errorSource: ServiceSource.prixCarburantsApi,
      );

      await expectLater(
        chain.getStationDetail('fr-00000000'),
        throwsA(isA<ServiceChainExhaustedException>()),
      );
      expect(wired.adapter.fetchCount, 1,
          reason: 'a real 404 is terminal — retrying it just wastes a '
              'request and adds latency');
    });
  });
}
