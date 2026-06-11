// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../utils/json_extensions.dart';
import 'sync_transport.dart';
import '../../core/logging/error_logger.dart';

/// Deletion tombstones (#3078, Epic #3075).
///
/// TankSync merges synced entities as `server ∪ local` then upserts. So when
/// device A deletes a favorite, device B's next sync re-adds it (the union
/// re-includes the still-local row) and the delete **resurrects**. A tombstone
/// is the durable "this id was deliberately deleted" record that lets every
/// device's merge filter the resurrected row out for good.
///
/// One `deletions` row per `(user_id, table_name, record_id)` (idempotent via
/// that unique key). On a synced delete the owning sync class additionally
/// [record]s a tombstone; before each union it [fetchTombstonedIds] and runs
/// the server rows through `SyncHelper.removeTombstoned`.
class DeletionsSync {
  DeletionsSync._();

  /// The Supabase table name. Exposed so the schema completeness drift-guard
  /// and the sync classes reference the same literal.
  static const table = 'deletions';

  /// Record a tombstone for [recordId] in [tableName]. Idempotent — a repeat
  /// delete of the same id just refreshes `deleted_at`. No-op + silent when
  /// unauthenticated or on a transient failure (the local delete already
  /// happened; sync must never throw back into the caller).
  static Future<void> record(String tableName, String recordId) =>
      recordAll(tableName, [recordId]);

  /// Batch analogue of [record] — one round-trip for many ids of the same
  /// [tableName]. No-op when the id list is empty or unauthenticated.
  ///
  /// Returns `true` when the tombstone upsert reached the server, `false`
  /// when it was skipped (unauthenticated) or failed transiently — the
  /// #3123 journal keeps the entry queued in that case.
  static Future<bool> recordAll(
    String tableName,
    Iterable<String> recordIds, {
    SyncTransport? transport,
  }) async {
    final ids = recordIds.toList();
    if (ids.isEmpty) return true;
    final t = transport ?? SupabaseSyncTransport.currentOrNull();
    if (t == null) return false;

    final now = DateTime.now().toUtc().toIso8601String();
    final rows = ids
        .map((id) => {
              'user_id': t.userId,
              'table_name': tableName,
              'record_id': id,
              'deleted_at': now,
            })
        .toList();
    try {
      await t.upsert(
        table,
        rows,
        onConflict: 'user_id,table_name,record_id',
      );
      debugPrint('DeletionsSync.record: ${ids.length} tombstone(s) '
          'for "$tableName"');
      return true;
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.sync, e, st,
          context: const {'where': 'DeletionsSync.record FAILED'}));
      return false;
    }
  }

  /// Fetch the set of record ids the current user has tombstoned for
  /// [tableName]. Returns an empty set when unauthenticated or on failure —
  /// the caller then simply skips the tombstone filter (degrades to the old
  /// union behaviour rather than dropping rows it shouldn't).
  static Future<Set<String>> fetchTombstonedIds(
    String tableName, {
    SyncTransport? transport,
  }) async {
    final t = transport ?? SupabaseSyncTransport.currentOrNull();
    if (t == null) return {};
    try {
      final rows = await t.select(
        table,
        'record_id',
        filters: {'table_name': tableName},
      );
      return rows
          .map((r) => r.getString('record_id'))
          .whereType<String>()
          .toSet();
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.sync, e, st,
          context: const {'where': 'DeletionsSync.fetchTombstonedIds FAILED'}));
      return {};
    }
  }
}
