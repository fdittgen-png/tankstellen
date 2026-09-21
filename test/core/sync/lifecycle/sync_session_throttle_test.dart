// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// #4162 — throttle and network loss: the launch init and the passes meet
/// a network that is down, slow, or comes back.
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sync/supabase_client.dart';
import 'package:tankstellen/core/sync/sync_pull_coordinator.dart';
import 'package:tankstellen/core/sync/tanksync_init_retry.dart';
import 'package:tankstellen/core/sync/tanksync_session_phase.dart';

import '../../../helpers/silence_error_logger.dart';
import '../support/sync_session_driver.dart';

void main() {
  silenceErrorLoggerSpool();

  late SyncSession s;
  tearDown(() => s.dispose());

  final t0 = DateTime.utc(2026, 9, 16, 12);

  /// A device configured for sync whose keychain lost its session and
  /// whose stored id is gone too — the init must sign in over the network.
  Future<SyncDiskImage> needsNetworkImage({List<SyncPullEntry>? entries}) async {
    s = await SyncSession.start(entries: entries ?? const []);
    await s.connectConsented();
    final image = await s.capture();
    return image.copyWith(
      settings: {...image.settings}..remove('sync_user_id'),
      keychain: const {},
    );
  }

  test('network down at launch: init fails, the ladder arms, and walking it '
      'to exhaustion leaves a built client with no session and nothing '
      'retrying (hidden sub-state)',
      () async {
    final image = await needsNetworkImage();
    s.kill();
    final backend = s.backend.relaunched()
      ..keychain.clear()
      ..networkDown = true;
    s = await SyncSession.start(image: image, backend: backend);

    expect(TankSyncInitRetry.instance.pending, isTrue);
    expect(s.trace.last, TankSyncSessionPhase.initFailed);

    for (var i = 0; i < TankSyncInitRetry.maxAttempts; i++) {
      await TankSyncInitRetry.instance.retryNowIfPending();
    }

    expect(TankSyncInitRetry.instance.pending, isFalse);
    expect(TankSyncClient.sessionUserId, isNull);
    expect(s.trace.last, TankSyncSessionPhase.sessionLost);
    s.trace.expectClean();
  });

  test('network back mid-ladder: the next attempt is ready and replays the '
      'launch pulls', () async {
    var pulls = 0;
    final entries = [
      SyncPullEntry(tables: const ['favorites'], pull: () async => ++pulls),
    ];
    final image = await needsNetworkImage(entries: entries);
    s.kill();
    final backend = s.backend.relaunched()
      ..keychain.clear()
      ..networkDown = true;
    s = await SyncSession.start(image: image, backend: backend, entries: entries);
    await TankSyncInitRetry.instance.retryNowIfPending();
    expect(TankSyncInitRetry.instance.pending, isTrue);
    pulls = 0;

    backend.networkDown = false;
    await TankSyncInitRetry.instance.retryNowIfPending();
    await SyncSession.settle();

    expect(TankSyncInitRetry.instance.pending, isFalse);
    expect(TankSyncClient.sessionUserId, isNotNull);
    expect(pulls, 1);
    expect(SyncPullCoordinator.instance.lastOutcome, SyncPassOutcome.completed);
    final phases = s.trace.phases;
    expect(phases.sublist(phases.length - 3), [
      TankSyncSessionPhase.initFailed,
      TankSyncSessionPhase.initializing,
      TankSyncSessionPhase.ready,
    ]);
    s.trace.expectClean();
  });

  test('a table timing out pass after pass: each pass reports its timeouts, '
      'and the #4112 escalation still needs three strikes', () async {
    s = await SyncSession.start(entries: [
      SyncPullEntry(
        tables: const ['trips'],
        // #4420 — the pull is a completer nothing ever completes, so the
        // budget being already spent makes the timeout the only reachable
        // outcome. A real 10 ms one waited on the wall clock to reach the
        // same certainty, three times over.
        timeout: Duration.zero,
        pull: () => Completer<int>().future,
      ),
    ]);
    await s.connectConsented();

    for (var pass = 1; pass <= 3; pass++) {
      await SyncPullCoordinator.instance.pullAll(now: () => t0);
      expect(SyncPullCoordinator.instance.lastOutcome,
          SyncPassOutcome.completedWithTimeouts);
      expect(SyncPullCoordinator.instance.consecutiveTimeoutsFor(['trips']),
          pass);
    }
    expect(SyncPullCoordinator.timeoutsBeforeError, 3);
    s.trace.expectClean();
  });

  test('network lost mid-session: a refresh attempt fails retryably, the '
      'session and the phase stay', () async {
    s = await SyncSession.start();
    await s.connectConsented();
    s.backend.networkDown = true;

    // gotrue retries a retryable refresh with backoff; the session stays
    // while it does, and the network coming back lets the retry land.
    final tick = s.backend.autoRefreshTick();
    await SyncSession.settle();
    expect(TankSyncClient.sessionUserId, isNotNull);
    expect(s.trace.last, TankSyncSessionPhase.ready);
    s.backend.networkDown = false;
    await tick;
    await SyncSession.settle();

    expect(TankSyncClient.sessionUserId, isNotNull);
    expect(s.trace.last, TankSyncSessionPhase.ready);
    s.trace.expectClean();
  });
}
