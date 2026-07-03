// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sync/tanksync_init.dart';
import 'package:tankstellen/core/sync/tanksync_init_retry.dart';

import '../../helpers/silence_error_logger.dart';

/// #3450 — the background init-retry ladder: 30 s → 5 min backoff, max
/// five attempts, terminal outcomes stop it, and a late success runs the
/// launch-pull callback.
void main() {
  silenceErrorLoggerSpool();

  final retry = TankSyncInitRetry.instance;

  setUp(retry.disarm);
  tearDown(retry.disarm);

  test('backoff ladder is 30 s → 5 min with five attempts', () {
    expect(TankSyncInitRetry.backoff.first, const Duration(seconds: 30));
    expect(TankSyncInitRetry.backoff.last, const Duration(minutes: 5));
    expect(TankSyncInitRetry.maxAttempts, 5);
    // Monotonic non-decreasing ladder.
    for (var i = 1; i < TankSyncInitRetry.backoff.length; i++) {
      expect(
        TankSyncInitRetry.backoff[i] >= TankSyncInitRetry.backoff[i - 1],
        isTrue,
      );
    }
  });

  test('a late success runs onReady and disarms', () {
    fakeAsync((async) {
      var attempts = 0;
      var readyRuns = 0;
      retry.arm(
        attempt: () async {
          attempts++;
          // Fails twice, succeeds on the third try.
          return attempts < 3
              ? TankSyncInitOutcome.failed
              : TankSyncInitOutcome.ready;
        },
        onReady: () async => readyRuns++,
      );

      async.elapse(const Duration(seconds: 29));
      expect(attempts, 0, reason: 'first retry waits the full 30 s');
      async.elapse(const Duration(seconds: 2));
      expect(attempts, 1);

      async.elapse(const Duration(minutes: 1));
      expect(attempts, 2);
      async.elapse(const Duration(minutes: 2));
      expect(attempts, 3);

      expect(readyRuns, 1, reason: 'late success must run the launch sync');
      expect(retry.pending, isFalse, reason: 'success is terminal');
      async.elapse(const Duration(hours: 1));
      expect(attempts, 3, reason: 'no further attempts after success');
    });
  });

  test('gives up after five failed attempts', () {
    fakeAsync((async) {
      var attempts = 0;
      retry.arm(
        attempt: () async {
          attempts++;
          return TankSyncInitOutcome.failed;
        },
        onReady: () async {},
      );

      async.elapse(const Duration(hours: 1));

      expect(attempts, TankSyncInitRetry.maxAttempts,
          reason: 'the ladder is bounded — max 5 attempts');
      expect(retry.pending, isFalse);
    });
  });

  test('a thrown attempt counts as failed and backs off', () {
    fakeAsync((async) {
      var attempts = 0;
      retry.arm(
        attempt: () async {
          attempts++;
          throw StateError('network down');
        },
        onReady: () async {},
      );

      async.elapse(const Duration(hours: 1));

      expect(attempts, TankSyncInitRetry.maxAttempts);
      expect(retry.pending, isFalse);
    });
  });

  test('relinkRequired is terminal and surfaces via onRelinkRequired '
      '(#3449 — retrying can never conjure a session)', () {
    fakeAsync((async) {
      var attempts = 0;
      var relinkSurfaced = 0;
      retry.arm(
        attempt: () async {
          attempts++;
          return TankSyncInitOutcome.relinkRequired;
        },
        onReady: () async => fail('must not run the launch sync'),
        onRelinkRequired: () => relinkSurfaced++,
      );

      async.elapse(const Duration(hours: 1));

      expect(attempts, 1);
      expect(relinkSurfaced, 1);
      expect(retry.pending, isFalse);
    });
  });

  test('retryNowIfPending (the app-resume fast path) skips the backoff',
      () {
    fakeAsync((async) {
      var attempts = 0;
      retry.arm(
        attempt: () async {
          attempts++;
          return TankSyncInitOutcome.ready;
        },
        onReady: () async {},
      );

      // Resume 5 s after arming — well inside the 30 s backoff.
      async.elapse(const Duration(seconds: 5));
      unawaited(retry.retryNowIfPending());
      async.flushMicrotasks();

      expect(attempts, 1);
      expect(retry.pending, isFalse);
    });
  });

  test('retryNowIfPending is a no-op when nothing is armed', () async {
    await retry.retryNowIfPending();
    expect(retry.pending, isFalse);
  });
}
