import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/services/dio_factory.dart';
import 'package:tankstellen/core/services/rate_limit_interceptor.dart';

/// Regression tests for issue #428 — rate limiting must be on by default
/// for every DioFactory.create call, with an opt-out for user-triggered
/// services.
void main() {
  group('DioFactory.create rate limiting', () {
    test('default Dio has exactly one RateLimitInterceptor', () {
      final dio = DioFactory.create();
      final rateLimiters = dio.interceptors.whereType<RateLimitInterceptor>();
      expect(rateLimiters, hasLength(1));
      expect(rateLimiters.first.minInterval, DioFactory.defaultRateLimit);
    });

    test('rateLimit override is forwarded to the interceptor', () {
      final dio = DioFactory.create(
        rateLimit: const Duration(seconds: 5),
        rateLimitJitterRangeMs: 1500,
      );
      final interceptor =
          dio.interceptors.whereType<RateLimitInterceptor>().single;
      expect(interceptor.minInterval, const Duration(seconds: 5));
      expect(interceptor.jitterRangeMs, 1500);
    });

    test('rateLimit: null opts out — no interceptor installed', () {
      final dio = DioFactory.create(rateLimit: null);
      expect(dio.interceptors.whereType<RateLimitInterceptor>(), isEmpty);
    });

    test('caller-provided interceptors are appended after the rate limiter',
        () {
      final custom = _NoopInterceptor();
      final dio = DioFactory.create(interceptors: [custom]);
      // Dio prepends a built-in ImplyContentTypeInterceptor; we only care
      // that the rate limiter is installed *before* the caller's custom
      // interceptors so it can gate them.
      final rlIndex = dio.interceptors
          .toList()
          .indexWhere((i) => i is RateLimitInterceptor);
      final customIndex = dio.interceptors.toList().indexOf(custom);
      expect(rlIndex, isNonNegative);
      expect(customIndex, isNonNegative);
      expect(rlIndex, lessThan(customIndex));
    });

    test('two Dios get independent rate limiters (per-instance gating)', () {
      final a = DioFactory.create();
      final b = DioFactory.create();
      final aInt = a.interceptors.whereType<RateLimitInterceptor>().single;
      final bInt = b.interceptors.whereType<RateLimitInterceptor>().single;
      expect(identical(aInt, bInt), isFalse);
    });
  });

  group('RateLimitInterceptor serialisation', () {
    test('two consecutive requests are spaced by at least minInterval',
        () async {
      final interceptor = RateLimitInterceptor(
        minInterval: const Duration(milliseconds: 100),
        jitterBaseMs: 0,
        jitterRangeMs: 0,
      );

      final stopwatch = Stopwatch()..start();
      await _fireRequest(interceptor);
      await _fireRequest(interceptor);
      stopwatch.stop();

      expect(
        stopwatch.elapsed,
        greaterThanOrEqualTo(const Duration(milliseconds: 95)),
        reason: 'second request should be delayed by ≈ minInterval',
      );
    });

    test('first request is not delayed', () async {
      final interceptor = RateLimitInterceptor(
        minInterval: const Duration(milliseconds: 500),
      );

      final stopwatch = Stopwatch()..start();
      await _fireRequest(interceptor);
      stopwatch.stop();

      expect(stopwatch.elapsed, lessThan(const Duration(milliseconds: 50)));
    });
  });
}

Future<void> _fireRequest(RateLimitInterceptor interceptor) async {
  final handler = _CapturingHandler();
  await interceptor.onRequest(RequestOptions(path: '/test'), handler);
  await handler.completed;
}

class _CapturingHandler extends RequestInterceptorHandler {
  final _completer = Completer<void>();
  Future<void> get completed => _completer.future;

  @override
  void next(RequestOptions requestOptions) {
    if (!_completer.isCompleted) _completer.complete();
  }
}

class _NoopInterceptor extends Interceptor {}
