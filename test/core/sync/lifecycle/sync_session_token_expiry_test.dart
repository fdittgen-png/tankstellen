// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// #4162 — token expiry: the SDK drops a session on its own when the
/// server rejects the refresh token, and nobody in the app asks it to
/// (#4338).
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

  Future<void> readyDevice({List<SyncPullEntry> entries = const []}) async {
    s = await SyncSession.start(entries: entries);
    await s.connectConsented();
    s = await s.relaunch(await s.capture(), entries: entries);
    expect(s.trace.last, TankSyncSessionPhase.ready);
  }

  Future<void> loseSession() async {
    s.backend.rejectRefreshTokens = true;
    await s.backend.autoRefreshTick();
    await SyncSession.settle();
    expect(TankSyncClient.sessionUserId, isNull);
  }

  test('a rejected refresh token moves sync to relink-required at once — '
      'not at the next cold start (#4338)', () async {
    await readyDevice();
    final storedId = s.storage.getSetting('sync_user_id');

    await loseSession();

    expect(s.container.read(syncStateProvider).relinkRequired, isTrue);
    expect(s.trace.last, TankSyncSessionPhase.relinkRequired);
    expect(s.trace.edges,
        contains((TankSyncSessionPhase.ready, TankSyncSessionPhase.relinkRequired)));
    expect(s.storage.getSetting('sync_user_id'), storedId,
        reason: 'nothing mints a new identity over the stored one');
    s.trace.expectClean();
  });

  test('a pass without a session is recorded as unauthenticated and never '
      'stamps completion, so a resume does not treat sync as fresh (#4338)',
      () async {
    var pulls = 0;
    await readyDevice(entries: [
      SyncPullEntry(tables: const ['favorites'], pull: () async => ++pulls),
    ]);
    final launchStamp = SyncPullCoordinator.instance.lastCompletedAt;
    await loseSession();

    await SyncPullCoordinator.instance.pullAll(now: () => t0);
    expect(SyncPullCoordinator.instance.lastOutcome,
        SyncPassOutcome.completedUnauthenticated);
    expect(SyncPullCoordinator.instance.lastCompletedAt, launchStamp);

    pulls = 0;
    await AppResumeSync.instance.onAppResumed(
        now: () => launchStamp!.add(const Duration(minutes: 20)));
    expect(pulls, 1, reason: 'the resume ran a pass: nothing fresh to skip');
    expect(SyncPullCoordinator.instance.lastCompletedAt, launchStamp);
  });

  test('the relink flag survives provider rebuilds (#4338)', () async {
    await readyDevice();
    await loseSession();
    expect(s.container.read(syncStateProvider).relinkRequired, isTrue);

    s.container.invalidate(syncStateProvider);
    expect(s.container.read(syncStateProvider).relinkRequired, isTrue);

    // A consent save rebuilds SyncState too (it watches the consent).
    await s.setConsent(true);
    expect(s.container.read(syncStateProvider).relinkRequired, isTrue);
    s.trace.expectClean();
  });

  test('an email sign-in on the lost identity re-links it and clears the '
      'flag', () async {
    await readyDevice();
    final storedId = s.storage.getSetting('sync_user_id') as String;
    s.backend.project(kHostA).emailAccounts['driver@example.com'] = storedId;
    await loseSession();
    s.backend.rejectRefreshTokens = false;

    await s.sync
        .signInWithEmail('driver@example.com', 'secret', isSignUp: false);
    await SyncSession.settle();

    expect(TankSyncClient.sessionUserId, storedId);
    expect(s.container.read(syncStateProvider).relinkRequired, isFalse);
    s.container.invalidate(syncStateProvider);
    expect(s.container.read(syncStateProvider).relinkRequired, isFalse,
        reason: 'the re-link cleared the owner, not only the state object');
    expect(s.trace.last, TankSyncSessionPhase.ready);

    // A later release (consent withdrawn) leaves no session behind; the
    // re-linked identity must not come back flagged.
    await s.setConsent(false);
    expect(TankSyncClient.sessionUserId, isNull);
    expect(s.container.read(syncStateProvider).relinkRequired, isFalse);
    s.trace.expectClean();
  });

  test('the next cold start finds the stored id without a session and '
      'raises relink (#3449)', () async {
    await readyDevice();
    await loseSession();
    s = await s.relaunch(await s.capture());

    expect(s.trace.last, TankSyncSessionPhase.relinkRequired);
    expect(s.container.read(syncStateProvider).relinkRequired, isTrue);
    s.trace.expectClean();
  });

  // A retryable refresh failure (offline) keeps the session: see the
  // throttle suite, which lets gotrue's backoff land instead of waiting it
  // out.
}
