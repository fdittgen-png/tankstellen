// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../utils/json_extensions.dart';
import 'deletions_sync.dart';
import 'supabase_client.dart';
import 'sync_helper.dart';
import 'sync_run_trace.dart';
import '../../core/logging/error_logger.dart';

/// Ignored-stations sync with Supabase, pulled out of [SyncService] (#727).
///
/// Same bidirectional-merge pattern as favorites: upload local-only
/// ids (idempotent via `(user_id, station_id)` upsert conflict), then
/// return the union of local + server sets. Unauthenticated path
/// returns the input unchanged — the feature keeps working on pure
/// local state when the user isn't signed in.
class IgnoredStationsSync {
  IgnoredStationsSync._();

  /// Merge [localIgnoredIds] with the user's `ignored_stations` rows
  /// on Supabase. Returns the superset (local ∪ server).
  static Future<List<String>> merge(List<String> localIgnoredIds) async {
    final client = TankSyncClient.client;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) {
      debugPrint('IgnoredStationsSync.merge: not authenticated');
      return localIgnoredIds;
    }

    try {
      final serverRows = await client
          .from('ignored_stations')
          .select('station_id')
          .eq('user_id', userId);
      // #3078 — drop tombstoned ids so an un-ignore on another device
      // doesn't resurrect through the union below.
      final tombstoned =
          await DeletionsSync.fetchTombstonedIds('ignored_stations');
      final serverIds = SyncHelper.removeTombstoned(
        serverRows.map((r) => r.getString('station_id')),
        tombstoned,
        key: (id) => id,
      ).whereType<String>().toSet();
      final localIds =
          localIgnoredIds.where((id) => !tombstoned.contains(id)).toSet();

      debugPrint('IgnoredStationsSync.merge: local=${localIds.length}, '
          'server=${serverIds.length}');

      // Upload local-only ids.
      final localOnly = localIds.difference(serverIds);
      if (localOnly.isNotEmpty) {
        final rows = localOnly
            .map((id) => {'user_id': userId, 'station_id': id})
            .toList();
        await client
            .from('ignored_stations')
            .upsert(rows, onConflict: 'user_id,station_id');
        debugPrint(
            'IgnoredStationsSync.merge: uploaded ${localOnly.length}');
      }

      // #3126 — per-table counts into the exportable trace.
      SyncRunTrace.table(
        'ignored_stations',
        uploaded: localOnly.length,
        downloaded: serverIds.difference(localIds).length,
        tombstoned: tombstoned.length,
      );

      return localIds.union(serverIds).toList();
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.sync, e, st, context: const {'where': 'IgnoredStationsSync.merge FAILED'}));
      return localIgnoredIds;
    }
  }

  /// Un-ignore a single station on the server (#3078). Before this existed
  /// the un-ignore path only re-ran [merge], whose union re-added the still-
  /// server row, so the station never actually un-hid. Now the server row is
  /// deleted AND tombstoned, so neither side resurrects it. Silent on failure.
  static Future<void> delete(String stationId) async {
    final client = TankSyncClient.client;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return;
    try {
      // #3123 — tombstone-first (journal-backed): a failed row delete must
      // not also skip the tombstone, or the un-ignore resurrects.
      await DeletionsSync.record('ignored_stations', stationId);
      await client
          .from('ignored_stations')
          .delete()
          .eq('user_id', userId)
          .eq('station_id', stationId);
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.sync, e, st,
          context: const {'where': 'IgnoredStationsSync.delete FAILED'}));
    }
  }
}
