// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../features/consumption/domain/entities/fill_up.dart';
import '../utils/json_extensions.dart';
import 'deletions_sync.dart';
import 'supabase_client.dart';
import 'sync_helper.dart';
import 'sync_transport.dart';
import '../../core/logging/error_logger.dart';

/// Per-fill-up consumption-log sync with Supabase (#713), pulled out
/// of [SyncService] (#727).
///
/// Same shape as [VehiclesSync]: the server row carries a full
/// [FillUp] JSON blob and the download branch decodes each row back
/// into the domain entity. Merge rule: dedupe by id (both directions
/// idempotent via `(user_id, id)` upsert conflict) + last-write-wins
/// for ids present on both sides (#3122). The extra `vehicle_id` +
/// `recorded_at` columns are for server-side filtering — clients only
/// read the `data` blob.
class FillUpsSync {
  FillUpsSync._();

  /// Merge [localFillUps] with the user's `fill_ups` rows on
  /// Supabase. Returns the union, with the fresher side winning for ids
  /// present on both (#3122 LWW — see [SyncHelper.lwwSplit] for the
  /// tie/missing-stamp policy). Unauthenticated path returns the input
  /// unchanged. [transport] is injectable for tests.
  static Future<List<FillUp>> merge(
    List<FillUp> localFillUps, {
    SyncTransport? transport,
  }) async {
    final t = transport ?? SupabaseSyncTransport.currentOrNull();
    if (t == null) {
      debugPrint('FillUpsSync.merge: not authenticated');
      return localFillUps;
    }

    try {
      final serverRowsRaw =
          await t.select('fill_ups', 'id, data, updated_at');

      // #3078 — drop tombstoned rows from BOTH sides so a delete on another
      // device can't resurrect through the union/re-upload below.
      final tombstoned =
          await DeletionsSync.fetchTombstonedIds('fill_ups', transport: t);
      final serverRows = SyncHelper.removeTombstoned(
        serverRowsRaw,
        tombstoned,
        key: (r) => r.getString('id'),
      ).toList();
      final liveLocal =
          localFillUps.where((f) => !tombstoned.contains(f.id)).toList();

      final serverIds = serverRows
          .map((r) => r.getString('id'))
          .whereType<String>()
          .toSet();
      final localIds = liveLocal.map((f) => f.id).toSet();

      debugPrint('FillUpsSync.merge: local=${localIds.length}, '
          'server=${serverIds.length}');

      // #3122 — last-write-wins for ids present on both sides: a local
      // edit re-uploads, a fresher server row overwrites the local copy.
      final lww = SyncHelper.lwwSplit(
        local: liveLocal,
        serverRows: serverRows,
        id: (f) => f.id,
        localStamp: (f) => f.updatedAt,
        tombstoned: tombstoned,
      );

      // Upload local-only + local-newer fill-ups.
      final localOnly =
          liveLocal.where((f) => !serverIds.contains(f.id)).toList();
      final toUpload = [...localOnly, ...lww.localNewer];
      if (toUpload.isNotEmpty) {
        final rows = toUpload
            .map((f) => {
                  'id': f.id,
                  'user_id': t.userId,
                  'vehicle_id': f.vehicleId,
                  'recorded_at': f.date.toIso8601String(),
                  'data': f.toJson(),
                  // Carry the local edit stamp so the next LWW compare
                  // sees equal stamps (skip) instead of a phantom-newer
                  // server row. Legacy unstamped records fall back to
                  // upload time.
                  'updated_at': (f.updatedAt ?? DateTime.now())
                      .toUtc()
                      .toIso8601String(),
                })
            .toList();
        await t.upsert('fill_ups', rows, onConflict: 'user_id,id');
        debugPrint('FillUpsSync.merge: uploaded ${toUpload.length} '
            'fill-ups (${lww.localNewer.length} local-newer edits)');
      }

      FillUp? decode(Map<String, dynamic> r) {
        final data = r['data'];
        if (data is Map<String, dynamic>) {
          try {
            return FillUp.fromJson(data);
          } catch (e, st) {
            unawaited(errorLogger.log(ErrorLayer.sync, e, st,
                context: const {'where': 'FillUpsSync.merge decode failed'}));
            return null;
          }
        }
        return null;
      }

      // Download server-only fill-ups…
      final downloaded = serverRows
          .where((r) => !localIds.contains(r.getString('id')))
          .map(decode)
          .whereType<FillUp>()
          .toList();
      // …and overwrite local copies the server has a fresher edit of.
      final serverNewerById = <String, FillUp>{
        for (final f
            in lww.serverNewer.map(decode).whereType<FillUp>())
          f.id: f,
      };

      return [
        for (final f in liveLocal) serverNewerById[f.id] ?? f,
        ...downloaded,
      ];
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.sync, e, st, context: const {'where': 'FillUpsSync.merge FAILED'}));
      return localFillUps;
    }
  }

  /// Remove a single fill-up from the server (called on explicit
  /// delete from the consumption log). Silent on failure.
  static Future<void> delete(String fillUpId) async {
    final client = TankSyncClient.client;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return;
    try {
      // #3078/#3123 — tombstone-first (journal-backed): the tombstone must
      // not depend on the row delete succeeding.
      await DeletionsSync.record('fill_ups', fillUpId);
      await client
          .from('fill_ups')
          .delete()
          .eq('user_id', userId)
          .eq('id', fillUpId);
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.sync, e, st, context: const {'where': 'FillUpsSync.delete FAILED'}));
    }
  }
}
