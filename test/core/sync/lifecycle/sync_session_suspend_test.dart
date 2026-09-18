// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// #4162 — suspend: the app is backgrounded (and resumed) while a pass or
/// an init is parked on the network.
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/app/startup/launch_sync_phase.dart';
import 'package:tankstellen/core/sync/app_resume_sync.dart';
import 'package:tankstellen/core/sync/supabase_client.dart';
import 'package:tankstellen/core/sync/sync_pull_coordinator.dart';
import 'package:tankstellen/core/sync/tanksync_init.dart';
import 'package:tankstellen/core/sync/tanksync_init_retry.dart';
import 'package:tankstellen/core/sync/tanksync_session_phase.dart';

import '../../../helpers/silence_error_logger.dart';
import '../support/sync_session_driver.dart';

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
      'gate while the abandoned pull still runs — pinned (S6), a second '
      'pass overlaps it', () async {
    final hung = Completer<void>();
    var inFlight = 0;
    var maxInFlight = 0;
    s = await SyncSession.start(entries: [
      SyncPullEntry(
        tables: const ['favorites'],
        timeout: const Duration(milliseconds: 20),
        pull: () async {
          inFlight++;
          if (inFlight > maxInFlight) maxInFlight = inFlight;
          await hung.future;
          inFlight--;
          return 0;
        },
      ),
    ]);
    await s.connectConsented();
    await SyncPullCoordinator.instance.pullAll(now: () => t0);
    expect(SyncPullCoordinator.instance.lastOutcome,
        SyncPassOutcome.completedWithTimeouts);
    expect(SyncPullCoordinator.instance.isRunning, isFalse);

    await SyncPullCoordinator.instance.pullAll(now: () => t0);

    expect(maxInFlight, greaterThanOrEqualTo(2),
        reason: 'the timeout does not cancel the pull it abandons');
    hung.complete();
    await SyncSession.settle();
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
    try {
      await abandoned.timeout(const Duration(milliseconds: 20));
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
