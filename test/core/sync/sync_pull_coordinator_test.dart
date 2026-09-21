// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sync/sync_pull_coordinator.dart';
import 'package:tankstellen/core/sync/sync_pull_lease.dart';

import '../../helpers/silence_error_logger.dart';

/// #3450 — the coordinator's two load-bearing properties:
///
///  1. one failing / hung table never blocks the others (per-entry
///     timeout + per-entry catch);
///  2. the pass runs in parallel — wall-clock ≈ the SLOWEST pull, not the
///     sum (pinned with fake latency under fakeAsync).
void main() {
  silenceErrorLoggerSpool();

  final coordinator = SyncPullCoordinator.instance;

  setUp(coordinator.resetForTest);
  tearDown(coordinator.resetForTest);

  SyncPullEntry entry(
    String table, {
    Duration latency = Duration.zero,
    Duration timeout = const Duration(seconds: 15),
    Object? throwing,
    void Function()? onDone,
    int pulled = 1,
  }) =>
      SyncPullEntry(
        tables: [table],
        timeout: timeout,
        pull: () async {
          if (latency > Duration.zero) {
            await Future<void>.delayed(latency);
          }
          if (throwing != null) throw throwing; // ignore: only_throw_errors
          onDone?.call();
          return pulled;
        },
      );

  test('one table failing never blocks the others (and pullAll itself '
      'completes normally — the never-throws contract)', () async {
    final completed = <String>[];
    coordinator.register(enabled: () => true, entries: [
      entry('a', onDone: () => completed.add('a')),
      entry('boom', throwing: StateError('server 500')),
      entry('b', onDone: () => completed.add('b')),
    ]);

    await expectLater(coordinator.pullAll(), completes);

    expect(completed, containsAll(['a', 'b']),
        reason: 'a failing pull is isolated — the rest must complete');
    expect(coordinator.lastCompletedAt, isNotNull,
        reason: 'the pass completes despite the failure');
  });

  test('one HUNG table times out on its own budget; the others complete',
      () {
    fakeAsync((async) {
      final completed = <String>[];
      var passDone = false;
      coordinator.register(enabled: () => true, entries: [
        entry('fast', onDone: () => completed.add('fast')),
        // Never completes within its 15 s budget.
        entry('hung',
            latency: const Duration(minutes: 10),
            onDone: () => completed.add('hung')),
      ]);

      unawaited(coordinator.pullAll().then((_) => passDone = true));
      async.elapse(const Duration(seconds: 16));

      expect(completed, ['fast']);
      expect(passDone, isTrue,
          reason: 'the hung pull is released by its per-table timeout — '
              'the whole pass must not hang');
    });
  });

  test('wall-clock ≈ the slowest pull, not the sum (#3450 parallelism)',
      () {
    fakeAsync((async) {
      var done = false;
      coordinator.register(enabled: () => true, entries: [
        entry('a', latency: const Duration(seconds: 4)),
        entry('b', latency: const Duration(seconds: 4)),
        entry('c', latency: const Duration(seconds: 4)),
        entry('d', latency: const Duration(seconds: 4)),
      ]);

      unawaited(coordinator.pullAll().then((_) => done = true));

      // Serial execution would need 16 s; parallel needs ~4 s.
      async.elapse(const Duration(seconds: 5));
      expect(done, isTrue,
          reason: '4 pulls of 4 s each must finish in ~4 s (parallel), '
              'not 16 s (serial)');
    });
  });

  test('master gate off / empty registry → no-op, no completion stamp',
      () async {
    await coordinator.pullAll(); // nothing registered
    expect(coordinator.lastCompletedAt, isNull);

    var ran = false;
    coordinator.register(enabled: () => false, entries: [
      entry('a', onDone: () => ran = true),
    ]);
    await coordinator.pullAll();
    expect(ran, isFalse);
    expect(coordinator.lastCompletedAt, isNull);
  });

  test('re-registration replaces (never duplicates) the entries', () async {
    var calls = 0;
    List<SyncPullEntry> entries() =>
        [entry('a', onDone: () => calls++)];
    coordinator.register(enabled: () => true, entries: entries());
    coordinator.register(enabled: () => true, entries: entries());

    await coordinator.pullAll();

    expect(calls, 1, reason: 'double registration must not double-pull');
    expect(coordinator.coveredTables, {'a'});
  });

  test('lastCompletedAt stamps only after a completed pass', () async {
    final stamped = DateTime(2026, 7, 3, 12);
    coordinator.register(enabled: () => true, entries: [entry('a')]);

    await coordinator.pullAll(now: () => stamped);

    expect(coordinator.lastCompletedAt, stamped);
  });

  group('#4112 — a timed-out pull warns first and escalates only when it '
      'persists', () {
    test('consecutive timed-out passes escalate; one success clears the '
        'board', () {
      var alwaysHangs = true;
      SyncPullEntry hanging() => SyncPullEntry(
            tables: const ['favorites'],
            timeout: const Duration(seconds: 15),
            pull: () async {
              if (alwaysHangs) {
                await Future<void>.delayed(const Duration(days: 1));
              }
              return 1;
            },
          );

      fakeAsync((async) {
        coordinator.register(enabled: () => true, entries: [hanging()]);
        for (var pass = 1; pass <= 3; pass++) {
          unawaited(coordinator.pullAll());
          async.elapse(const Duration(seconds: 20));
          expect(coordinator.consecutiveTimeoutsFor(const ['favorites']), pass);
        }
        // Below the threshold a timeout is a warning; at it, an error.
        // That distinction is the whole fix: a single failed PULL costs
        // the user nothing (the local data is intact and the next pass
        // catches up), so reporting the first one at error level put it
        // in the same bucket as a corrupted box.
        expect(SyncPullCoordinator.timeoutsBeforeError, 3);

        alwaysHangs = false;
        unawaited(coordinator.pullAll());
        async.elapse(const Duration(seconds: 20));
        expect(coordinator.consecutiveTimeoutsFor(const ['favorites']), 0,
            reason: 'one successful pass means the tables are converging '
                'again');
      });
    });

    test('a hung table still costs its OWN budget and no more — there is '
        'no in-pass retry doubling it', () {
      fakeAsync((async) {
        var passDone = false;
        coordinator.register(enabled: () => true, entries: [
          entry('hung', latency: const Duration(minutes: 10)),
        ]);
        unawaited(coordinator.pullAll().then((_) => passDone = true));
        async.elapse(const Duration(seconds: 16));
        expect(passDone, isTrue,
            reason: 'a retry seconds after a 15 s timeout on a slow link '
                'would have timed out too, and doubled every other '
                "table's wait for the pass to finish");
      });
    });

    test('an error is reported immediately — only TIMEOUTS are routine',
        () async {
      coordinator.register(enabled: () => true, entries: [
        entry('boom', throwing: StateError('schema mismatch')),
      ]);
      await coordinator.pullAll();
      expect(coordinator.consecutiveTimeoutsFor(const ['boom']), 0,
          reason: 'a server that answered with an error is not a timeout');
    });
  });


  group('#4162 — every pass records how it ended', () {
    test('gate closed, nothing registered, already running', () async {
      await coordinator.pullAll();
      expect(coordinator.lastOutcome, SyncPassOutcome.skippedNothingRegistered);

      coordinator.register(enabled: () => false, entries: [entry('a')]);
      await coordinator.pullAll();
      expect(coordinator.lastOutcome, SyncPassOutcome.skippedGateClosed);

      final release = Completer<void>();
      coordinator.register(enabled: () => true, entries: [
        SyncPullEntry(tables: const ['slow'], pull: () async {
          await release.future;
          return 0;
        }),
      ]);
      final first = coordinator.pullAll();
      await coordinator.pullAll();
      expect(coordinator.lastOutcome, SyncPassOutcome.skippedAlreadyRunning);
      release.complete();
      await first;
      expect(coordinator.lastOutcome, SyncPassOutcome.completed);
    });

    test('a timed-out entry makes the pass completedWithTimeouts', () async {
      coordinator.register(enabled: () => true, entries: [
        entry('a'),
        SyncPullEntry(
          tables: const ['hung'],
          timeout: const Duration(milliseconds: 10),
          pull: () => Completer<int>().future,
        ),
      ]);
      await coordinator.pullAll();
      expect(coordinator.lastOutcome, SyncPassOutcome.completedWithTimeouts);
    });

    test('a pass without a session — at its start or its end — is '
        'completedUnauthenticated and stamps nothing', () async {
      var session = false;
      coordinator.register(
        enabled: () => true,
        entries: [entry('a', onDone: () => session = false)],
        authenticated: () => session,
      );
      await coordinator.pullAll();
      expect(coordinator.lastOutcome, SyncPassOutcome.completedUnauthenticated);
      expect(coordinator.lastCompletedAt, isNull,
          reason: '#4338 — a pass that synced nothing never stamps');

      session = true;
      await coordinator.pullAll();
      expect(coordinator.lastOutcome, SyncPassOutcome.completedUnauthenticated,
          reason: 'the session was lost during the pass');
      expect(coordinator.lastCompletedAt, isNull);
    });

    test('a gate that throws records failed and still completes', () async {
      coordinator.register(
        enabled: () => throw StateError('container disposed'),
        entries: [entry('a')],
      );
      await expectLater(coordinator.pullAll(), completes);
      expect(coordinator.lastOutcome, SyncPassOutcome.failed);
    });
  });

  group('#4377 — a pull that outlives its timeout never writes', () {
    /// A pull shaped like every real one: the wire answers, then the
    /// result is checked against the pass's lease before it is persisted.
    /// [wire] is the network the test holds open.
    SyncPullEntry checked(
      Completer<int> wire, {
      required List<int> persisted,
      required List<Object> refused,
      required List<SyncPullLease?> leases,
    }) =>
        SyncPullEntry(
          tables: const ['favorites'],
          timeout: const Duration(seconds: 15),
          pull: () async {
            final lease = SyncPullLease.current;
            leases.add(lease);
            final rows = await wire.future;
            try {
              lease?.checkLive();
              persisted.add(rows);
            } catch (e) {
              refused.add(e);
            }
            return rows;
          },
        );

    test('the pass ends completedWithTimeouts; when the abandoned pull '
        'finally answers, its lease is dead, the result is refused and '
        'recorded, nothing is persisted', () {
      fakeAsync((async) {
        final wire = Completer<int>();
        final persisted = <int>[];
        final refused = <Object>[];
        final leases = <SyncPullLease?>[];
        coordinator.register(enabled: () => true, entries: [
          checked(wire,
              persisted: persisted, refused: refused, leases: leases),
        ]);

        unawaited(coordinator.pullAll());
        async.flushMicrotasks();
        expect(leases.single, isNotNull,
            reason: 'the pull runs with its pass lease as the ambient one');
        expect(leases.single!.isLive, isTrue);
        expect(leases.single!.generation, 1);

        async.elapse(const Duration(seconds: 16));
        expect(coordinator.lastOutcome, SyncPassOutcome.completedWithTimeouts);
        expect(coordinator.isRunning, isFalse);
        expect(leases.single!.isLive, isFalse,
            reason: 'the timeout retired the generation it abandoned');

        wire.complete(7);
        async.flushMicrotasks();
        expect(persisted, isEmpty,
            reason: 'the late answer belongs to a pass that already ended');
        expect(refused.single, isA<SyncPullAbandonedException>());
        expect(coordinator.discardedFor(const ['favorites']), 1);
        expect(coordinator.discardedLateResults, 1);
      });
    });

    test('the next pass runs the SAME table under a newer generation and '
        'persists; the abandoned one still cannot', () {
      fakeAsync((async) {
        final first = Completer<int>();
        final second = Completer<int>();
        var calls = 0;
        final persisted = <int>[];
        final refused = <Object>[];
        final leases = <SyncPullLease?>[];
        coordinator.register(enabled: () => true, entries: [
          SyncPullEntry(
            tables: const ['favorites'],
            timeout: const Duration(seconds: 15),
            pull: () async {
              final wire = ++calls == 1 ? first : second;
              final lease = SyncPullLease.current;
              leases.add(lease);
              final rows = await wire.future;
              try {
                lease?.checkLive();
                persisted.add(rows);
              } catch (e) {
                refused.add(e);
              }
              return rows;
            },
          ),
        ]);

        unawaited(coordinator.pullAll());
        async.elapse(const Duration(seconds: 16));
        expect(coordinator.lastOutcome, SyncPassOutcome.completedWithTimeouts);

        // The resume / "sync now" pass: both pulls are now in flight.
        unawaited(coordinator.pullAll());
        async.flushMicrotasks();
        expect(calls, 2);
        expect(leases[1]!.generation, greaterThan(leases[0]!.generation));
        expect(leases[1]!.isLive, isTrue);
        expect(leases[0]!.isLive, isFalse);

        // The wire answers the ABANDONED pull first, then the live one.
        first.complete(1);
        async.flushMicrotasks();
        second.complete(2);
        async.flushMicrotasks();

        expect(persisted, [2],
            reason: 'exactly one snapshot is persisted — the current '
                "pass's, never the abandoned one's");
        expect(refused, hasLength(1));
        expect(coordinator.lastOutcome, SyncPassOutcome.completed);
        expect(coordinator.discardedFor(const ['favorites']), 1);
      });
    });

    test('a pull that answers within its budget keeps its lease and is '
        'never refused', () async {
      final wire = Completer<int>()..complete(3);
      final persisted = <int>[];
      final refused = <Object>[];
      final leases = <SyncPullLease?>[];
      coordinator.register(enabled: () => true, entries: [
        checked(wire, persisted: persisted, refused: refused, leases: leases),
      ]);
      await coordinator.pullAll();
      expect(persisted, [3]);
      expect(refused, isEmpty);
      expect(coordinator.discardedLateResults, 0);
      expect(coordinator.lastOutcome, SyncPassOutcome.completed);
    });

    test('outside any pass there is no lease: a direct merge is never '
        'refused', () {
      expect(SyncPullLease.current, isNull);
    });
  });
}
