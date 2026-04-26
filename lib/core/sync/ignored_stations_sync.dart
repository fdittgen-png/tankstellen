import 'package:flutter/foundation.dart';

import '../utils/json_extensions.dart';
import 'supabase_client.dart';

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
      final serverIds = serverRows
          .map((r) => r.getString('station_id'))
          .whereType<String>()
          .toSet();
      final localIds = localIgnoredIds.toSet();

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

      return localIds.union(serverIds).toList();
    } catch (e, st) {
      debugPrint('IgnoredStationsSync.merge FAILED: $e\n$st');
      return localIgnoredIds;
    }
  }
}
