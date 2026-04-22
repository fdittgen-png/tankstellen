import 'package:flutter/foundation.dart';

import '../../features/vehicle/domain/entities/vehicle_profile.dart';
import '../utils/json_extensions.dart';
import 'supabase_client.dart';

/// Per-vehicle profile sync with Supabase (#713), pulled out of
/// [SyncService] (#727).
///
/// Vehicles are the one sync concern where the server row carries a
/// full domain JSON blob (engine fuel type, display name, flex-fuel
/// config, per-vehicle defaults) rather than a bare id — the
/// download branch decodes each row back into a [VehicleProfile]
/// and appends it to the local list.
///
/// Per-device `UserProfile`s are NOT synced (each device keeps its
/// own defaulting), only the `VehicleProfile`s. That invariant is
/// what the merge rule here preserves.
class VehiclesSync {
  VehiclesSync._();

  /// Merge [localVehicles] with the user's `vehicles` rows on
  /// Supabase. Returns the superset (local + server-only downloaded).
  /// Unauthenticated path returns the input unchanged.
  static Future<List<VehicleProfile>> merge(
    List<VehicleProfile> localVehicles,
  ) async {
    final client = TankSyncClient.client;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) {
      debugPrint('VehiclesSync.merge: not authenticated');
      return localVehicles;
    }

    try {
      final serverRows = await client
          .from('vehicles')
          .select('id, data')
          .eq('user_id', userId);

      final serverIds = serverRows
          .map((r) => r.getString('id'))
          .whereType<String>()
          .toSet();
      final localIds = localVehicles.map((v) => v.id).toSet();

      debugPrint('VehiclesSync.merge: local=${localIds.length}, '
          'server=${serverIds.length}');

      // Upload local-only vehicles.
      final localOnly =
          localVehicles.where((v) => !serverIds.contains(v.id)).toList();
      if (localOnly.isNotEmpty) {
        final rows = localOnly
            .map((v) => {
                  'id': v.id,
                  'user_id': userId,
                  'data': v.toJson(),
                  'updated_at': DateTime.now().toIso8601String(),
                })
            .toList();
        await client
            .from('vehicles')
            .upsert(rows, onConflict: 'user_id,id');
        debugPrint('VehiclesSync.merge: uploaded ${localOnly.length} '
            'new vehicles');
      }

      // Download server-only vehicles.
      final downloaded = serverRows
          .where((r) => !localIds.contains(r.getString('id')))
          .map((r) {
        final data = r['data'];
        if (data is Map<String, dynamic>) {
          try {
            return VehicleProfile.fromJson(data);
          } catch (e) {
            debugPrint('VehiclesSync.merge decode failed: $e');
            return null;
          }
        }
        return null;
      }).whereType<VehicleProfile>().toList();

      return [...localVehicles, ...downloaded];
    } catch (e) {
      debugPrint('VehiclesSync.merge FAILED: $e');
      return localVehicles;
    }
  }

  /// Remove a single vehicle from the server (called on explicit
  /// delete from the vehicle list screen). Silent on failure — the
  /// local delete already happened and there's nothing the caller
  /// can do about a transient network blip.
  static Future<void> delete(String vehicleId) async {
    final client = TankSyncClient.client;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return;
    try {
      await client
          .from('vehicles')
          .delete()
          .eq('user_id', userId)
          .eq('id', vehicleId);
    } catch (e) {
      debugPrint('VehiclesSync.delete FAILED: $e');
    }
  }
}
