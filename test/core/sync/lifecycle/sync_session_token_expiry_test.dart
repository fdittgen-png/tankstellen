// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// #4162 — token expiry: the SDK drops a session on its own when the
/// server rejects the refresh token, and nobody in the app asks it to.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sync/app_resume_sync.dart';
import 'package:tankstellen/core/sync/supabase_client.dart';
import 'package:tankstellen/core/sync/sync_provider.dart';
import 'package:tankstellen/core/sync/sync_pull_coordinator.dart';
import 'package:tankstellen/core/sync/tanksync_session_phase.dart';

import '../../../helpers/silence_error_logger.dart';
import '../support/sync_session_driver.dart';

void main() {
  silenceErrorLoggerSpool();

  late SyncSession s;
  tearDown(() => s.dispose());

  final t0 = DateTime.utc(2026, 9, 16, 12);

  Future<SyncSession> readyDevice() async {
    s = await SyncSession.start();
    await s.connectConsented();
    s = await s.relaunch(await s.capture());
    expect(s.trace.last, TankSyncSessionPhase.ready);
    return s;
  }

  test('a rejected refresh token drops the session: the SDK signs out with '
      'sessionExpired and the gate sees it', () async {
    await readyDevice();
    final storedId = s.storage.getSetting('sync_user_id');

    s.backend.rejectRefreshTokens = true;
    await s.backend.autoRefreshTick();
    await SyncSession.settle();

    expect(TankSyncClient.sessionUserId, isNull);
    expect(s.trace.observations.last.cause, 'auth:signedOut(sessionExpired)');
    expect(s.storage.getSetting('sync_user_id'), storedId,
        reason: 'nothing mints a new identity over the stored one');
    // #4338 (S3) — pinned: the session is lost and nothing flags it.
    expect(s.trace.saw(
            (TankSyncSessionPhase.ready, TankSyncSessionPhase.sessionLost)),
        isTrue);
    expect(s.container.read(syncStateProvider).relinkRequired, isFalse);
    s.trace.expectLawful();
  });

  test('a pass after the loss is recorded as unauthenticated — and, pinned '
      '(#4338), still stamps completion, so a resume treats sync as fresh',
      () async {
    s = await SyncSession.start(entries: [
      SyncPullEntry(tables: const ['favorites'], pull: () async => 0),
    ]);
    await s.connectConsented();
    s.backend.rejectRefreshTokens = true;
    await s.backend.autoRefreshTick();
    await SyncSession.settle();

    await SyncPullCoordinator.instance.pullAll(now: () => t0);
    expect(SyncPullCoordinator.instance.lastOutcome,
        SyncPassOutcome.completedUnauthenticated);
    expect(SyncPullCoordinator.instance.lastCompletedAt, t0);

    await AppResumeSync.instance
        .onAppResumed(now: () => t0.add(const Duration(minutes: 5)));
    expect(SyncPullCoordinator.instance.lastCompletedAt, t0,
        reason: 'the resume debounce read the unauthenticated stamp');
  });

  test('the next cold start finds the stored id without a session and '
      'raises relink (#3449)', () async {
    await readyDevice();
    s.backend.rejectRefreshTokens = true;
    await s.backend.autoRefreshTick();
    s = await s.relaunch(await s.capture());

    expect(s.trace.last, TankSyncSessionPhase.relinkRequired);
    expect(s.container.read(syncStateProvider).relinkRequired, isTrue);
    s.trace.expectClean();
  });

  // A retryable refresh failure (offline) keeps the session: see the
  // throttle suite, which lets gotrue's backoff land instead of waiting it
  // out.
}
