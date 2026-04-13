import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/services/rate_limit_interceptor.dart';

/// A seeded Random that always returns 0, removing jitter from tests.
class _ZeroRandom implements Random {
  @override
  int nextInt(int max) => 0;
  @override
  double nextDouble() => 0.0;
  @override
  bool nextBool() => false;
}

/// Handler that records the timestamp when next() is called.
class _TimestampHandler extends RequestInterceptorHandler {
  final List<DateTime> timestamps;

  _TimestampHandler(this.timestamps);

  @override
  void next(RequestOptions requestOptions) {
    timestamps.add(DateTime.now());
    super.next(requestOptions);
  }
}

void main() {
  group('RateLimitInterceptor', () {
    late RateLimitInterceptor interceptor;
    late List<DateTime> requestTimestamps;

    setUp(() {
      requestTimestamps = [];
      interceptor = RateLimitInterceptor(
        minInterval: const Duration(milliseconds: 100),
        random: _ZeroRandom(),
      );
    });

    RequestOptions makeOptions() => RequestOptions(path: '/test');

    test('first request proceeds without delay', () async {
      final stopwatch = Stopwatch()..start();

      await interceptor.onRequest(
        makeOptions(),
        _TimestampHandler(requestTimestamps),
      );

      stopwatch.stop();
      expect(requestTimestamps, hasLength(1));
      expect(stopwatch.elapsedMilliseconds, lessThan(50));
    });

    test('second request is delayed by minInterval', () async {
      await interceptor.onRequest(
        makeOptions(),
        _TimestampHandler(requestTimestamps),
      );

      final stopwatch = Stopwatch()..start();
      await interceptor.onRequest(
        makeOptions(),
        _TimestampHandler(requestTimestamps),
      );
      stopwatch.stop();

      expect(requestTimestamps, hasLength(2));
      final gap = requestTimestamps[1].difference(requestTimestamps[0]);
      // 5ms slack: Future.delayed precision on slower CI runners is ~1-2ms
      // and DateTime.now() can round down on Windows.
      expect(gap.inMilliseconds, greaterThanOrEqualTo(95));
    });

    test('concurrent requests are serialized, not parallel', () async {
      final futures = [
        interceptor.onRequest(makeOptions(), _TimestampHandler(requestTimestamps)),
        interceptor.onRequest(makeOptions(), _TimestampHandler(requestTimestamps)),
        interceptor.onRequest(makeOptions(), _TimestampHandler(requestTimestamps)),
      ];

      await Future.wait(futures);

      expect(requestTimestamps, hasLength(3));

      // First request is immediate, 2nd and 3rd are each delayed.
      // 5ms slack: Future.delayed precision is ~1-2ms on CI; DateTime.now()
      // can round down on Windows runners.
      final gap1 = requestTimestamps[1].difference(requestTimestamps[0]);
      final gap2 = requestTimestamps[2].difference(requestTimestamps[1]);

      expect(gap1.inMilliseconds, greaterThanOrEqualTo(95));
      expect(gap2.inMilliseconds, greaterThanOrEqualTo(95));
    });
  });
}
