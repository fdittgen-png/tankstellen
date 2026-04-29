import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/features/consumption/data/obd2/active_trip_recovery_service.dart';
import 'package:tankstellen/features/consumption/data/obd2/active_trip_repository.dart';
import 'package:tankstellen/features/consumption/data/trip_history_repository.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';

/// Direct unit tests for [ActiveTripRecoveryService] (#1303).
///
/// Mirrors the [PausedTripRecoveryService] test pattern: drives the
/// service against a fresh in-memory Hive box, fixes wall-clock for
/// determinism, and verifies the four cardinal cases:
///
///   1. no snapshot on disk → outcome.none, no recovery,
///   2. fresh snapshot → outcome.recovered + non-null
///      recoveredSnapshot,
///   3. stale snapshot → outcome.discarded + box cleared,
///   4. corrupt snapshot → outcome.none (loadSnapshot already
///      returns null on corrupt payloads),
///   5. stale automatic snapshot → onAutomaticRecovered fires once,
///   6. fresh automatic snapshot does NOT fire onAutomaticRecovered
///      from the recovery path (the wiring layer bumps the badge
///      after restoreFromSnapshot succeeds, not here),
///   7. failures inside loadSnapshot don't crash recovery.
void main() {
  group('ActiveTripRecoveryService (#1303)', () {
    late Directory tmpDir;
    late Box<String> box;
    late ActiveTripRepository activeRepo;
    late Box<String> historyBox;
    late TripHistoryRepository historyRepo;

    setUp(() async {
      tmpDir = Directory.systemTemp.createTempSync(
        'active_trip_recovery_test_',
      );
      Hive.init(tmpDir.path);
      final stamp = DateTime.now().microsecondsSinceEpoch;
      box = await Hive.openBox<String>('active_$stamp');
      historyBox = await Hive.openBox<String>('history_$stamp');
      activeRepo = ActiveTripRepository(box: box);
      historyRepo = TripHistoryRepository(box: historyBox);
    });

    tearDown(() async {
      await box.deleteFromDisk();
      await historyBox.deleteFromDisk();
      await Hive.close();
      tmpDir.deleteSync(recursive: true);
    });

    // -------- Helpers ----------------------------------------------------

    final fakeNow = DateTime.utc(2026, 4, 28, 12, 0);

    TripSummary summary() => const TripSummary(
          distanceKm: 5.5,
          maxRpm: 3500,
          highRpmSeconds: 2,
          idleSeconds: 30,
          harshBrakes: 1,
          harshAccelerations: 0,
        );

    ActiveTripSnapshot freshSnapshot({bool automatic = false}) =>
        ActiveTripSnapshot(
          id: 'session-fresh',
          vehicleId: 'veh-1',
          vin: 'VIN-FRESH',
          automatic: automatic,
          phase: 'recording',
          summary: summary(),
          samples: const [],
          odometerStartKm: 100.0,
          odometerLatestKm: 105.0,
          startedAt: fakeNow.subtract(const Duration(minutes: 30)),
          // 2 minutes ago — well within the 24 h window.
          lastFlushedAt: fakeNow.subtract(const Duration(minutes: 2)),
        );

    ActiveTripSnapshot staleSnapshot({bool automatic = false}) =>
        ActiveTripSnapshot(
          id: 'session-stale',
          vehicleId: 'veh-1',
          vin: 'VIN-STALE',
          automatic: automatic,
          phase: 'recording',
          summary: summary(),
          samples: const [],
          odometerStartKm: 100.0,
          odometerLatestKm: 105.0,
          startedAt: fakeNow.subtract(const Duration(days: 3)),
          // 25 hours ago — past the default 24 h staleness window.
          lastFlushedAt: fakeNow.subtract(const Duration(hours: 25)),
        );

    // -------- Tests ------------------------------------------------------

    test('no snapshot on disk returns none', () async {
      final svc = ActiveTripRecoveryService(
        activeRepo: activeRepo,
        historyRepo: historyRepo,
        now: () => fakeNow,
      );

      final outcome = await svc.recover();
      expect(outcome, ActiveTripRecoveryOutcome.none);
      expect(svc.recoveredSnapshot, isNull);
    });

    test('fresh snapshot is recovered, not cleared from disk', () async {
      final snap = freshSnapshot();
      await activeRepo.saveSnapshot(snap);

      final svc = ActiveTripRecoveryService(
        activeRepo: activeRepo,
        historyRepo: historyRepo,
        now: () => fakeNow,
      );

      final outcome = await svc.recover();
      expect(outcome, ActiveTripRecoveryOutcome.recovered);
      expect(svc.recoveredSnapshot, isNotNull);
      expect(svc.recoveredSnapshot!.id, 'session-fresh');
      // Recovery does NOT clear the snapshot on success — the
      // provider takes ownership and clears via [reset]/[stop]
      // or rewrites it on the next live sample.
      expect(activeRepo.loadSnapshot(), isNotNull);
    });

    test('stale snapshot is discarded and cleared from disk', () async {
      final snap = staleSnapshot();
      await activeRepo.saveSnapshot(snap);

      final svc = ActiveTripRecoveryService(
        activeRepo: activeRepo,
        historyRepo: historyRepo,
        now: () => fakeNow,
      );

      final outcome = await svc.recover();
      expect(outcome, ActiveTripRecoveryOutcome.discarded);
      expect(svc.recoveredSnapshot, isNull);
      expect(activeRepo.loadSnapshot(), isNull);
    });

    test(
      'stale automatic snapshot fires onAutomaticRecovered exactly once',
      () async {
        await activeRepo.saveSnapshot(staleSnapshot(automatic: true));

        var bumps = 0;
        final svc = ActiveTripRecoveryService(
          activeRepo: activeRepo,
          historyRepo: historyRepo,
          onAutomaticRecovered: () async {
            bumps++;
          },
          now: () => fakeNow,
        );

        final outcome = await svc.recover();
        expect(outcome, ActiveTripRecoveryOutcome.discarded);
        expect(bumps, 1);
      },
    );

    test('stale manual snapshot does NOT fire onAutomaticRecovered', () async {
      await activeRepo.saveSnapshot(staleSnapshot(automatic: false));

      var bumps = 0;
      final svc = ActiveTripRecoveryService(
        activeRepo: activeRepo,
        historyRepo: historyRepo,
        onAutomaticRecovered: () async {
          bumps++;
        },
        now: () => fakeNow,
      );

      final outcome = await svc.recover();
      expect(outcome, ActiveTripRecoveryOutcome.discarded);
      expect(bumps, 0);
    });

    test(
      'fresh automatic snapshot does NOT fire onAutomaticRecovered '
      'on the recovery path — wiring fires the badge after restore',
      () async {
        await activeRepo.saveSnapshot(freshSnapshot(automatic: true));

        var bumps = 0;
        final svc = ActiveTripRecoveryService(
          activeRepo: activeRepo,
          historyRepo: historyRepo,
          onAutomaticRecovered: () async {
            bumps++;
          },
          now: () => fakeNow,
        );

        final outcome = await svc.recover();
        expect(outcome, ActiveTripRecoveryOutcome.recovered);
        expect(bumps, 0,
            reason: 'recovery path leaves badging to the wiring layer');
      },
    );

    test(
      'a corrupt payload behaves like an empty box (none)',
      () async {
        await box.put('active', 'not even json');

        final svc = ActiveTripRecoveryService(
          activeRepo: activeRepo,
          historyRepo: historyRepo,
          now: () => fakeNow,
        );

        final outcome = await svc.recover();
        // loadSnapshot returns null on corrupt payloads, so the
        // service treats it identically to "no snapshot".
        expect(outcome, ActiveTripRecoveryOutcome.none);
        expect(svc.recoveredSnapshot, isNull);
      },
    );

    test('staleAfter override changes the threshold', () async {
      // 2 minutes ago — fresh under the default but stale under a
      // 1-minute override. Verifies the override actually wires.
      await activeRepo.saveSnapshot(freshSnapshot());

      final svc = ActiveTripRecoveryService(
        activeRepo: activeRepo,
        historyRepo: historyRepo,
        staleAfter: const Duration(minutes: 1),
        now: () => fakeNow,
      );

      final outcome = await svc.recover();
      expect(outcome, ActiveTripRecoveryOutcome.discarded);
    });

    test(
      'callback throw on stale recovery does not derail the clear',
      () async {
        await activeRepo.saveSnapshot(staleSnapshot(automatic: true));

        final svc = ActiveTripRecoveryService(
          activeRepo: activeRepo,
          historyRepo: historyRepo,
          onAutomaticRecovered: () async {
            throw StateError('badge service offline');
          },
          now: () => fakeNow,
        );

        final outcome = await svc.recover();
        expect(outcome, ActiveTripRecoveryOutcome.discarded);
        // The discarded snapshot is still gone — callback errors
        // are caught and logged, not propagated.
        expect(activeRepo.loadSnapshot(), isNull);
      },
    );
  });
}
