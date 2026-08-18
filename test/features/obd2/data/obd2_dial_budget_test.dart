// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/session/obd2_dial_budget.dart';
import 'package:tankstellen/features/obd2/data/session/obd2_service.dart';
import 'package:tankstellen/features/obd2/data/transport/obd2_transport.dart';

import '../../../helpers/silence_error_logger.dart';

/// #3671 — the whole-dial budget for the AUTOMATIC reconnect dial.
/// Field pathology: connect trace t3 showed one liveReconnect attempt
/// grinding 1,263,965 ms (21 min) while backgrounded, pinning the main
/// looper until the OS killed the process for excessive CPU.
void main() {
  silenceErrorLoggerSpool();

  test('a fast dial passes straight through (timer cancelled — no '
      'lingering budget timer after completion)', () {
    fakeAsync((async) {
      final svc = Obd2Service(FakeObd2Transport());
      Obd2Service? got;
      unawaited(dialWithBudget(() async => svc).then((s) => got = s));
      async.flushMicrotasks();
      expect(got, same(svc));
      // The budget timer must have been cancelled with the completion —
      // nothing left to fire.
      expect(async.pendingTimers, isEmpty);
    });
  });

  test('a dial grinding past the budget throws TimeoutException — the '
      'supervisor sees a stable-signature miss', () {
    fakeAsync((async) {
      final gate = Completer<Obd2Service?>();
      Object? failure;
      unawaited(dialWithBudget(
        () => gate.future,
        budget: const Duration(seconds: 5),
      ).catchError((Object e) {
        failure = e;
        return null;
      }));
      async.elapse(const Duration(seconds: 6));
      expect(failure, isA<TimeoutException>());
      gate.complete(null);
      async.flushMicrotasks();
    });
  });

  test('the zombie dial\'s LATE service is released, never leaked as a '
      'second live link', () {
    fakeAsync((async) {
      final transport = FakeObd2Transport();
      final zombie = Obd2Service(transport);
      unawaited(transport.connect());
      final gate = Completer<Obd2Service?>();
      unawaited(dialWithBudget(
        () => gate.future,
        budget: const Duration(seconds: 5),
      ).catchError((Object e) => null));
      async.elapse(const Duration(seconds: 6));

      // The runaway dial finally lands a service — long after the
      // attempt was written off. It must be disconnected immediately.
      expect(transport.isConnected, isTrue,
          reason: 'precondition: the zombie holds a LIVE link');
      gate.complete(zombie);
      async.flushMicrotasks();
      expect(transport.isConnected, isFalse,
          reason: 'a budget-overrun service must be torn down, not adopted');
    });
  });

  test('a zombie dial that eventually FAILS is swallowed — no unhandled '
      'async error reaches the zone', () {
    fakeAsync((async) {
      final gate = Completer<Obd2Service?>();
      unawaited(dialWithBudget(
        () => gate.future,
        budget: const Duration(seconds: 5),
      ).catchError((Object e) => null));
      async.elapse(const Duration(seconds: 6));
      gate.completeError(StateError('adapter died mid-grind'));
      async.flushMicrotasks(); // must not throw into the test zone
    });
  });
}
