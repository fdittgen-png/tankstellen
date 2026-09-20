// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// #4162 — suspend: the app is backgrounded (and resumed) while a pass or
/// an init is parked on the network.
///
/// #4420 — nothing in this suite may turn on real elapsed milliseconds.
/// Every future a pass can win or lose against is parked on a [Completer]
/// only the test completes, and the per-pass timeout budget is staged by
/// the test ([_PerPassBudgetEntry]): a pass that must be abandoned is
/// given none, a pass that must survive is given [_unlosableBudget].
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/app/startup/launch_sync_phase.dart';
import 'package:tankstellen/core/sync/app_resume_sync.dart';
import 'package:tankstellen/core/sync/supabase_client.dart';
import 'package:tankstellen/core/sync/sync_pull_coordinator.dart';
import 'package:tankstellen/core/sync/sync_pull_lease.dart';
import 'package:tankstellen/core/sync/sync_transport.dart';
import 'package:tankstellen/core/sync/tanksync_init.dart';
import 'package:tankstellen/core/sync/tanksync_init_retry.dart';
import 'package:tankstellen/core/sync/tanksync_session_phase.dart';

import '../../../helpers/silence_error_logger.dart';
import '../support/sync_session_driver.dart';

/// #4420 — the budget handed to a pass that must NOT be abandoned. The
/// work it covers is microtasks only, so no amount of CI load can burn
/// through an hour of it; a timeout here is a real defect, never noise.
const Duration _unlosableBudget = Duration(hours: 1);

/// #4420 — a pull entry whose timeout budget the test stages per pass.
///
/// [SyncPullCoordinator] reads `timeout` once per pass, so flipping
/// [budget] between two `pullAll` calls is what turns "the abandoned pass
/// answers after the current one" into a sequence the test dictates,
/// instead of a race between two real 20 ms timers that a loaded runner
/// can make BOTH passes lose.
class _PerPassBudgetEntry extends SyncPullEntry {
  _PerPassBudgetEntry({required super.tables, required super.pull})
      : super(timeout: Duration.zero);

  /// The budget the next pass over this entry runs on.
  Duration budget = Duration.zero;

  @override
  Duration get timeout => budget;
}

/// How many selects against the favorites table have reached the fake
/// wire — the observable that says an abandoned pull really is parked
/// there rather than still queued behind a microtask.
int _favoritesOnTheWire(SyncSession s) =>
    s.backend.requests.where((u) => u.path.endsWith('/favorites')).length;

void main() {
  silenceErrorLoggerSpool();

  late SyncSession s;
  tearDown(() => s.dispose());

  final t0 = DateTime.utc(2026, 9, 16, 12);

  test('a resume while a pass is parked skips instead of stacking a second '
      'pass', () async {
    final pull = GatedPull();
    s = await SyncSession.start(entries: [pull.entry()]);
    await s.connectConsented();
    final pass = SyncPullCoordinator.instance.pullAll(now: () => t0);
    await pull.started.future;

    await AppResumeSync.instance.onAppResumed(now: () => t0);
    expect(SyncPullCoordinator.instance.lastCompletedAt, isNull,
        reason: 'the resume saw the pass running and left');
    // A "sync now" tap reaches the coordinator itself.
    await SyncPullCoordinator.instance.pullAll(now: () => t0);
    expect(SyncPullCoordinator.instance.lastOutcome,
        SyncPassOutcome.skippedAlreadyRunning);

    pull.release.complete();
    await pass;
    expect(SyncPullCoordinator.instance.lastOutcome, SyncPassOutcome.completed);
    expect(SyncPullCoordinator.instance.lastCompletedAt, t0);
    s.trace.expectClean();
  });

  test('a pull that outlives its timeout: the pass ends and releases the '
      'gate while the abandoned pull is still on the wire — its late answer '
      'is refused at the transport and never persisted; the next pass '
      'persists once (S6, #4377)', () async {
    // #4420 — the abandoned select parks HERE, on a completer only this
    // test completes, and is released strictly after the current pass has
    // persisted. The ordering below is therefore a sequence the test
    // dictates, not a race two real 20 ms timers could both lose.
    final abandonedWire = Completer<void>();
    final persisted = <int>[];
    final refused = <Object>[];
    var inFlight = 0;
    var maxInFlight = 0;
    final entry = _PerPassBudgetEntry(
      tables: const ['favorites'],
      pull: () async {
        inFlight++;
        if (inFlight > maxInFlight) maxInFlight = inFlight;
        final transport = SupabaseSyncTransport.currentOrNull()!;
        try {
          final rows = await transport.select('favorites', 'id');
          // The persist step every real pull ends with.
          persisted.add(rows.length);
          return rows.length;
        } catch (e, st) {
          refused.add(e);
          Error.throwWithStackTrace(e, st);
        } finally {
          inFlight--;
        }
      },
    );
    s = await SyncSession.start(entries: [entry]);
    await s.connectConsented();
    // The connect already selected favorites once; count from here.
    final wireBefore = _favoritesOnTheWire(s);
    s.backend.hang = abandonedWire;

    // Pass 1 is given NO budget: its select goes on the wire and the pass
    // abandons it at once. The pull can only answer when this test
    // completes [abandonedWire], which happens strictly later — so "the
    // pass times out" is the only reachable outcome, not the likely one.
    entry.budget = Duration.zero;
    await SyncPullCoordinator.instance.pullAll(now: () => t0);
    expect(SyncPullCoordinator.instance.lastOutcome,
        SyncPassOutcome.completedWithTimeouts);
    expect(SyncPullCoordinator.instance.isRunning, isFalse);
    expect(inFlight, 1, reason: 'the timeout does not cancel the pull');
    await SyncSession.settle();
    expect(_favoritesOnTheWire(s) - wireBefore, 1,
        reason: 'the abandoned select really did reach the fake wire and is '
            'parked there — the whole sequence below rests on it, so pin '
            'it rather than assume it');

    // The resume / "sync now" pass starts while the abandoned select is
    // still parked. The wire is open again, so its own select answers at
    // once, and its budget is one CI load cannot burn through: this pass
    // CANNOT be abandoned the way pass 1 was.
    entry.budget = _unlosableBudget;
    s.backend.hang = null;
    await SyncPullCoordinator.instance.pullAll(now: () => t0);
    await SyncSession.settle();

    expect(SyncPullCoordinator.instance.lastOutcome, SyncPassOutcome.completed,
        reason: 'the current pass must NOT time out. If it did, both passes '
            'were abandoned, nothing persisted, and the ordering this test '
            'exists to catch was never exercised — that is the vacuous '
            'failure of #4420, not an ordering violation');
    expect(maxInFlight, 2,
        reason: 'the current pass ran while the abandoned pull was still on '
            'the wire — that overlap is the whole scenario');
    expect(persisted, [0], reason: 'the current pass persists the table');
    expect(refused, isEmpty,
        reason: 'nothing is refused yet — the abandoned pull has not '
            'answered');

    // Only NOW does the abandoned pull answer, strictly after the current
    // pass persisted. That order is the property (#4377).
    abandonedWire.complete();
    await SyncSession.settle();

    expect(persisted, [0],
        reason: 'exactly one pass persists the table — the current one; '
            'the abandoned answer must be discarded');
    expect(refused.single, isA<SyncPullAbandonedException>());
    expect(SyncPullCoordinator.instance.discardedFor(const ['favorites']), 1);
    expect(SyncPullCoordinator.instance.lastOutcome, SyncPassOutcome.completed);
    expect(SyncPullCoordinator.instance.lastCompletedAt, t0);
    expect(inFlight, 0);
    s.trace.expectClean();
  });

  test('an abandoned pull that answers with NO successor pass is still '
      'refused — the timeout retires its generation on the spot, it is not '
      'a side effect of the next pass minting a newer one (#4430)', () async {
    // The S6 test above always has a second pass, and that pass mints
    // generation 2 by itself. So it stays green even with the retirement
    // line in `_pullOne` deleted: generation 1 is retired either way.
    //
    // This is the shape where the line is the ONLY thing standing between
    // a late answer and a persist — the user backgrounds the app, the
    // pass times out, nothing resumes, and the abandoned select finally
    // comes back to a process that has moved on. Deleting
    // `if (_generation[name] == generation) _generation[name] = ...`
    // turns `persisted` into `[0]` and empties `refused`.
    final abandonedWire = Completer<void>();
    final persisted = <int>[];
    final refused = <Object>[];
    final entry = _PerPassBudgetEntry(
      tables: const ['favorites'],
      pull: () async {
        final transport = SupabaseSyncTransport.currentOrNull()!;
        try {
          final rows = await transport.select('favorites', 'id');
          persisted.add(rows.length);
          return rows.length;
        } catch (e, st) {
          refused.add(e);
          Error.throwWithStackTrace(e, st);
        }
      },
    );
    s = await SyncSession.start(entries: [entry]);
    await s.connectConsented();
    final wireBefore = _favoritesOnTheWire(s);
    s.backend.hang = abandonedWire;

    // One pass, no budget: the select reaches the wire and the pass
    // abandons it. Nothing follows it — that is the point.
    entry.budget = Duration.zero;
    await SyncPullCoordinator.instance.pullAll(now: () => t0);
    await SyncSession.settle();
    expect(SyncPullCoordinator.instance.lastOutcome,
        SyncPassOutcome.completedWithTimeouts);
    expect(_favoritesOnTheWire(s) - wireBefore, 1,
        reason: 'the abandoned select is parked on the fake wire');
    expect(persisted, isEmpty);
    expect(refused, isEmpty);

    // The answer arrives into a process with no pass in flight.
    abandonedWire.complete();
    await SyncSession.settle();

    expect(SyncPullCoordinator.instance.isRunning, isFalse,
        reason: 'no successor pass exists to retire generation 1 — only '
            'the timeout did');
    expect(persisted, isEmpty,
        reason: 'the late answer must not persist: the pass that asked for '
            'it ended, and no later pass vouched for the snapshot');
    expect(refused.single, isA<SyncPullAbandonedException>());
    expect(SyncPullCoordinator.instance.discardedFor(const ['favorites']), 1);
  });

  test('an init parked past its launch budget: the ladder arms while the '
      'pass is still in flight; the late success is ready, and the retry '
      'replays the launch pulls (S7)', () async {
    var pulls = 0;
    s = await SyncSession.start(entries: [
      SyncPullEntry(
          tables: const ['favorites'], pull: () async => ++pulls),
    ]);
    await s.connectConsented();
    final image = await s.capture();
    s = await s.relaunch(image, launch: false, entries: [
      SyncPullEntry(
          tables: const ['favorites'], pull: () async => ++pulls),
    ]);
    pulls = 0;
    final park = Completer<void>();
    s.backend.hang = park;
    // A keychain session needs no network to restore; drop it so the
    // init has to sign in over the parked network.
    s.backend.keychain.clear();
    await s.storage.putSetting('sync_user_id', null);

    final abandoned = TankSyncInit.run(s.storage);
    // #4420 — the init is parked on [park] and can only answer once this
    // test releases it, so an already-spent budget abandons it by
    // construction; the old real 20 ms one only did so by luck.
    await SyncSession.settle();
    try {
      await abandoned.timeout(Duration.zero);
    } on TimeoutException {
      // The launch paints on without sync.
    }
    LaunchSyncPhase.handleInitOutcome(s.container, s.storage);
    expect(TankSyncInitRetry.instance.pending, isTrue);
    expect(s.trace.last, TankSyncSessionPhase.initializing,
        reason: 'hidden sub-state: in flight with the ladder armed');

    s.backend.hang = null;
    park.complete();
    await abandoned;
    await SyncSession.settle();
    expect(TankSyncClient.sessionUserId, isNotNull);
    expect(s.trace.last, TankSyncSessionPhase.ready);

    await TankSyncInitRetry.instance.retryNowIfPending();
    expect(TankSyncInitRetry.instance.pending, isFalse);
    expect(pulls, 1, reason: 'the retry saw a live session and replayed');
    s.trace.expectClean();
  });
}
