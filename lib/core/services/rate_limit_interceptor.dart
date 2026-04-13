import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';

/// Serialises requests on a single Dio instance so consecutive calls are
/// at least [minInterval] apart, with a randomised jitter on top.
///
/// This protects rate-limited country APIs (Tankerkoenig, Prix Carburants,
/// MIMIT, …) from a thundering-herd burst on app resume or background
/// refresh. Each Dio instance owns its own interceptor — the gating is
/// per-instance, not global, so unrelated services don't block each other.
///
/// Use [DioFactory.create] to obtain a Dio with this interceptor already
/// installed; opt out per call site with `rateLimit: null` for endpoints
/// that should fire immediately (user-triggered actions like submitting
/// a station report or uploading an error trace).
class RateLimitInterceptor extends Interceptor {
  RateLimitInterceptor({
    this.minInterval = const Duration(seconds: 1),
    this.jitterBaseMs = 0,
    this.jitterRangeMs = 500,
    Random? random,
  }) : _random = random ?? Random();

  final Duration minInterval;
  final int jitterBaseMs;
  final int jitterRangeMs;
  final Random _random;
  DateTime? _lastRequest;
  Future<void> _gate = Future.value();

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Serialise by chaining each call onto the previous one.
    final previous = _gate;
    final current = Completer<void>();
    _gate = current.future;
    try {
      await previous;
      if (_lastRequest != null) {
        final elapsed = DateTime.now().difference(_lastRequest!);
        if (elapsed < minInterval) {
          final remaining = minInterval - elapsed;
          final jitter =
              jitterRangeMs > 0 ? _random.nextInt(jitterRangeMs) : 0;
          await Future<void>.delayed(
            remaining + Duration(milliseconds: jitterBaseMs + jitter),
          );
        }
      }
      _lastRequest = DateTime.now();
    } finally {
      current.complete();
    }
    handler.next(options);
  }
}
