// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3603 — reconnect stand-down. Field storm: 20 consecutive
// liveReconnect rfcommOpenFail timeouts over 21 minutes, each burning
// the full 23 s ladder budget at ~70 s cadence, with no escalation —
// the per-attempt bound (#3421) held but nothing above it stood down.
// And the #3625 blind spot: a success that proves nothing (drops again
// within seconds) reset the escalation forever. After
// [standDownThreshold] identical-signature misses OR rapid ready→drop
// flaps, the loop must hold [stormBackoff] instead of the fast ladder —
// while still never self-terminating (the #3527 no-dead-end invariant).
import 'dart:async';
import 'dart:math';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/obd2_link_drop_signal.dart';
import 'package:tankstellen/features/obd2/data/obd2_link_supervisor.dart';
import 'package:tankstellen/features/obd2/data/obd2_service.dart';
import 'package:tankstellen/features/obd2/data/obd2_transport.dart';

Obd2Service _liveService() => Obd2Service(FakeObd2Transport());

/// Scripted dialer (same shape as obd2_link_supervisor_test): pops
/// outcomes off a queue; an empty queue keeps returning the last one.
class _ScriptedDialer {
  final List<Object?> _script = [];
  int calls = 0;

  void enqueue(Object? outcome) => _script.add(outcome);

  /// Drops whatever the queue still holds (incl. the sticky last
  /// outcome) and scripts [outcome] from the next dial on.
  void replaceAll(Object? outcome) => _script
    ..clear()
    ..add(outcome);

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

  // Manual clock advanced in lockstep with fakeAsync elapse — inside
  // fakeAsync a raw DateTime.now() would not move with the timers.
  late DateTime nowValue;
  void elapse(FakeAsync async, Duration d) {
    nowValue = nowValue.add(d);
    async.elapse(d);
  }

  const storm = Duration(minutes: 5);

  Obd2LinkSupervisor build() => Obd2LinkSupervisor(
        dial: dialer.dial,
        drops: drops.stream,
        initialBackoff: const Duration(milliseconds: 500),
        maxBackoff: const Duration(seconds: 30),
        stormBackoff: storm,
        jitter: Random(42),
        now: () => nowValue,
      );

  setUp(() {
    drops = StreamController<Obd2LinkDropEvent>.broadcast();
    dialer = _ScriptedDialer();
    nowValue = DateTime(2026, 7, 24, 18, 14);
  });

  tearDown(() => drops.close());

  void dropNow() => drops.add(const Obd2LinkDropEvent(
      transportKind: 'classic', reason: 'socket-error'));

  test('three identical-signature faults stand the loop down to the '
      'storm cadence — the 21-minute field storm shape', () {
    fakeAsync((async) {
      dialer.enqueue(TimeoutException('classic connect exceeded the '
          'whole-ladder budget'));
      final sup = build();

      dropNow();
      async.flushMicrotasks();
      expect(dialer.calls, 1, reason: 'first drop dials immediately');
      expect(sup.inStandDown, isFalse);

      // Two more misses ride the fast ladder (0.5 s, 1 s + jitter).
      elapse(async, const Duration(seconds: 3));
      expect(dialer.calls, 3);
      expect(sup.inStandDown, isTrue,
          reason: 'the third identical TimeoutException is the storm '
              'signature');
      expect(sup.currentBackoffMs, storm.inMilliseconds,
          reason: 'stand-down jumps straight to the storm cadence');

      // The fast ladder would have fired ~5 more times in 2 minutes;
      // the stand-down holds.
      elapse(async, const Duration(minutes: 2));
      expect(dialer.calls, 3,
          reason: 'no dial inside the storm hold');

      // The no-dead-end invariant: the loop still retries eventually.
      elapse(async, const Duration(minutes: 4));
      expect(dialer.calls, 4,
          reason: 'the storm tick still dials — never self-terminates');

      unawaited(sup.dispose());
      async.flushMicrotasks();
    });
  });

  test('a signature CHANGE resets the streak — alternating failures keep '
      'the fast ladder', () {
    fakeAsync((async) {
      // Alternating timeout / clean-miss: no signature ever repeats
      // three times.
      dialer.enqueue(TimeoutException('ladder budget'));
      dialer.enqueue(null);
      dialer.enqueue(TimeoutException('ladder budget'));
      dialer.enqueue(null);
      final sup = build();

      dropNow();
      async.flushMicrotasks();
      // The fast ladder fires attempts 2-4 within ~4 s (0.5/1/2 s +
      // jitter); attempt 5 would come at ~5.7 s earliest.
      elapse(async, const Duration(seconds: 4));
      expect(dialer.calls, 4);
      expect(sup.inStandDown, isFalse,
          reason: 'alternating signatures: no streak of three '
              'identical failures ever formed');

      unawaited(sup.dispose());
      async.flushMicrotasks();
    });
  });

  test('three rapid ready→drop flaps stand down; the next drop does NOT '
      'redial instantly (#3625 blind spot)', () {
    fakeAsync((async) {
      dialer.enqueue(_liveService());
      final sup = build();
      unawaited(sup.connect());
      async.flushMicrotasks();
      expect(sup.state.value, Obd2LinkState.ready);

      // Three connect→drop cycles, each dying ~2 s after ready — the
      // dial itself always "succeeds" (fresh service every time).
      for (var i = 0; i < 3; i++) {
        dialer.enqueue(_liveService());
        elapse(async, const Duration(seconds: 2));
        dropNow();
        async.flushMicrotasks();
      }
      // Flap 1 and 2 redialed instantly (state is ready again); the
      // THIRD flap crossed the threshold: the loop is parked on the
      // storm timer, not ready.
      expect(sup.inStandDown, isTrue);
      expect(sup.state.value, Obd2LinkState.reconnecting,
          reason: 'the instant redial after flap 3 is what burned 20 '
              'field cycles — the loop must hold instead');
      final callsAtStandDown = dialer.calls;

      elapse(async, const Duration(minutes: 2));
      expect(dialer.calls, callsAtStandDown,
          reason: 'no dial inside the storm hold');

      unawaited(sup.dispose());
      async.flushMicrotasks();
    });
  });

  test('a ready that SURVIVES the flap window clears the streak', () {
    fakeAsync((async) {
      dialer.enqueue(_liveService());
      final sup = build();
      unawaited(sup.connect());
      async.flushMicrotasks();

      // Two flaps…
      for (var i = 0; i < 2; i++) {
        dialer.enqueue(_liveService());
        elapse(async, const Duration(seconds: 2));
        dropNow();
        async.flushMicrotasks();
      }
      // …then a ready that lives past the 30 s window before dropping.
      dialer.enqueue(_liveService());
      elapse(async, const Duration(seconds: 45));
      dropNow();
      async.flushMicrotasks();

      expect(sup.inStandDown, isFalse,
          reason: 'the durable ready proved the link works — streak '
              'cleared, fast ladder restored');
      expect(sup.state.value, Obd2LinkState.ready,
          reason: 'the drop after the durable ready redialed instantly');

      unawaited(sup.dispose());
      async.flushMicrotasks();
    });
  });

  test('#3642/#3699 consecutive storm holds ESCALATE 5 → 15 min and CAP '
      'at 15 — a parked car stops hammering, but an engine start is never '
      'more than one hold away', () {
    fakeAsync((async) {
      dialer.enqueue(TimeoutException('ladder budget'));
      final sup = build();
      dropNow();
      async.flushMicrotasks();
      elapse(async, const Duration(seconds: 3));
      expect(sup.inStandDown, isTrue);
      expect(dialer.calls, 3);

      // Hold 1: storm ×1 (5 min + ≤37 s jitter).
      elapse(async, const Duration(minutes: 6));
      expect(dialer.calls, 4, reason: 'first storm hold is 5 min');

      // Hold 2: storm ×3 (15 min + ≤112 s jitter) — a 5-min cadence
      // would have dialed twice more by 13 min.
      elapse(async, const Duration(minutes: 13));
      expect(dialer.calls, 4, reason: 'second hold escalated past 13 min');
      elapse(async, const Duration(minutes: 4));
      expect(dialer.calls, 5, reason: 'second storm hold is 15 min');

      // Hold 3: STILL ×3 — #3699 capped the ×12 (60 min) step: overnight
      // holds past an hour left the morning drive without hands-free
      // connect for the whole hold (2026-08-11 field log).
      elapse(async, const Duration(minutes: 13));
      expect(dialer.calls, 5, reason: 'third hold escalated past 13 min');
      elapse(async, const Duration(minutes: 4));
      expect(dialer.calls, 6,
          reason: 'the no-dead-end invariant survives the escalation — '
              'the loop still dials every ≤15 min (#3699 cap)');

      // A user connect resets the escalation back to the fast ladder.
      dialer.replaceAll(_liveService());
      unawaited(sup.connect());
      async.flushMicrotasks();
      expect(sup.inStandDown, isFalse);
      expect(sup.state.value, Obd2LinkState.ready);

      unawaited(sup.dispose());
      async.flushMicrotasks();
    });
  });

  test('#3642 an AUTOMATED connectWith during a stand-down neither dials '
      'nor resets the hold — automation is not user intent', () {
    fakeAsync((async) {
      dialer.enqueue(TimeoutException('ladder budget'));
      final sup = build();
      dropNow();
      async.flushMicrotasks();
      elapse(async, const Duration(seconds: 3));
      expect(sup.inStandDown, isTrue);
      final callsBefore = dialer.calls;

      var overrideCalls = 0;
      Obd2Service? got = _liveService(); // sentinel — must become null
      unawaited(sup.connectWith(() async {
        overrideCalls++;
        return _liveService();
      }, automated: true).then((s) => got = s));
      async.flushMicrotasks();

      expect(overrideCalls, 0,
          reason: 'the 36 ms instant redial from the 2026-07-29 field '
              'export — an automated arm must not dial into the hold');
      expect(dialer.calls, callsBefore);
      expect(got, isNull, reason: 'the caller sees a plain miss');
      expect(sup.inStandDown, isTrue,
          reason: 'the stand-down accounting survives the automated arm');

      // The supervisor's own storm timer keeps ownership of the cadence.
      elapse(async, const Duration(minutes: 6));
      expect(dialer.calls, callsBefore + 1,
          reason: 'the held dial still fires, with the DEFAULT dialer');

      unawaited(sup.dispose());
      async.flushMicrotasks();
    });
  });

  test('#3642 an automated connectWith OUTSIDE a stand-down dials through '
      'the normal single-flight machinery', () {
    fakeAsync((async) {
      dialer.enqueue(null);
      final sup = build();

      var overrideCalls = 0;
      Obd2Service? got;
      unawaited(sup.connectWith(() async {
        overrideCalls++;
        return _liveService();
      }, automated: true).then((s) => got = s));
      async.flushMicrotasks();

      expect(overrideCalls, 1);
      expect(got, isNotNull);
      expect(sup.state.value, Obd2LinkState.ready);

      unawaited(sup.dispose());
      async.flushMicrotasks();
    });
  });

  test('#3642 wake() breaks an active stand-down hold — sustained movement '
      'must not wait out an escalated timer', () {
    fakeAsync((async) {
      dialer.enqueue(TimeoutException('ladder budget'));
      final sup = build();
      dropNow();
      async.flushMicrotasks();
      elapse(async, const Duration(seconds: 3));
      expect(sup.inStandDown, isTrue);
      final callsBefore = dialer.calls;

      // The car drives off: the GPS movement nudge fires wake().
      dialer.replaceAll(_liveService());
      sup.wake();
      async.flushMicrotasks();
      expect(dialer.calls, callsBefore + 1,
          reason: 'movement dials immediately instead of holding');
      expect(sup.inStandDown, isFalse);
      expect(sup.state.value, Obd2LinkState.ready);

      unawaited(sup.dispose());
      async.flushMicrotasks();
    });
  });

  test('user connect() exits the stand-down and dials immediately', () {
    fakeAsync((async) {
      dialer.enqueue(TimeoutException('ladder budget'));
      final sup = build();
      dropNow();
      async.flushMicrotasks();
      elapse(async, const Duration(seconds: 3));
      expect(sup.inStandDown, isTrue);
      final callsBefore = dialer.calls;

      dialer.replaceAll(_liveService());
      unawaited(sup.connect());
      async.flushMicrotasks();
      expect(dialer.calls, callsBefore + 1,
          reason: 'user intent bypasses the storm hold');
      expect(sup.inStandDown, isFalse);
      expect(sup.state.value, Obd2LinkState.ready);

      unawaited(sup.dispose());
      async.flushMicrotasks();
    });
  });
}
