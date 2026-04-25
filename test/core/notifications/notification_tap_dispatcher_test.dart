import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/notifications/notification_tap_dispatcher.dart';

/// Tests for [NotificationTapDispatcher] — a process-lifetime singleton
/// broadcast hub for notification taps (#1012 phase 3, #561 coverage).
///
/// IMPORTANT: the dispatcher is intentionally a static singleton wrapping
/// a single [StreamController.broadcast]. Once [debugClose] runs, the
/// controller stays closed for the rest of the process — there is no
/// "reset" hook by design (production code never closes it). The
/// debugClose-related tests therefore live in the LAST group so they
/// don't poison earlier subscriptions.
void main() {
  group('NotificationTapDispatcher — live singleton semantics', () {
    test('instance is identical across calls (singleton)', () {
      final a = NotificationTapDispatcher.instance;
      final b = NotificationTapDispatcher.instance;
      expect(identical(a, b), isTrue,
          reason: 'instance getter must always return the same singleton.');
    });

    test('dispatch(payload) emits payload on stream', () async {
      final dispatcher = NotificationTapDispatcher.instance;

      final received = <String?>[];
      final sub = dispatcher.stream.listen(received.add);
      addTearDown(sub.cancel);

      dispatcher.dispatch('radius:de-001');

      // Let the broadcast controller flush the event.
      await Future<void>.delayed(Duration.zero);

      expect(received, ['radius:de-001']);
    });

    test('multiple subscribers each receive the same payload (broadcast)',
        () async {
      final dispatcher = NotificationTapDispatcher.instance;

      final firstReceived = <String?>[];
      final secondReceived = <String?>[];
      final firstSub = dispatcher.stream.listen(firstReceived.add);
      final secondSub = dispatcher.stream.listen(secondReceived.add);
      addTearDown(firstSub.cancel);
      addTearDown(secondSub.cancel);

      dispatcher.dispatch('radius:fr-99');
      await Future<void>.delayed(Duration.zero);

      expect(firstReceived, ['radius:fr-99']);
      expect(secondReceived, ['radius:fr-99']);
    });

    test('dispatching a null payload is allowed and emits null', () async {
      final dispatcher = NotificationTapDispatcher.instance;

      final received = <String?>[];
      final sub = dispatcher.stream.listen(received.add);
      addTearDown(sub.cancel);

      dispatcher.dispatch(null);
      await Future<void>.delayed(Duration.zero);

      // The dispatcher is schema-free; legacy/non-radius taps may carry
      // a null payload and must still flow through to subscribers.
      expect(received, [null]);
    });

    test(
        'late subscribers do NOT receive past payloads '
        '(broadcast, not replay)', () async {
      final dispatcher = NotificationTapDispatcher.instance;

      // Dispatch with no listeners — broadcast streams drop these.
      dispatcher.dispatch('lost-tap');
      await Future<void>.delayed(Duration.zero);

      final lateReceived = <String?>[];
      final lateSub = dispatcher.stream.listen(lateReceived.add);
      addTearDown(lateSub.cancel);

      // Give the listener a tick to confirm it got nothing buffered.
      await Future<void>.delayed(Duration.zero);
      expect(lateReceived, isEmpty,
          reason:
              'Broadcast streams must not replay events emitted before subscription.');

      dispatcher.dispatch('fresh-tap');
      await Future<void>.delayed(Duration.zero);
      expect(lateReceived, ['fresh-tap']);
    });
  });

  // -----------------------------------------------------------------
  // Closing tests — run LAST. Once we close the singleton's controller
  // there is no public reset path, so any later test that subscribes
  // would observe a closed stream. Keep these grouped at the bottom.
  // -----------------------------------------------------------------
  group('NotificationTapDispatcher — debugClose (must run last)', () {
    test('debugClose closes the stream; subsequent dispatch is a no-op',
        () async {
      final dispatcher = NotificationTapDispatcher.instance;

      var doneFired = false;
      final received = <String?>[];
      final sub = dispatcher.stream.listen(
        received.add,
        onDone: () => doneFired = true,
      );
      addTearDown(sub.cancel);

      await dispatcher.debugClose();
      // Allow the onDone callback to flush.
      await Future<void>.delayed(Duration.zero);

      expect(doneFired, isTrue,
          reason: 'Closing the controller must complete the stream.');

      // dispatch() guards on isClosed and must not throw.
      expect(() => dispatcher.dispatch('post-close'), returnsNormally);
      await Future<void>.delayed(Duration.zero);

      expect(received, isEmpty,
          reason: 'No payload should be delivered after close.');
    });

    test('debugClose is idempotent — calling it twice does not throw',
        () async {
      final dispatcher = NotificationTapDispatcher.instance;

      // Already closed by the previous test; a second close must short-
      // circuit on the isClosed guard rather than re-closing.
      await expectLater(dispatcher.debugClose(), completes);
    });
  });
}
