// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/features/obd2/data/active_trip_recovery_service.dart';
import 'package:tankstellen/features/obd2/data/active_trip_repository.dart';
import 'package:tankstellen/features/obd2/data/paused_trip_repository.dart';
import 'package:tankstellen/features/trips/data/trip_history_repository.dart';
import 'package:tankstellen/features/trips/domain/trip_recorder.dart';
import '../../../helpers/hive_temp_dir.dart';
import '../../../helpers/silence_error_logger.dart';

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
  silenceErrorLoggerSpool();
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
      await closeHiveAndDeleteTemp(tmpDir);
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

    test('#4328 — a snapshot whose trip is already in history is retired '
        'with its paused row, not recovered', () async {
      final snap = freshSnapshot();
      await activeRepo.saveSnapshot(snap);
      await historyRepo.save(
          TripHistoryEntry(id: snap.id, vehicleId: 'veh-1', summary: summary()));
      final pausedBox = await Hive.openBox<String>('paused_4328');
      addTearDown(pausedBox.deleteFromDisk);
      final pausedRepo = PausedTripRepository(box: pausedBox);
      await pausedRepo.save(PausedTripEntry(
        id: snap.id,
        vehicleId: 'veh-1',
        vin: null,
        summary: summary(),
        odometerStartKm: null,
        odometerLatestKm: null,
        pausedAt: fakeNow.subtract(const Duration(minutes: 3)),
      ));

      final svc = ActiveTripRecoveryService(
        activeRepo: activeRepo,
        historyRepo: historyRepo,
        pausedRepo: pausedRepo,
        now: () => fakeNow,
      );

      expect(await svc.recover(), ActiveTripRecoveryOutcome.alreadySaved);
      expect(svc.recoveredSnapshot, isNull);
      expect(activeRepo.loadSnapshot(), isNull);
      expect(pausedRepo.load(snap.id), isNull);
      expect(historyRepo.loadAll(), hasLength(1));
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

    test(
        '#3250 — a fresh snapshot whose phase is already terminal '
        'is DISCARDED + cleared, not resurrected', () async {
      // #4243 — 'stopped' is the only terminal wire value any version
      // ever wrote; the loop used to include 'saved', which no producer
      // has ever emitted.
      for (final phase in ['stopped']) {
        await activeRepo.clearSnapshot();
        // Fresh by timestamp, but the trip was already finalised to history —
        // recovering it would re-surface a saved trip + overwrite it on End.
        await activeRepo.saveSnapshot(
          ActiveTripSnapshot(
            id: 'session-$phase',
            vehicleId: 'veh-1',
            vin: 'VIN',
            automatic: false,
            phase: phase,
            summary: summary(),
            samples: const [],
            odometerStartKm: 100.0,
            odometerLatestKm: 105.0,
            startedAt: fakeNow.subtract(const Duration(minutes: 30)),
            lastFlushedAt: fakeNow.subtract(const Duration(minutes: 2)),
          ),
        );
        final svc = ActiveTripRecoveryService(
          activeRepo: activeRepo,
          historyRepo: historyRepo,
          now: () => fakeNow,
        );
        final outcome = await svc.recover();
        expect(outcome, ActiveTripRecoveryOutcome.discarded,
            reason: 'phase=$phase is already finalised — never recovered');
        expect(svc.recoveredSnapshot, isNull);
        expect(activeRepo.loadSnapshot(), isNull,
            reason: 'the zombie WAL must be cleared (phase=$phase)');
      }
    });

    test('#4243 — an UNRECOGNISED phase is not treated as finalised: it '
        'reaches the staleness check instead of being discarded', () async {
      await activeRepo.clearSnapshot();
      await activeRepo.saveSnapshot(
        ActiveTripSnapshot(
          id: 'session-future',
          vehicleId: 'veh-1',
          vin: 'VIN',
          automatic: false,
          // A value a future version might write, or a corrupt row.
          phase: 'someFuturePhase',
          summary: summary(),
          samples: const [],
          odometerStartKm: 100.0,
          odometerLatestKm: 105.0,
          startedAt: fakeNow.subtract(const Duration(minutes: 30)),
          lastFlushedAt: fakeNow.subtract(const Duration(minutes: 2)),
        ),
      );
      final svc = ActiveTripRecoveryService(
        activeRepo: activeRepo,
        historyRepo: historyRepo,
        now: () => fakeNow,
      );
      // Fresh by timestamp, so it is RECOVERED — losing somebody's live
      // drive because this build cannot name its phase is the worse of
      // the two failures.
      expect(await svc.recover(), ActiveTripRecoveryOutcome.recovered);
      expect(svc.recoveredSnapshot?.id, 'session-future');
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
