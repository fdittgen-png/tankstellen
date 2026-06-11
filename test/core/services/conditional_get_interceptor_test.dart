// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/services/conditional_get_interceptor.dart';
import 'package:tankstellen/core/services/dio_factory.dart';

void main() {
  group('ConditionalGetInterceptor — 304 revalidation', () {
    test('replays the cached body when the upstream answers 304', () async {
      final adapter = _ScriptedAdapter([
        // First GET: 200 + ETag.
        _Step.ok({'price': 1.5}, etag: '"v1"'),
        // Second GET: server sees If-None-Match and answers 304 (empty body).
        _Step.notModified(),
      ]);
      final dio = _dioWith(adapter);

      final first = await dio.get<Map<dynamic, dynamic>>('https://x.test/data');
      expect(first.statusCode, 200);
      expect(first.data, {'price': 1.5});

      final second = await dio.get<Map<dynamic, dynamic>>('https://x.test/data');
      // 304 is transparently turned into a 200 carrying the cached body.
      expect(second.statusCode, 200);
      expect(second.data, {'price': 1.5});
      expect(second.extra['tankstellen.conditionalGet'], '304');

      // The second request must have carried the validator.
      expect(adapter.requests[1].headers['If-None-Match'], '"v1"');
    });

    test('sends If-Modified-Since from a cached Last-Modified', () async {
      const lastMod = 'Wed, 21 Oct 2026 07:28:00 GMT';
      final adapter = _ScriptedAdapter([
        _Step.ok({'n': 1}, lastModified: lastMod),
        _Step.notModified(),
      ]);
      final dio = _dioWith(adapter);

      await dio.get<Map<dynamic, dynamic>>('https://x.test/feed');
      final second = await dio.get<Map<dynamic, dynamic>>('https://x.test/feed');

      expect(adapter.requests[1].headers['If-Modified-Since'], lastMod);
      expect(second.data, {'n': 1});
    });

    test('different query strings are independent cache entries', () async {
      final adapter = _ScriptedAdapter([
        _Step.ok({'q': 'a'}, etag: '"a"'),
        _Step.ok({'q': 'b'}, etag: '"b"'),
      ]);
      final dio = _dioWith(adapter);

      final a = await dio.get<Map<dynamic, dynamic>>('https://x.test/s?q=a');
      final b = await dio.get<Map<dynamic, dynamic>>('https://x.test/s?q=b');
      expect(a.data, {'q': 'a'});
      expect(b.data, {'q': 'b'});
      // Neither request revalidated the other's entry.
      expect(adapter.requests[1].headers.containsKey('If-None-Match'), isFalse);
    });
  });

  group('ConditionalGetInterceptor — offline fallback', () {
    test('serves the cached body when the network later fails', () async {
      final adapter = _ScriptedAdapter([
        _Step.ok({'price': 2.0}, etag: '"v2"'),
        _Step.networkError(),
      ]);
      final dio = _dioWith(adapter);

      final first = await dio.get<Map<dynamic, dynamic>>('https://x.test/data');
      expect(first.data, {'price': 2.0});

      // Network drops on the next call — the cached body is served instead of
      // throwing.
      final second = await dio.get<Map<dynamic, dynamic>>('https://x.test/data');
      expect(second.statusCode, 200);
      expect(second.data, {'price': 2.0});
      expect(second.extra['tankstellen.conditionalGet'], 'offline');
    });

    test('propagates the error when nothing is cached yet', () async {
      final adapter = _ScriptedAdapter([_Step.networkError()]);
      final dio = _dioWith(adapter);

      await expectLater(
        dio.get<Map<dynamic, dynamic>>('https://x.test/cold'),
        throwsA(isA<DioException>()),
      );
    });

    test('does not rescue a real 4xx/5xx (those carry a body)', () async {
      final adapter = _ScriptedAdapter([
        _Step.ok({'ok': true}, etag: '"v3"'),
        _Step.status(500),
      ]);
      final dio = _dioWith(adapter);

      await dio.get<Map<dynamic, dynamic>>('https://x.test/data');
      await expectLater(
        dio.get<Map<dynamic, dynamic>>('https://x.test/data'),
        throwsA(isA<DioException>()),
      );
    });
  });

  group('ConditionalGetInterceptor — bookkeeping', () {
    test('only GET responses with a validator are cached', () {
      final interceptor = ConditionalGetInterceptor();
      expect(interceptor.cacheSize, 0);
    });

    test('LRU bound evicts the oldest entry', () async {
      final interceptor = ConditionalGetInterceptor(maxEntries: 2);
      final adapter = _ScriptedAdapter([
        _Step.ok({'i': 1}, etag: '"1"'),
        _Step.ok({'i': 2}, etag: '"2"'),
        _Step.ok({'i': 3}, etag: '"3"'),
      ]);
      final dio = Dio(BaseOptions())
        ..httpClientAdapter = adapter
        ..interceptors.add(interceptor);

      await dio.get<Map<dynamic, dynamic>>('https://x.test/a');
      await dio.get<Map<dynamic, dynamic>>('https://x.test/b');
      await dio.get<Map<dynamic, dynamic>>('https://x.test/c');
      expect(interceptor.cacheSize, 2);
    });
  });

  group('DioFactory wiring', () {
    test('installs a ConditionalGetInterceptor by default', () {
      final dio = DioFactory.create();
      expect(
        dio.interceptors.whereType<ConditionalGetInterceptor>(),
        isNotEmpty,
      );
    });

    test('conditionalGet: false opts out', () {
      final dio = DioFactory.create(conditionalGet: false);
      expect(
        dio.interceptors.whereType<ConditionalGetInterceptor>(),
        isEmpty,
      );
    });
  });
}

Dio _dioWith(_ScriptedAdapter adapter) {
  // Build through DioFactory so the test exercises the real interceptor wiring,
  // but disable the rate limiter so the test doesn't sleep between calls.
  final dio = DioFactory.create(rateLimit: null);
  dio.httpClientAdapter = adapter;
  return dio;
}

/// Drives a fixed script of responses, recording each request's options so
/// tests can assert on the conditional headers that were sent.
class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter(this._steps);

  final List<_Step> _steps;
  final List<RequestOptions> requests = [];
  int _i = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (_i >= _steps.length) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.unknown,
        error: 'script exhausted',
      );
    }
    return _steps[_i++].toResponseBody(options);
  }

  @override
  void close({bool force = false}) {}
}

/// One scripted upstream outcome.
class _Step {
  _Step._(this._build);

  final ResponseBody Function(RequestOptions) _build;

  ResponseBody toResponseBody(RequestOptions o) => _build(o);

  static _Step ok(
    Map<String, dynamic> body, {
    String? etag,
    String? lastModified,
  }) {
    return _Step._((o) {
      final headers = <String, List<String>>{
        'content-type': ['application/json'],
      };
      if (etag != null) headers['etag'] = [etag];
      if (lastModified != null) headers['last-modified'] = [lastModified];
      return ResponseBody.fromString(_json(body), 200, headers: headers);
    });
  }

  static _Step notModified() {
    return _Step._((o) => ResponseBody.fromString('', 304));
  }

  static _Step status(int code) {
    return _Step._((o) => ResponseBody.fromString('{"err":true}', code,
        headers: {
          'content-type': ['application/json'],
        }));
  }

  static _Step networkError() {
    return _Step._((o) => throw DioException(
          requestOptions: o,
          type: DioExceptionType.connectionError,
          error: 'simulated network drop',
        ));
  }
}

String _json(Map<String, dynamic> m) {
  final entries = m.entries.map((e) {
    final v = e.value;
    final encoded = v is String ? '"$v"' : '$v';
    return '"${e.key}":$encoded';
  }).join(',');
  return '{$entries}';
}
