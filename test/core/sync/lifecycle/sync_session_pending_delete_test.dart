// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// #4345 — a delete made while the session is unavailable (lost,
/// consent withdrawn, not yet ready) must not come back from the server.
///
/// Every test drives the production feature path (`Favorites.remove`),
/// the real #3123 journal in a real Hive `settings` box, a process kill
/// through the disk image, and the real favorites union merge against the
/// fake backend's rows.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/core/sync/deletions_sync.dart';
import 'package:tankstellen/core/sync/favorites_sync.dart';
import 'package:tankstellen/core/sync/pending_deletions_journal.dart';
import 'package:tankstellen/core/sync/supabase_client.dart';
import 'package:tankstellen/core/sync/tanksync_session_phase.dart';
import 'package:tankstellen/features/alerts/providers/alert_provider.dart';
import 'package:tankstellen/features/favorites/providers/favorites_provider.dart';
import 'package:tankstellen/features/itinerary/providers/itinerary_provider.dart';
import 'package:tankstellen/features/trips/providers/vehicle_baseline_summary_provider.dart';

import '../../../helpers/hive_temp_dir.dart';
import '../../../helpers/silence_error_logger.dart';
import '../support/fake_tanksync_backend.dart';
import '../support/sync_session_driver.dart';

const _station = 'de-station-4345';

void main() {
  silenceErrorLoggerSpool();
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  late SyncSession s;

  setUpAll(() async {
    dir = Directory.systemTemp.createTempSync('pending_delete_4345_');
    Hive.init(dir.path);
    await Hive.openBox<dynamic>(HiveBoxes.settings);
    await Hive.openBox<String>(HiveBoxes.obd2Baselines);
  });
  tearDownAll(() async {
    await closeHiveAndDeleteTemp(dir);
  });
  tearDown(() => s.dispose());

  FakeSupabaseProject project() => s.backend.project(kHostA);

  List<Map<String, dynamic>> tombstonesIn(
    String table,
    String recordId,
    String userId,
  ) =>
      [
        for (final r in project().rows('deletions'))
          if (r['table_name'] == table &&
              r['record_id'] == recordId &&
              r['user_id'] == userId)
            r,
      ];

  List<Map<String, dynamic>> tombstonesFor(String userId) =>
      tombstonesIn('favorites', _station, userId);

  bool onServer() =>
      project().rows('favorites').any((r) => r['station_id'] == _station);

  Set<String> journaled() =>
      PendingDeletionsJournal.pendingIds('favorites');

  /// A consented device whose favorite reached the server.
  Future<String> syncedFavorite() async {
    s = await SyncSession.start();
    await s.connectConsented();
    await s.storage.addFavorite(_station);
    await FavoritesSync.syncAndPersist(s.storage);
    expect(onServer(), isTrue);
    return s.storage.getSetting('sync_user_id') as String;
  }

  Future<void> removeThroughFeature() =>
      s.container.read(favoritesProvider.notifier).remove(_station);

  /// The session is ready again: the real union merge must not bring the
  /// favorite back, and must write its tombstone exactly once.
  Future<void> expectAppliedOnceAndNotResurrected(String userId) async {
    expect(TankSyncClient.sessionUserId, userId);
    await FavoritesSync.syncAndPersist(s.storage);
    expect(s.storage.getFavoriteIds(), isNot(contains(_station)),
        reason: 'the server row came back through the union merge');
    expect(tombstonesFor(userId), hasLength(1));
    expect(journaled(), isEmpty, reason: 'confirmed → journal entry gone');

    final writes = project().writes.where((t) => t == 'deletions').length;
    await FavoritesSync.syncAndPersist(s.storage);
    expect(project().writes.where((t) => t == 'deletions').length, writes,
        reason: 'a second pass replays nothing');
    expect(s.storage.getFavoriteIds(), isNot(contains(_station)));
  }

  test('a delete while ready still goes straight through', () async {
    final userId = await syncedFavorite();

    await removeThroughFeature();
    await SyncSession.settle();

    expect(onServer(), isFalse);
    expect(tombstonesFor(userId), hasLength(1));
    expect(journaled(), isEmpty);
  });

  test('session lost: the delete is journaled, survives a kill, and is '
      'applied once when the same account is re-linked', () async {
    final userId = await syncedFavorite();
    project().emailAccounts['driver@example.com'] = userId;
    s.backend.rejectRefreshTokens = true;
    await s.backend.autoRefreshTick();
    await SyncSession.settle();
    expect(TankSyncClient.sessionUserId, isNull);
    s.backend.requests.clear();

    await removeThroughFeature();
    await SyncSession.settle();

    expect(s.backend.requests, isEmpty, reason: 'no session, nothing sent');
    expect(journaled(), {_station});

    s = await s.relaunch(await s.capture());
    expect(s.trace.last, TankSyncSessionPhase.relinkRequired);
    expect(journaled(), {_station}, reason: 'the intent survived the kill');

    s.backend.rejectRefreshTokens = false;
    await s.sync
        .signInWithEmail('driver@example.com', 'secret', isSignUp: false);
    await SyncSession.settle();

    await expectAppliedOnceAndNotResurrected(userId);
  });

  test('consent withdrawn: the delete is journaled without sending, survives '
      'a kill, and is applied once after the consent is granted again',
      () async {
    final userId = await syncedFavorite();
    await s.setConsent(false);
    s.backend.requests.clear();

    await removeThroughFeature();
    await SyncSession.settle();

    expect(s.backend.requests, isEmpty, reason: 'no consent, nothing sent');
    expect(journaled(), {_station});

    s = await s.relaunch(await s.capture());
    expect(s.trace.last, TankSyncSessionPhase.consentWithdrawn);
    expect(journaled(), {_station});
    s.backend.requests.clear();
    await SyncSession.settle();
    expect(s.backend.requests, isEmpty,
        reason: 'a journaled intent never replays without consent');

    await s.setConsent(true);
    await SyncSession.settle();

    await expectAppliedOnceAndNotResurrected(userId);
  });

  test('session not yet ready (launch init still to run): the delete is '
      'journaled, survives a kill, and is applied once when ready', () async {
    final userId = await syncedFavorite();
    s = await s.relaunch(await s.capture(), launch: false);
    expect(TankSyncClient.isInitialized, isFalse);
    // The disk image carries the sync settings, not the favorites store:
    // put the favorite back the way the killed process left it.
    await s.storage.addFavorite(_station);

    await removeThroughFeature();
    await SyncSession.settle();

    expect(s.backend.requests, isEmpty);
    expect(journaled(), {_station});

    s = await s.relaunch(await s.capture());
    expect(s.trace.last, TankSyncSessionPhase.ready);

    await expectAppliedOnceAndNotResurrected(userId);
  });

  test('a journaled delete never replays under another account, even for '
      'the same station id', () async {
    final userA = await syncedFavorite();
    s.backend.rejectRefreshTokens = true;
    await s.backend.autoRefreshTick();
    await SyncSession.settle();
    await removeThroughFeature();
    await SyncSession.settle();
    s.backend.rejectRefreshTokens = false;

    // "Start fresh": a new anonymous identity B, knowingly.
    await s.sync.switchToAnonymous();
    await SyncSession.settle();
    final userB = TankSyncClient.sessionUserId!;
    expect(userB, isNot(userA));
    await FavoritesSync.syncAndPersist(s.storage);

    expect(tombstonesFor(userB), isEmpty);
    expect(tombstonesFor(userA), isEmpty);
    expect(PendingDeletionsJournal.quarantinedContexts(), isNotEmpty,
        reason: "A's intent is kept, not discarded and not replayed as B");
  });

  test('sync never set up: a local delete journals nothing', () async {
    s = await SyncSession.start();
    await s.storage.addFavorite(_station);

    await removeThroughFeature();
    await SyncSession.settle();

    expect(journaled(), isEmpty);
    expect(s.backend.requests, isEmpty);
  });

  /// #4345 — the other entities whose feature delete used to leave no
  /// trace while the consent was withdrawn: the intent is journaled with
  /// nothing sent, survives a kill, and replays exactly once after the
  /// consent is granted again (every merge drains the journal first).
  group('consent withdrawn, per entity', () {
    Future<void> expectWithdrawnDeleteJournaledAndReplayedOnce(
      String table,
      String recordId,
      Future<void> Function() delete,
    ) async {
      s = await SyncSession.start();
      await s.connectConsented();
      final userId = s.storage.getSetting('sync_user_id') as String;
      await s.setConsent(false);
      s.backend.requests.clear();

      await delete();
      await SyncSession.settle();

      expect(s.backend.requests, isEmpty, reason: 'no consent, nothing sent');
      expect(PendingDeletionsJournal.pendingIds(table), {recordId},
          reason: 'the $table delete left no durable intent');

      s = await s.relaunch(await s.capture());
      expect(PendingDeletionsJournal.pendingIds(table), {recordId});

      await s.setConsent(true);
      await SyncSession.settle();
      expect(TankSyncClient.sessionUserId, userId);
      await DeletionsSync.drainJournal();

      expect(tombstonesIn(table, recordId, userId), hasLength(1));
      expect(PendingDeletionsJournal.pendingIds(table), isEmpty);
      final writes = project().writes.where((t) => t == 'deletions').length;
      await DeletionsSync.drainJournal();
      expect(project().writes.where((t) => t == 'deletions').length, writes,
          reason: 'a second drain replays nothing');
    }

    test('alerts', () => expectWithdrawnDeleteJournaledAndReplayedOnce(
          'alerts',
          'alert-4345',
          () => s.container.read(alertProvider.notifier).removeAlert('alert-4345'),
        ));

    test('itineraries', () => expectWithdrawnDeleteJournaledAndReplayedOnce(
          'itineraries',
          'route-4345',
          () => s.container.read(itineraryProvider.notifier).delete('route-4345'),
        ));

    test('vehicle baselines', () => expectWithdrawnDeleteJournaledAndReplayedOnce(
          'obd2_baselines',
          'vehicle-4345',
          () => s.container.read(resetVehicleBaselinesProvider('vehicle-4345').future),
        ));

    test('sync never set up: none of them journals anything', () async {
      s = await SyncSession.start();

      await s.container.read(alertProvider.notifier).removeAlert('alert-4345');
      await s.container.read(itineraryProvider.notifier).delete('route-4345');
      await s.container
          .read(resetVehicleBaselinesProvider('vehicle-4345').future);
      await SyncSession.settle();

      for (final table in ['alerts', 'itineraries', 'obd2_baselines']) {
        expect(PendingDeletionsJournal.pendingIds(table), isEmpty,
            reason: table);
      }
      expect(s.backend.requests, isEmpty);
    });
  });
}
