// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3529 (Epic #3527) — Obd2LinkSupervisor invariants: single flight,
// one intent flag, NO dead-end states (the loop retries until user stop
// or engine-off — the property whose absence stranded the 2026-07-08
// trip), and recycle-not-resume on every attempt.

import 'dart:async';
import 'dart:math';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/obd2_link_drop_signal.dart';
import 'package:tankstellen/features/obd2/data/obd2_link_supervisor.dart';
import 'package:tankstellen/features/obd2/data/obd2_service.dart';
import 'package:tankstellen/features/obd2/data/obd2_transport.dart';

Obd2Service _liveService() => Obd2Service(FakeObd2Transport());

/// Scripted dialer: pops outcomes off a queue; when the queue is empty
/// it keeps returning the last outcome. `null` = miss, a service =
/// success, an error object = fault.
class _ScriptedDialer {
  final List<Object?> _script = [];
  int calls = 0;

  void enqueue(Object? outcome) => _script.add(outcome);

  Future<Obd2Service?> dial() async {
    calls++;
    final outcome = _script.length > 1 ? _script.removeAt(0) : _script.first;
    if (outcome is Obd2Service) return outcome;
    if (outcome == null) return null;
    throw outcome;
  }
}

void main() {
  late StreamController<Obd2LinkDropEvent> drops;
  late _ScriptedDialer dialer;

  Obd2LinkSupervisor build() => Obd2LinkSupervisor(
        dial: dialer.dial,
        drops: drops.stream,
        initialBackoff: const Duration(milliseconds: 500),
        maxBackoff: const Duration(seconds: 30),
        jitter: Random(42),
      );

  setUp(() {
    drops = StreamController<Obd2LinkDropEvent>.broadcast();
    dialer = _ScriptedDialer();
  });

  tearDown(() => drops.close());

  test('drop → immediate dial → ready on success', () {
    fakeAsync((async) {
      dialer.enqueue(_liveService());
      final sup = build();

      drops.add(const Obd2LinkDropEvent(
          transportKind: 'classic', reason: 'socket-error'));
      async.flushMicrotasks();

      expect(sup.state.value, Obd2LinkState.ready);
      expect(sup.service, isNotNull);
      expect(dialer.calls, 1);
      unawaited(sup.dispose());
      async.flushMicrotasks();
    });
  });

  test('misses keep retrying with growing backoff — NO terminal state', () {
    fakeAsync((async) {
      dialer.enqueue(null); // every attempt misses
      final sup = build();

      drops.add(const Obd2LinkDropEvent(
          transportKind: 'classic', reason: 'socket-done'));
      async.flushMicrotasks();
      expect(sup.state.value, Obd2LinkState.reconnecting);

      // Far beyond the old maxAttempts=6 horizon: two minutes of misses.
      async.elapse(const Duration(minutes: 2));
      final callsAtTwoMinutes = dialer.calls;
      expect(callsAtTwoMinutes, greaterThan(6),
          reason: 'the loop must outlive the old terminalFailed cap');
      expect(sup.state.value, Obd2LinkState.reconnecting,
          reason: 'no dead end — still trying');

      // Backoff is capped, not runaway: over the NEXT two minutes the
      // attempt rate settles to ~30 s cadence.
      async.elapse(const Duration(minutes: 2));
      final callsInSecondWindow = dialer.calls - callsAtTwoMinutes;
      expect(callsInSecondWindow, inInclusiveRange(3, 6),
          reason: 'capped ~30s backoff ⇒ ≈4 attempts per 2 min');

      // And when the adapter finally reappears, the loop connects. The
      // queued miss still in front costs one more capped cycle, so give
      // it two full ~30 s backoff periods (+ jitter).
      dialer.enqueue(_liveService());
      async.elapse(const Duration(seconds: 80));
      expect(sup.state.value, Obd2LinkState.ready);
      unawaited(sup.dispose());
      async.flushMicrotasks();
    });
  });

  test('user disconnect parks the loop; later drops do not dial', () {
    fakeAsync((async) {
      dialer.enqueue(_liveService());
      final sup = build();
      unawaited(sup.connect());
      async.flushMicrotasks();
      expect(sup.state.value, Obd2LinkState.ready);

      unawaited(sup.disconnect());
      async.flushMicrotasks();
      expect(sup.state.value, Obd2LinkState.userDisconnected);
      final callsAfterDisconnect = dialer.calls;

      drops.add(const Obd2LinkDropEvent(
          transportKind: 'ble', reason: 'disconnect-edge'));
      async.elapse(const Duration(minutes: 1));

      expect(dialer.calls, callsAfterDisconnect,
          reason: 'user intent wins — zero auto-dials while parked');
      expect(sup.state.value, Obd2LinkState.userDisconnected);
      unawaited(sup.dispose());
      async.flushMicrotasks();
    });
  });

  test('connect() clears the intent flag and dials again', () {
    fakeAsync((async) {
      dialer.enqueue(_liveService());
      final sup = build();
      unawaited(sup.disconnect());
      async.flushMicrotasks();
      expect(sup.userRequestedDisconnect, isTrue);

      unawaited(sup.connect());
      async.flushMicrotasks();

      expect(sup.userRequestedDisconnect, isFalse);
      expect(sup.state.value, Obd2LinkState.ready);
      unawaited(sup.dispose());
      async.flushMicrotasks();
    });
  });

  test('disconnect during an in-flight auto-dial releases the fresh link',
      () {
    fakeAsync((async) {
      // A dialer we can hold open mid-flight.
      final gate = Completer<Obd2Service?>();
      var released = false;
      final transport = FakeObd2Transport();
      final service = Obd2Service(transport);
      final sup = Obd2LinkSupervisor(
        dial: () => gate.future,
        drops: drops.stream,
        jitter: Random(42),
      );

      drops.add(const Obd2LinkDropEvent(
          transportKind: 'classic', reason: 'socket-error'));
      async.flushMicrotasks();
      expect(sup.state.value, Obd2LinkState.reconnecting);

      unawaited(sup.disconnect()); // user parks it mid-dial
      async.flushMicrotasks();
      // The dial completes AFTER the user's intent was recorded.
      unawaited(transport.connect());
      async.flushMicrotasks();
      gate.complete(service);
      async.flushMicrotasks();
      released = !transport.isConnected;

      expect(sup.state.value, Obd2LinkState.userDisconnected);
      expect(sup.service, isNull);
      expect(released, isTrue,
          reason: 'the unwanted fresh link must be torn down, not leaked');
      unawaited(sup.dispose());
      async.flushMicrotasks();
    });
  });

  test('engineOff parks; wake() re-dials', () {
    fakeAsync((async) {
      dialer.enqueue(_liveService());
      final sup = build();

      sup.noteEngineOff();
      expect(sup.state.value, Obd2LinkState.engineOff);

      drops.add(const Obd2LinkDropEvent(
          transportKind: 'classic', reason: 'socket-done'));
      async.elapse(const Duration(seconds: 30));
      expect(dialer.calls, 0, reason: 'engine off ⇒ no dialing');

      sup.wake();
      async.flushMicrotasks();
      expect(sup.state.value, Obd2LinkState.ready);
      unawaited(sup.dispose());
      async.flushMicrotasks();
    });
  });

  test('single flight: concurrent connects share one dial', () {
    fakeAsync((async) {
      final gate = Completer<Obd2Service?>();
      var dials = 0;
      final sup = Obd2LinkSupervisor(
        dial: () {
          dials++;
          return gate.future;
        },
        drops: drops.stream,
        jitter: Random(42),
      );

      unawaited(sup.connect());
      unawaited(sup.connect());
      drops.add(const Obd2LinkDropEvent(
          transportKind: 'ble', reason: 'disconnect-edge'));
      async.flushMicrotasks();

      expect(dials, 1, reason: 'everything joins the one in-flight dial');
      gate.complete(_liveService());
      async.flushMicrotasks();
      expect(sup.state.value, Obd2LinkState.ready);
      unawaited(sup.dispose());
      async.flushMicrotasks();
    });
  });

  test('a dial FAULT (not just a miss) also feeds the backoff loop', () {
    fakeAsync((async) {
      dialer.enqueue(StateError('rfcomm refused'));
      final sup = build();

      drops.add(const Obd2LinkDropEvent(
          transportKind: 'classic', reason: 'socket-error'));
      async.flushMicrotasks();
      expect(sup.state.value, Obd2LinkState.reconnecting);

      dialer.enqueue(_liveService());
      async.elapse(const Duration(seconds: 2));

      expect(sup.state.value, Obd2LinkState.ready,
          reason: 'fault → backoff → next attempt succeeds');
      unawaited(sup.dispose());
      async.flushMicrotasks();
    });
  });
}
