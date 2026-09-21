// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'trip_history_repository.dart';
import '../../../core/sync/deletions_sync.dart';
import '../../../core/sync/locally_retained_ids.dart';
import '../../../core/sync/sync_pull_lease.dart';
import '../../../core/sync/sync_transport.dart';
import 'trips_sync_json.dart';
import 'trips_sync_rows.dart';
import '../../../core/logging/error_logger.dart';
import '../../../core/logging/app_log.dart';
import '../../../core/sync/sync_row_ops.dart';

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
/// - Failures log and swallow — the local entry stays the source of
///   truth, the next save retries the upload.
///
/// ## #4377 — every wire call goes through the fenced [SyncTransport]
///
/// Trips never go through `EntitySync` (their reconcile is [merge]), and
/// until #4377 they read `TankSyncClient.client` directly — so the #4337
/// fence (a withdrawn consent or a released client refuses every further
/// call) and the #4377 pull lease (an abandoned pass refuses its late
/// answer) both stopped short of trips. Every method now takes the same
/// optional [SyncTransport] the other syncs take: production resolves
/// [SupabaseSyncTransport.currentOrNull], tests inject a fake, and a
/// transport opened before a withdrawal refuses the write after it.
class TripsSync {
  TripsSync._();

  /// The transport for this call, or null (logged) when nobody is signed
  /// in — the "unauthenticated path returns unchanged" contract.
  static SyncTransport? _transport(SyncTransport? transport, String where) {
    final t = transport ?? SupabaseSyncTransport.currentOrNull();
    if (t == null) {
      log.debug('TripsSync.$where: not authenticated, skipping', tag: 'sync');
    }
    return t;
  }

  /// #4337 / #4377 — a fenced transport or a refused late answer is the
  /// consent withdrawal (or the pass timeout) doing its job, not a fault:
  /// one info line, no error trace.
  static bool _fenced(Object e, String where) {
    if (e is! SyncFencedException && e is! SyncPullAbandonedException) {
      return false;
    }
    log.info('TripsSync.$where fenced: $e', tag: 'sync');
    return true;
  }

  /// Upload [entry] to `public.trip_summaries`. No-op when the user
  /// isn't signed into TankSync.
  ///
  /// Caller is responsible for the consent gate (`consentSyncTrips`)
  /// — the wire layer doesn't read consent so it stays a pure I/O
  /// helper; consent decisions live next to the user-visible toggle.
  static Future<void> uploadSummary(
    TripHistoryEntry entry, {
    SyncTransport? transport,
  }) async {
    final t = _transport(transport, 'uploadSummary');
    if (t == null) return;
    final startedAt = entry.summary.startedAt;
    final endedAt = entry.summary.endedAt;
    if (startedAt == null || endedAt == null) {
      // A trip with no timestamps cannot satisfy the
      // NOT-NULL `started_at` / `ended_at` columns. Silently skip —
      // happens for empty / aborted trips that the user wouldn't
      // want synced anyway.
      log.debug(
        'TripsSync.uploadSummary: ${entry.id} has null timestamps; '
        'skipping upload',
        tag: 'sync',
      );
      return;
    }
    try {
      await t.upsert(
        'trip_summaries',
        [TripsSyncRows.buildSummaryRow(entry, t.userId)],
        onConflict: 'user_id,id',
      );
      log.debug('TripsSync.uploadSummary: uploaded ${entry.id}', tag: 'sync');
    } catch (e, st) {
      if (_fenced(e, 'uploadSummary')) return;
      log.error(e, st, layer: ErrorLayer.sync, context: {'where': 'TripsSync.uploadSummary FAILED for ${entry.id}', 'entity': entry.id});
    }
    // Phase 4 (#1541) — fan out the heavy blob to `trip_details`.
    // [uploadDetails] no-ops when the entry has no samples /
    // diagnostics, so legacy / empty trips don't pay a wasted round
    // trip. Errors are logged inside and intentionally don't propagate
    // — a missing details row is a soft degradation (the list view
    // still works), not a hard failure of the summary upload.
    await uploadDetails(entry, transport: t);
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
  static Future<void> uploadDetails(
    TripHistoryEntry entry, {
    SyncTransport? transport,
  }) async {
    final t = _transport(transport, 'uploadDetails');
    if (t == null) return;
    if (entry.samples.isEmpty && entry.gpsSampleDiagnostics.isEmpty) {
      // Nothing heavy to ship — the compact summary already
      // carries everything the list view needs.
      return;
    }
    try {
      await t.upsert(
        'trip_details',
        [
          {
            'id': entry.id,
            'user_id': t.userId,
            'data': tripDetailsJson(entry),
            'updated_at': SyncRowOps.lwwStamp(null),
          },
        ],
        onConflict: 'user_id,id',
      );
      log.debug('TripsSync.uploadDetails: uploaded ${entry.id}', tag: 'sync');
    } catch (e, st) {
      if (_fenced(e, 'uploadDetails')) return;
      log.error(e, st, layer: ErrorLayer.sync, context: {'where': 'TripsSync.uploadDetails FAILED for ${entry.id}', 'entity': entry.id});
    }
  }

  /// Fetch the `trip_details.data` blob for [tripId] — `{samples, gpsd}`
  /// — or `null` when the row is missing (server has no details), the
  /// user isn't signed in, or the fetch fails. The trip-detail screen
  /// calls this lazily when the local Hive entry has empty samples
  /// (typically because it was downloaded by [merge] from another
  /// device).
  static Future<Map<String, dynamic>?> fetchDetails(
    String tripId, {
    SyncTransport? transport,
  }) async {
    final t = _transport(transport, 'fetchDetails');
    if (t == null) return null;
    try {
      final rows = await t.select('trip_details', 'data', filters: {'id': tripId});
      if (rows.isEmpty) return null;
      final data = rows.first['data'];
      if (data is! Map) return null;
      return data.cast<String, dynamic>();
    } catch (e, st) {
      if (_fenced(e, 'fetchDetails')) return null;
      log.error(e, st, layer: ErrorLayer.sync, context: {'where': 'TripsSync.fetchDetails FAILED for $tripId', 'entity': tripId});
      return null;
    }
  }

  /// Remove a single trip from the server (called when the user
  /// deletes the trip locally). Silent on failure — the local
  /// delete is the canonical signal; a stale server row is
  /// reconciled on the next sync pass (phase 3).
  static Future<void> deleteSummary(
    String tripId, {
    SyncTransport? transport,
  }) async {
    final t = _transport(transport, 'deleteSummary');
    if (t == null) return;
    try {
      // #3123 first — the tombstone outlives the row.
      await DeletionsSync.recordAll('trip_summaries', [tripId], transport: t);
      await t.deleteWhere('trip_summaries', {'id': tripId});
    } catch (e, st) {
      if (_fenced(e, 'deleteSummary')) return;
      log.error(e, st, layer: ErrorLayer.sync, context: {'where': 'TripsSync.deleteSummary FAILED for $tripId', 'entity': tripId});
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
  /// - A fenced transport (#4337) or an abandoned pass (#4377) → returns
  ///   the input unchanged, so the launch persist step saves and removes
  ///   nothing.
  ///
  /// #3613 — [localEntries] may be SUMMARY-ONLY decoded (empty `samples`
  /// with the stored count on `sampleCount`): the reconcile itself only
  /// reads ids + summaries. The one step that needs the heavy payload —
  /// the local-only `trip_details` heal upload — hydrates each candidate
  /// through [loadFull] (typically `TripHistoryRepository.loadById`)
  /// right before uploading, so in the steady state (no local-only
  /// entries) not a single sample is ever materialised. Pass null when
  /// [localEntries] are already fully decoded.
  static Future<List<TripHistoryEntry>> merge(
    List<TripHistoryEntry> localEntries, {
    TripHistoryEntry? Function(String id)? loadFull,
    SyncTransport? transport,
  }) async {
    final t = _transport(transport, 'merge');
    if (t == null) return localEntries;
    try {
      final serverRows = await t.select('trip_summaries', 'id, data');

      // #3078 — a trip deleted on another device must not resurrect. Drop
      // tombstoned ids from BOTH the re-upload set and the downloaded union.
      final tombstoned = await DeletionsSync.fetchTombstonedIds(
          'trip_summaries',
          transport: t);
      final liveLocal =
          localEntries.where((e) => !tombstoned.contains(e.id)).toList();
      // #4056 — "Data stored locally on this device is kept". #4046 fixed
      // this promise in EntitySync.merge, and trips never go through
      // EntitySync: a wipe tombstoned the ids AND retained them, this
      // merge dropped them from liveLocal, and mergeAndPruneTrips then
      // deleted every local entry absent from the result — the device's
      // whole trip history, one launch after the user asked to keep it.
      // Retained ids stay in the result (never re-uploaded: they are
      // excluded from liveLocal, hence from localOnly, by design).
      final retained =
          LocallyRetainedIds.forTable('trip_summaries', transport: t);
      final keptLocally = TripsSyncRows.retainedAfterWipe(
        localEntries,
        tombstoned: tombstoned,
        retained: retained,
      );
      // #4072 — release retained ids whose local row is gone (deleted
      // here since the wipe) so the retention blob cannot grow unbounded.
      if (retained.isNotEmpty) {
        final gone = retained.difference(localEntries.map((e) => e.id).toSet());
        if (gone.isNotEmpty) {
          await LocallyRetainedIds.release('trip_summaries', gone,
              transport: t);
        }
      }
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
      // #3613 — re-hydrate summary-only entries so the details-heal
      // upload still carries the samples/gpsd blob. A failed hydrate
      // falls back to the entry we have (summary heals, details retry
      // on the next pass — same as a pre-#3613 0-sample entry).
      final uploadable = loadFull == null
          ? localOnly
          : localOnly
              .map((e) => loadFull(e.id) ?? e)
              .toList(growable: false);
      await _uploadBatch(t, uploadable);

      // Decode server-only rows (off the UI isolate, #3451) and return the
      // union the launch caller persists back to Hive (#2239 pins mergeRows).
      final merged = await mergeTripRowsOffThread(liveLocal, serverRows,
          tombstoned: tombstoned);
      // #4377 — the last gate before the caller persists: a pass that
      // timed out while the rows were decoding hands nothing back.
      SyncPullLease.current?.checkLive();
      log.debug(
          'TripsSync.merge: local=${liveLocal.length} '
          'server=${serverIds.length} '
          'downloaded=${merged.length - liveLocal.length} '
          'keptAfterWipe=${keptLocally.length}',
          tag: 'sync');
      return [...merged, ...keptLocally];
    } catch (e, st) {
      if (_fenced(e, 'merge')) return localEntries;
      log.error(e, st, layer: ErrorLayer.sync, context: const {'where': 'TripsSync.merge FAILED'});
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
    SyncTransport t,
    List<TripHistoryEntry> entries,
  ) async {
    await _batchUpsert(t, 'trip_summaries', TripsSyncRows.buildSummaryRows(entries, t.userId));
    await _batchUpsert(t, 'trip_details', TripsSyncRows.buildDetailRows(entries, t.userId));
  }

  /// A fenced upsert (#4337/#4377) is NOT isolated: it rethrows so the
  /// merge stops at once instead of trying the next table.
  static Future<void> _batchUpsert(
    SyncTransport t,
    String table,
    List<Map<String, dynamic>> rows,
  ) async {
    if (rows.isEmpty) return;
    try {
      await t.upsert(table, rows, onConflict: 'user_id,id');
    } catch (e, st) {
      if (e is SyncFencedException || e is SyncPullAbandonedException) rethrow;
      log.error(e, st, layer: ErrorLayer.sync, context: {'where': 'TripsSync._batchUpsert $table FAILED'});
    }
  }

  /// Wipe every synced trip for the current user from BOTH
  /// `trip_summaries` AND `trip_details` (#1479 phase 5 — 'Forget
  /// all synced trips' button on the TankSync transparency screen).
  ///
  /// Local Hive entries are NOT touched — the user explicitly opted
  /// to drop the cloud copy, not to delete their on-device history.
  /// A subsequent merge will re-download nothing because the server
  /// is empty; the local entries remain authoritative.
  static Future<void> forgetAllForUser({SyncTransport? transport}) async {
    final t = _transport(transport, 'forgetAllForUser');
    if (t == null) return;
    try {
      await t.deleteWhere('trip_summaries', const {});
      await t.deleteWhere('trip_details', const {});
      log.debug('TripsSync.forgetAllForUser: wiped server-side rows',
          tag: 'sync');
    } catch (e, st) {
      if (_fenced(e, 'forgetAllForUser')) return;
      log.error(e, st, layer: ErrorLayer.sync, context: const {'where': 'TripsSync.forgetAllForUser FAILED'});
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
  static Future<void> pruneOldDetails({
    int olderThanDays = 90,
    SyncTransport? transport,
  }) async {
    final t = _transport(transport, 'pruneOldDetails');
    if (t == null) return;
    final cutoff =
        DateTime.now().toUtc().subtract(Duration(days: olderThanDays));
    try {
      await t.deleteOlderThan(
          'trip_details', 'updated_at', cutoff.toIso8601String());
    } catch (e, st) {
      if (_fenced(e, 'pruneOldDetails')) return;
      log.error(e, st, layer: ErrorLayer.sync, context: const {'where': 'TripsSync.pruneOldDetails FAILED'});
    }
  }
}
