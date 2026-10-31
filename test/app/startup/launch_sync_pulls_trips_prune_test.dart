// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/app/startup/launch_sync_pulls.dart';
import 'package:tankstellen/features/trips/data/trip_history_repository.dart';
import 'package:tankstellen/features/trips/domain/trip_recorder.dart';

import '../../helpers/hive_temp_dir.dart';
import '../../helpers/silence_error_logger.dart';
import 'package:tankstellen/features/trips/data/trips_sync_rows.dart';

/// #3453 — the trips half of the delete-my-synced-data round-trip:
/// a trip deleted server-side (tombstoned) on device A must be REMOVED
/// from device B's local history on its next pull.
///
/// `TripsSync.merge` already drops tombstoned ids from its local input;
/// what was missing was the persist step acting on the drop — the old
/// `pullTrips` loop only ever SAVED downloads. These tests drive the
/// extracted [LaunchSyncPulls.mergeAndPruneTrips] seam with a fake merge
/// standing in for the tombstone-filtered server round-trip.
void main() {
  silenceErrorLoggerSpool();
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmpDir;
  late Box<String> box;
  late TripHistoryRepository repo;

  setUp(() async {
    tmpDir = Directory.systemTemp.createTempSync('trips_prune_test_');
    Hive.init(tmpDir.path);
    box = await Hive.openBox<String>(
      'test_${DateTime.now().microsecondsSinceEpoch}',
    );
    repo = TripHistoryRepository(box: box);
  });

  tearDown(() async {
    await box.deleteFromDisk();
    await closeHiveAndDeleteTemp(tmpDir);
  });

  TripHistoryEntry entry(String id, {int day = 1}) => TripHistoryEntry(
        id: id,
        vehicleId: 'v-1',
        summary: TripSummary(
          distanceKm: 12,
          maxRpm: 2800,
          highRpmSeconds: 12,
          idleSeconds: 30,
          harshBrakes: 1,
          harshAccelerations: 2,
          avgLPer100Km: 6.5,
          fuelLitersConsumed: 0.8,
          startedAt: DateTime(2026, 6, day, 8),
          endedAt: DateTime(2026, 6, day, 8, 20),
        ),
      );

  test('a locally-held trip ABSENT from the merge result is removed '
      '(tombstoned on another device)', () async {
    await repo.save(entry('trip-keep', day: 1));
    await repo.save(entry('trip-deleted', day: 2));

    // The tombstone-filtered merge: the server tombstoned 'trip-deleted',
    // so TripsSync.merge returns only the surviving local entry.
    final changed = await LaunchSyncPulls.mergeAndPruneTrips(
      repo,
      (local) async =>
          local.where((e) => e.id != 'trip-deleted').toList(),
    );

    expect(changed, 1);
    expect(repo.loadAll().map((e) => e.id), ['trip-keep'],
        reason: 'the deleted trip must disappear locally on the next '
            'pull instead of lingering forever');
  });

  // #4056 — compose the REAL reconcile the way TripsSync.merge does it:
  // tombstone-filter → mergeRows → append retainedAfterWipe. Trip A was
  // wiped-and-kept (tombstoned + retained), trip B was deleted on another
  // device (tombstoned only). A must survive the prune, B must not.
  test('a trip the user wiped server-side but chose to KEEP survives the '
      'launch prune; a genuinely deleted one does not (#4056)', () async {
    await repo.save(entry('kept-A', day: 1));
    await repo.save(entry('deleted-B', day: 2));
    final tombstoned = {'kept-A', 'deleted-B'};
    final retained = {'kept-A'};

    Future<List<TripHistoryEntry>> realShapedMerge(
        List<TripHistoryEntry> local) async {
      final live = local.where((e) => !tombstoned.contains(e.id)).toList();
      final merged = TripsSyncRows.mergeRows(live, const [], tombstoned: tombstoned);
      return [
        ...merged,
        ...TripsSyncRows.retainedAfterWipe(local,
            tombstoned: tombstoned, retained: retained),
      ];
    }

    await LaunchSyncPulls.mergeAndPruneTrips(repo, realShapedMerge);

    expect(repo.storedIds, contains('kept-A'),
        reason: 'the dialog promised "data stored locally on this device '
            'is kept" — before #4056 this trip was deleted on the next launch');
    expect(repo.storedIds, isNot(contains('deleted-B')),
        reason: 'a delete from another device must still propagate (#3078)');
  });

  test('server-only entries are still saved (download direction intact)',
      () async {
    await repo.save(entry('trip-local', day: 1));

    final changed = await LaunchSyncPulls.mergeAndPruneTrips(
      repo,
      (local) async => [...local, entry('trip-downloaded', day: 3)],
    );

    expect(changed, 1);
    expect(repo.loadAll().map((e) => e.id).toSet(),
        {'trip-local', 'trip-downloaded'});
  });

  // #4543 — the server holds more trips than the local cap. Saving
  // every server-only trip wrote and trimmed the same (S − cap) old trips
  // on EVERY launch/resume pull. Only trips that survive the cap when
  // ranked with the local ones newest-first may be saved, and a second
  // pull with the same server state must be a no-op.
  test('server trips beyond the local cap are not re-saved on every pull '
      '(#4543)', () async {
    const cap = 20;
    final capped = TripHistoryRepository(box: box, cap: cap);
    final t0 = DateTime(2026, 1, 1);
    TripHistoryEntry at(String id, int hour) => TripHistoryEntry(
          id: id,
          vehicleId: 'v-1',
          summary: TripSummary(
            distanceKm: 12,
            maxRpm: 2800,
            highRpmSeconds: 12,
            idleSeconds: 30,
            harshBrakes: 1,
            harshAccelerations: 2,
            fuelLitersConsumed: 0.8,
            startedAt: t0.add(Duration(hours: hour)),
            endedAt: t0.add(Duration(hours: hour, minutes: 20)),
          ),
        );
    // Local: hours 100..119 (the newest window of the box).
    for (var h = 100; h < 100 + cap; h++) {
      await capped.save(at('local-$h', h));
    }
    // Server: every local trip + 30 OLDER ones + 2 NEWER ones (S = 52).
    final server = [
      ...capped.loadSummaries(),
      for (var h = 0; h < 30; h++) at('old-$h', h),
      at('new-200', 200),
      at('new-201', 201),
    ];
    // Shaped like TripsSync.merge: local ∪ server, by id.
    Future<List<TripHistoryEntry>> merge(List<TripHistoryEntry> local) async {
      final localIds = local.map((e) => e.id).toSet();
      return [...local, ...server.where((e) => !localIds.contains(e.id))];
    }

    final first = await LaunchSyncPulls.mergeAndPruneTrips(capped, merge);

    expect(first, 2,
        reason: 'only the two newer trips survive the cap; the 30 older '
            'ones would be trimmed right after their save');
    final ids = capped.storedIds.toSet();
    expect(ids, hasLength(cap));
    expect(ids, containsAll(['new-200', 'new-201']));
    expect(ids.where((id) => id.startsWith('old-')), isEmpty);

    final second = await LaunchSyncPulls.mergeAndPruneTrips(capped, merge);
    expect(second, 0,
        reason: 'a second pull with the same server state must not '
            'write (and trim) anything');
    expect(capped.storedIds.toSet(), ids);
  });

  test('a failed/unauthenticated merge (input returned unchanged) '
      'removes NOTHING', () async {
    await repo.save(entry('trip-a', day: 1));
    await repo.save(entry('trip-b', day: 2));

    final changed = await LaunchSyncPulls.mergeAndPruneTrips(
      repo,
      (local) async => local,
    );

    expect(changed, 0);
    expect(repo.loadAll(), hasLength(2));
  });
}
