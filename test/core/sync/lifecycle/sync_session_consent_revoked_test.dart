// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// #4162 — consent revoked: the Cloud Sync consent is withdrawn while a
/// session is live, mid-pass, or before a setup (GDPR Art. 7(3), #3866).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sync/supabase_client.dart';
import 'package:tankstellen/core/sync/sync_provider.dart';
import 'package:tankstellen/core/sync/sync_pull_coordinator.dart';
import 'package:tankstellen/core/sync/sync_transport.dart';
import 'package:tankstellen/core/sync/tanksync_session_phase.dart';

import '../../../helpers/silence_error_logger.dart';
import '../support/sync_session_driver.dart';

void main() {
  silenceErrorLoggerSpool();

  late SyncSession s;
  tearDown(() => s.dispose());

  test('withdrawing consent after an in-session setup: pinned (#4337), '
      '`enabled` stays true — the setup published its config by hand and '
      'the provider never subscribed to the consent', () async {
    s = await SyncSession.start();
    await s.connectConsented();
    await s.setConsent(false);

    // `SyncState.build` reads `sync_enabled && consent` — with sync still
    // off at launch the `&&` short-circuits, the consent is never watched,
    // and `connect` then sets its state without a rebuild.
    expect(s.container.read(syncStateProvider).enabled, isTrue);
    expect(TankSyncClient.sessionUserId, isNotNull);
    s.backend.requests.clear();
    await s.backend.autoRefreshTick();
    expect(s.backend.requests.map((u) => u.path), contains('/auth/v1/token'));
    expect(s.trace.saw(SessionInvariant.noCloudWithoutConsent), isTrue);
    s.trace.expectLawful();
  });

  test('withdrawing consent while ready after a launch: sync turns off for '
      'the app, but pinned (#4337) the client stays signed in and '
      'refreshing', () async {
    s = await SyncSession.start();
    await s.connectConsented();
    s = await s.relaunch(await s.capture());
    expect(s.trace.last, TankSyncSessionPhase.ready);

    await s.setConsent(false);

    expect(s.container.read(syncStateProvider).enabled, isFalse);
    expect(TankSyncClient.sessionUserId, isNotNull);
    expect(s.trace.saw(SessionInvariant.noCloudWithoutConsent), isTrue);
    s.backend.requests.clear();
    await s.backend.autoRefreshTick();
    expect(s.backend.requests.map((u) => u.path), contains('/auth/v1/token'));
    s.trace.expectLawful();
  });

  test('withdrawing consent mid-pass: pinned (#4337), the pass goes on '
      'writing and stamps completion', () async {
    final pull = GatedPull();
    s = await SyncSession.start(entries: [pull.entry()]);
    await s.connectConsented();
    pull.body = () async {
      final transport = SupabaseSyncTransport.currentOrNull();
      await transport?.upsert('favorites', [
        {'id': 'x', 'user_id': transport.userId},
      ], onConflict: 'id');
    };
    final pass = SyncPullCoordinator.instance
        .pullAll(now: () => DateTime.utc(2026, 9, 16, 12));
    await pull.started.future;
    final project = s.backend.project(kHostA);
    final writesBefore = project.writes.length;

    await s.setConsent(false);
    pull.release.complete();
    await pass;

    expect(project.writes.length, writesBefore + 1,
        reason: 'the upload after the withdrawal reached the server');
    expect(SyncPullCoordinator.instance.lastCompletedAt, isNotNull);
    s.trace.expectLawful();
  });

  test('"Set up cloud sync" with consent withdrawn: pinned (#4337), setup '
      'mints a new identity over the stored one and uploads', () async {
    s = await SyncSession.start();
    await s.connectConsented();
    final storedId = s.storage.getSetting('sync_user_id');
    await s.setConsent(false);
    s = await s.relaunch(await s.capture());
    // The section offers setup: `enabled` folds the consent in.
    expect(s.container.read(syncStateProvider).isConfigured, isFalse);

    await s.sync.connect(urlOf(kHostA), 'anon-key-$kHostA');
    await SyncSession.settle();

    expect(s.storage.getSetting('sync_user_id'), isNot(storedId));
    expect(s.container.read(syncStateProvider).enabled, isTrue);
    expect(s.trace.saw(SessionInvariant.noCloudWithoutConsent), isTrue);
    s.trace.expectLawful();
  });

  test('a launch without consent builds no client', () async {
    s = await SyncSession.start();
    await s.connectConsented();
    await s.setConsent(false);
    final image = await s.capture();
    s = await s.relaunch(image);

    expect(TankSyncClient.isInitialized, isFalse);
    expect(s.backend.requests, isEmpty);
    expect(s.trace.last, TankSyncSessionPhase.consentWithdrawn);
    s.trace.expectClean();
  });

  test('granting consent again after a consent-less launch: pinned, nothing '
      'resumes until the next launch', () async {
    s = await SyncSession.start();
    await s.connectConsented();
    await s.setConsent(false);
    s = await s.relaunch(await s.capture());

    await s.setConsent(true);

    expect(TankSyncClient.isInitialized, isFalse);
    expect(s.trace.last, TankSyncSessionPhase.configured);
    s.trace.expectClean();
  });
}
