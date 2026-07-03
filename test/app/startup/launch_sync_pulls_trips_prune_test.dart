// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/app/startup/launch_sync_pulls.dart';
import 'package:tankstellen/features/consumption/data/trip_history_repository.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';

import '../../helpers/silence_error_logger.dart';

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
    await Hive.close();
    tmpDir.deleteSync(recursive: true);
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
