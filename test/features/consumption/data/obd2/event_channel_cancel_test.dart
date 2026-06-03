// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/event_channel_cancel.dart';

/// Minimal fake [StreamSubscription] whose only meaningful method is
/// [cancel]. Every other method throws [UnimplementedError] so a
/// regression that touches them shows up loudly in the test output.
///
/// The cancel behaviour is parametric: pass [cancelError] to make
/// [cancel] complete with that error, or leave it null for a clean
/// completion. [cancelCallCount] records how many times cancel was
/// invoked so tests can assert idempotency.
class _FakeStreamSubscription<T> implements StreamSubscription<T> {
  _FakeStreamSubscription({this.cancelError});

  final Object? cancelError;
  int cancelCallCount = 0;

  @override
  Future<void> cancel() async {
    cancelCallCount++;
    if (cancelError != null) {
      throw cancelError!;
    }
  }

  @override
  Future<E> asFuture<E>([E? futureValue]) =>
      throw UnimplementedError('asFuture');

  @override
  bool get isPaused => throw UnimplementedError('isPaused');

  @override
  void onData(void Function(T data)? handleData) =>
      throw UnimplementedError('onData');

  @override
  void onDone(void Function()? handleDone) =>
      throw UnimplementedError('onDone');

  @override
  void onError(Function? handleError) => throw UnimplementedError('onError');

  @override
  void pause([Future<void>? resumeSignal]) => throw UnimplementedError('pause');

  @override
  void resume() => throw UnimplementedError('resume');
}

void main() {
  group('SafeEventChannelCancel.safeCancel', () {
    test('completes normally when subscription cancel() succeeds', () async {
      // ignore: cancel_subscriptions
      final sub = _FakeStreamSubscription<int>();

      await sub.safeCancel();

      expect(sub.cancelCallCount, 1);
    });

    test('swallows benign "No active stream to cancel" PlatformException',
        () async {
      // ignore: cancel_subscriptions
      final sub = _FakeStreamSubscription<int>(
        cancelError: PlatformException(
          code: 'error',
          message: 'No active stream to cancel',
        ),
      );

      // Helper completes without throwing — the whole point of #1323.
      await sub.safeCancel();

      expect(sub.cancelCallCount, 1);
    });

    test('rethrows PlatformException with a different message', () async {
      // ignore: cancel_subscriptions
      final sub = _FakeStreamSubscription<int>(
        cancelError: PlatformException(
          code: 'error',
          message: 'Different error',
        ),
      );

      await expectLater(
        sub.safeCancel(),
        throwsA(
          isA<PlatformException>().having(
            (e) => e.message,
            'message',
            'Different error',
          ),
        ),
      );
      expect(sub.cancelCallCount, 1);
    });

    test('rethrows non-PlatformException errors unchanged', () async {
      // ignore: cancel_subscriptions
      final sub = _FakeStreamSubscription<int>(
        cancelError: StateError('boom'),
      );

      await expectLater(
        sub.safeCancel(),
        throwsA(
          isA<StateError>().having((e) => e.message, 'message', 'boom'),
        ),
      );
      expect(sub.cancelCallCount, 1);
    });

    // #2763 — error-log #15 also flagged a "No active stream to cancel"
    // PlatformException. It is ALREADY guarded by safeCancel; this regression
    // lock proves a DOUBLE cancel of an already-torn-down EventChannel sub
    // never propagates that benign exception (the lifecycle/tab-nav race),
    // while a different PlatformException still rethrows on every call.
    test('double safeCancel of a benign "No active stream" sub never throws',
        () async {
      // ignore: cancel_subscriptions
      final sub = _FakeStreamSubscription<int>(
        cancelError: PlatformException(
          code: 'error',
          message: 'No active stream to cancel',
        ),
      );

      // Both calls complete normally — no PlatformException escapes.
      await sub.safeCancel();
      await sub.safeCancel();

      expect(sub.cancelCallCount, 2);
    });

    test('double safeCancel still rethrows a non-benign PlatformException',
        () async {
      // ignore: cancel_subscriptions
      final sub = _FakeStreamSubscription<int>(
        cancelError: PlatformException(
          code: 'error',
          message: 'Some other platform failure',
        ),
      );

      await expectLater(sub.safeCancel(), throwsA(isA<PlatformException>()));
      await expectLater(sub.safeCancel(), throwsA(isA<PlatformException>()));
      expect(sub.cancelCallCount, 2);
    });
  });
}
