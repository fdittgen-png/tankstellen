// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// #4162 — partial restore: the two stores a TankSync session lives in
/// (the settings box and the platform keychain) come back independently —
/// or the SDK's own state outlives the app's.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sync/supabase_client.dart';
import 'package:tankstellen/core/sync/sync_provider.dart';
import 'package:tankstellen/core/sync/tanksync_session_phase.dart';

import '../../../helpers/silence_error_logger.dart';
import '../support/fake_tanksync_backend.dart';
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

  test('disconnect, then set up a DIFFERENT backend in the same process: '
      'every request goes to the new backend (#4336)', () async {
    await connectedImage();
    await s.sync.disconnect();
    expect(TankSyncClient.isInitialized, isFalse);
    expect(TankSyncClient.sdkInitialized, isFalse,
        reason: 'disconnect releases the SDK client, not only the app flag');
    s.backend.requests.clear();

    await s.sync.connect(urlOf(kHostB), 'anon-key-$kHostB');
    await SyncSession.settle();

    expect(s.storage.getSetting('supabase_url'), urlOf(kHostB));
    expect(TankSyncClient.backendHost, kHostB);
    expect(TankSyncClient.sdkHost, kHostB);
    expect(s.backend.requests, isNotEmpty);
    expect(s.backend.hostsContacted, {kHostB},
        reason: 'no request after setting up B may reach A');
    expect(s.storage.getSetting('sync_user_id'),
        startsWith('$kHostB-user-'));
    s.trace.expectClean();
  });

  test('an init for a different backend while a client is live replaces '
      'the client instead of keeping the old one (#4336)', () async {
    await connectedImage();
    s.backend.requests.clear();

    await TankSyncClient.init(url: urlOf(kHostB), anonKey: 'anon-key-$kHostB');
    await TankSyncClient.signInAnonymously();

    expect(TankSyncClient.sdkHost, kHostB);
    expect(s.backend.hostsContacted, {kHostB});
  });

  test('an SDK left initialised for another backend is never used as the '
      'client of this one (#4336)', () async {
    s = await SyncSession.start();
    await s.backend.initialize(
      url: urlOf(kHostA),
      publishableKey: 'k',
      persistSessionKey: 'sb-a-project-auth-token',
    );

    await TankSyncClient.init(url: urlOf(kHostB), anonKey: 'anon-key-$kHostB');

    expect(TankSyncClient.sdkHost, kHostB);
    expect(TankSyncClient.client, isNotNull);
    s.backend.requests.clear();
    await TankSyncClient.signInAnonymously();
    expect(s.backend.hostsContacted, {kHostB});
  });

  test('if the SDK ever refuses to let go of the old client, the app sees '
      'no client at all rather than the wrong one (#4336)', () async {
    s = await SyncSession.start(backend: _StickySdk());
    await TankSyncClient.init(url: urlOf(kHostA), anonKey: 'k');
    expect(TankSyncClient.client, isNotNull);

    await TankSyncClient.init(url: urlOf(kHostB), anonKey: 'k');

    expect(TankSyncClient.backendHost, kHostB);
    expect(TankSyncClient.sdkHost, kHostA);
    expect(TankSyncClient.client, isNull);
    expect(await TankSyncClient.signInAnonymously(), isNull);
    expect(s.backend.requests, isEmpty);
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

/// An SDK whose dispose does nothing — the client it built stays live.
class _StickySdk extends FakeTankSyncBackend {
  @override
  Future<void> dispose() async {}
}
