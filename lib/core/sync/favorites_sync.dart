import 'package:flutter/foundation.dart';

import '../utils/json_extensions.dart';
import 'supabase_client.dart';

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
      final serverIds = serverRows
          .map((r) => r.getString('station_id'))
          .whereType<String>()
          .toSet();
      final localIds = localFavoriteIds.toSet();

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

      return localIds.union(serverIds).toList();
    } catch (e, st) {
      debugPrint('FavoritesSync.merge FAILED: $e\n$st');
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
      await client
          .from('favorites')
          .delete()
          .eq('user_id', userId)
          .eq('station_id', stationId);
      debugPrint('FavoritesSync.delete: $stationId removed from server');
    } catch (e, st) {
      debugPrint('FavoritesSync.delete FAILED: $e\n$st');
    }
  }
}
