import 'package:flutter/foundation.dart';

import '../../features/consumption/domain/entities/fill_up.dart';
import '../utils/json_extensions.dart';
import 'supabase_client.dart';

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
      final serverRows = await client
          .from('fill_ups')
          .select('id, data')
          .eq('user_id', userId);

      final serverIds = serverRows
          .map((r) => r.getString('id'))
          .whereType<String>()
          .toSet();
      final localIds = localFillUps.map((f) => f.id).toSet();

      debugPrint('FillUpsSync.merge: local=${localIds.length}, '
          'server=${serverIds.length}');

      // Upload local-only fill-ups.
      final localOnly =
          localFillUps.where((f) => !serverIds.contains(f.id)).toList();
      if (localOnly.isNotEmpty) {
        final rows = localOnly
            .map((f) => {
                  'id': f.id,
                  'user_id': userId,
                  'vehicle_id': f.vehicleId,
                  'recorded_at': f.date.toIso8601String(),
                  'data': f.toJson(),
                  'updated_at': DateTime.now().toIso8601String(),
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
          } catch (e) {
            debugPrint('FillUpsSync.merge decode failed: $e');
            return null;
          }
        }
        return null;
      }).whereType<FillUp>().toList();

      return [...localFillUps, ...downloaded];
    } catch (e) {
      debugPrint('FillUpsSync.merge FAILED: $e');
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
    } catch (e) {
      debugPrint('FillUpsSync.delete FAILED: $e');
    }
  }
}
