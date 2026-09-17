// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// #4162 — consent revoked: the Cloud Sync consent is withdrawn while a
/// session is live, mid-pass, or before a setup (GDPR Art. 7(3), #3866),
/// and granted again (#4337).
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

  /// Withdrawing must take the client down locally: no live client, no SDK
  /// client, no refresh reaching the server — and the persisted session
  /// kept, so granting again resumes the same identity.
  Future<void> expectReleasedLocally() async {
    expect(TankSyncClient.isInitialized, isFalse);
    expect(TankSyncClient.sdkInitialized, isFalse);
    expect(TankSyncClient.sessionUserId, isNull);
    expect(s.backend.keychain, isNotEmpty,
        reason: 'the session is released, not signed out');
    s.backend.requests.clear();
    await s.backend.autoRefreshTick();
    expect(s.backend.requests, isEmpty,
        reason: 'nothing may refresh against the backend after withdrawal');
  }

  test('withdrawing consent after an in-session setup: sync turns off and '
      'the client is released locally (#4337)', () async {
    s = await SyncSession.start();
    await s.connectConsented();
    await s.setConsent(false);

    expect(s.container.read(syncStateProvider).enabled, isFalse,
        reason: 'SyncState must follow the consent even when it was first '
            'built with sync off');
    await expectReleasedLocally();
    expect(s.trace.last, TankSyncSessionPhase.consentWithdrawn);
    s.trace.expectClean();
  });

  test('withdrawing consent while ready after a launch: sync turns off and '
      'the client is released locally (#4337)', () async {
    s = await SyncSession.start();
    await s.connectConsented();
    s = await s.relaunch(await s.capture());
    expect(s.trace.last, TankSyncSessionPhase.ready);
    final project = s.backend.project(kHostA);
    final writes = project.writes.length;

    await s.setConsent(false);

    expect(s.container.read(syncStateProvider).enabled, isFalse);
    await expectReleasedLocally();
    expect(project.writes.length, writes,
        reason: 'withdrawal deletes nothing and uploads nothing');
    s.trace.expectClean();
  });

  test('withdrawing consent mid-pass fences the pass: its upload is refused '
      'and it does not stamp completion (#4337)', () async {
    final pull = GatedPull();
    s = await SyncSession.start(entries: [pull.entry()]);
    await s.connectConsented();
    final transport = SupabaseSyncTransport.currentOrNull()!;
    pull.body = () => transport.upsert('favorites', [
          {'id': 'x', 'user_id': transport.userId},
        ], onConflict: 'id');
    final pass = SyncPullCoordinator.instance
        .pullAll(now: () => DateTime.utc(2026, 9, 16, 12));
    await pull.started.future;
    final project = s.backend.project(kHostA);
    final writesBefore = project.writes.length;

    await s.setConsent(false);
    pull.release.complete();
    await pass;

    expect(project.writes.length, writesBefore,
        reason: 'no upload may reach the server after the withdrawal');
    expect(SyncPullCoordinator.instance.lastOutcome, SyncPassOutcome.fenced);
    expect(SyncPullCoordinator.instance.lastCompletedAt, isNull);
    s.trace.expectClean();
  });

  test('"Set up cloud sync" with consent withdrawn is refused before any '
      'network call, and the stored identity stays (#4337)', () async {
    s = await SyncSession.start();
    await s.connectConsented();
    final storedId = s.storage.getSetting('sync_user_id');
    await s.setConsent(false);
    s = await s.relaunch(await s.capture());
    expect(s.container.read(syncStateProvider).isConfigured, isFalse);

    await expectLater(
      s.sync.connect(urlOf(kHostA), 'anon-key-$kHostA'),
      throwsA(isA<CloudSyncConsentRequired>()),
    );
    await SyncSession.settle();

    expect(s.backend.requests, isEmpty);
    expect(s.storage.getSetting('sync_user_id'), storedId);
    expect(s.container.read(syncStateProvider).enabled, isFalse);
    s.trace.expectClean();
  });

  test('setup never mints a new identity over a stored one that has no '
      'session (#4337)', () async {
    s = await SyncSession.start();
    await s.connectConsented();
    final storedId = s.storage.getSetting('sync_user_id');
    s = await s.relaunch((await s.capture()).withoutKeychain());
    final accounts = s.backend.project(kHostA).refreshTokens.length;

    await expectLater(
      s.sync.connect(urlOf(kHostA), 'anon-key-$kHostA'),
      throwsA(isA<StateError>()),
    );
    await SyncSession.settle();

    expect(s.storage.getSetting('sync_user_id'), storedId);
    expect(s.backend.project(kHostA).refreshTokens.length, accounts,
        reason: 'no anonymous account was minted');
  });

  test('granting consent again in the same session resumes the stored '
      'identity (#4337)', () async {
    var pulls = 0;
    s = await SyncSession.start(entries: [
      SyncPullEntry(tables: const ['favorites'], pull: () async => ++pulls),
    ]);
    await s.connectConsented();
    final storedId = s.storage.getSetting('sync_user_id');
    await s.setConsent(false);
    pulls = 0;

    await s.setConsent(true);

    expect(TankSyncClient.sessionUserId, storedId);
    expect(s.storage.getSetting('sync_user_id'), storedId);
    expect(s.backend.project(kHostA).refreshTokens.values.toSet(), {storedId},
        reason: 'one identity, never a second one');
    expect(s.container.read(syncStateProvider).enabled, isTrue);
    expect(pulls, 1, reason: 'the resumed session pulls');
    expect(s.trace.last, TankSyncSessionPhase.ready);
    s.trace.expectClean();
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

  test('granting consent again after a consent-less launch resumes the '
      'stored identity without waiting for the next launch (#4337)',
      () async {
    s = await SyncSession.start();
    await s.connectConsented();
    final storedId = s.storage.getSetting('sync_user_id');
    await s.setConsent(false);
    s = await s.relaunch(await s.capture());

    await s.setConsent(true);

    expect(TankSyncClient.sessionUserId, storedId);
    expect(s.trace.last, TankSyncSessionPhase.ready);
    s.trace.expectClean();
  });
}
