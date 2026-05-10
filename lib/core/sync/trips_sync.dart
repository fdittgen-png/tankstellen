import 'package:flutter/foundation.dart';

import '../../features/consumption/data/trip_history_repository.dart';
import 'supabase_client.dart';

/// Per-trip-summary sync with Supabase (#1479 phase 2).
///
/// Phase-2 scope: ONE-WAY upload of trip summaries from the local
/// rolling log to `public.trip_summaries`. Per-trip detail rows
/// (`public.trip_details` with full pointSamples + GPS diagnostics)
/// are deferred to phase 4 so phase 2 ships the cross-device list
/// view without paying the per-trip bandwidth cost up front.
///
/// Same column shape as the migration in
/// `supabase/migrations/20260507000001_trip_summaries_and_details.sql`:
/// `(user_id, id)` is the primary key, `vehicle_id` /
/// `started_at` / `ended_at` are server-side filters, and `data`
/// carries the compact summary JSON (no samples, no gpsd) so a
/// 60-min trip stays around 1 KB rather than 250 KB.
///
/// Mirrors [FillUpsSync] / [VehiclesSync]:
/// - Unauthenticated callers return early without surfacing an error.
/// - Failures `debugPrint` and swallow — the local entry stays the
///   source of truth, the next save retries the upload.
/// - The download / merge half lands in phase 3.
class TripsSync {
  TripsSync._();

  /// Upload [entry] to `public.trip_summaries`. No-op when the user
  /// isn't signed into TankSync.
  ///
  /// Caller is responsible for the consent gate (`consentSyncTrips`)
  /// — the wire layer doesn't read consent so it stays a pure I/O
  /// helper; consent decisions live next to the user-visible toggle.
  static Future<void> uploadSummary(TripHistoryEntry entry) async {
    final client = TankSyncClient.client;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) {
      debugPrint('TripsSync.uploadSummary: not authenticated, skipping');
      return;
    }
    final startedAt = entry.summary.startedAt;
    final endedAt = entry.summary.endedAt;
    if (startedAt == null || endedAt == null) {
      // A trip with no timestamps cannot satisfy the
      // NOT-NULL `started_at` / `ended_at` columns. Silently skip —
      // happens for empty / aborted trips that the user wouldn't
      // want synced anyway.
      debugPrint(
        'TripsSync.uploadSummary: ${entry.id} has null timestamps; '
        'skipping upload',
      );
      return;
    }
    try {
      await client.from('trip_summaries').upsert({
        'id': entry.id,
        'user_id': userId,
        'vehicle_id': entry.vehicleId,
        'started_at': startedAt.toIso8601String(),
        'ended_at': endedAt.toIso8601String(),
        // The summary blob stays compact: just the entity's JSON form
        // WITHOUT the per-tick `samples` and GPS-diagnostics arrays
        // so a 60-min commute is ~1 KB instead of ~250 KB. The full-
        // detail row lands in phase 4 under `public.trip_details`.
        'data': _compactSummaryJson(entry),
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,id');
      debugPrint('TripsSync.uploadSummary: uploaded ${entry.id}');
    } catch (e, st) {
      debugPrint('TripsSync.uploadSummary FAILED for ${entry.id}: $e\n$st');
    }
  }

  /// Remove a single trip from the server (called when the user
  /// deletes the trip locally). Silent on failure — the local
  /// delete is the canonical signal; a stale server row is
  /// reconciled on the next sync pass (phase 3).
  static Future<void> deleteSummary(String tripId) async {
    final client = TankSyncClient.client;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return;
    try {
      await client
          .from('trip_summaries')
          .delete()
          .eq('user_id', userId)
          .eq('id', tripId);
    } catch (e, st) {
      debugPrint('TripsSync.deleteSummary FAILED for $tripId: $e\n$st');
    }
  }
}

/// Strips the per-tick `samples` and GPS-diagnostics arrays from a
/// [TripHistoryEntry]'s JSON form so the upload payload stays under
/// the 1 KB target for `public.trip_summaries.data` (#1479 phase 2).
///
/// The full-detail blob (samples + gpsd) is the phase-4 concern and
/// lands in `public.trip_details` — keeping the summary tight here
/// means the cross-device list view (phase 3) can paginate without
/// dragging a year of trip telemetry through every fetch.
Map<String, dynamic> _compactSummaryJson(TripHistoryEntry entry) {
  final json = entry.toJson();
  json.remove('samples');
  json.remove('gpsd');
  return json;
}
