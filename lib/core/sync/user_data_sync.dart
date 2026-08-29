// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'supabase_client.dart';
import '../../features/trips/api.dart';
import '../../core/logging/error_logger.dart';

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
          unawaited(errorLogger.log(ErrorLayer.sync, e, st, context: {
            'where': 'UserDataSync.fetchAll: ${entry.key} unavailable'
          }));
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
      unawaited(errorLogger.log(ErrorLayer.sync, e, st,
          context: const {'where': 'UserDataSync.fetchAll FAILED'}));
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
  static Future<ServerErasureResult> deleteAll() async {
    final client = TankSyncClient.client;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) {
      return const ServerErasureResult(failedTables: ['not-authenticated']);
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
      unawaited(errorLogger.log(ErrorLayer.sync, e, st, context: const {
        'where': 'erase_my_data RPC unavailable (schema < v9?) — per-table'
      }));
    }
    final failed = <String>[];
    final deleted = <String, int>{};
    for (final entry in deletableTables.entries) {
      try {
        await client.from(entry.key).delete().eq(entry.value, userId);
        deleted[entry.key] = -1; // count unknown on this path
      } catch (e, st) {
        failed.add(entry.key);
        unawaited(errorLogger.log(ErrorLayer.sync, e, st, context: {
          'where': 'UserDataSync.deleteAll FAILED for ${entry.key}'
        }));
      }
    }
    try {
      await TripsSync.forgetAllForUser();
    } catch (e, st) {
      failed.add('trip_summaries');
      unawaited(errorLogger.log(ErrorLayer.sync, e, st,
          context: const {'where': 'UserDataSync.deleteAll trips FAILED'}));
    }
    return ServerErasureResult(deleted: deleted, failedTables: failed);
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
      unawaited(errorLogger.log(ErrorLayer.sync, e, st,
          context: {'where': 'UserDataSync.deleteOwnRow $table'}));
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
