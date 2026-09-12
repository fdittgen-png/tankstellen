// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT


import 'package:flutter/foundation.dart';

import '../logging/error_logger.dart';
import '../logging/app_log.dart';
import '../utils/json_extensions.dart';
import 'deletions_sync.dart';
import 'locally_retained_ids.dart';
import 'sync_transport.dart';

/// What the user asked to wipe from their sync database (#3453).
enum SyncedDataCategory { trips, vehicles, fillUps, everything }

/// #3453 — "delete my synced data": server-side, per-category deletion of
/// the caller's OWN rows, available to ANONYMOUS users.
///
/// An anonymous UUID is a full identity: every synced table's RLS policy
/// is `FOR ALL USING (user_id = auth.uid())` (cf. #3081), and the
/// [SyncTransport] additionally scopes every select/delete to the
/// session's user id — so this can only ever reach the caller's rows,
/// community database included.
///
/// **Tombstone-correct**: each table's row ids are recorded as deletion
/// tombstones (journal-first, #3123) BEFORE the rows are deleted, so a
/// second device's later pull removes/never-resurrects them instead of
/// re-uploading its still-local copies (#3078). This is exactly why
/// `everything` must NOT wipe the `deletions` table — the tombstones are
/// what makes the wipe stick across devices. (Tombstones are wiped only
/// by the full account deletion in `UserDataSync.deleteAll`, which also
/// signs the identity out.)
///
/// **Server-side ONLY** (per the issue): local data on this device stays
/// untouched — the confirmation dialog copy says so. The identity remains
/// usable after any category, including [SyncedDataCategory.everything].
///
/// #4046 — that last sentence used to be false. The tombstone written
/// above is also what `EntitySync.merge` used to drop local rows by, so
/// the device promised its copy was the device that deleted it on the
/// next sync. [LocallyRetainedIds] records the ids this wipe intends to
/// keep; the merge keeps exactly those and still never re-uploads them.
/// The two meanings of a tombstone — "the user deleted this record" and
/// "the server copy is gone, the local one stays" — are now distinct.
///
/// Out of scope, documented deferrals:
///  * `price_reports` key on `reporter_id` (not `user_id`), outside the
///    user-scoped transport seam — covered by full account deletion.
///  * `trip_shares` key on `owner_id` — same; covered by account deletion.
class SyncedDataDeletion {
  SyncedDataDeletion._();

  /// Per-table id column used for the deletion tombstones. `null` means
  /// the table has no per-record id to tombstone (`push_tokens` is one
  /// row per user and no merge unions it back) — row delete only.
  static const Map<String, String?> idColumnByTable = {
    'trip_summaries': 'id',
    'trip_details': 'id',
    'vehicles': 'id',
    'fill_ups': 'id',
    'favorites': 'station_id',
    'ignored_stations': 'station_id',
    'alerts': 'id',
    'station_ratings': 'station_id',
    'itineraries': 'id',
    'obd2_baselines': 'vehicle_id',
    'push_tokens': null,
  };

  /// The tables each category wipes. `everything` is every key of
  /// [idColumnByTable] — pinned against it by the unit test so a new
  /// synced table can't silently escape the everything-wipe.
  static const Map<SyncedDataCategory, List<String>> categoryTables = {
    SyncedDataCategory.trips: ['trip_summaries', 'trip_details'],
    SyncedDataCategory.vehicles: ['vehicles'],
    SyncedDataCategory.fillUps: ['fill_ups'],
    SyncedDataCategory.everything: [
      'trip_summaries',
      'trip_details',
      'vehicles',
      'fill_ups',
      'favorites',
      'ignored_stations',
      'alerts',
      'station_ratings',
      'itineraries',
      'obd2_baselines',
      'push_tokens',
    ],
  };

  /// Wipe [category] from the server. Returns `true` when every table's
  /// tombstone + delete round-trip succeeded, `false` when unauthenticated
  /// or any table failed (each table is isolated: one failure is logged
  /// and the remaining tables still get wiped — the user confirmed the
  /// destructive action). Failures do not propagate to the caller.
  static Future<SyncedDataDeletionOutcome> delete(
    SyncedDataCategory category, {
    SyncTransport? transport,
  }) async {
    final t = transport ?? SupabaseSyncTransport.currentOrNull();
    if (t == null) return SyncedDataDeletionOutcome.failed;

    var outcome = SyncedDataDeletionOutcome.deleted;
    for (final table in categoryTables[category]!) {
      try {
        final idColumn = idColumnByTable[table];
        if (idColumn != null) {
          // Tombstone-first (#3078/#3123): the durable "these ids are
          // dead" records must not depend on the row delete succeeding.
          final rows = await t.select(table, idColumn);
          final ids = rows
              .map((r) => r.getString(idColumn))
              .whereType<String>()
              .toList();
          // #4046 — the dialog promises "data stored locally on this
          // device is kept". The tombstone alone does not deliver that:
          // the next merge would drop these ids from the local set too.
          // Record the intent BEFORE the tombstone, so a crash between
          // the two leaves the rows kept rather than silently removed.
          await LocallyRetainedIds.retain(table, ids, transport: t);
          // #4046 — recordAll returns FALSE when the tombstone could not
          // be uploaded (it stays queued locally). Deleting the server
          // rows anyway is correct — that is what the user asked for —
          // but reporting unqualified success is not: without the
          // tombstone, another device can re-upload its copy and the
          // data comes back. Surface it.
          if (!await DeletionsSync.recordAll(table, ids, transport: t)) {
            // #4059 — the rows ARE deleted; only the tombstone is not
            // durable yet. That is a different message from "failed".
            outcome = outcome.worst(
              DeletionsSync.deletionsTableAbsentThisSession
                  ? SyncedDataDeletionOutcome.deletedSchemaOutdated
                  : SyncedDataDeletionOutcome.deletedTombstonePending,
            );
            log.warn(
              'SyncedDataDeletion: server rows for "$table" deleted but the '
              'deletion tombstone is only queued locally — another device '
              'could re-upload until it lands',
              layer: ErrorLayer.sync,
            );
          }
        }
        // User-scoped by the transport contract (mirrors RLS).
        await t.deleteWhere(table, const {});
        debugPrint('SyncedDataDeletion: wiped "$table"');
      } catch (e, st) {
        outcome = SyncedDataDeletionOutcome.failed;
        log.error(e, st, layer: ErrorLayer.sync, context: {
          'where': 'SyncedDataDeletion.delete FAILED for table',
          'table': table,
          'category': category.name,
        });
      }
    }
    return outcome;
  }
}

/// What [SyncedDataDeletion.delete] achieved (#4059). Ordered from best
/// to worst so [worst] can fold per-table results into one verdict.
///
/// "Rows deleted, tombstone not yet durable" used to collapse into
/// `false`, and the tile told the user their deletion had FAILED when it
/// had succeeded — on a pre-v3 self-host that message could never be
/// escaped, because a retry found nothing left to delete and reported
/// the same failure again.
enum SyncedDataDeletionOutcome {
  /// Rows deleted and the tombstone confirmed server-side.
  deleted,

  /// Rows deleted; the tombstone is queued locally (#3123) and lands on
  /// the next sync. Other devices drop their copies after that.
  deletedTombstonePending,

  /// Rows deleted; the backend has no `deletions` table, so the tombstone
  /// can never land. Another device could re-upload — re-run the setup SQL.
  deletedSchemaOutdated,

  /// At least one table's rows could not be deleted.
  failed;

  SyncedDataDeletionOutcome worst(SyncedDataDeletionOutcome other) =>
      index >= other.index ? this : other;
}
