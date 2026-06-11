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

/// Favorites sync with Supabase, pulled out of [SyncService] (#727).
///
/// Bidirectional merge over the `favorites` table — local-only ids
/// upload (idempotent via `(user_id, station_id)` upsert conflict),
/// and the returned list is the union of local + server. Unlike the
/// other id-based syncs, favorites additionally expose an explicit
/// [delete] for "user unfavorited a station" — the other direction
/// (server unfavorited) isn't a user-visible flow.
class FavoritesSync {
  FavoritesSync._();

  /// Merge [localFavoriteIds] with the user's `favorites` rows on
  /// Supabase. Returns the superset (local ∪ server).
  static Future<List<String>> merge(List<String> localFavoriteIds) async {
    final client = TankSyncClient.client;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) {
      debugPrint('FavoritesSync.merge: not authenticated '
          '(client=${client != null}, userId=$userId)');
      return localFavoriteIds;
    }

    try {
      final serverRows = await client
          .from('favorites')
          .select('station_id')
          .eq('user_id', userId);
      // #3078 — drop tombstoned ids from the server set so a delete on
      // another device can't resurrect through the union below.
      final tombstoned = await DeletionsSync.fetchTombstonedIds('favorites');
      final serverIds = SyncHelper.removeTombstoned(
        serverRows.map((r) => r.getString('station_id')),
        tombstoned,
        key: (id) => id,
      ).whereType<String>().toSet();
      final localIds =
          localFavoriteIds.where((id) => !tombstoned.contains(id)).toSet();

      debugPrint('FavoritesSync.merge: local=${localIds.length}, '
          'server=${serverIds.length}, userId=$userId');

      // Upload local-only favorites.
      final localOnly = localIds.difference(serverIds);
      if (localOnly.isNotEmpty) {
        final rows = localOnly
            .map((id) => {'user_id': userId, 'station_id': id})
            .toList();
        await client
            .from('favorites')
            .upsert(rows, onConflict: 'user_id,station_id');
        debugPrint('FavoritesSync.merge: uploaded '
            '${localOnly.length} new favorites');
      }

      // #3126 — per-table counts into the exportable trace.
      SyncRunTrace.table(
        'favorites',
        uploaded: localOnly.length,
        downloaded: serverIds.difference(localIds).length,
        tombstoned: tombstoned.length,
      );

      return localIds.union(serverIds).toList();
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.sync, e, st, context: const {'where': 'FavoritesSync.merge FAILED'}));
      return localFavoriteIds;
    }
  }

  /// Delete a single favorite from the server. Called only when the
  /// user explicitly removes a favorite on this device — the union
  /// merge path never deletes.
  static Future<void> delete(String stationId) async {
    final client = TankSyncClient.client;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return;

    try {
      // #3078/#3123 — tombstone-first: the tombstone is the durable "this
      // id is dead" record (journal-backed), so it must not depend on the
      // row delete succeeding — a network blip used to skip it entirely
      // and the next union merge resurrected the favorite.
      await DeletionsSync.record('favorites', stationId);
      await client
          .from('favorites')
          .delete()
          .eq('user_id', userId)
          .eq('station_id', stationId);
      debugPrint('FavoritesSync.delete: $stationId removed from server');
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.sync, e, st, context: const {'where': 'FavoritesSync.delete FAILED'}));
    }
  }
}
