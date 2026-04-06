import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/alerts/data/models/price_alert.dart';
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
  // Ignored Stations
  // ---------------------------------------------------------------------------

  /// Sync ignored stations: merges local and server sets.
  static Future<List<String>> syncIgnoredStations(
    List<String> localIgnoredIds,
  ) async {
    final client = _client;
    final userId = _authenticatedUserId;
    if (client == null || userId == null) {
      debugPrint('SyncService.syncIgnoredStations: not authenticated');
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

      debugPrint('SyncService.syncIgnoredStations: local=${localIds.length}, server=${serverIds.length}');

      // Upload local-only
      final localOnly = localIds.difference(serverIds);
      if (localOnly.isNotEmpty) {
        final rows = localOnly
            .map((id) => {'user_id': userId, 'station_id': id})
            .toList();
        await client.from('ignored_stations').upsert(rows, onConflict: 'user_id,station_id');
        debugPrint('SyncService.syncIgnoredStations: uploaded ${localOnly.length}');
      }

      return localIds.union(serverIds).toList();
    } catch (e) {
      debugPrint('SyncService.syncIgnoredStations FAILED: $e');
      return localIgnoredIds;
    }
  }

  // ---------------------------------------------------------------------------
  // Ratings
  // ---------------------------------------------------------------------------

  /// Sync a single station rating to the server. Upserts (add or update).
  ///
  /// [shared] — when true, the rating is visible to all database users.
  /// When false (default), only the owner can see it (private mode).
  static Future<void> syncRating(String stationId, int rating, {bool shared = false}) async {
    final client = _client;
    final userId = _authenticatedUserId;
    if (client == null || userId == null) return;

    try {
      await client.from('station_ratings').upsert({
        'user_id': userId,
        'station_id': stationId,
        'rating': rating,
        'is_shared': shared,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,station_id');
      debugPrint('SyncService.syncRating: $stationId = $rating stars (shared=$shared)');
    } catch (e) {
      debugPrint('SyncService.syncRating FAILED: $e');
    }
  }

  /// Delete a rating from the server (when favorite is removed).
  static Future<void> deleteRating(String stationId) async {
    final client = _client;
    final userId = _authenticatedUserId;
    if (client == null || userId == null) return;

    try {
      await client
          .from('station_ratings')
          .delete()
          .eq('user_id', userId)
          .eq('station_id', stationId);
      debugPrint('SyncService.deleteRating: $stationId removed');
    } catch (e) {
      debugPrint('SyncService.deleteRating FAILED: $e');
    }
  }

  /// Fetch all ratings from server (for initial sync).
  static Future<Map<String, int>> fetchRatings() async {
    final client = _client;
    final userId = _authenticatedUserId;
    if (client == null || userId == null) return {};

    try {
      final rows = await client
          .from('station_ratings')
          .select('station_id, rating')
          .eq('user_id', userId);
      final result = <String, int>{};
      for (final r in rows) {
        final stationId = r.getString('station_id');
        final rating = r.getInt('rating');
        if (stationId != null && rating != null) {
          result[stationId] = rating;
        }
      }
      return result;
    } catch (e) {
      debugPrint('SyncService.fetchRatings FAILED: $e');
      return {};
    }
  }

  // ---------------------------------------------------------------------------
  // Price History (server-side)
  // ---------------------------------------------------------------------------

  /// Fetch price history from server for a station.
  static Future<List<Map<String, dynamic>>> fetchPriceHistory(
    String stationId, {
    int days = 30,
  }) async {
    final client = _client;
    if (client == null) return [];

    try {
      final cutoff = DateTime.now().subtract(Duration(days: days)).toIso8601String();
      final rows = await client
          .from('price_snapshots')
          .select()
          .eq('station_id', stationId)
          .gte('recorded_at', cutoff)
          .order('recorded_at', ascending: true);
      return List<Map<String, dynamic>>.from(rows);
    } catch (e) {
      debugPrint('SyncService.fetchPriceHistory FAILED: $e');
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // Alerts
  // ---------------------------------------------------------------------------

  /// Sync alerts: merges local and server sets.
  static Future<List<PriceAlert>> syncAlerts(
    List<PriceAlert> localAlerts,
  ) async {
    final client = _client;
    final userId = _authenticatedUserId;
    if (client == null || userId == null) {
      debugPrint('SyncService.syncAlerts: not authenticated');
      return localAlerts;
    }

    try {
      final serverRows =
          await client.from('alerts').select().eq('user_id', userId);
      final serverAlertIds = serverRows
          .map((r) => r.getString('id'))
          .whereType<String>()
          .toSet();
      final localAlertIds = localAlerts.map((a) => a.id).toSet();

      debugPrint('SyncService.syncAlerts: local=${localAlertIds.length}, server=${serverAlertIds.length}');

      // Upload local-only alerts
      final localOnly =
          localAlerts.where((a) => !serverAlertIds.contains(a.id)).toList();
      if (localOnly.isNotEmpty) {
        final rows = localOnly
            .map((a) => {
                  'id': a.id,
                  'user_id': userId,
                  'station_id': a.stationId,
                  'station_name': a.stationName,
                  'fuel_type': a.fuelType.name,
                  'target_price': a.targetPrice,
                  'is_active': a.isActive,
                  'created_at': a.createdAt.toIso8601String(),
                })
            .toList();
        await client.from('alerts').upsert(rows, onConflict: 'id');
        debugPrint('SyncService.syncAlerts: uploaded ${localOnly.length} alerts');
      }

      // Download server-only alerts
      final serverOnly =
          serverRows.where((r) => !localAlertIds.contains(r.getString('id')));
      final downloaded = serverOnly.map((r) {
        return PriceAlert.fromJson({
          'id': r.getString('id') ?? '',
          'stationId': r.getString('station_id') ?? '',
          'stationName': r.getString('station_name') ?? '',
          'fuelType': r.getString('fuel_type') ?? '',
          'targetPrice': r.getDouble('target_price') ?? 0.0,
          'isActive': r.getBool('is_active') ?? true,
          'createdAt': r.getString('created_at') ?? '',
        });
      }).toList();

      return [...localAlerts, ...downloaded];
    } catch (e) {
      debugPrint('SyncService.syncAlerts FAILED: $e');
      return localAlerts;
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
  }
}
