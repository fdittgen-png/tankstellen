import 'package:flutter/foundation.dart';

import '../../features/itinerary/domain/entities/saved_itinerary.dart';
import '../utils/json_extensions.dart';
import 'supabase_client.dart';

/// Saved-itinerary sync with Supabase, pulled out of [SyncService]
/// (#727).
///
/// Unlike the other merge-style sync classes, itineraries are
/// one-way from the server's perspective: local provider holds the
/// source of truth and push explicitly via [save] / [delete] on
/// every user action, then reconciles with [fetchAll] on login.
/// Deduplication happens at the caller (the itinerary provider
/// unions the local list with `fetchAll`'s return before rendering).
class ItinerariesSync {
  ItinerariesSync._();

  /// Save or update an itinerary on the server. Returns `true` on
  /// success, `false` when unauthenticated or the upsert fails —
  /// mirrors the original contract so the itinerary provider's
  /// "synced?" badge keeps working.
  static Future<bool> save(SavedItinerary itinerary) async {
    final client = TankSyncClient.client;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return false;

    try {
      await client.from('itineraries').upsert({
        'id': itinerary.id,
        'user_id': userId,
        'name': itinerary.name,
        'waypoints': itinerary.waypoints,
        'distance_km': itinerary.distanceKm,
        'duration_minutes': itinerary.durationMinutes,
        'avoid_highways': itinerary.avoidHighways,
        'fuel_type': itinerary.fuelType,
        'selected_station_ids': itinerary.selectedStationIds,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'id');
      debugPrint('ItinerariesSync.save: saved "${itinerary.name}"');
      return true;
    } catch (e) {
      debugPrint('ItinerariesSync.save FAILED: $e');
      return false;
    }
  }

  /// Fetch every itinerary owned by the authenticated user. Returns
  /// an empty list when unauthenticated or the query fails — the
  /// provider keeps showing whatever was in local cache.
  static Future<List<SavedItinerary>> fetchAll() async {
    final client = TankSyncClient.client;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return [];

    try {
      final rows = await client
          .from('itineraries')
          .select()
          .eq('user_id', userId)
          .order('updated_at', ascending: false);

      return rows.map((r) {
        final createdAtStr = r.getString('created_at');
        final updatedAtStr = r.getString('updated_at');
        return SavedItinerary(
          id: r.getString('id') ?? '',
          name: r.getString('name') ?? '',
          waypoints: r.getList<Map<String, dynamic>>('waypoints'),
          distanceKm: r.getDouble('distance_km') ?? 0.0,
          durationMinutes: r.getDouble('duration_minutes') ?? 0.0,
          avoidHighways: r.getBool('avoid_highways') ?? false,
          fuelType: r.getString('fuel_type') ?? 'e10',
          selectedStationIds: r.getList<String>('selected_station_ids'),
          createdAt: createdAtStr != null
              ? DateTime.tryParse(createdAtStr) ?? DateTime.now()
              : DateTime.now(),
          updatedAt: updatedAtStr != null
              ? DateTime.tryParse(updatedAtStr) ?? DateTime.now()
              : DateTime.now(),
        );
      }).toList();
    } catch (e) {
      debugPrint('ItinerariesSync.fetchAll FAILED: $e');
      return [];
    }
  }

  /// Delete a single itinerary from the server. Returns `true` on
  /// success, `false` when unauthenticated or the delete fails.
  static Future<bool> delete(String itineraryId) async {
    final client = TankSyncClient.client;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return false;

    try {
      await client
          .from('itineraries')
          .delete()
          .eq('id', itineraryId)
          .eq('user_id', userId);
      return true;
    } catch (e) {
      debugPrint('ItinerariesSync.delete FAILED: $e');
      return false;
    }
  }
}
