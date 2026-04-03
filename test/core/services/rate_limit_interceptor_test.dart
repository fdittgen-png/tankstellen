import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/services/service_providers.dart';

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
      expect(gap.inMilliseconds, greaterThanOrEqualTo(100));
    });

    test('concurrent requests are serialized, not parallel', () async {
      final futures = [
        interceptor.onRequest(makeOptions(), _TimestampHandler(requestTimestamps)),
        interceptor.onRequest(makeOptions(), _TimestampHandler(requestTimestamps)),
        interceptor.onRequest(makeOptions(), _TimestampHandler(requestTimestamps)),
      ];

      await Future.wait(futures);

      expect(requestTimestamps, hasLength(3));

      // First request is immediate, 2nd and 3rd are each delayed
      final gap1 = requestTimestamps[1].difference(requestTimestamps[0]);
      final gap2 = requestTimestamps[2].difference(requestTimestamps[1]);

      expect(gap1.inMilliseconds, greaterThanOrEqualTo(100));
      expect(gap2.inMilliseconds, greaterThanOrEqualTo(100));
    });
  });
}
