// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sync/trips_sync.dart';
import 'package:tankstellen/features/consumption/data/trip_history_repository.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';

/// #1479 phase 2 — surface-level coverage of [TripsSync].
///
/// We don't stand up a real Supabase client here; the wire layer is
/// exercised by the manual end-to-end checklist in
/// `docs/guides/tanksync-trips.md` and by Phase 3's merge tests when
/// they land. What we DO pin here:
///   - `uploadSummary` is a no-op when nothing is signed in (does not
///     throw, does not crash on a missing client).
///   - `deleteSummary` is a no-op when nothing is signed in.
///
/// These are the "do-no-harm" guarantees the recording-stop hook
/// relies on so an unauthenticated user with `consentSyncTrips=true`
/// (rare, but possible if they signed out without revoking the
/// consent) doesn't wedge the local save path.
void main() {
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
}
