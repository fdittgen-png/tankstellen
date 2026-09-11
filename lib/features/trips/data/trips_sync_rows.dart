// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../core/logging/app_log.dart';
import '../../../core/logging/error_logger.dart';
import '../../../core/sync/sync_row_ops.dart';
import 'trip_history_repository.dart';
import 'trips_sync_json.dart';

/// The pure half of trips sync: the exact `trip_summaries` /
/// `trip_details` row shapes the wire methods upsert, and the reconcile
/// steps the launch merge composes (#4056 decomposition of `TripsSync`).
///
/// `TripsSync` reads `TankSyncClient.client` directly, so its wire calls
/// cannot be exercised without a live Supabase session. Everything that
/// CAN be pinned by a unit test lives here instead: the column contract
/// (`buildSummaryRow` / `buildSummaryRows` / `buildDetailRows`), the
/// union the caller must persist (`mergeRows`, the #2239 seam), and the
/// wiped-but-kept rescue (`retainedAfterWipe`, the #4056 seam). The wire
/// methods delegate; the tests drive these.
///
/// `updated_at` stamps go through [SyncRowOps.lwwStamp] — the one place
/// the sync layer reads the wall clock, via the #3660 `AppClock` seam.
class TripsSyncRows {
  const TripsSyncRows._();

  /// Pure multi-row analogue of [buildSummaryRow]. Null-timestamp
  /// entries are skipped (mirrors the [uploadSummary] guard) so the
  /// NOT-NULL `started_at` / `ended_at` columns are never violated. A
  /// unit-testable seam for the batch contract.
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
  static List<Map<String, dynamic>> buildDetailRows(
    List<TripHistoryEntry> entries,
    String userId, {
    DateTime? now,
  }) {
    final stamp = SyncRowOps.lwwStamp(now);
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

  /// Pure builder for one `public.trip_summaries` row — the exact
  /// column map [uploadSummary] upserts. Extracted so a unit test can
  /// pin every column (the wire `upsert` call can't be exercised
  /// without a live Supabase client). [now] defaults to wall-clock and
  /// is injectable so the `updated_at` assertion stays deterministic.
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
      'updated_at': SyncRowOps.lwwStamp(now),
    };
  }

  /// #4056 — the local entries a server wipe tombstoned but this device
  /// chose to keep. Pure seam so the promise is testable without a wire.
  ///
  /// An id is rescued only when it is BOTH tombstoned and retained: a
  /// tombstone alone means "the user deleted this record — every device
  /// drops it" (#3078, unchanged); retained alone means nothing is at
  /// risk, the entry is still in the live set. The caller appends the
  /// result to the merge output so [LaunchSyncPulls.mergeAndPruneTrips]
  /// sees the entry as present and never deletes it.
  static List<TripHistoryEntry> retainedAfterWipe(
    List<TripHistoryEntry> localEntries, {
    required Set<String> tombstoned,
    required Set<String> retained,
  }) {
    if (retained.isEmpty) return const [];
    return [
      for (final e in localEntries)
        if (tombstoned.contains(e.id) && retained.contains(e.id)) e,
    ];
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
        log.error(e, st, layer: ErrorLayer.sync, context: {'where': 'TripsSyncRows.mergeRows decode failed for $id', 'entity': id});
      }
    }
    return [...localEntries, ...downloaded];
  }
}
