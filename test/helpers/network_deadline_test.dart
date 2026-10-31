// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'network_retry.dart';

void main() {
  group('probe deadline and cancellation (#4541)', () {
    test(
      'success cancels outstanding requests without changing the result',
      () async {
        late CancelToken token;
        final result = await withNetworkDeadline((value) async {
          token = value;
          return 42;
        });
        expect(result, 42);
        expect(token.isCancelled, isTrue);
      },
    );

    test(
      'a contract failure is preserved and cancels outstanding requests',
      () async {
        late CancelToken token;
        final error = TestFailure('schema changed');
        await expectLater(
          withNetworkDeadline<void>((value) async {
            token = value;
            throw error;
          }),
          throwsA(same(error)),
        );
        expect(token.isCancelled, isTrue);
      },
    );

    test('a stalled probe fails and cancels before the runner timeout', () {
      fakeAsync((clock) {
        final pending = Completer<int>();
        late CancelToken token;
        Object? error;
        unawaited(
          withNetworkDeadline((value) {
            token = value;
            return pending.future;
          }, timeout: const Duration(seconds: 25)).then<void>(
            (_) => fail('stalled probe must fail'),
            onError: (Object value) {
              error = value;
            },
          ),
        );
        clock.elapse(const Duration(seconds: 24));
        expect(error, isNull);
        expect(token.isCancelled, isFalse);
        clock.elapse(const Duration(seconds: 1));
        expect(error, isA<TimeoutException>());
        expect(token.isCancelled, isTrue);
        // A late source error is consumed by Future.timeout, not reported as
        // another test's uncaught failure (the observed nightly regression).
        pending.completeError(StateError('late transport error'));
        clock.flushMicrotasks();
        expect(clock.nonPeriodicTimerCount, 0);
      });
    });

    test('cancellation during service backoff prevents another invocation', () {
      fakeAsync((clock) {
        final token = CancelToken();
        var calls = 0;
        Object? error;
        unawaited(
          retryNetwork<int>(() async {
            calls++;
            throw DioException.connectionTimeout(
              timeout: const Duration(seconds: 1),
              requestOptions: RequestOptions(path: '/probe'),
            );
          }, cancelToken: token).then<void>(
            (_) => fail('cancelled probe must fail'),
            onError: (Object value) {
              error = value;
            },
          ),
        );
        clock.flushMicrotasks();
        expect(calls, 1);
        token.cancel('deadline');
        clock.elapse(const Duration(seconds: 6));
        expect(calls, 1);
        expect(error, same(token.cancelError));
        expect(clock.nonPeriodicTimerCount, 0);
      });
    });

    test(
      'service-wrapped cancellation does not schedule another retry',
      () async {
        final token = CancelToken();
        var calls = 0;
        await expectLater(
          retryNetwork<void>(
            () async {
              calls++;
              token.cancel('deadline');
              throw StateError('service wraps the transport cancellation');
            },
            cancelToken: token,
            baseDelay: Duration.zero,
          ),
          throwsA(same(token.cancelError)),
        );
        expect(calls, 1);
      },
    );
  });
}
