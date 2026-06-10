// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../features/consumption/domain/entities/fill_up.dart';
import '../utils/json_extensions.dart';
import 'deletions_sync.dart';
import 'supabase_client.dart';
import 'sync_helper.dart';
import '../../core/logging/error_logger.dart';

/// Per-fill-up consumption-log sync with Supabase (#713), pulled out
/// of [SyncService] (#727).
///
/// Same shape as [VehiclesSync]: the server row carries a full
/// [FillUp] JSON blob and the download branch decodes each row back
/// into the domain entity. Merge rule: dedupe by id (both directions
/// idempotent via `(user_id, id)` upsert conflict). The extra
/// `vehicle_id` + `recorded_at` columns are for server-side
/// filtering — clients only read the `data` blob.
class FillUpsSync {
  FillUpsSync._();

  /// Merge [localFillUps] with the user's `fill_ups` rows on
  /// Supabase. Returns the superset (local + server-only downloaded).
  /// Unauthenticated path returns the input unchanged.
  static Future<List<FillUp>> merge(List<FillUp> localFillUps) async {
    final client = TankSyncClient.client;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) {
      debugPrint('FillUpsSync.merge: not authenticated');
      return localFillUps;
    }

    try {
      final serverRowsRaw = await client
          .from('fill_ups')
          .select('id, data')
          .eq('user_id', userId);

      // #3078 — drop tombstoned rows from BOTH sides so a delete on another
      // device can't resurrect through the union/re-upload below.
      final tombstoned = await DeletionsSync.fetchTombstonedIds('fill_ups');
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

      // Upload local-only fill-ups.
      final localOnly =
          liveLocal.where((f) => !serverIds.contains(f.id)).toList();
      if (localOnly.isNotEmpty) {
        final rows = localOnly
            .map((f) => {
                  'id': f.id,
                  'user_id': userId,
                  'vehicle_id': f.vehicleId,
                  'recorded_at': f.date.toIso8601String(),
                  'data': f.toJson(),
                  'updated_at': DateTime.now().toUtc().toIso8601String(),
                })
            .toList();
        await client
            .from('fill_ups')
            .upsert(rows, onConflict: 'user_id,id');
        debugPrint('FillUpsSync.merge: uploaded ${localOnly.length} '
            'new fill-ups');
      }

      // Download server-only fill-ups.
      final downloaded = serverRows
          .where((r) => !localIds.contains(r.getString('id')))
          .map((r) {
        final data = r['data'];
        if (data is Map<String, dynamic>) {
          try {
            return FillUp.fromJson(data);
          } catch (e, st) {
            unawaited(errorLogger.log(ErrorLayer.sync, e, st, context: const {'where': 'FillUpsSync.merge decode failed'}));
            return null;
          }
        }
        return null;
      }).whereType<FillUp>().toList();

      return [...liveLocal, ...downloaded];
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
      await client
          .from('fill_ups')
          .delete()
          .eq('user_id', userId)
          .eq('id', fillUpId);
      await DeletionsSync.record('fill_ups', fillUpId); // #3078
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.sync, e, st, context: const {'where': 'FillUpsSync.delete FAILED'}));
    }
  }
}
