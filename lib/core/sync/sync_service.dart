import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/alerts/data/models/price_alert.dart';
import '../../features/consumption/data/baseline_sync.dart';
import '../../features/consumption/domain/entities/fill_up.dart';
import '../../features/itinerary/domain/entities/saved_itinerary.dart';
import '../../features/vehicle/domain/entities/vehicle_profile.dart';
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
    await client.from('vehicles').delete().eq('user_id', userId);
    await client.from('fill_ups').delete().eq('user_id', userId);
  }

  // ---------------------------------------------------------------------------
  // Vehicles (#713)
  // ---------------------------------------------------------------------------

  /// Two-way sync of vehicles: uploads local-only, downloads server-only.
  /// Profiles are NOT synced (each device keeps its own defaulting).
  static Future<List<VehicleProfile>> syncVehicles(
    List<VehicleProfile> localVehicles,
  ) async {
    final client = _client;
    final userId = _authenticatedUserId;
    if (client == null || userId == null) {
      debugPrint('SyncService.syncVehicles: not authenticated');
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

      debugPrint(
          'SyncService.syncVehicles: local=${localIds.length}, server=${serverIds.length}');

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
        debugPrint(
            'SyncService.syncVehicles: uploaded ${localOnly.length} new vehicles');
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
            debugPrint('SyncService.syncVehicles decode failed: $e');
            return null;
          }
        }
        return null;
      }).whereType<VehicleProfile>().toList();

      return [...localVehicles, ...downloaded];
    } catch (e) {
      debugPrint('SyncService.syncVehicles FAILED: $e');
      return localVehicles;
    }
  }

  /// Remove a single vehicle from the server (called on explicit delete).
  static Future<void> deleteVehicle(String vehicleId) async {
    final client = _client;
    final userId = _authenticatedUserId;
    if (client == null || userId == null) return;
    try {
      await client
          .from('vehicles')
          .delete()
          .eq('user_id', userId)
          .eq('id', vehicleId);
    } catch (e) {
      debugPrint('SyncService.deleteVehicle FAILED: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Consumption logs / fill-ups (#713)
  // ---------------------------------------------------------------------------

  /// Two-way sync of fill-ups (consumption log): uploads local-only,
  /// downloads server-only. Deduplication by id.
  static Future<List<FillUp>> syncFillUps(List<FillUp> localFillUps) async {
    final client = _client;
    final userId = _authenticatedUserId;
    if (client == null || userId == null) {
      debugPrint('SyncService.syncFillUps: not authenticated');
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

      debugPrint(
          'SyncService.syncFillUps: local=${localIds.length}, server=${serverIds.length}');

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
        await client.from('fill_ups').upsert(rows, onConflict: 'user_id,id');
        debugPrint(
            'SyncService.syncFillUps: uploaded ${localOnly.length} new fill-ups');
      }

      final downloaded = serverRows
          .where((r) => !localIds.contains(r.getString('id')))
          .map((r) {
        final data = r['data'];
        if (data is Map<String, dynamic>) {
          try {
            return FillUp.fromJson(data);
          } catch (e) {
            debugPrint('SyncService.syncFillUps decode failed: $e');
            return null;
          }
        }
        return null;
      }).whereType<FillUp>().toList();

      return [...localFillUps, ...downloaded];
    } catch (e) {
      debugPrint('SyncService.syncFillUps FAILED: $e');
      return localFillUps;
    }
  }

  /// Remove a single fill-up from the server (called on explicit delete).
  static Future<void> deleteFillUp(String fillUpId) async {
    final client = _client;
    final userId = _authenticatedUserId;
    if (client == null || userId == null) return;
    try {
      await client
          .from('fill_ups')
          .delete()
          .eq('user_id', userId)
          .eq('id', fillUpId);
    } catch (e) {
      debugPrint('SyncService.deleteFillUp FAILED: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // OBD2 baselines (#780)
  // ---------------------------------------------------------------------------

  /// Two-way sync of the baseline payload for a single vehicle.
  /// Merge rule is per-situation: for every driving situation, the
  /// accumulator with the higher sample count wins. Returns the
  /// merged JSON payload that callers should persist locally and
  /// hand back to [BaselineStore]; returns the original [localJson]
  /// unchanged when offline or unauthenticated.
  ///
  /// [totalSampleCountOverride] lets the caller supply a
  /// pre-computed total — the Dart layer already counts samples for
  /// the status UI, so we avoid decoding the JSON twice when it's
  /// already available.
  static Future<String?> syncVehicleBaseline({
    required String vehicleId,
    required String? localJson,
    int? totalSampleCountOverride,
  }) async {
    final client = _client;
    final userId = _authenticatedUserId;
    if (client == null || userId == null) {
      debugPrint('SyncService.syncVehicleBaseline: not authenticated');
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
      final total = totalSampleCountOverride ??
          totalSampleCount(mergedDecoded);

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
      debugPrint('SyncService.syncVehicleBaseline FAILED: $e');
      return localJson;
    }
  }

  /// Remove a single vehicle's baseline from the server. Called on
  /// explicit "Forget baseline" from the vehicle edit UI.
  static Future<void> deleteVehicleBaseline(String vehicleId) async {
    final client = _client;
    final userId = _authenticatedUserId;
    if (client == null || userId == null) return;
    try {
      await client
          .from('obd2_baselines')
          .delete()
          .eq('user_id', userId)
          .eq('vehicle_id', vehicleId);
    } catch (e) {
      debugPrint('SyncService.deleteVehicleBaseline FAILED: $e');
    }
  }
}
