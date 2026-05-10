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
  });
}
