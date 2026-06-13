// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/station_services/uk/uk_fuel_finder_auth.dart';

/// #3190 — the statutory Fuel Finder API is fronted by OAuth 2.0 client
/// credentials. These pin the token flow against a mock transport (no live
/// endpoint): the POST shape (RFC 6749 §4.4), caching until expiry, expiry
/// re-fetch, [UkFuelFinderAuth.invalidate] re-fetch, and the malformed-response
/// guards.

/// Captures every request and serves a programmable queue of JSON bodies.
class _CapturingAdapter implements HttpClientAdapter {
  _CapturingAdapter(this.bodies);

  /// One canned (statusCode, jsonBody) per request, consumed in order; the
  /// last entry repeats once the queue is drained.
  final List<(int, Map<String, dynamic>)> bodies;

  final List<RequestOptions> requests = [];
  final List<String> requestBodies = [];
  int _i = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (requestStream != null) {
      final chunks = await requestStream.toList();
      requestBodies.add(utf8.decode(chunks.expand((c) => c).toList()));
    } else {
      requestBodies.add('');
    }
    final entry = bodies[_i < bodies.length ? _i : bodies.length - 1];
    _i++;
    return ResponseBody.fromString(
      jsonEncode(entry.$2),
      entry.$1,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio _dio(_CapturingAdapter adapter) {
  final dio = Dio();
  dio.httpClientAdapter = adapter;
  return dio;
}

void main() {
  const tokenUrl = 'https://developer.fuel-finder.service.gov.uk/oauth/token';

  group('UkFuelFinderAuth — client-credentials token flow (#3190)', () {
    test('POSTs grant_type=client_credentials with the client id + secret', () async {
      final adapter = _CapturingAdapter([
        (200, {'access_token': 'tok-1', 'token_type': 'Bearer', 'expires_in': 3600}),
      ]);
      final auth = UkFuelFinderAuth(
        dio: _dio(adapter),
        tokenUrl: tokenUrl,
        clientId: 'client-abc',
        clientSecret: 'secret-xyz',
        scope: 'fuel-prices:read',
      );

      final token = await auth.accessToken();

      expect(token, 'tok-1');
      expect(adapter.requests.single.path, tokenUrl);
      expect(adapter.requests.single.method, 'POST');
      final body = adapter.requestBodies.single;
      expect(body, contains('grant_type=client_credentials'));
      expect(body, contains('client_id=client-abc'));
      expect(body, contains('client_secret=secret-xyz'));
      expect(body, contains('scope=fuel-prices'));
    });

    test('caches the token — a second call within expiry does NOT re-POST',
        () async {
      var clock = DateTime(2026, 6, 13, 12);
      final adapter = _CapturingAdapter([
        (200, {'access_token': 'tok-1', 'expires_in': 3600}),
      ]);
      final auth = UkFuelFinderAuth(
        dio: _dio(adapter),
        tokenUrl: tokenUrl,
        clientId: 'c',
        clientSecret: 's',
        now: () => clock,
      );

      expect(await auth.accessToken(), 'tok-1');
      clock = clock.add(const Duration(minutes: 10)); // still well within 1h
      expect(await auth.accessToken(), 'tok-1');
      expect(adapter.requests.length, 1, reason: 'second call served from cache');
    });

    test('re-fetches once the cached token is within the refresh margin of '
        'expiry', () async {
      var clock = DateTime(2026, 6, 13, 12);
      final adapter = _CapturingAdapter([
        (200, {'access_token': 'tok-1', 'expires_in': 60}),
        (200, {'access_token': 'tok-2', 'expires_in': 60}),
      ]);
      final auth = UkFuelFinderAuth(
        dio: _dio(adapter),
        tokenUrl: tokenUrl,
        clientId: 'c',
        clientSecret: 's',
        now: () => clock,
      );

      expect(await auth.accessToken(), 'tok-1');
      // 40s in: 60s token, 30s margin → effective expiry at 30s, so this is stale.
      clock = clock.add(const Duration(seconds: 40));
      expect(await auth.accessToken(), 'tok-2');
      expect(adapter.requests.length, 2);
    });

    test('invalidate() forces a re-fetch on the next call', () async {
      final adapter = _CapturingAdapter([
        (200, {'access_token': 'tok-1', 'expires_in': 3600}),
        (200, {'access_token': 'tok-2', 'expires_in': 3600}),
      ]);
      final auth = UkFuelFinderAuth(
        dio: _dio(adapter),
        tokenUrl: tokenUrl,
        clientId: 'c',
        clientSecret: 's',
      );

      expect(await auth.accessToken(), 'tok-1');
      auth.invalidate();
      expect(await auth.accessToken(), 'tok-2');
      expect(adapter.requests.length, 2);
    });

    test('throws when the response carries no access_token', () async {
      final adapter = _CapturingAdapter([
        (200, {'token_type': 'Bearer', 'expires_in': 3600}),
      ]);
      final auth = UkFuelFinderAuth(
        dio: _dio(adapter),
        tokenUrl: tokenUrl,
        clientId: 'c',
        clientSecret: 's',
      );

      expect(() => auth.accessToken(), throwsA(isA<DioException>()));
    });
  });
}
