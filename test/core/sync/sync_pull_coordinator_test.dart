// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sync/sync_pull_coordinator.dart';

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
          if (throwing != null) throw throwing;
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
}
