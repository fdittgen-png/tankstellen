// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later


import 'package:flutter/foundation.dart';

import 'supabase_client.dart';
import '../../features/trips/api.dart';
import '../../core/logging/error_logger.dart';
import '../../core/logging/app_log.dart';

/// GDPR data-management operations over the user's full server-side
/// footprint, pulled out of [SyncService] (#727).
///
/// Two paths:
///
/// - [fetchAll] — gather every row the user owns across EVERY sync table
///   into a single `Map<String, dynamic>` (Art. 15 access / Art. 20
///   portability). #3869 — the read set is a superset of the deletion
///   set, pinned by test: the app never deletes data it would not show.
/// - [deleteAll] — wipe every row on explicit account deletion (Art. 17).
///   #3868 — one `erase_my_data()` transaction on a schema ≥ v9, the
///   per-table path on an older self-host; either way the caller gets a
///   [ServerErasureResult] that names what could NOT be erased instead of
///   a silent "success".
class UserDataSync {
  UserDataSync._();

  /// Every table [fetchAll] reads, paired with the column the user's id
  /// lives in. `trip_shares` is read twice (given and received).
  @visibleForTesting
  static const readableTables = <String, String>{
    'favorites': 'user_id',
    'alerts': 'user_id',
    'ignored_stations': 'user_id',
    'push_tokens': 'user_id',
    'price_reports': 'reporter_id',
    'content_reports': 'reporter_user_id',
    'itineraries': 'user_id',
    'vehicles': 'user_id',
    'fill_ups': 'user_id',
    'obd2_baselines': 'user_id',
    'station_ratings': 'user_id',
    'trip_summaries': 'user_id',
    'trip_details': 'user_id',
    'trip_shares': 'owner_id',
    'wait_time_pings': 'user_id',
    'sync_settings': 'user_id',
    'deletions': 'user_id',
    // #4212 — the two fleet tables that name the person (ADR 0025 D9
    // matrix); the org's own rows are not the user's to export or erase.
    'fleet_members': 'user_id',
    'vehicle_assignments': 'user_id',
    // #4215 — the employee's own expenses and document metadata (never
    // the bytes; those are private objects the export does not carry),
    // plus the audit rows in which THEY are the actor — ADR 0025 D9
    // puts the subject's own access rows in their export, and keeps the
    // org's rows out of it.
    'fleet_expenses': 'user_id',
    'fleet_documents': 'user_id',
    'fleet_audit_events': 'actor',
    'users': 'id',
  };

  /// Fetch every row the user owns, grouped by table name. Returns
  /// `{'error': message}` when unauthenticated or on a hard failure; a
  /// table missing on an older self-host yields an empty list for that
  /// key (and is listed under `'unavailable'`) so the export stays whole.
  static Future<Map<String, dynamic>> fetchAll() async {
    final client = TankSyncClient.client;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) {
      return {'error': 'Not authenticated (userId=$userId)'};
    }
    debugPrint('UserDataSync.fetchAll: userId=$userId');
    final out = <String, dynamic>{};
    final unavailable = <String>[];
    try {
      for (final entry in readableTables.entries) {
        try {
          out[entry.key] =
              await client.from(entry.key).select().eq(entry.value, userId);
        } catch (e, st) {
          // A self-host schema older than the table: export what exists.
          unavailable.add(entry.key);
          out[entry.key] = const <dynamic>[];
          log.error(e, st, layer: ErrorLayer.sync, context: {
            'where': 'UserDataSync.fetchAll: ${entry.key} unavailable', 'entity': entry.key
          });
        }
      }
      try {
        out['trip_shares_received'] = await client
            .from('trip_shares')
            .select()
            .eq('shared_with_id', userId);
      } catch (_) {
        out['trip_shares_received'] = const <dynamic>[];
      }
      // Legacy key the transparency cards read (#2107).
      out['reports'] = out['price_reports'];
      if (unavailable.isNotEmpty) out['unavailable'] = unavailable;
      return out;
    } catch (e, st) {
      log.error(e, st, layer: ErrorLayer.sync, context: const {'where': 'UserDataSync.fetchAll FAILED'});
      return {'error': e.toString()};
    }
  }

  /// Every server-side table the per-table fallback of [deleteAll] wipes,
  /// paired with the user-id column. Ordered children-before-parents so
  /// the `public.users` row (FK target) goes last. `trip_summaries` /
  /// `trip_details` are wiped via [TripsSync.forgetAllForUser].
  ///
  /// Asserted ⊆ [readableTables] by test (#2292 / #3869): a table that
  /// becomes deletable but not exportable is a defect.
  @visibleForTesting
  static const deletableTables = <String, String>{
    // #4215 — the expense and its document row go first: both reference
    // the org and the vehicle. `fleet_audit_events` is deliberately NOT
    // here — ADR 0025 D9 retains privileged-access records on a
    // legal-obligation basis, so they are exported, never erased.
    'fleet_expenses': 'user_id',
    'fleet_documents': 'user_id',
    'vehicle_assignments': 'user_id', // #4212 — the person's fleet rows
    'fleet_members': 'user_id',
    'trip_shares': 'owner_id',
    'content_reports': 'reporter_user_id', // #3726 — UGC report rows
    'price_reports': 'reporter_id',
    'wait_time_pings': 'user_id',
    'push_tokens': 'user_id',
    'obd2_baselines': 'user_id',
    'station_ratings': 'user_id',
    'ignored_stations': 'user_id',
    'itineraries': 'user_id',
    'fill_ups': 'user_id',
    'vehicles': 'user_id',
    'alerts': 'user_id',
    'favorites': 'user_id',
    'sync_settings': 'user_id',
    'deletions': 'user_id', // #3078 — wipe the user's tombstones too
    'users': 'id',
  };

  /// Delete every row the user owns (GDPR right to erasure). Never
  /// throws; returns what happened. No-op result when unauthenticated.
  ///
  /// #4215 — the receipt BYTES go first, through the Storage API,
  /// because nothing downstream can remove them: `erase_my_data()`
  /// deletes the `fleet_documents` rows, but a SQL delete on
  /// `storage.objects` is refused outright by Supabase's
  /// statement-level trigger and would in any case leave the S3 object
  /// orphaned. Doing it here also means the objects are gone before the
  /// rows that name them are.
  static Future<ServerErasureResult> deleteAll() async {
    final client = TankSyncClient.client;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) {
      return const ServerErasureResult(failedTables: ['not-authenticated']);
    }
    try {
      await _eraseFleetDocumentObjects(userId);
    } catch (e, st) {
      // Belt as well as braces: the row erasure below is the part the
      // user is legally owed, and nothing about the bucket may stop it.
      log.error(e, st, layer: ErrorLayer.sync, context: const {
        'where': 'UserDataSync: receipt object sweep failed'
      });
    }
    // #3868 — one transaction, no bulk-delete trap, covers public.users.
    try {
      final rows = await client.rpc<List<dynamic>>('erase_my_data');
      final deleted = <String, int>{
        for (final r in rows)
          if (r is Map)
            '${r['table_name']}': (r['rows_deleted'] as num?)?.toInt() ?? 0,
      };
      return ServerErasureResult(viaRpc: true, deleted: deleted);
    } catch (e, st) {
      // Schema < v9 (self-host that has not re-run the setup SQL): fall
      // back to the per-table path and REPORT what it could not do.
      log.error(e, st, layer: ErrorLayer.sync, context: const {
        'where': 'erase_my_data RPC unavailable (schema < v9?) — per-table'
      });
    }
    final failed = <String>[];
    final deleted = <String, int>{};
    for (final entry in deletableTables.entries) {
      try {
        await client.from(entry.key).delete().eq(entry.value, userId);
        deleted[entry.key] = -1; // count unknown on this path
      } catch (e, st) {
        failed.add(entry.key);
        log.error(e, st, layer: ErrorLayer.sync, context: {
          'where': 'UserDataSync.deleteAll FAILED for ${entry.key}', 'entity': entry.key
        });
      }
    }
    try {
      await TripsSync.forgetAllForUser();
    } catch (e, st) {
      failed.add('trip_summaries');
      log.error(e, st, layer: ErrorLayer.sync, context: const {'where': 'UserDataSync.deleteAll trips FAILED'});
    }
    return ServerErasureResult(deleted: deleted, failedTables: failed);
  }

  /// #4215 — the private bucket the fleet receipt objects live in.
  ///
  /// Spelled out here rather than imported: `lib/core/` must not depend
  /// on `lib/features/` (epic #3129 pins the fleet pair at zero, and
  /// the `api.dart` barrel does not excuse it). `FleetDocumentStore.bucket`
  /// is the other half of the constant, and
  /// `user_data_sync_coverage_test` asserts the two agree — so the
  /// duplication is a pinned pair, not a place they can drift apart.
  @visibleForTesting
  static const fleetDocumentsBucket = 'fleet-documents';

  /// Remove the stored receipt objects [userId] owns, through the
  /// Storage API (#4215, GDPR Art. 17).
  ///
  /// This runs BEFORE `erase_my_data()`, and the order is the point.
  /// The RPC deletes the `fleet_documents` ROWS but cannot delete the
  /// bytes: Supabase refuses a direct SQL delete on `storage.objects`
  /// with a statement-level trigger — one that fires even for a
  /// zero-row statement, which is how the first version of that sweep
  /// aborted account deletion for every user of the app — and even
  /// where such a delete succeeds it only drops the row and orphans
  /// the S3 object. The Storage API is the only path that removes
  /// them, and the keys have to be read while the rows still exist.
  ///
  /// A storage fault is caught and logged, and the erasure continues:
  /// an outage in the bucket must not also cost the user their row
  /// deletion. The call site guards it a second time, so the promise
  /// does not rest on this method's own discipline — and the same rule
  /// is proven at the seam by `FleetDocumentStore`'s fault-path tests,
  /// which can inject a throwing transport where this layer cannot.
  static Future<int> _eraseFleetDocumentObjects(String userId) async {
    final client = TankSyncClient.client;
    if (client == null) return 0;
    try {
      final rows = await client
          .from('fleet_documents')
          .select('object_key')
          .eq('user_id', userId);
      final keys = <String>[
        for (final row in rows)
          if (row['object_key'] is String) row['object_key'] as String,
      ];
      if (keys.isEmpty) return 0;
      await client.storage.from(fleetDocumentsBucket).remove(keys);
      return keys.length;
    } catch (e, st) {
      log.error(e, st, layer: ErrorLayer.sync, context: const {
        'where': 'UserDataSync: fleet receipt objects not removed'
      });
      return 0;
    }
  }

  /// #3868 — delete ONE row the user owns (their own price report or
  /// content report) — RLS permits it; the UI needed a button.
  static Future<bool> deleteOwnRow({
    required String table,
    required String idColumn,
    required Object id,
  }) async {
    final client = TankSyncClient.client;
    if (client == null || client.auth.currentUser == null) return false;
    try {
      await client.from(table).delete().eq(idColumn, id);
      return true;
    } catch (e, st) {
      log.error(e, st, layer: ErrorLayer.sync, context: {'where': 'UserDataSync.deleteOwnRow $table'});
      return false;
    }
  }
}

/// The outcome of [UserDataSync.deleteAll] — honest by construction.
class ServerErasureResult {
  const ServerErasureResult({
    this.viaRpc = false,
    this.deleted = const {},
    this.failedTables = const [],
  });

  /// True when the single-transaction `erase_my_data()` ran.
  final bool viaRpc;

  /// Rows deleted per table (`-1` = unknown on the per-table path).
  final Map<String, int> deleted;

  /// Tables the erase could not touch — empty means everything is gone.
  final List<String> failedTables;

  bool get complete => failedTables.isEmpty;
}
