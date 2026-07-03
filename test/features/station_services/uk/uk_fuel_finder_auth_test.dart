// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/station_services/uk/uk_fuel_finder_auth.dart';

/// #3190 — the statutory Fuel Finder API is fronted by OAuth 2.0 client
/// credentials. These pin the token flow against a mock transport (no live
/// endpoint): the POST shape (the live contract — a JSON body with
/// `client_id` + `client_secret`, NOT the RFC 6749 form exchange), the
/// `{data:{access_token,…}}` response envelope, caching until expiry, expiry
/// re-fetch, [UkFuelFinderAuth.invalidate] re-fetch, the packed-credentials
/// parser, and the malformed-response guards.

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
  const tokenUrl = 'https://test.fuel-finder.example/oauth/token';

  group('UkFuelFinderAuth — client-credentials token flow (#3190)', () {
    test('POSTs the JSON credential body of the live token contract',
        () async {
      final adapter = _CapturingAdapter([
        (200, {'access_token': 'tok-1', 'token_type': 'Bearer', 'expires_in': 3600}),
      ]);
      final auth = UkFuelFinderAuth(
        dio: _dio(adapter),
        tokenUrl: tokenUrl,
        clientId: 'client-abc',
        clientSecret: 'secret-xyz',
      );

      final token = await auth.accessToken();

      expect(token, 'tok-1');
      expect(adapter.requests.single.path, tokenUrl);
      expect(adapter.requests.single.method, 'POST');
      expect(adapter.requests.single.headers[Headers.contentTypeHeader],
          contains('application/json'));
      final body = jsonDecode(adapter.requestBodies.single);
      expect(body, {
        'client_id': 'client-abc',
        'client_secret': 'secret-xyz',
      });
    });

    test('defaults to the statutory generate_access_token endpoint', () {
      expect(
        UkFuelFinderAuth.defaultTokenUrl,
        'https://www.fuel-finder.service.gov.uk'
        '/api/v1/oauth/generate_access_token',
      );
      final auth = UkFuelFinderAuth(
        dio: Dio(),
        clientId: 'c',
        clientSecret: 's',
      );
      expect(auth.tokenUrl, UkFuelFinderAuth.defaultTokenUrl);
    });

    test('unwraps the live {data:{access_token,expires_in}} envelope',
        () async {
      final adapter = _CapturingAdapter([
        (200, {
          'data': {'access_token': 'tok-enveloped', 'expires_in': 3600},
        }),
      ]);
      final auth = UkFuelFinderAuth(
        dio: _dio(adapter),
        tokenUrl: tokenUrl,
        clientId: 'c',
        clientSecret: 's',
      );

      expect(await auth.accessToken(), 'tok-enveloped');
    });

    test('fromPackedCredentials parses the Settings key slot', () {
      final auth = UkFuelFinderAuth.fromPackedCredentials(
        'client-abc:secret-with:colon',
        dio: Dio(),
      );
      expect(auth, isNotNull);
      expect(auth!.clientId, 'client-abc');
      // Everything past the FIRST separator is the secret.
      expect(auth.clientSecret, 'secret-with:colon');
      expect(auth.tokenUrl, UkFuelFinderAuth.defaultTokenUrl);

      // Non-credential key shapes (e.g. a Tankerkönig key in the shared
      // slot) must not produce a GB auth.
      expect(UkFuelFinderAuth.fromPackedCredentials(null, dio: Dio()), isNull);
      expect(UkFuelFinderAuth.fromPackedCredentials('', dio: Dio()), isNull);
      expect(
          UkFuelFinderAuth.fromPackedCredentials('no-separator', dio: Dio()),
          isNull);
      expect(UkFuelFinderAuth.fromPackedCredentials(':secret', dio: Dio()),
          isNull);
      expect(UkFuelFinderAuth.fromPackedCredentials('id:', dio: Dio()),
          isNull);
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
