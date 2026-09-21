// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// #4162 — kill: the process dies inside a write sequence, and the next
/// launch starts from whatever reached disk.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sync/sync_provider.dart';
import 'package:tankstellen/core/sync/sync_pull_coordinator.dart';
import 'package:tankstellen/core/sync/tanksync_session_phase.dart';

import '../../../helpers/silence_error_logger.dart';
import '../support/sync_session_driver.dart';

void main() {
  silenceErrorLoggerSpool();

  late SyncSession s;
  tearDown(() => s.dispose());

  test('killed mid-connect — after sync_enabled, before sync_user_id: the '
      'relaunch adopts the identity the dead process minted, never a new one',
      () async {
    s = await SyncSession.start();
    await s.setConsent(true);
    SyncDiskImage? atKill;
    s.storage.onPut = (key) {
      if (key == 'sync_mode') atKill ??= s.snapshot();
    };
    await s.sync.connect(urlOf(kHostA), 'anon-key-$kHostA');
    await SyncSession.settle();
    final image = atKill!;
    expect(image.settings['sync_enabled'], isTrue);
    expect(image.settings.containsKey('sync_user_id'), isFalse);
    expect(image.keychain, isNotEmpty,
        reason: 'the SDK persisted the session on sign-in, before the kill');

    s = await s.relaunch(image);

    final project = s.backend.project(kHostA);
    expect(project.refreshTokens.values.toSet(), hasLength(1),
        reason: 'one identity on the server, not two');
    expect(s.storage.getSetting('sync_user_id'),
        project.refreshTokens.values.single);
    expect(s.trace.last, TankSyncSessionPhase.ready);
    s.trace.expectClean();
  });

  test('killed mid-connect before the SDK persisted a session: the relaunch '
      'mints — there is no identity anywhere to keep', () async {
    s = await SyncSession.start();
    await s.setConsent(true);
    final image = SyncDiskImage(
      settings: {
        'sync_enabled': true,
        'supabase_url': urlOf(kHostA),
        'consent_cloud_sync': true,
      },
      anonKey: 'anon-key-$kHostA',
    );
    s = await s.relaunch(image);

    expect(s.storage.getSetting('sync_user_id'), isNotNull);
    expect(s.trace.last, TankSyncSessionPhase.ready);
    s.trace.expectClean();
  });

  test('killed mid-pass: the relaunch resumes the same identity and a fresh '
      'pass completes', () async {
    final pull = GatedPull();
    s = await SyncSession.start(entries: [pull.entry()]);
    await s.connectConsented();
    final storedId = s.storage.getSetting('sync_user_id');
    final pass = SyncPullCoordinator.instance.pullAll();
    await pull.started.future;
    expect(SyncPullCoordinator.instance.isRunning, isTrue);
    final image = s.snapshot();

    s = await s.relaunch(image, entries: [
      SyncPullEntry(tables: const ['favorites'], pull: () async => 0),
    ]);

    expect(s.storage.getSetting('sync_user_id'), storedId);
    expect(s.trace.last, TankSyncSessionPhase.ready);
    expect(SyncPullCoordinator.instance.lastOutcome, SyncPassOutcome.completed,
        reason: "the relaunch's own launch pass");
    s.trace.expectClean();
    // The dead process's pass never resumes; release it only so the test
    // leaves no pending future behind.
    pull.release.complete();
    await pass;
  });

  test('killed while relink is required: the flag is not persisted, and the '
      'relaunch derives it again', () async {
    s = await SyncSession.start();
    await s.connectConsented();
    s = await s.relaunch((await s.capture()).withoutKeychain());
    expect(s.container.read(syncStateProvider).relinkRequired, isTrue);

    s = await s.relaunch(await s.capture());

    expect(s.container.read(syncStateProvider).relinkRequired, isTrue);
    expect(s.trace.last, TankSyncSessionPhase.relinkRequired);
    s.trace.expectClean();
  });
}
