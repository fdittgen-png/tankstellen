// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// #4162 — partial restore: the two stores a TankSync session lives in
/// (the settings box and the platform keychain) come back independently —
/// or the SDK's own state outlives the app's.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sync/supabase_client.dart';
import 'package:tankstellen/core/sync/sync_provider.dart';
import 'package:tankstellen/core/sync/tanksync_session_phase.dart';

import '../../../helpers/silence_error_logger.dart';
import '../support/sync_session_driver.dart';

void main() {
  silenceErrorLoggerSpool();

  late SyncSession s;
  tearDown(() => s.dispose());

  Future<SyncDiskImage> connectedImage() async {
    s = await SyncSession.start();
    await s.connectConsented();
    return s.capture();
  }

  test('iOS reinstall: the keychain survives, Hive is wiped — sync is off '
      'and nothing is adopted or contacted', () async {
    final image = await connectedImage();
    s = await s.relaunch(const SyncDiskImage().copyWith(
      keychain: image.keychain,
    ));

    expect(s.trace.last, TankSyncSessionPhase.off);
    expect(TankSyncClient.isInitialized, isFalse);
    expect(s.backend.requests, isEmpty);
    s.trace.expectClean();
  });

  test('settings restored without sync_user_id, keychain intact: the launch '
      'adopts the keychain session instead of minting a new identity',
      () async {
    final image = await connectedImage();
    final minted = image.settings['sync_user_id'];
    s = await s.relaunch(image.copyWith(
      settings: {...image.settings}..remove('sync_user_id'),
    ));

    expect(s.storage.getSetting('sync_user_id'), minted);
    expect(s.backend.project(kHostA).refreshTokens.values.toSet(), {minted},
        reason: 'no second account was minted');
    expect(s.trace.last, TankSyncSessionPhase.ready);
    s.trace.expectClean();
  });

  test('Android restore: settings back, keychain not (backup rules exclude '
      'it) — relink required, the stored identity is kept (#3449)', () async {
    final image = await connectedImage();
    s = await s.relaunch(image.withoutKeychain());

    expect(s.trace.last, TankSyncSessionPhase.relinkRequired);
    expect(s.container.read(syncStateProvider).relinkRequired, isTrue);
    expect(s.storage.getSetting('sync_user_id'),
        image.settings['sync_user_id']);
    expect(s.trace.phases, [
      TankSyncSessionPhase.configured,
      TankSyncSessionPhase.initializing,
      TankSyncSessionPhase.sessionLost,
      TankSyncSessionPhase.relinkRequired,
    ]);
    s.trace.expectClean();
  });

  test('Android restore of nothing (both stores excluded): a fresh device',
      () async {
    await connectedImage();
    s = await s.relaunch(const SyncDiskImage());

    expect(s.trace.last, TankSyncSessionPhase.off);
    expect(s.backend.requests, isEmpty);
    s.trace.expectClean();
  });

  test('the SDK outlives a disconnect: setting up a DIFFERENT backend in the '
      'same process — pinned (#4336), the old client stays live', () async {
    await connectedImage();
    await s.sync.disconnect();
    expect(TankSyncClient.isInitialized, isFalse);
    expect(TankSyncClient.sdkInitialized, isTrue,
        reason: 'signOut resets the app flag only');
    s.backend.requests.clear();

    await s.sync.connect(urlOf(kHostB), 'anon-key-$kHostB');
    await SyncSession.settle();

    expect(s.storage.getSetting('supabase_url'), urlOf(kHostB));
    expect(TankSyncClient.backendHost, kHostB);
    expect(s.backend.skippedInitializeCalls, 1);
    expect(s.backend.hostsContacted, {kHostA},
        reason: 'every request after setting up B went to A');
    expect(s.trace.saw(SessionInvariant.clientMatchesBackend), isTrue);
    s.trace.expectLawful();
  });

  test('disconnect then set up the SAME backend: the identity restarts '
      'cleanly on it', () async {
    await connectedImage();
    await s.sync.disconnect();
    s.backend.requests.clear();

    await s.sync.connect(urlOf(kHostA), 'anon-key-$kHostA');
    await SyncSession.settle();

    expect(s.backend.hostsContacted, {kHostA});
    expect(TankSyncClient.sessionUserId, isNotNull);
    expect(s.trace.last, TankSyncSessionPhase.ready);
    s.trace.expectClean();
  });
}
