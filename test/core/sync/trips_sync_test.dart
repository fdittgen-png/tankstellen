// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/sync/trips_sync.dart';
import 'package:tankstellen/features/consumption/data/trip_history_repository.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';
import '../../helpers/silence_error_logger.dart';

/// #1479 phase 2 / #2239 — coverage of [TripsSync].
///
/// `TripsSync` reads the static `TankSyncClient.client` directly, so the
/// live wire `upsert` / `select` calls can't be exercised in a unit test
/// without a real Supabase client. Rather than mock the brittle
/// query-builder chain, the column-shape and merge-union logic are
/// factored into the pure, `@visibleForTesting` [TripsSync.buildSummaryRow]
/// and [TripsSync.mergeRows] seams — the wire methods just delegate to
/// them. These tests pin those seams plus the unauthenticated do-no-harm
/// guards.
void main() {
  silenceErrorLoggerSpool();

  group('TripsSync', () {
    test('uploadSummary is a no-op when not signed in', () async {
      final entry = TripHistoryEntry(
        id: 'test-trip-id',
        vehicleId: null,
        summary: TripSummary(
          startedAt: DateTime(2026, 5, 10, 10, 0),
          endedAt: DateTime(2026, 5, 10, 10, 30),
          distanceKm: 12.5,
          maxRpm: 3000,
          highRpmSeconds: 5,
          idleSeconds: 30,
          harshBrakes: 0,
          harshAccelerations: 0,
        ),
      );
      // The unauthenticated branch returns immediately; this test
      // proves it doesn't throw rather than asserting any I/O effect.
      await TripsSync.uploadSummary(entry);
    });

    test('deleteSummary is a no-op when not signed in', () async {
      // Same do-no-harm guarantee for the local-delete companion.
      await TripsSync.deleteSummary('test-trip-id');
    });

    test(
      '#1479 phase 3 — merge() returns local entries unchanged when not '
      'signed in (do-no-harm contract for the merge path)',
      () async {
        final local = [
          TripHistoryEntry(
            id: 'a',
            vehicleId: null,
            summary: TripSummary(
              startedAt: DateTime(2026, 5, 10, 9),
              endedAt: DateTime(2026, 5, 10, 9, 30),
              distanceKm: 8,
              maxRpm: 2500,
              highRpmSeconds: 0,
              idleSeconds: 60,
              harshBrakes: 0,
              harshAccelerations: 0,
            ),
          ),
        ];
        final merged = await TripsSync.merge(local);
        expect(merged, local,
            reason: 'unauth merge must return the input list verbatim');
      },
    );

    test(
      '#1479 phase 5 — forgetAllForUser is a no-op when not signed in',
      () async {
        await TripsSync.forgetAllForUser();
      },
    );

    test(
      '#1479 phase 5 — pruneOldDetails is a no-op when not signed in',
      () async {
        await TripsSync.pruneOldDetails();
        await TripsSync.pruneOldDetails(olderThanDays: 30);
      },
    );

    test(
      '#1541 phase 4 — uploadDetails is a no-op when not signed in',
      () async {
        final entry = TripHistoryEntry(
          id: 'details-noauth',
          vehicleId: null,
          summary: TripSummary(
            startedAt: DateTime(2026, 5, 11, 12),
            endedAt: DateTime(2026, 5, 11, 12, 20),
            distanceKm: 9,
            maxRpm: 2700,
            highRpmSeconds: 0,
            idleSeconds: 12,
            harshBrakes: 0,
            harshAccelerations: 0,
          ),
        );
        // No samples / gpsd here so even an authenticated caller would
        // skip the upsert. The point of THIS test is the auth gate.
        await TripsSync.uploadDetails(entry);
      },
    );

    test(
      '#1541 phase 4 — fetchDetails returns null when not signed in',
      () async {
        final result = await TripsSync.fetchDetails('any-trip-id');
        expect(result, isNull,
            reason: 'unauth fetch must return null so the trip-detail '
                'screen falls back to its empty-samples render path');
      },
    );
  });

  // ───────────────────────────────────────────────────────────────────
  // #2239 — uploadSummary writes the expected `trip_summaries` columns.
  // The wire `upsert` is delegated to the pure [buildSummaryRow]; pinning
  // it here proves the column contract that the (already-deployed)
  // migration's NOT-NULL `started_at` / `ended_at` + JSONB `data` rely
  // on, and that the heavy samples / gpsd arrays are stripped from the
  // compact summary blob.
  // ───────────────────────────────────────────────────────────────────
  group('TripsSync.buildSummaryRow — trip_summaries column contract', () {
    test('emits every expected column with the compact (samples-stripped) '
        'data blob', () {
      final started = DateTime.utc(2026, 5, 28, 9, 0);
      final ended = DateTime.utc(2026, 5, 28, 9, 42);
      final entry = TripHistoryEntry(
        id: '2026-05-28T09:00:00.000Z',
        vehicleId: 'veh-42',
        summary: TripSummary(
          startedAt: started,
          endedAt: ended,
          distanceKm: 21.5,
          maxRpm: 3200,
          highRpmSeconds: 8,
          idleSeconds: 40,
          harshBrakes: 1,
          harshAccelerations: 2,
          avgLPer100Km: 6.1,
          fuelLitersConsumed: 1.31,
        ),
        // Heavy per-tick payload that MUST NOT leak into the compact
        // summary blob (it belongs in trip_details).
        samples: [
          TripSample(
            timestamp: started,
            speedKmh: 0,
            rpm: 800,
          ),
          TripSample(
            timestamp: started.add(const Duration(seconds: 1)),
            speedKmh: 12,
            rpm: 1500,
          ),
        ],
      );

      final now = DateTime.utc(2026, 5, 28, 10, 0);
      final row = TripsSync.buildSummaryRow(entry, 'user-abc', now: now);

      // Server-side filter columns + composite-key columns.
      expect(row['id'], '2026-05-28T09:00:00.000Z');
      expect(row['user_id'], 'user-abc');
      expect(row['vehicle_id'], 'veh-42');
      expect(row['started_at'], started.toIso8601String());
      expect(row['ended_at'], ended.toIso8601String());
      expect(row['updated_at'], now.toIso8601String());

      // The compact `data` blob: a Map carrying the summary, but NOT the
      // heavy `samples` / `gpsd` arrays.
      final data = row['data'] as Map<String, dynamic>;
      expect(data['id'], entry.id);
      expect(data['vehicleId'], 'veh-42');
      expect(data.containsKey('summary'), isTrue);
      expect(data.containsKey('samples'), isFalse,
          reason: 'samples must stay in trip_details, not the summary blob');
      expect(data.containsKey('gpsd'), isFalse,
          reason: 'gps diagnostics must stay in trip_details');

      // The data blob is JSON-serialisable (Supabase JSONB round-trip).
      expect(() => jsonEncode(data), returnsNormally);
    });

    test('the row decodes back through TripHistoryEntry.fromJson — the '
        'shape merge() relies on for downloaded rows', () {
      final started = DateTime.utc(2026, 5, 28, 7, 0);
      final entry = TripHistoryEntry(
        id: 'roundtrip-1',
        vehicleId: 'veh-x',
        summary: TripSummary(
          startedAt: started,
          endedAt: started.add(const Duration(minutes: 15)),
          distanceKm: 7.2,
          maxRpm: 2600,
          highRpmSeconds: 0,
          idleSeconds: 22,
          harshBrakes: 0,
          harshAccelerations: 0,
        ),
      );
      final row = TripsSync.buildSummaryRow(entry, 'u1');
      final decoded = TripHistoryEntry.fromJson(
        (row['data'] as Map).cast<String, dynamic>(),
      );
      expect(decoded.id, 'roundtrip-1');
      expect(decoded.vehicleId, 'veh-x');
      expect(decoded.summary.distanceKm, 7.2);
      // Downloaded summaries carry no per-tick telemetry — that arrives
      // lazily from trip_details on first open.
      expect(decoded.samples, isEmpty);
    });
  });

  // ───────────────────────────────────────────────────────────────────
  // #2239 — REGRESSION for the "download silently discarded" bug class.
  //
  // The sibling AlertsSync defect was: merge() returned the merged
  // superset but the CALLER threw the return value away, so a row
  // recorded on another device never landed locally. TripsSync.merge
  // delegates the decode-and-union to the pure [mergeRows]; these tests
  // prove (a) downloaded rows ARE included in the returned superset and
  // (b) when that superset is persisted exactly as
  // `AppInitializer._runTripsSyncMerge` does it, the remote trip surfaces
  // in the local store.
  // ───────────────────────────────────────────────────────────────────
  group('TripsSync.mergeRows — applies downloaded entries (#2239)', () {
    Map<String, dynamic> serverRow(TripHistoryEntry e) => {
          'id': e.id,
          'data': TripsSync.buildSummaryRow(e, 'remote-user')['data'],
        };

    TripHistoryEntry mkEntry(String id, DateTime started) => TripHistoryEntry(
          id: id,
          vehicleId: 'veh-1',
          summary: TripSummary(
            startedAt: started,
            endedAt: started.add(const Duration(minutes: 18)),
            distanceKm: 9.4,
            maxRpm: 2900,
            highRpmSeconds: 3,
            idleSeconds: 28,
            harshBrakes: 0,
            harshAccelerations: 0,
          ),
        );

    test('server-only rows are appended to the local list (the superset '
        'the caller must persist)', () {
      final localA = mkEntry('local-a', DateTime.utc(2026, 5, 27, 8));
      final remoteB = mkEntry('remote-b', DateTime.utc(2026, 5, 28, 8));

      final merged = TripsSync.mergeRows(
        [localA],
        [serverRow(localA), serverRow(remoteB)],
      );

      final ids = merged.map((e) => e.id).toList();
      expect(ids, containsAll(<String>['local-a', 'remote-b']),
          reason: 'the downloaded remote trip MUST appear in the result; '
              'discarding it is the bug this guards');
      expect(merged.length, 2);
    });

    test('local entries win on id collision — no duplicate, local kept', () {
      final shared = mkEntry('shared', DateTime.utc(2026, 5, 26, 8));
      final merged = TripsSync.mergeRows([shared], [serverRow(shared)]);
      expect(merged, hasLength(1));
      expect(identical(merged.first, shared), isTrue,
          reason: 'local-wins: the kept entry is the local instance');
    });

    test('a corrupt server row is skipped, not fatal to the merge', () {
      final remoteB = mkEntry('remote-b', DateTime.utc(2026, 5, 28, 8));
      final merged = TripsSync.mergeRows(
        const [],
        [
          {'id': 'corrupt', 'data': 'not-a-map'}, // bad shape → skipped
          serverRow(remoteB),
        ],
      );
      expect(merged.map((e) => e.id), ['remote-b']);
    });

    test(
      'persisting the merged superset (as AppInitializer does) surfaces the '
      'remote trip in the local Hive store',
      () async {
        TestWidgetsFlutterBinding.ensureInitialized();
        final tmpDir =
            Directory.systemTemp.createTempSync('trips_merge_persist_');
        Hive.init(tmpDir.path);
        final box = await Hive.openBox<String>(
          'merge_${DateTime.now().microsecondsSinceEpoch}',
        );
        addTearDown(() async {
          await box.deleteFromDisk();
          await Hive.close();
          tmpDir.deleteSync(recursive: true);
        });

        final repo = TripHistoryRepository(box: box);
        // Device starts with one locally-recorded trip.
        final localA = mkEntry('local-a', DateTime.utc(2026, 5, 27, 8));
        await repo.save(localA);

        // Sync pass downloads a trip recorded on another device.
        final remoteB = mkEntry('remote-b', DateTime.utc(2026, 5, 28, 8));
        final local = repo.loadAll();
        final localIds = local.map((e) => e.id).toSet();
        final merged = TripsSync.mergeRows(local, [serverRow(remoteB)]);

        // Exactly the persist-back loop from
        // AppInitializer._runTripsSyncMerge.
        for (final entry in merged) {
          if (localIds.contains(entry.id)) continue;
          await repo.save(entry);
        }

        final after = repo.loadAll().map((e) => e.id).toSet();
        expect(after, containsAll(<String>{'local-a', 'remote-b'}),
            reason: 'the cross-device trip must be readable locally after '
                'the merge is persisted');
      },
    );
  });
}
