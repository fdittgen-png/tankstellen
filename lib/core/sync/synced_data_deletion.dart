// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../logging/error_logger.dart';
import '../utils/json_extensions.dart';
import 'deletions_sync.dart';
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
  static Future<bool> delete(
    SyncedDataCategory category, {
    SyncTransport? transport,
  }) async {
    final t = transport ?? SupabaseSyncTransport.currentOrNull();
    if (t == null) return false;

    var allOk = true;
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
          await DeletionsSync.recordAll(table, ids, transport: t);
        }
        // User-scoped by the transport contract (mirrors RLS).
        await t.deleteWhere(table, const {});
        debugPrint('SyncedDataDeletion: wiped "$table"');
      } catch (e, st) {
        allOk = false;
        unawaited(errorLogger.log(ErrorLayer.sync, e, st, context: {
          'where': 'SyncedDataDeletion.delete FAILED for table',
          'table': table,
          'category': category.name,
        }));
      }
    }
    return allOk;
  }
}
