// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/error/exceptions.dart';
import 'package:tankstellen/core/services/mixins/station_service_helpers.dart';
import 'package:tankstellen/core/services/rate_limit_interceptor.dart';

/// Records whether next() ran without completing Dio's underlying future
/// (calling super.next would surface the result/error to a non-existent caller
/// and throw asynchronously in a unit test).
class _CapturingResponseHandler extends ResponseInterceptorHandler {
  bool called = false;
  @override
  void next(Response response) {
    called = true;
  }
}

class _CapturingErrorHandler extends ErrorInterceptorHandler {
  bool called = false;
  @override
  void next(DioException err) {
    called = true;
  }
}

/// Minimal mixin host so we can call [throwApiException].
class _Helper with StationServiceHelpers {}

void main() {
  group('parseRetryAfter (#2255)', () {
    test('delta-seconds form', () {
      expect(parseRetryAfter('5'), const Duration(seconds: 5));
      expect(parseRetryAfter('  30 '), const Duration(seconds: 30));
      expect(parseRetryAfter('0'), Duration.zero);
    });

    test('negative delta-seconds clamps to zero', () {
      expect(parseRetryAfter('-3'), Duration.zero);
    });

    test('HTTP-date form computes delta from now', () {
      final now = DateTime.utc(2015, 10, 21, 7, 28, 0);
      // 60 s in the future.
      final result =
          parseRetryAfter('Wed, 21 Oct 2015 07:29:00 GMT', now: now);
      expect(result, const Duration(seconds: 60));
    });

    test('HTTP-date in the past clamps to zero', () {
      final now = DateTime.utc(2015, 10, 21, 7, 30, 0);
      final result =
          parseRetryAfter('Wed, 21 Oct 2015 07:28:00 GMT', now: now);
      expect(result, Duration.zero);
    });

    test('null / blank / garbage → null', () {
      expect(parseRetryAfter(null), isNull);
      expect(parseRetryAfter(''), isNull);
      expect(parseRetryAfter('   '), isNull);
      expect(parseRetryAfter('not-a-date'), isNull);
    });
  });

  group('RateLimitInterceptor 429 / Retry-After cooldown (#2255)', () {
    RequestOptions opts() => RequestOptions(path: '/test');

    Response resp429(RequestOptions o, {String? retryAfter}) => Response(
          requestOptions: o,
          statusCode: 429,
          headers: retryAfter == null
              ? Headers()
              : (Headers()..set('retry-after', retryAfter)),
        );

    test('onResponse 429 with Retry-After stashes parsed delay on extra '
        'and arms a cooldown', () {
      final now = DateTime.utc(2026, 1, 1, 0, 0, 0);
      final interceptor = RateLimitInterceptor(
        minInterval: const Duration(seconds: 1),
        clock: () => now,
      );
      final o = opts();
      interceptor.onResponse(
        resp429(o, retryAfter: '7'),
        _CapturingResponseHandler(),
      );

      expect(o.extra[kRetryAfterExtraKey], const Duration(seconds: 7));
      expect(interceptor.cooldownUntil, now.add(const Duration(seconds: 7)));
    });

    test('onError 429 without Retry-After applies defaultCooldown', () {
      final now = DateTime.utc(2026, 1, 1, 0, 0, 0);
      final interceptor = RateLimitInterceptor(
        defaultCooldown: const Duration(seconds: 5),
        clock: () => now,
      );
      final o = opts();
      final err = DioException(
        requestOptions: o,
        type: DioExceptionType.badResponse,
        response: resp429(o),
      );
      final handler = _CapturingErrorHandler();
      interceptor.onError(err, handler);

      expect(handler.called, isTrue, reason: 'error must propagate');
      // No Retry-After header → extra holds null, cooldown = defaultCooldown.
      expect(o.extra.containsKey(kRetryAfterExtraKey), isTrue);
      expect(o.extra[kRetryAfterExtraKey], isNull);
      expect(interceptor.cooldownUntil, now.add(const Duration(seconds: 5)));
    });

    test('non-429 response without Retry-After does not arm a cooldown', () {
      final interceptor = RateLimitInterceptor();
      final o = opts();
      interceptor.onResponse(
        Response(requestOptions: o, statusCode: 200),
        _CapturingResponseHandler(),
      );
      expect(interceptor.cooldownUntil, isNull);
      expect(o.extra.containsKey(kRetryAfterExtraKey), isFalse);
    });

    test('cooldown delays the next request beyond minInterval', () async {
      final interceptor = RateLimitInterceptor(
        minInterval: const Duration(milliseconds: 50),
        jitterRangeMs: 0,
        // Real clock for this timing assertion.
      );
      // Arm a 200 ms cooldown via a 429 response.
      final o1 = opts();
      interceptor.onResponse(
        resp429(o1, retryAfter: '0'),
        _CapturingResponseHandler(),
      );
      // Override cooldownUntil to a precise near-future point.
      interceptor.cooldownUntil =
          DateTime.now().add(const Duration(milliseconds: 200));

      final handler = _GateHandler();
      final sw = Stopwatch()..start();
      await interceptor.onRequest(opts(), handler);
      await handler.completed;
      sw.stop();

      expect(handler.fired, isTrue);
      expect(sw.elapsedMilliseconds, greaterThanOrEqualTo(150),
          reason: 'the cooldown must hold the request back ~200 ms, well '
              'beyond the 50 ms minInterval');
    });
  });

  group('throwApiException surfaces rateLimited + retryAfter (#2255)', () {
    test('429 DioException with Retry-After header → '
        'ApiException.kind=rateLimited + retryAfter', () {
      final helper = _Helper();
      final o = RequestOptions(path: '/x');
      final err = DioException(
        requestOptions: o,
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: o,
          statusCode: 429,
          headers: Headers()..set('retry-after', '12'),
        ),
      );

      ApiException? caught;
      try {
        helper.throwApiException(err);
      } on ApiException catch (e) {
        caught = e;
      }

      expect(caught, isNotNull);
      expect(caught.kind, FailureKind.rateLimited);
      expect(caught.statusCode, 429);
      expect(caught.retryAfter, const Duration(seconds: 12));
    });

    test('429 with the parsed Retry-After stashed on extra wins', () {
      final helper = _Helper();
      final o = RequestOptions(path: '/x')
        ..extra[kRetryAfterExtraKey] = const Duration(seconds: 3);
      final err = DioException(
        requestOptions: o,
        type: DioExceptionType.badResponse,
        response: Response(requestOptions: o, statusCode: 429),
      );

      ApiException? caught;
      try {
        helper.throwApiException(err);
      } on ApiException catch (e) {
        caught = e;
      }

      expect(caught.retryAfter, const Duration(seconds: 3));
      expect(caught.kind, FailureKind.rateLimited);
    });
  });
}

class _GateHandler extends RequestInterceptorHandler {
  bool fired = false;
  final _completer = Completer<void>();
  Future<void> get completed => _completer.future;
  @override
  void next(RequestOptions requestOptions) {
    fired = true;
    if (!_completer.isCompleted) _completer.complete();
  }
}
