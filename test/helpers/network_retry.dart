// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart' show TestFailure;

/// Bounded retry for the `network`-tagged nightly suite (#3096).
///
/// The live API-connectivity / search tests hit real upstream endpoints
/// (Italy MIMIT, Denmark OK, …) which intermittently TIME OUT or return a
/// transient 5xx. Those blips filed a `nightly-flaky` issue every few nights
/// even though nothing in the app or the upstream contract was broken. These
/// helpers retry ONLY transient transport failures a couple of times, so a
/// blip self-heals — while a GENUINE, persistent breakage (every attempt
/// fails, or the upstream contract changed → an assertion fails) still fails
/// hard, preserving the whole point of the live suite.

bool _isTransient(DioException e) =>
    e.type == DioExceptionType.connectionTimeout ||
    e.type == DioExceptionType.receiveTimeout ||
    e.type == DioExceptionType.sendTimeout ||
    e.type == DioExceptionType.connectionError ||
    (e.response?.statusCode != null && e.response!.statusCode! >= 500);

class _RetryInterceptor extends Interceptor {
  _RetryInterceptor(this._dio, {this.maxRetries = 2});

  static const _baseDelay = Duration(seconds: 2);

  final Dio _dio;
  final int maxRetries;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final attempt = (err.requestOptions.extra['retry_attempt'] as int?) ?? 0;
    if (_isTransient(err) && attempt < maxRetries) {
      await Future<void>.delayed(_baseDelay * (attempt + 1));
      final opts = err.requestOptions..extra['retry_attempt'] = attempt + 1;
      try {
        return handler.resolve(await _dio.fetch<dynamic>(opts));
      } catch (_) {
        return handler.next(err);
      }
    }
    return handler.next(err);
  }
}

/// A [Dio] that transparently retries transient transport failures (#3096).
/// Drop-in for `Dio(BaseOptions(...))` in the live network tests.
Dio retryingDio(BaseOptions options, {int maxRetries = 2}) {
  final dio = Dio(options);
  dio.interceptors.add(_RetryInterceptor(dio, maxRetries: maxRetries));
  return dio;
}

/// Retry [body] up to [attempts] times on a transient [DioException] (#3096),
/// for live tests that go through a SERVICE (which owns its own Dio) rather
/// than a raw [Dio]. A [TestFailure] (a real assertion) is NEVER retried — it
/// rethrows immediately so a genuine contract break fails fast.
Future<T> retryNetwork<T>(
  Future<T> Function() body, {
  int attempts = 3,
  Duration baseDelay = const Duration(seconds: 2),
}) async {
  Object? lastError;
  StackTrace? lastStack;
  for (var i = 0; i < attempts; i++) {
    try {
      return await body();
    } on TestFailure {
      rethrow;
    } catch (e, st) {
      if (e is DioException && !_isTransient(e)) rethrow;
      lastError = e;
      lastStack = st;
      if (i < attempts - 1) await Future<void>.delayed(baseDelay * (i + 1));
    }
  }
  Error.throwWithStackTrace(lastError!, lastStack!);
}
