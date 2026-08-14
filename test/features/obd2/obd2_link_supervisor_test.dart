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

/// #3676 — a transport whose commands never complete (a wedged ELM):
/// exercises the ATZ bound in [Obd2LinkSupervisor.resetLink].
class _NeverAnsweringTransport extends FakeObd2Transport {
  @override
  Future<String> sendCommand(String cmd) {
    sentCommands.add(cmd);
    return Completer<String>().future;
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

      // #3603 / #3642 / #3699 — three identical misses stand the loop
      // down, and consecutive holds ESCALATE (5 → 15 min, capped at 15
      // since #3699: the 60-min cap blinded engine starts); the
      // INVARIANT under test is unchanged: no dead end, ever.
      // 40 min = ladder (~0) + 5-min hold + 15-min hold + a second
      // 15-min hold (+ jitter) — 6 dials.
      async.elapse(const Duration(minutes: 40));
      expect(dialer.calls, 6,
          reason: 'fast ladder ×3, then the 5 min hold and two capped '
              '15 min holds');
      expect(sup.state.value, Obd2LinkState.reconnecting,
          reason: 'no dead end — still trying');

      // The escalated cadence parks at ≤15-min periods — steady, never
      // terminal.
      async.elapse(const Duration(minutes: 55));
      expect(dialer.calls, greaterThanOrEqualTo(9),
          reason: 'the capped 15-min hold keeps dialing — the loop must '
              'outlive the old terminalFailed cap');

      // And when the adapter finally reappears, the loop connects. The
      // queued miss still in front costs one more capped hold, so two
      // full 15-min periods (+ jitter) must pass.
      dialer.enqueue(_liveService());
      async.elapse(const Duration(minutes: 40));
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

  test(
      'connectWith joining a MISSED in-flight dial still dials its own '
      'target afterwards — the override is never swallowed (#3553)', () {
    fakeAsync((async) {
      final gate = Completer<Obd2Service?>();
      var defaultDials = 0;
      final sup = Obd2LinkSupervisor(
        dial: () {
          defaultDials++;
          return gate.future;
        },
        drops: drops.stream,
        jitter: Random(42),
      );
      // The backoff loop dials (the stale last-good adapter) and hangs.
      drops.add(const Obd2LinkDropEvent(
          transportKind: 'classic', reason: 'socket-error'));
      async.flushMicrotasks();
      expect(defaultDials, 1);

      // Auto-record dials the ACTIVE vehicle's (different) adapter.
      var overrideDials = 0;
      final live = _liveService();
      Obd2Service? got;
      unawaited(sup.connectWith(() async {
        overrideDials++;
        return live;
      }).then((s) => got = s));
      async.flushMicrotasks();
      expect(overrideDials, 0,
          reason: 'never two concurrent dials — the override waits');

      gate.complete(null); // the stale-target dial MISSES
      async.flushMicrotasks();
      expect(overrideDials, 1,
          reason: 'the override dial must run right after the miss');
      expect(identical(got, live), isTrue,
          reason: 'the caller gets ITS OWN dial result, not the miss');
      expect(sup.state.value, Obd2LinkState.ready);
      unawaited(sup.dispose());
      async.flushMicrotasks();
    });
  });

  test(
      'connectWith joining an in-flight dial that SUCCEEDS returns the '
      'live link without a second dial (#3553 — one link satisfies all)',
      () {
    fakeAsync((async) {
      final gate = Completer<Obd2Service?>();
      final sup = Obd2LinkSupervisor(
        dial: () => gate.future,
        drops: drops.stream,
        jitter: Random(42),
      );
      drops.add(const Obd2LinkDropEvent(
          transportKind: 'classic', reason: 'socket-error'));
      async.flushMicrotasks();

      var overrideDials = 0;
      Obd2Service? got;
      unawaited(sup.connectWith(() async {
        overrideDials++;
        return _liveService();
      }).then((s) => got = s));
      async.flushMicrotasks();

      final live = _liveService();
      gate.complete(live);
      async.flushMicrotasks();
      expect(overrideDials, 0,
          reason: 'a live link from the in-flight dial satisfies everyone');
      expect(identical(got, live), isTrue);
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

  group('resetLink — user-initiated hard reset (#3676)', () {
    test('sends ATZ to the LIVE adapter, recycles it, and adopts a fresh '
        'dial', () {
      fakeAsync((async) {
        final firstTransport = FakeObd2Transport();
        unawaited(firstTransport.connect()); // a LIVE link takes commands
        final first = Obd2Service(firstTransport);
        final second = _liveService();
        dialer.enqueue(first);
        dialer.enqueue(second);
        final sup = build();

        unawaited(sup.connect());
        async.flushMicrotasks();
        expect(sup.service, same(first));

        Obd2Service? redialed;
        unawaited(sup.resetLink().then((s) => redialed = s));
        async.flushMicrotasks();

        expect(firstTransport.sentCommands, contains('ATZ'),
            reason: 'the chip reset must reach the dongle before the '
                'recycle tears the socket down');
        expect(firstTransport.isConnected, isFalse,
            reason: 'the old link is fully recycled (fresh socket rule)');
        expect(redialed, same(second));
        expect(sup.state.value, Obd2LinkState.ready);
        unawaited(sup.dispose());
        async.flushMicrotasks();
      });
    });

    test('with NO live link the ATZ step is skipped and the reset is just '
        'a fresh user dial (also usable from the userDisconnected park)',
        () {
      fakeAsync((async) {
        dialer.enqueue(_liveService());
        final sup = build();
        expect(sup.state.value, Obd2LinkState.idle);

        Obd2Service? redialed;
        unawaited(sup.resetLink().then((s) => redialed = s));
        async.flushMicrotasks();
        expect(redialed, isNotNull);
        expect(sup.state.value, Obd2LinkState.ready);
        unawaited(sup.dispose());
        async.flushMicrotasks();
      });
    });

    test('a WEDGED adapter that never answers ATZ cannot stall the reset '
        '— the 4 s bound fires and the redial still runs', () {
      fakeAsync((async) {
        final wedged = Obd2Service(_NeverAnsweringTransport());
        final fresh = _liveService();
        dialer.enqueue(wedged);
        dialer.enqueue(fresh);
        final sup = build();
        unawaited(sup.connect());
        async.flushMicrotasks();
        expect(sup.service, same(wedged));

        Obd2Service? redialed;
        unawaited(sup.resetLink().then((s) => redialed = s));
        async.elapse(const Duration(seconds: 5)); // past the ATZ bound
        async.flushMicrotasks();
        expect(redialed, same(fresh),
            reason: 'the ATZ timeout is swallowed; the recycle+redial is '
                'the real reset');
        unawaited(sup.dispose());
        async.flushMicrotasks();
      });
    });
  });

}
