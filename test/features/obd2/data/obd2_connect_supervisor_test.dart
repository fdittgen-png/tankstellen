// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/obd2_connect_supervisor.dart';
import 'package:tankstellen/features/obd2/data/obd2_connect_trace.dart';
import 'package:tankstellen/features/obd2/data/obd2_connect_trace_log.dart';

/// #3185 — unit tests for the single-flight connect-admission state machine.
/// Pure-Dart: attempts are completer-gated closures, the preempt grace runs
/// on an injected wait, nothing sleeps for real.
void main() {
  setUp(Obd2ConnectTraceLog.clear);
  tearDown(Obd2ConnectTraceLog.clear);

  /// Let queued microtasks/timers of the supervisor run.
  Future<void> pump() => Future<void>.delayed(Duration.zero);

  group('single-flight admission (#3185)', () {
    test('a second ACTIVE attempt queues — bodies never overlap', () async {
      final sup = Obd2ConnectSupervisor();
      final firstGate = Completer<void>();
      var firstRunning = false;
      var secondStarted = false;

      final f1 = sup.admit<String>(
        owner: 'one',
        attempt: () async {
          firstRunning = true;
          await firstGate.future;
          firstRunning = false;
          return 'one';
        },
      );
      await pump();
      expect(firstRunning, isTrue);
      expect(sup.state, Obd2SupervisorState.active);
      expect(sup.currentOwner, 'one');

      final f2 = sup.admit<String>(
        owner: 'two',
        attempt: () async {
          // The pre-#3185 race: a second entrant ran its scan-stop/teardown
          // while the first was mid-handshake. Single-flight means this body
          // must only ever run once the first fully completed.
          expect(firstRunning, isFalse,
              reason: 'second attempt must not overlap the first');
          secondStarted = true;
          return 'two';
        },
      );
      await pump();
      expect(secondStarted, isFalse, reason: 'second attempt must wait');
      expect(sup.queuedCount, 1);

      firstGate.complete();
      expect(await f1, 'one');
      expect(await f2, 'two');
      expect(secondStarted, isTrue);
      expect(sup.state, Obd2SupervisorState.idle);
    });

    test('queued attempts run FIFO', () async {
      final sup = Obd2ConnectSupervisor();
      final order = <String>[];
      final gate = Completer<void>();
      final f1 = sup.admit<void>(
        owner: 'a',
        attempt: () async {
          await gate.future;
          order.add('a');
        },
      );
      await pump();
      final f2 =
          sup.admit<void>(owner: 'b', attempt: () async => order.add('b'));
      final f3 =
          sup.admit<void>(owner: 'c', attempt: () async => order.add('c'));
      await pump();
      gate.complete();
      await Future.wait([f1, f2, f3]);
      expect(order, ['a', 'b', 'c']);
    });

    test('re-entrant nested admit runs INLINE (no self-deadlock) — the '
        'direct→scan-fallback→connect chain stays one admission', () async {
      final sup = Obd2ConnectSupervisor();
      final result = await sup.admit<String>(
        owner: 'outer',
        attempt: () async {
          // Nested public-method re-entry inside the same logical attempt.
          final inner = await sup.admit<String>(
            owner: 'inner',
            attempt: () async => 'inner-ran',
          );
          return 'outer:$inner';
        },
      ).timeout(const Duration(seconds: 5));
      expect(result, 'outer:inner-ran');
      expect(sup.state, Obd2SupervisorState.idle);
    });

    test('FAULT INJECTION — a throwing attempt releases the slot: the error '
        'propagates unchanged and the next requester still runs', () async {
      final sup = Obd2ConnectSupervisor();
      await expectLater(
        sup.admit<void>(
          owner: 'boom',
          attempt: () async => throw StateError('injected fault'),
        ),
        throwsA(isA<StateError>()),
      );
      expect(sup.state, Obd2SupervisorState.idle);
      // The slot must not be wedged: the next admit completes normally.
      await expectLater(
        sup.admit<String>(owner: 'next', attempt: () async => 'ok'),
        completion('ok'),
      );
    });

    test('a STALE zone token (work leaked from a finished attempt) does NOT '
        'bypass admission — it queues like any requester', () async {
      final sup = Obd2ConnectSupervisor();
      late Future<String> Function() leaked;
      await sup.admit<void>(
        owner: 'first',
        attempt: () async {
          // Capture a closure that will run AFTER this admission released.
          leaked = () =>
              sup.admit<String>(owner: 'leak', attempt: () async => 'leaked');
        },
      );
      // A new holder takes the slot…
      final gate = Completer<void>();
      final holder = sup.admit<void>(
        owner: 'holder',
        attempt: () => gate.future,
      );
      await pump();
      // …so the leaked closure must WAIT, not run inline off its dead token.
      var leakedDone = false;
      final leakedFuture = leaked().then((v) {
        leakedDone = true;
        return v;
      });
      await pump();
      expect(leakedDone, isFalse,
          reason: 'stale admission token must not grant inline access');
      gate.complete();
      await holder;
      expect(await leakedFuture, 'leaked');
    });
  });

  group('passive admission + preemption (#3185)', () {
    test('passive try-acquire SKIPS (returns null, attempt not run) while an '
        'active attempt is in flight', () async {
      final sup = Obd2ConnectSupervisor();
      final gate = Completer<void>();
      final active = sup.admit<void>(owner: 'active', attempt: () => gate.future);
      await pump();
      var passiveRan = false;
      final result = await sup.admitPassive<String>(
        owner: 'passive',
        onPreempt: () async {},
        attempt: () async {
          passiveRan = true;
          return 'never';
        },
      );
      expect(result, isNull);
      expect(passiveRan, isFalse);
      gate.complete();
      await active;
    });

    test('an arriving ACTIVE requester preempts the passive holder: '
        'onPreempt fires, the passive unwinds, the active runs', () async {
      final sup = Obd2ConnectSupervisor();
      final passiveWait = Completer<String?>();
      var preempted = false;

      final passive = sup.admitPassive<String>(
        owner: 'passive',
        // The production preempt closes the passive channel, which unwinds
        // the unbounded autoConnect wait — modelled by completing it null.
        onPreempt: () async {
          preempted = true;
          passiveWait.complete(null);
        },
        attempt: () => passiveWait.future,
      );
      await pump();
      expect(sup.state, Obd2SupervisorState.passive);

      final active =
          sup.admit<String>(owner: 'user-connect', attempt: () async => 'ok');
      await pump();
      expect(preempted, isTrue);
      expect(await passive, isNull);
      expect(await active.timeout(const Duration(seconds: 5)), 'ok');
      expect(sup.state, Obd2SupervisorState.idle);
    });

    test('a passive holder that IGNORES preemption is force-released after '
        'the bounded grace — the active proceeds, the zombie unwind no-ops',
        () async {
      final grace = Completer<void>();
      final sup = Obd2ConnectSupervisor(wait: (_) => grace.future);
      final stuck = Completer<String?>();

      final passive = sup.admitPassive<String>(
        owner: 'zombie',
        onPreempt: () async {}, // ignores the teardown request
        attempt: () => stuck.future,
      );
      await pump();

      final active =
          sup.admit<String>(owner: 'user-connect', attempt: () async => 'ok');
      await pump();
      expect(sup.state, Obd2SupervisorState.draining);

      grace.complete(); // the grace elapses; the slot is force-released
      expect(await active.timeout(const Duration(seconds: 5)), 'ok');

      // The zombie finally unwinds — its late release must not corrupt the
      // machine: a third attempt still admits normally.
      stuck.complete('late');
      expect(await passive, 'late');
      await expectLater(
        sup.admit<String>(owner: 'third', attempt: () async => 'fine'),
        completion('fine'),
      );
      expect(sup.state, Obd2SupervisorState.idle);
    });

    test('FAULT INJECTION — a THROWING onPreempt is contained: the grace '
        'hand-off still releases the slot to the active requester', () async {
      final grace = Completer<void>();
      final sup = Obd2ConnectSupervisor(wait: (_) => grace.future);
      final stuck = Completer<String?>();
      unawaited(sup.admitPassive<String>(
        owner: 'zombie',
        onPreempt: () async => throw StateError('teardown fault'),
        attempt: () => stuck.future,
      ));
      await pump();
      final active =
          sup.admit<String>(owner: 'user-connect', attempt: () async => 'ok');
      await pump();
      grace.complete();
      expect(await active.timeout(const Duration(seconds: 5)), 'ok');
      stuck.complete(null);
    });
  });

  group('admission-wait visibility (#3185)', () {
    test('a requester that WAITED leaves a one-shot note that the next ROOT '
        'trace records as a supervisor-admission step', () async {
      final sup = Obd2ConnectSupervisor();
      final gate = Completer<void>();
      final holder = sup.admit<void>(owner: 'holder', attempt: () => gate.future);
      await pump();
      final waiter = sup.admit<void>(
        owner: 'waiter',
        attempt: () async {
          // The attempt opens its trace AFTER admission, like every public
          // connect entry does.
          final trace = Obd2ConnectTraceLog.beginTrace(
              origin: Obd2ConnectOrigin.firstConnect, mac: 'aa:bb');
          trace.setOutcome(Obd2ConnectOutcome.success);
          Obd2ConnectTraceLog.endTrace(trace);
        },
      );
      await pump();
      gate.complete();
      await Future.wait([holder, waiter]);

      final trace = Obd2ConnectTraceLog.snapshot().first;
      final step = trace.steps
          .firstWhere((s) => s.label == 'supervisor-admission');
      expect(step.detail, contains('"waiter"'));
      expect(step.detail, contains('"holder"'));
      expect(Obd2ConnectTraceLog.pendingAdmissionNote, isNull,
          reason: 'the note is one-shot — consumed by the root trace');
    });

    test('an attempt admitted IMMEDIATELY leaves no admission note', () async {
      final sup = Obd2ConnectSupervisor();
      await sup.admit<void>(owner: 'solo', attempt: () async {});
      expect(Obd2ConnectTraceLog.pendingAdmissionNote, isNull);
    });
  });
}
