// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/logging/error_logger.dart';
import '../utils/json_extensions.dart';
import 'deletions_sync.dart';
import 'sync_device_identity.dart';
import 'sync_helper.dart';
import 'sync_run_trace.dart';
import 'sync_transport.dart';

/// The generic per-entity sync engine (#3127, Epic #3120).
///
/// Before this existed, ~12 `*_sync.dart` files were structural clones of
/// the same bidirectional merge (favorites vs ignored stations differed
/// essentially by table name), so every fix to the merge algorithm —
/// tombstone filtering (#3078/#3121), last-write-wins (#3122), the durable
/// deletion journal (#3123), forensic stamps (#3125), run-trace counts
/// (#3126) — had to be hand-copied N times. [EntitySync] is that algorithm
/// written ONCE; each entity file shrinks to a declarative config (table
/// name, codec, conflict key) plus thin static forwarders that preserve
/// its long-standing public API.
///
/// The canonical [merge] pass, in order:
///
///  1. unauthenticated → return the local input unchanged (the feature
///     keeps working on pure-local state);
///  2. fetch the user's server rows + the entity's deletion tombstones
///     (which drains the #3123 pending-deletions journal first);
///  3. drop tombstoned ids from BOTH sides so a delete on another device
///     never resurrects through the union (#3078);
///  4. when the entity carries a [localStamp], split both-sides ids via
///     [SyncHelper.lwwSplit] — local-newer re-uploads, server-newer
///     overwrites the local copy (#3122);
///  5. upload local-only (+ local-newer) records through [encode];
///  6. decode server-only (+ server-newer) rows through [decode];
///  7. report per-table up/down/tombstone counts to [SyncRunTrace] (#3126);
///  8. return the merged union; any failure logs to [ErrorLayer.sync] and
///     returns the local input unchanged — sync is fire-and-forget and
///     must not derail the caller.
///
/// All I/O goes through the injectable [SyncTransport] seam (#3122):
/// production resolves [SupabaseSyncTransport.currentOrNull], tests inject
/// a fake — the per-entity authenticated paths are unit-testable without a
/// live Supabase session, retiring the static-global-client problem the
/// audit flagged.
class EntitySync<T> {
  /// The Supabase table this entity persists to. HARD RULE #5: a NEW
  /// table requires schema_verifier + wizard SQL + a schema-version bump —
  /// this class only reorganises existing tables.
  final String table;

  /// Prefix for debug prints and error-log contexts (e.g. `FavoritesSync`),
  /// kept per-entity so existing log forensics stay greppable.
  final String logName;

  /// The server column carrying the record id (`id`, or `station_id` for
  /// the id-set tables).
  final String idColumn;

  /// Column list for the merge's server fetch.
  final String selectColumns;

  /// Upsert conflict target making re-uploads idempotent.
  final String onConflict;

  /// The local record's id.
  final String Function(T record) idOf;

  /// Build the upload row for [record], owned by [userId].
  final Map<String, dynamic> Function(T record, String userId) encode;

  /// Decode a server row back into the domain record, or `null` to skip
  /// it. A decoder that THROWS aborts the whole merge (input returned
  /// unchanged) — wrap with [jsonbDataDecoder] for per-row resilience.
  final T? Function(JsonRow row) decode;

  /// The record's local edit stamp — non-null enables the #3122 LWW path
  /// for ids present on both sides. `null` keeps the pure id-union merge
  /// (e.g. `alerts`, whose table has no `updated_at` column to compare —
  /// see the HARD RULE #5 deferral note in `alerts_sync.dart`).
  final DateTime? Function(T record)? localStamp;

  /// Whether [delete] writes the durable tombstone BEFORE the row delete
  /// (the #3123 default) or after it (the `alerts` ordering, #3121). Both
  /// always record the tombstone — only the network call order differs.
  final bool tombstoneFirstDelete;

  const EntitySync({
    required this.table,
    required this.logName,
    required this.idColumn,
    required this.selectColumns,
    required this.onConflict,
    required this.idOf,
    required this.encode,
    required this.decode,
    this.localStamp,
    this.tombstoneFirstDelete = true,
  });

  /// The id-set flavour shared by `favorites` / `ignored_stations` — the
  /// two tables the audit called out as "differ essentially by table
  /// name". One `(user_id, station_id)` row per id; the merged result is
  /// the local ∪ server superset.
  static EntitySync<String> idSet({
    required String table,
    required String logName,
  }) =>
      EntitySync<String>(
        table: table,
        logName: logName,
        idColumn: 'station_id',
        selectColumns: 'station_id',
        onConflict: 'user_id,station_id',
        idOf: (id) => id,
        encode: (id, userId) => {'user_id': userId, 'station_id': id},
        decode: (row) => row.getString('station_id'),
      );

  /// Merge [local] with the user's rows on the server. Returns the union,
  /// with the fresher side winning for both-sides ids when [localStamp]
  /// is configured (#3122 — see [SyncHelper.lwwSplit] for the
  /// tie/missing-stamp policy). Unauthenticated and failure paths return
  /// the input unchanged. [transport] is injectable for tests.
  Future<List<T>> merge(List<T> local, {SyncTransport? transport}) async {
    final t = transport ?? SupabaseSyncTransport.currentOrNull();
    if (t == null) {
      debugPrint('$logName.merge: not authenticated');
      return local;
    }

    try {
      final serverRowsRaw = await t.select(table, selectColumns);

      // #3078 — drop tombstoned ids from BOTH sides so a delete on another
      // device can't resurrect through the union/re-upload below.
      final tombstoned =
          await DeletionsSync.fetchTombstonedIds(table, transport: t);
      final serverRows = SyncHelper.removeTombstoned(
        serverRowsRaw,
        tombstoned,
        key: (r) => r.getString(idColumn),
      ).toList();
      final liveLocal =
          local.where((r) => !tombstoned.contains(idOf(r))).toList();

      final serverIds = serverRows
          .map((r) => r.getString(idColumn))
          .whereType<String>()
          .toSet();
      final localIds = liveLocal.map(idOf).toSet();

      debugPrint('$logName.merge: local=${localIds.length}, '
          'server=${serverIds.length}');

      // #3122 — last-write-wins for ids present on both sides: a local
      // edit re-uploads, a fresher server row overwrites the local copy.
      final stamp = localStamp;
      final lww = stamp == null
          ? LwwSplit<T>(localNewer: const [], serverNewer: const [])
          : SyncHelper.lwwSplit(
              local: liveLocal,
              serverRows: serverRows,
              id: idOf,
              localStamp: stamp,
              tombstoned: tombstoned,
            );

      // Upload local-only + local-newer records.
      final localOnly =
          liveLocal.where((r) => !serverIds.contains(idOf(r))).toList();
      final toUpload = [...localOnly, ...lww.localNewer];
      if (toUpload.isNotEmpty) {
        final rows = toUpload.map((r) => encode(r, t.userId)).toList();
        await t.upsert(table, rows, onConflict: onConflict);
        debugPrint('$logName.merge: uploaded ${toUpload.length} '
            '(${lww.localNewer.length} local-newer edits)');
      }

      // Download server-only records…
      final downloaded = serverRows
          .where((r) => !localIds.contains(r.getString(idColumn)))
          .map(decode)
          .whereType<T>()
          .toList();
      // …and overwrite local copies the server has a fresher edit of.
      final serverNewerById = <String, T>{
        for (final r in lww.serverNewer.map(decode).whereType<T>()) idOf(r): r,
      };

      // #3126 — per-table counts into the exportable trace.
      SyncRunTrace.table(
        table,
        uploaded: toUpload.length,
        downloaded: downloaded.length + serverNewerById.length,
        tombstoned: tombstoned.length,
      );

      return [
        for (final r in liveLocal) serverNewerById[idOf(r)] ?? r,
        ...downloaded,
      ];
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.sync, e, st,
          context: {'where': '$logName.merge FAILED'}));
      return local;
    }
  }

  /// Delete one record from the server and record its durable tombstone
  /// (#3078/#3121/#3123) so no later [merge] resurrects it. Silent on
  /// failure — the caller's local delete already happened. See
  /// [tombstoneFirstDelete] for the call ordering.
  Future<bool> delete(String recordId, {SyncTransport? transport}) =>
      deleteRow(
        table: table,
        idColumn: idColumn,
        recordId: recordId,
        logContext: '$logName.delete',
        tombstoneFirst: tombstoneFirstDelete,
        transport: transport,
      );

  /// The shared tombstone-and-delete used by [delete] AND by the entities
  /// that have a bespoke read path but the same clone-pattern delete
  /// (ratings, baselines, itineraries). Returns `true` when the server row
  /// delete succeeded, `false` when unauthenticated or on a transient
  /// failure (the tombstone intent stays journaled either way, #3123).
  static Future<bool> deleteRow({
    required String table,
    required String idColumn,
    required String recordId,
    required String logContext,
    bool tombstoneFirst = true,
    SyncTransport? transport,
  }) async {
    final t = transport ?? SupabaseSyncTransport.currentOrNull();
    if (t == null) return false;

    // #3078/#3123 — tombstone-first (journal-backed) by default: the
    // durable "this id is dead" record must not depend on the row delete
    // succeeding. `recordAll` has its own internal guard and does not
    // throw back into this flow.
    if (tombstoneFirst) {
      await DeletionsSync.recordAll(table, [recordId], transport: t);
    }
    var deleted = false;
    try {
      await t.deleteWhere(table, {idColumn: recordId});
      debugPrint('$logContext: $recordId removed from server');
      deleted = true;
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.sync, e, st,
          context: {'where': '$logContext FAILED'}));
    }
    // #3121 — the alerts ordering: tombstone regardless of the row-delete
    // outcome, after the delete attempt.
    if (!tombstoneFirst) {
      await DeletionsSync.recordAll(table, [recordId], transport: t);
    }
    return deleted;
  }

  /// The #3125 forensic origin stamps every uploaded JSONB `data` blob
  /// carries (sync-transparent: decode ignores unknown keys, every
  /// re-upload re-stamps with the writing device).
  static Map<String, dynamic> forensicStamps() => {
        'device_id': SyncDeviceIdentity.deviceId,
        'app_version': SyncDeviceIdentity.appVersion,
      };

  /// The `updated_at` column value for an upload: carry the local edit
  /// stamp so the next LWW compare sees equal stamps (skip) instead of a
  /// phantom-newer server row; legacy unstamped records fall back to
  /// upload time. Always UTC (#3124).
  static String lwwStamp(DateTime? updatedAt) =>
      (updatedAt ?? DateTime.now()).toUtc().toIso8601String();

  /// A per-row resilient decoder for the JSONB-`data`-blob tables
  /// (`fill_ups` / `vehicles`): a corrupt row logs under [where] and is
  /// skipped instead of aborting the whole merge.
  static T? Function(JsonRow) jsonbDataDecoder<T>(
    T Function(Map<String, dynamic> json) fromJson, {
    required String where,
  }) =>
      (row) {
        final data = row['data'];
        if (data is! Map<String, dynamic>) return null;
        try {
          return fromJson(data);
        } catch (e, st) {
          unawaited(
              errorLogger.log(ErrorLayer.sync, e, st, context: {'where': where}));
          return null;
        }
      };
}
