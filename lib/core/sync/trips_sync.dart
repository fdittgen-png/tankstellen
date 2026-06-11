// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/consumption/data/trip_history_repository.dart';
import 'deletions_sync.dart';
import 'supabase_client.dart';
import 'trips_sync_json.dart';
import '../../core/logging/error_logger.dart';

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
      await client
          .from('trip_summaries')
          .upsert(buildSummaryRow(entry, userId), onConflict: 'user_id,id');
      debugPrint('TripsSync.uploadSummary: uploaded ${entry.id}');
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.sync, e, st, context: {'where': 'TripsSync.uploadSummary FAILED for ${entry.id}'}));
    }
    // Phase 4 (#1541) — fan out the heavy blob to `trip_details`.
    // [uploadDetails] no-ops when the entry has no samples /
    // diagnostics, so legacy / empty trips don't pay a wasted round
    // trip. Errors are logged inside and intentionally don't propagate
    // — a missing details row is a soft degradation (the list view
    // still works), not a hard failure of the summary upload.
    await uploadDetails(entry);
  }

  /// Upload the heavy per-tick blob — `samples` + `gpsd` — for [entry]
  /// to `public.trip_details` (#1479 phase 4). No-op when the user
  /// isn't signed in or when the entry carries no samples and no
  /// diagnostics (an empty payload would just round-trip as nothing).
  ///
  /// Sibling to [uploadSummary]: the summary table powers the cheap
  /// cross-device list view, the details table is the per-trip blob
  /// fetched on-demand when the user opens a trip recorded on
  /// another phone. Same `(user_id, id)` composite primary key as
  /// the migration in
  /// `supabase/migrations/20260507000001_trip_summaries_and_details.sql`.
  static Future<void> uploadDetails(TripHistoryEntry entry) async {
    final client = TankSyncClient.client;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) {
      debugPrint('TripsSync.uploadDetails: not authenticated, skipping');
      return;
    }
    if (entry.samples.isEmpty && entry.gpsSampleDiagnostics.isEmpty) {
      // Nothing heavy to ship — the compact summary already
      // carries everything the list view needs.
      return;
    }
    try {
      await client.from('trip_details').upsert({
        'id': entry.id,
        'user_id': userId,
        'data': tripDetailsJson(entry),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'user_id,id');
      debugPrint('TripsSync.uploadDetails: uploaded ${entry.id}');
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.sync, e, st, context: {'where': 'TripsSync.uploadDetails FAILED for ${entry.id}'}));
    }
  }

  /// Fetch the `trip_details.data` blob for [tripId] — `{samples, gpsd}`
  /// — or `null` when the row is missing (server has no details), the
  /// user isn't signed in, or the fetch fails. The trip-detail screen
  /// calls this lazily when the local Hive entry has empty samples
  /// (typically because it was downloaded by [merge] from another
  /// device).
  static Future<Map<String, dynamic>?> fetchDetails(String tripId) async {
    final client = TankSyncClient.client;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) {
      debugPrint('TripsSync.fetchDetails: not authenticated');
      return null;
    }
    try {
      final row = await client
          .from('trip_details')
          .select('data')
          .eq('user_id', userId)
          .eq('id', tripId)
          .maybeSingle();
      if (row == null) return null;
      final data = row['data'];
      if (data is! Map) return null;
      return data.cast<String, dynamic>();
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.sync, e, st, context: {'where': 'TripsSync.fetchDetails FAILED for $tripId'}));
      return null;
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
      await DeletionsSync.record('trip_summaries', tripId); // #3123 first
      await client
          .from('trip_summaries')
          .delete()
          .eq('user_id', userId)
          .eq('id', tripId);
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.sync, e, st, context: {'where': 'TripsSync.deleteSummary FAILED for $tripId'}));
    }
  }

  /// Merge [localEntries] with the user's `trip_summaries` rows on
  /// Supabase (#1479 phase 3). Returns the union (local + server-only)
  /// so the caller can persist any newly-downloaded summaries into
  /// the local Hive box for cross-device continuity.
  ///
  /// - Unauthenticated → returns the input unchanged.
  /// - Local-only entries are uploaded (mirrors the
  ///   [uploadSummary] path so a missing server row is healed).
  /// - Server-only entries are decoded from the compact summary JSON
  ///   and added to the result. Their `samples` + `gpsd` fields are
  ///   empty (those live in `trip_details` and arrive on demand in
  ///   phase 4).
  /// - Decode failures are skipped silently — one corrupt row should
  ///   never block the whole merge.
  static Future<List<TripHistoryEntry>> merge(
    List<TripHistoryEntry> localEntries,
  ) async {
    final client = TankSyncClient.client;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) {
      debugPrint('TripsSync.merge: not authenticated');
      return localEntries;
    }
    try {
      final serverRows = await client
          .from('trip_summaries')
          .select('id, data')
          .eq('user_id', userId);

      // #3078 — a trip deleted on another device must not resurrect. Drop
      // tombstoned ids from BOTH the re-upload set and the downloaded union.
      final tombstoned =
          await DeletionsSync.fetchTombstonedIds('trip_summaries');
      final liveLocal =
          localEntries.where((e) => !tombstoned.contains(e.id)).toList();
      final serverIds = <String>{};
      for (final r in serverRows) {
        final id = r['id'];
        if (id is String && !tombstoned.contains(id)) serverIds.add(id);
      }

      // Upload local-only entries (heals a missing server row from a
      // previous offline save). #2319 — batch the Nx2 round-trips into
      // one upsert each instead of a serial per-entry loop.
      final localOnly =
          liveLocal.where((e) => !serverIds.contains(e.id)).toList();
      await _uploadBatch(client, userId, localOnly);

      // Decode server-only rows and return the union — the superset the
      // app-launch caller persists back to Hive (see
      // `AppInitializer._runTripsSyncMerge`; #2239 pins this seam).
      final merged = mergeRows(liveLocal, serverRows, tombstoned: tombstoned);
      debugPrint('TripsSync.merge: local=${liveLocal.length} '
          'server=${serverIds.length} '
          'downloaded=${merged.length - liveLocal.length}');
      return merged;
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.sync, e, st, context: const {'where': 'TripsSync.merge FAILED'}));
      return localEntries;
    }
  }

  /// Bulk-upload [entries] to `trip_summaries` + `trip_details` in one
  /// upsert each (#2319), preserving the single-trip contracts: null-
  /// timestamp entries are skipped (NOT-NULL summary columns), entries
  /// with no samples/gpsd add no details row, and the two upserts are
  /// isolated so one failure never blocks the other. The single-trip
  /// [uploadSummary] path is untouched.
  static Future<void> _uploadBatch(
    SupabaseClient client,
    String userId,
    List<TripHistoryEntry> entries,
  ) async {
    await _batchUpsert(client, 'trip_summaries', buildSummaryRows(entries, userId));
    await _batchUpsert(client, 'trip_details', buildDetailRows(entries, userId));
  }

  static Future<void> _batchUpsert(
    SupabaseClient client,
    String table,
    List<Map<String, dynamic>> rows,
  ) async {
    if (rows.isEmpty) return;
    try {
      await client.from(table).upsert(rows, onConflict: 'user_id,id');
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.sync, e, st, context: {'where': 'TripsSync._batchUpsert $table FAILED'}));
    }
  }

  /// Pure multi-row analogue of [buildSummaryRow]. Null-timestamp
  /// entries are skipped (mirrors the [uploadSummary] guard) so the
  /// NOT-NULL `started_at` / `ended_at` columns are never violated. A
  /// unit-testable seam for the batch contract.
  @visibleForTesting
  static List<Map<String, dynamic>> buildSummaryRows(
    List<TripHistoryEntry> entries,
    String userId, {
    DateTime? now,
  }) {
    final rows = <Map<String, dynamic>>[];
    for (final entry in entries) {
      if (entry.summary.startedAt == null || entry.summary.endedAt == null) {
        continue;
      }
      rows.add(buildSummaryRow(entry, userId, now: now));
    }
    return rows;
  }

  /// Pure multi-row analogue of the single-trip [uploadDetails] payload.
  /// Entries with no `samples` AND no `gpsd` contribute nothing (matches
  /// the single-trip no-op guard). A unit-testable seam.
  @visibleForTesting
  static List<Map<String, dynamic>> buildDetailRows(
    List<TripHistoryEntry> entries,
    String userId, {
    DateTime? now,
  }) {
    final stamp = (now ?? DateTime.now()).toUtc().toIso8601String();
    final rows = <Map<String, dynamic>>[];
    for (final entry in entries) {
      if (entry.samples.isEmpty && entry.gpsSampleDiagnostics.isEmpty) {
        continue;
      }
      rows.add({
        'id': entry.id,
        'user_id': userId,
        'data': tripDetailsJson(entry),
        'updated_at': stamp,
      });
    }
    return rows;
  }

  /// Wipe every synced trip for the current user from BOTH
  /// `trip_summaries` AND `trip_details` (#1479 phase 5 — 'Forget
  /// all synced trips' button on the TankSync transparency screen).
  ///
  /// Local Hive entries are NOT touched — the user explicitly opted
  /// to drop the cloud copy, not to delete their on-device history.
  /// A subsequent merge will re-download nothing because the server
  /// is empty; the local entries remain authoritative.
  static Future<void> forgetAllForUser() async {
    final client = TankSyncClient.client;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) {
      debugPrint('TripsSync.forgetAllForUser: not authenticated');
      return;
    }
    try {
      await client.from('trip_summaries').delete().eq('user_id', userId);
      await client.from('trip_details').delete().eq('user_id', userId);
      debugPrint('TripsSync.forgetAllForUser: wiped server-side rows');
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.sync, e, st, context: const {'where': 'TripsSync.forgetAllForUser FAILED'}));
    }
  }

  /// Prune `trip_details` rows older than [olderThanDays] for the
  /// current user (#1479 phase 5 — retention). Summary rows keep
  /// forever; only the heavy per-tick blobs auto-prune so the
  /// cross-device list view stays complete while storage stays
  /// bounded.
  ///
  /// Default 90 days matches the issue's spec. Caller decides when
  /// to invoke (typically on app launch alongside the other sync
  /// passes).
  static Future<void> pruneOldDetails({int olderThanDays = 90}) async {
    final client = TankSyncClient.client;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return;
    final cutoff = DateTime.now().subtract(Duration(days: olderThanDays));
    try {
      await client
          .from('trip_details')
          .delete()
          .eq('user_id', userId)
          .lt('updated_at', cutoff.toIso8601String());
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.sync, e, st, context: const {'where': 'TripsSync.pruneOldDetails FAILED'}));
    }
  }

  /// Pure builder for one `public.trip_summaries` row — the exact
  /// column map [uploadSummary] upserts. Extracted so a unit test can
  /// pin every column (the wire `upsert` call can't be exercised
  /// without a live Supabase client). [now] defaults to wall-clock and
  /// is injectable so the `updated_at` assertion stays deterministic.
  @visibleForTesting
  static Map<String, dynamic> buildSummaryRow(
    TripHistoryEntry entry,
    String userId, {
    DateTime? now,
  }) {
    return {
      'id': entry.id,
      'user_id': userId,
      'vehicle_id': entry.vehicleId,
      'started_at': entry.summary.startedAt!.toIso8601String(),
      'ended_at': entry.summary.endedAt!.toIso8601String(),
      // The summary blob stays compact: just the entity's JSON form
      // WITHOUT the per-tick `samples` and GPS-diagnostics arrays so a
      // 60-min commute is ~1 KB instead of ~250 KB. The full blob
      // (samples + gpsd) goes to `public.trip_details` in
      // [uploadDetails] right after.
      'data': compactSummaryJson(entry),
      'updated_at': (now ?? DateTime.now()).toUtc().toIso8601String(),
    };
  }

  /// Pure merge step: returns `[...localEntries, ...server-only]` given
  /// the raw `trip_summaries` rows fetched in [merge]. Server rows whose
  /// id is already local are skipped (local wins), and a row that fails
  /// to decode is dropped rather than aborting the whole merge.
  ///
  /// This is the value the app-launch caller persists back to the local
  /// Hive box (`AppInitializer._runTripsSyncMerge`). It is the seam the
  /// "download silently discarded" regression test (#2239) pins — the
  /// sibling AlertsSync bug was the caller throwing this superset away,
  /// so a trip recorded on another device never landed locally.
  @visibleForTesting
  static List<TripHistoryEntry> mergeRows(
    List<TripHistoryEntry> localEntries,
    List<Map<String, dynamic>> serverRows, {
    Set<String> tombstoned = const {},
  }) {
    final localIds = localEntries.map((e) => e.id).toSet();
    final downloaded = <TripHistoryEntry>[];
    for (final r in serverRows) {
      final id = r['id'];
      // #3078 — also skip a server row the user deleted on another device.
      if (id is! String ||
          localIds.contains(id) ||
          tombstoned.contains(id)) {
        continue;
      }
      final data = r['data'];
      if (data is! Map) continue;
      try {
        downloaded.add(
          TripHistoryEntry.fromJson(data.cast<String, dynamic>()),
        );
      } catch (e, st) {
        unawaited(errorLogger.log(ErrorLayer.sync, e, st, context: {'where': 'TripsSync.mergeRows decode failed for $id'}));
      }
    }
    return [...localEntries, ...downloaded];
  }
}
