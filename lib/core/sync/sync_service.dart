import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/itinerary/domain/entities/saved_itinerary.dart';
import '../utils/json_extensions.dart';
import 'supabase_client.dart';

/// Orchestrates two-way sync between local Hive storage and Supabase.
///
/// CRITICAL: All methods use `auth.uid()` from the active Supabase session
/// (NOT a stored userId from Hive). RLS policies check `user_id = auth.uid()`,
/// so the JWT token's user ID must match the user_id column in every query.
class SyncService {
  SyncService._();

  static SupabaseClient? get _client => TankSyncClient.client;

  /// Get the authenticated user ID from the active JWT session.
  /// Returns null if not authenticated — callers must abort sync.
  static String? get _authenticatedUserId =>
      _client?.auth.currentUser?.id;

  // ---------------------------------------------------------------------------
  // Favorites
  // ---------------------------------------------------------------------------

  /// Sync favorites: merges local and server sets.
  /// Uses the authenticated session's user ID (NOT a provided one).
  static Future<List<String>> syncFavorites(
    List<String> localFavoriteIds,
  ) async {
    final client = _client;
    final userId = _authenticatedUserId;
    if (client == null || userId == null) {
      debugPrint('SyncService.syncFavorites: not authenticated (client=${client != null}, userId=$userId)');
      return localFavoriteIds;
    }

    try {
      // 1. Fetch server favorites
      final serverRows = await client
          .from('favorites')
          .select('station_id')
          .eq('user_id', userId);
      final serverIds = serverRows
          .map((r) => r.getString('station_id'))
          .whereType<String>()
          .toSet();
      final localIds = localFavoriteIds.toSet();

      debugPrint('SyncService.syncFavorites: local=${localIds.length}, server=${serverIds.length}, userId=$userId');

      // 2. Upload local-only favorites
      final localOnly = localIds.difference(serverIds);
      if (localOnly.isNotEmpty) {
        final rows = localOnly
            .map((id) => {'user_id': userId, 'station_id': id})
            .toList();
        await client.from('favorites').upsert(rows, onConflict: 'user_id,station_id');
        debugPrint('SyncService.syncFavorites: uploaded ${localOnly.length} new favorites');
      }

      // 3. Return merged set
      final merged = localIds.union(serverIds).toList();
      return merged;
    } catch (e) {
      debugPrint('SyncService.syncFavorites FAILED: $e');
      return localFavoriteIds;
    }
  }

  // ---------------------------------------------------------------------------
  // Delete single favorite (when user explicitly removes)
  // ---------------------------------------------------------------------------

  /// Delete a single favorite from the server.
  /// Only called when user explicitly removes a favorite.
  static Future<void> deleteFavorite(String stationId) async {
    final client = _client;
    final userId = _authenticatedUserId;
    if (client == null || userId == null) return;

    try {
      await client
          .from('favorites')
          .delete()
          .eq('user_id', userId)
          .eq('station_id', stationId);
      debugPrint('SyncService.deleteFavorite: $stationId removed from server');
    } catch (e) {
      debugPrint('SyncService.deleteFavorite FAILED: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Data transparency
  // ---------------------------------------------------------------------------

  /// Fetch all user data. Uses authenticated session userId.
  static Future<Map<String, dynamic>> fetchAllUserData() async {
    final client = _client;
    final userId = _authenticatedUserId;
    if (client == null || userId == null) {
      return {'error': 'Not authenticated (userId=$userId)'};
    }

    debugPrint('SyncService.fetchAllUserData: userId=$userId');

    try {
      final favorites =
          await client.from('favorites').select().eq('user_id', userId);
      final alerts =
          await client.from('alerts').select().eq('user_id', userId);
      final pushTokens =
          await client.from('push_tokens').select().eq('user_id', userId);
      final reports =
          await client.from('price_reports').select().eq('reporter_id', userId);
      final itineraries =
          await client.from('itineraries').select().eq('user_id', userId);

      debugPrint('SyncService.fetchAllUserData: favorites=${favorites.length}, alerts=${alerts.length}');

      return {
        'favorites': favorites,
        'alerts': alerts,
        'push_tokens': pushTokens,
        'reports': reports,
        'itineraries': itineraries,
      };
    } catch (e) {
      debugPrint('SyncService.fetchAllUserData FAILED: $e');
      return {'error': e.toString()};
    }
  }

  // ---------------------------------------------------------------------------
  // Itineraries
  // ---------------------------------------------------------------------------

  /// Save or update an itinerary on the server.
  static Future<bool> saveItinerary(SavedItinerary itinerary) async {
    final client = _client;
    final userId = _authenticatedUserId;
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
      debugPrint('SyncService.saveItinerary: saved "${itinerary.name}"');
      return true;
    } catch (e) {
      debugPrint('SyncService.saveItinerary FAILED: $e');
      return false;
    }
  }

  /// Fetch all itineraries for the current user.
  static Future<List<SavedItinerary>> fetchItineraries() async {
    final client = _client;
    final userId = _authenticatedUserId;
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
      debugPrint('SyncService.fetchItineraries FAILED: $e');
      return [];
    }
  }

  /// Delete an itinerary from the server.
  static Future<bool> deleteItinerary(String itineraryId) async {
    final client = _client;
    final userId = _authenticatedUserId;
    if (client == null || userId == null) return false;

    try {
      await client
          .from('itineraries')
          .delete()
          .eq('id', itineraryId)
          .eq('user_id', userId);
      return true;
    } catch (e) {
      debugPrint('SyncService.deleteItinerary FAILED: $e');
      return false;
    }
  }

  /// Delete all user data from the server.
  static Future<void> deleteAllUserData() async {
    final client = _client;
    final userId = _authenticatedUserId;
    if (client == null || userId == null) return;

    await client.from('favorites').delete().eq('user_id', userId);
    await client.from('alerts').delete().eq('user_id', userId);
    await client.from('push_tokens').delete().eq('user_id', userId);
    await client.from('price_reports').delete().eq('reporter_id', userId);
    await client.from('vehicles').delete().eq('user_id', userId);
    await client.from('fill_ups').delete().eq('user_id', userId);
  }


}
