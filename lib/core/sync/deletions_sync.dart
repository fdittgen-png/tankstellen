// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../utils/json_extensions.dart';
import 'pending_deletions_journal.dart';
import 'sync_device_identity.dart';
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
///
/// **#3123 durability:** tombstone writes used to be fail-open — a network
/// blip skipped them and re-enabled resurrection. Every [recordAll] now
/// journals its ids in [PendingDeletionsJournal] *before* the network
/// attempt and clears them only on server confirmation;
/// [fetchTombstonedIds] drains the journal first and unions any
/// still-pending ids into its result, so a journaled delete is honoured
/// locally even while the server write keeps failing.
///
/// **#3125 forensics:** each tombstone row is stamped with the writing
/// install's `device_id` + `app_version` (see [SyncDeviceIdentity]), so a
/// multi-device account can answer *which* device deleted a record and on
/// which build. A pre-v4 self-host schema without those columns is detected
/// and retried without the stamps — old schemas keep working tombstones
/// (minus forensics) until the wizard SQL is re-run.
class DeletionsSync {
  DeletionsSync._();

  /// The Supabase table name. Exposed so the schema completeness drift-guard
  /// and the sync classes reference the same literal.
  static const table = 'deletions';

  /// Record a tombstone for [recordId] in [tableName]. Idempotent — a repeat
  /// delete of the same id just refreshes `deleted_at`. No-op + silent when
  /// unauthenticated or on a transient failure (the local delete already
  /// happened; sync must never throw back into the caller) — but the intent
  /// stays journaled (#3123) and is replayed on the next sync.
  static Future<void> record(String tableName, String recordId) =>
      recordAll(tableName, [recordId]);

  /// Batch analogue of [record] — one round-trip for many ids of the same
  /// [tableName]. No-op when the id list is empty.
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

    // #3123 — journal-first: persist the durable "these ids are dead"
    // intent BEFORE any auth check or network attempt, so an offline or
    // flaky delete is replayed by the next sync's drain instead of lost.
    await PendingDeletionsJournal.addAll(tableName, ids);

    final t = transport ?? SupabaseSyncTransport.currentOrNull();
    if (t == null) return false;

    final now = DateTime.now().toUtc().toIso8601String();
    final rows = ids
        .map((id) => {
              'user_id': t.userId,
              'table_name': tableName,
              'record_id': id,
              'deleted_at': now,
              // #3125 — forensic origin stamps (see class doc).
              'device_id': SyncDeviceIdentity.deviceId,
              'app_version': SyncDeviceIdentity.appVersion,
            })
        .toList();
    try {
      await _upsertTombstones(t, rows);
      // Confirmed server-side → the journal entry has served its purpose.
      await PendingDeletionsJournal.removeAll(tableName, ids);
      debugPrint('DeletionsSync.record: ${ids.length} tombstone(s) '
          'for "$tableName"');
      return true;
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.sync, e, st,
          context: const {'where': 'DeletionsSync.record FAILED'}));
      return false;
    }
  }

  /// Upsert [rows] with the #3125 forensic columns; a self-host schema
  /// that predates v4 rejects the unknown payload keys (PGRST204), so
  /// retry once without them rather than breaking tombstones outright.
  /// The schema verifier separately flags the outdated schema.
  static Future<void> _upsertTombstones(
    SyncTransport t,
    List<Map<String, dynamic>> rows,
  ) async {
    try {
      await t.upsert(table, rows, onConflict: 'user_id,table_name,record_id');
    } catch (e) {
      if (!_isMissingForensicColumn(e)) rethrow;
      debugPrint('DeletionsSync: schema predates the #3125 forensic '
          'columns — retrying tombstone upsert without them');
      final legacyRows = [
        for (final row in rows)
          {...row}
            ..remove('device_id')
            ..remove('app_version'),
      ];
      await t.upsert(
        table,
        legacyRows,
        onConflict: 'user_id,table_name,record_id',
      );
    }
  }

  /// Whether [error] is PostgREST's "unknown column in payload" rejection
  /// (code `PGRST204`) for one of the #3125 forensic columns.
  static bool _isMissingForensicColumn(Object error) {
    final message = error.toString();
    if (!message.contains('device_id') && !message.contains('app_version')) {
      return false;
    }
    return message.contains('PGRST204') ||
        message.toLowerCase().contains('column');
  }

  /// Replay every journaled-but-unconfirmed tombstone (#3123). Called at
  /// the start of [fetchTombstonedIds] so pending tombstones land
  /// server-side *before* the caller's union merge runs. Never throws —
  /// a failed replay simply stays journaled for the next attempt.
  static Future<void> drainJournal({SyncTransport? transport}) async {
    final pending = PendingDeletionsJournal.snapshot();
    for (final entry in pending.entries) {
      await recordAll(entry.key, entry.value, transport: transport);
    }
  }

  /// Fetch the set of record ids the current user has tombstoned for
  /// [tableName]. Always unions in the locally-journaled pending ids
  /// (#3123) so a delete whose server write keeps failing still stays
  /// dead in this device's merges. Returns only the journaled ids when
  /// unauthenticated or on failure — the caller then degrades to the old
  /// union behaviour for server rows rather than dropping rows it
  /// shouldn't.
  static Future<Set<String>> fetchTombstonedIds(
    String tableName, {
    SyncTransport? transport,
  }) async {
    final t = transport ?? SupabaseSyncTransport.currentOrNull();
    if (t == null) return PendingDeletionsJournal.pendingIds(tableName);

    // #3123 — replay journaled tombstones before the union reads them.
    await drainJournal(transport: t);

    try {
      final rows = await t.select(
        table,
        'record_id',
        filters: {'table_name': tableName},
      );
      return {
        ...rows.map((r) => r.getString('record_id')).whereType<String>(),
        // Ids whose replay just failed still count as tombstoned locally.
        ...PendingDeletionsJournal.pendingIds(tableName),
      };
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.sync, e, st,
          context: const {'where': 'DeletionsSync.fetchTombstonedIds FAILED'}));
      return PendingDeletionsJournal.pendingIds(tableName);
    }
  }
}
