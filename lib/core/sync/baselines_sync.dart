import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../features/consumption/data/baseline_sync.dart';
import 'supabase_client.dart';

/// Per-vehicle OBD2 baseline sync with Supabase (#780), pulled out of
/// [SyncService] (#727).
///
/// Baselines are heavier than the other sync concerns: the payload
/// is a JSON blob keyed by driving situation (per-situation
/// accumulators the trip recorder builds), and the merge rule is
/// "for every situation, the accumulator with the higher sample
/// count wins". That merge logic lives in
/// `features/consumption/data/baseline_sync.dart`
/// (`mergeBaselineJson`, `totalSampleCount`) — we just wire it up to
/// the Supabase `obd2_baselines` table here.
class BaselinesSync {
  BaselinesSync._();

  /// Two-way merge of one vehicle's baseline. Returns the merged JSON
  /// payload that callers should persist locally; returns the
  /// original [localJson] unchanged when offline or unauthenticated,
  /// so baseline recording keeps working without the cloud layer.
  ///
  /// [totalSampleCountOverride] lets the caller supply a pre-computed
  /// total — the Dart layer already counts samples for the status UI,
  /// so we avoid decoding the JSON twice when it's already available.
  static Future<String?> merge({
    required String vehicleId,
    required String? localJson,
    int? totalSampleCountOverride,
  }) async {
    final client = TankSyncClient.client;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) {
      debugPrint('BaselinesSync.merge: not authenticated');
      return localJson;
    }

    try {
      final serverRow = await client
          .from('obd2_baselines')
          .select('data')
          .eq('user_id', userId)
          .eq('vehicle_id', vehicleId)
          .maybeSingle();

      final serverData = serverRow == null
          ? null
          : (serverRow['data'] as Map?)?.cast<String, dynamic>();

      final merged = mergeBaselineJson(
        localJson,
        serverData == null ? null : jsonEncode(serverData),
      );
      if (merged == null) return localJson;

      final mergedDecoded =
          (jsonDecode(merged) as Map).cast<String, dynamic>();
      final total =
          totalSampleCountOverride ?? totalSampleCount(mergedDecoded);

      await client.from('obd2_baselines').upsert(
        {
          'user_id': userId,
          'vehicle_id': vehicleId,
          'total_samples': total,
          'data': mergedDecoded,
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'user_id,vehicle_id',
      );
      return merged;
    } catch (e) {
      debugPrint('BaselinesSync.merge FAILED: $e');
      return localJson;
    }
  }

  /// Remove a single vehicle's baseline from the server. Called on
  /// explicit "Forget baseline" from the vehicle edit UI. Silent on
  /// failure — there's nothing the caller can do about a network
  /// blip, and the local copy is already gone by the time this runs.
  static Future<void> delete(String vehicleId) async {
    final client = TankSyncClient.client;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return;
    try {
      await client
          .from('obd2_baselines')
          .delete()
          .eq('user_id', userId)
          .eq('vehicle_id', vehicleId);
    } catch (e) {
      debugPrint('BaselinesSync.delete FAILED: $e');
    }
  }
}
