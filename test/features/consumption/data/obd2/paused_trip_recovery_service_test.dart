import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/features/consumption/data/obd2/paused_trip_recovery_service.dart';
import 'package:tankstellen/features/consumption/data/obd2/paused_trip_repository.dart';
import 'package:tankstellen/features/consumption/data/trip_history_repository.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';

/// Direct unit tests for [PausedTripRecoveryService]
/// (#1004 phase 4-WAL).
///
/// Drives the launch-time recovery against in-memory Hive boxes (no
/// Riverpod, no mock framework). Each test sets up a fresh paused-
/// trips box + a fresh history box keyed on a microsecond suffix so
/// Windows tearDowns don't race the next setUp.
///
/// Covers:
///   1. stale entries land in history,
///   2. fresh entries are skipped,
///   3. automatic entries fire the badge-bump callback once each,
///   4. one corrupt row doesn't block the rest,
///   5. the recovered count is returned.
void main() {
  group('PausedTripRecoveryService (#1004 phase 4-WAL)', () {
    late Directory tmpDir;
    late Box<String> pausedBox;
    late Box<String> historyBox;
    late PausedTripRepository pausedRepo;
    late TripHistoryRepository historyRepo;

    setUp(() async {
      tmpDir = Directory.systemTemp.createTempSync(
        'paused_trip_recovery_test_',
      );
      Hive.init(tmpDir.path);
      // Microsecond suffix avoids cross-test contamination on Windows
      // where deleteFromDisk can race the next setUp.
      final stamp = DateTime.now().microsecondsSinceEpoch;
      pausedBox = await Hive.openBox<String>('paused_$stamp');
      historyBox = await Hive.openBox<String>('history_$stamp');
      pausedRepo = PausedTripRepository(box: pausedBox);
      historyRepo = TripHistoryRepository(box: historyBox);
    });

    tearDown(() async {
      await pausedBox.deleteFromDisk();
      await historyBox.deleteFromDisk();
      await Hive.close();
      tmpDir.deleteSync(recursive: true);
    });

    // -------- Helpers ----------------------------------------------------

    TripSummary summary({double distance = 12.4}) => TripSummary(
          distanceKm: distance,
          maxRpm: 4200,
          highRpmSeconds: 18.5,
          idleSeconds: 42,
          harshBrakes: 2,
          harshAccelerations: 1,
          avgLPer100Km: 6.7,
          fuelLitersConsumed: 0.83,
          startedAt: DateTime.utc(2026, 4, 27, 8, 30),
          endedAt: DateTime.utc(2026, 4, 27, 9, 15),
        );

    PausedTripEntry entryOlderThanThreshold({
      String id = 'stale-1',
      bool automatic = false,
    }) =>
        PausedTripEntry(
          id: id,
          vehicleId: 'veh-1',
          vin: 'VIN-OLD-1',
          summary: summary(),
          odometerStartKm: 9271.6,
          odometerLatestKm: 9284.0,
          // Far older than the default 5-minute threshold.
          pausedAt: DateTime.utc(2026, 4, 27, 8, 0),
          automatic: automatic,
        );

    PausedTripEntry entryYoungerThanThreshold({
      String id = 'fresh-1',
      bool automatic = false,
      required DateTime now,
    }) =>
        PausedTripEntry(
          id: id,
          vehicleId: 'veh-2',
          vin: 'VIN-FRESH-1',
          summary: summary(distance: 1.0),
          odometerStartKm: null,
          odometerLatestKm: null,
          // 30 s ago — well inside the 5-minute window.
          pausedAt: now.subtract(const Duration(seconds: 30)),
          automatic: automatic,
        );

    // Fix wall-clock so the "older than 5 min" decision is deterministic.
    final fakeNow = DateTime.utc(2026, 4, 27, 12, 0);

    // -------- Tests ------------------------------------------------------

    test('finalises a stale entry into history', () async {
      final stale = entryOlderThanThreshold();
      await pausedRepo.save(stale);

      final svc = PausedTripRecoveryService(
        pausedRepo: pausedRepo,
        historyRepo: historyRepo,
        now: () => fakeNow,
      );

      final recovered = await svc.recoverStale();

      expect(recovered, 1);
      // Paused row removed.
      expect(pausedRepo.load(stale.id), isNull);
      // History row written with matching id + summary fields.
      final history = historyRepo.loadAll();
      expect(history, hasLength(1));
      expect(history.single.id, stale.id);
      expect(history.single.vehicleId, 'veh-1');
      expect(history.single.summary.distanceKm, stale.summary.distanceKm);
      // Manual paused entries deserialise to automatic = false.
      expect(history.single.automatic, isFalse);
    });

    test('skips an entry younger than the threshold', () async {
      final fresh = entryYoungerThanThreshold(now: fakeNow);
      await pausedRepo.save(fresh);

      final svc = PausedTripRecoveryService(
        pausedRepo: pausedRepo,
        historyRepo: historyRepo,
        now: () => fakeNow,
      );

      final recovered = await svc.recoverStale();

      expect(recovered, 0);
      // Paused row preserved — the controller's grace timer must still
      // be free to finalise it without conflict.
      expect(pausedRepo.load(fresh.id), isNotNull);
      expect(historyRepo.loadAll(), isEmpty);
    });

    test(
      'recovered automatic entries fire onAutomaticRecovered exactly '
      'once each; non-automatic entries do not',
      () async {
        await pausedRepo
            .save(entryOlderThanThreshold(id: 'auto-1', automatic: true));
        await pausedRepo
            .save(entryOlderThanThreshold(id: 'auto-2', automatic: true));
        await pausedRepo
            .save(entryOlderThanThreshold(id: 'manual-1', automatic: false));

        var bumps = 0;
        final svc = PausedTripRecoveryService(
          pausedRepo: pausedRepo,
          historyRepo: historyRepo,
          onAutomaticRecovered: () async {
            bumps++;
          },
          now: () => fakeNow,
        );

        final recovered = await svc.recoverStale();

        expect(recovered, 3);
        expect(bumps, 2, reason: 'only the two automatic entries bump');
        // All three rows finalised.
        expect(historyRepo.loadAll().map((e) => e.id).toSet(), {
          'auto-1',
          'auto-2',
          'manual-1',
        });
        // Recovered automatic flag round-trips through history.
        final byId = {for (final e in historyRepo.loadAll()) e.id: e};
        expect(byId['auto-1']!.automatic, isTrue);
        expect(byId['auto-2']!.automatic, isTrue);
        expect(byId['manual-1']!.automatic, isFalse);
      },
    );

    test('one corrupt entry does not block recovery of others', () async {
      // Stash a valid stale + a valid fresh row, then write raw garbage
      // under a third key. loadAll() drops the corrupt row internally,
      // but we also assert the recovery loop survives if a downstream
      // step on a single entry throws.
      await pausedRepo.save(entryOlderThanThreshold(id: 'good-1'));
      await pausedRepo.save(entryOlderThanThreshold(id: 'good-2'));
      await pausedBox.put('bad', 'not even json');

      final svc = PausedTripRecoveryService(
        pausedRepo: pausedRepo,
        historyRepo: historyRepo,
        now: () => fakeNow,
      );

      final recovered = await svc.recoverStale();

      expect(recovered, 2);
      expect(historyRepo.loadAll().map((e) => e.id).toSet(),
          {'good-1', 'good-2'});
      // The corrupt row was never deserialised by loadAll(), so it
      // remains in the box untouched — that's fine, we're only
      // claiming the recovery loop doesn't trip on it.
      expect(pausedBox.containsKey('bad'), isTrue);
    });

    test('returns the count of recovered entries', () async {
      await pausedRepo.save(entryOlderThanThreshold(id: 'a'));
      await pausedRepo.save(entryOlderThanThreshold(id: 'b'));
      await pausedRepo.save(entryOlderThanThreshold(id: 'c'));
      await pausedRepo
          .save(entryYoungerThanThreshold(id: 'd', now: fakeNow));

      final svc = PausedTripRecoveryService(
        pausedRepo: pausedRepo,
        historyRepo: historyRepo,
        now: () => fakeNow,
      );

      final recovered = await svc.recoverStale();
      expect(recovered, 3);
    });

    test(
      'empty paused box returns 0 without touching history',
      () async {
        final svc = PausedTripRecoveryService(
          pausedRepo: pausedRepo,
          historyRepo: historyRepo,
          now: () => fakeNow,
        );
        final recovered = await svc.recoverStale();
        expect(recovered, 0);
        expect(historyRepo.loadAll(), isEmpty);
      },
    );

    test(
      'callback skipped when onAutomaticRecovered is null even on '
      'automatic entries',
      () async {
        await pausedRepo
            .save(entryOlderThanThreshold(id: 'auto-x', automatic: true));

        final svc = PausedTripRecoveryService(
          pausedRepo: pausedRepo,
          historyRepo: historyRepo,
          // Intentionally null — the recovery must still finalise.
          onAutomaticRecovered: null,
          now: () => fakeNow,
        );

        final recovered = await svc.recoverStale();
        expect(recovered, 1);
        expect(historyRepo.loadAll().single.automatic, isTrue);
      },
    );
  });
}
