import 'package:flutter/foundation.dart';

import '../../../features/alerts/data/models/price_alert.dart';
import '../../../features/itinerary/domain/entities/saved_itinerary.dart';
import '../../sync/supabase_client.dart';
import '../sync_repository.dart';

/// Supabase implementation of [SyncRepository].
///
/// Delegates all operations to the existing [TankSyncClient] and
/// static [SyncService] methods, wrapped behind the abstract interface.
class SupabaseSyncRepository implements SyncRepository {
  @override
  bool get isConnected => TankSyncClient.isConnected;

  @override
  String? get authenticatedUserId => TankSyncClient.client?.auth.currentUser?.id;

  // Implementation delegates to existing SyncService static methods.
  // This wrapper exists to enable swapping the backend without
  // changing any provider or screen code.

  @override
  Future<List<String>> syncFavorites(List<String> localIds) async {
    // Delegate to existing SyncService (keeping backward compatibility)
    final client = TankSyncClient.client;
    final userId = authenticatedUserId;
    if (client == null || userId == null) return localIds;

    try {
      final serverRows = await client.from('favorites').select('station_id').eq('user_id', userId);
      final serverIds = (serverRows as List).map((r) => r['station_id'] as String).toSet();
      final localIdSet = localIds.toSet();

      final localOnly = localIdSet.difference(serverIds);
      if (localOnly.isNotEmpty) {
        final rows = localOnly.map((id) => {'user_id': userId, 'station_id': id}).toList();
        await client.from('favorites').upsert(rows, onConflict: 'user_id,station_id');
      }

      return localIdSet.union(serverIds).toList();
    } catch (e) {
      debugPrint('SupabaseSyncRepo.syncFavorites: $e');
      return localIds;
    }
  }

  @override
  Future<void> deleteFavorite(String stationId) async {
    final client = TankSyncClient.client;
    final userId = authenticatedUserId;
    if (client == null || userId == null) return;
    try {
      await client.from('favorites').delete().eq('user_id', userId).eq('station_id', stationId);
    } catch (e) {
      debugPrint('SupabaseSyncRepo.deleteFavorite: $e');
    }
  }

  @override
  Future<List<String>> syncIgnoredStations(List<String> localIds) async {
    final client = TankSyncClient.client;
    final userId = authenticatedUserId;
    if (client == null || userId == null) return localIds;

    try {
      final serverRows = await client.from('ignored_stations').select('station_id').eq('user_id', userId);
      final serverIds = (serverRows as List).map((r) => r['station_id'] as String).toSet();
      final localIdSet = localIds.toSet();

      final localOnly = localIdSet.difference(serverIds);
      if (localOnly.isNotEmpty) {
        final rows = localOnly.map((id) => {'user_id': userId, 'station_id': id}).toList();
        await client.from('ignored_stations').upsert(rows, onConflict: 'user_id,station_id');
      }

      return localIdSet.union(serverIds).toList();
    } catch (e) {
      debugPrint('SupabaseSyncRepo.syncIgnoredStations: $e');
      return localIds;
    }
  }

  @override
  Future<void> syncRating(String stationId, int rating, {bool shared = false}) async {
    final client = TankSyncClient.client;
    final userId = authenticatedUserId;
    if (client == null || userId == null) return;
    try {
      await client.from('station_ratings').upsert({
        'user_id': userId, 'station_id': stationId, 'rating': rating,
        'is_shared': shared, 'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,station_id');
    } catch (e) {
      debugPrint('SupabaseSyncRepo.syncRating: $e');
    }
  }

  @override
  Future<void> deleteRating(String stationId) async {
    final client = TankSyncClient.client;
    final userId = authenticatedUserId;
    if (client == null || userId == null) return;
    try {
      await client.from('station_ratings').delete().eq('user_id', userId).eq('station_id', stationId);
    } catch (e) {
      debugPrint('SupabaseSyncRepo.deleteRating: $e');
    }
  }

  @override
  Future<Map<String, int>> fetchRatings() async {
    final client = TankSyncClient.client;
    final userId = authenticatedUserId;
    if (client == null || userId == null) return {};
    try {
      final rows = await client.from('station_ratings').select('station_id, rating').eq('user_id', userId);
      return {for (final r in (rows as List)) r['station_id'] as String: (r['rating'] as num).toInt()};
    } catch (e) {
      debugPrint('SupabaseSyncRepo.fetchRatings: $e');
      return {};
    }
  }

  @override
  Future<List<PriceAlert>> syncAlerts(List<PriceAlert> localAlerts) async {
    // Delegate to existing pattern — upload local-only, download server-only
    final client = TankSyncClient.client;
    final userId = authenticatedUserId;
    if (client == null || userId == null) return localAlerts;

    try {
      final serverRows = await client.from('alerts').select().eq('user_id', userId);
      final serverAlertIds = (serverRows as List).map((r) => r['id'] as String).toSet();
      final localAlertIds = localAlerts.map((a) => a.id).toSet();

      final localOnly = localAlerts.where((a) => !serverAlertIds.contains(a.id)).toList();
      if (localOnly.isNotEmpty) {
        final rows = localOnly.map((a) => {
          'id': a.id, 'user_id': userId, 'station_id': a.stationId,
          'station_name': a.stationName, 'fuel_type': a.fuelType.name,
          'target_price': a.targetPrice, 'is_active': a.isActive,
          'created_at': a.createdAt.toIso8601String(),
        }).toList();
        await client.from('alerts').upsert(rows, onConflict: 'id');
      }

      final serverOnly = (serverRows as List).where((r) => !localAlertIds.contains(r['id']));
      final downloaded = serverOnly.map((r) => PriceAlert.fromJson({
        'id': r['id'], 'stationId': r['station_id'], 'stationName': r['station_name'],
        'fuelType': r['fuel_type'], 'targetPrice': (r['target_price'] as num).toDouble(),
        'isActive': r['is_active'] ?? true, 'createdAt': r['created_at'],
      })).toList();

      return [...localAlerts, ...downloaded];
    } catch (e) {
      debugPrint('SupabaseSyncRepo.syncAlerts: $e');
      return localAlerts;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchPriceHistory(String stationId, {int days = 30}) async {
    final client = TankSyncClient.client;
    if (client == null) return [];
    try {
      final cutoff = DateTime.now().subtract(Duration(days: days)).toIso8601String();
      final rows = await client.from('price_snapshots').select()
          .eq('station_id', stationId).gte('recorded_at', cutoff).order('recorded_at', ascending: true);
      return (rows as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('SupabaseSyncRepo.fetchPriceHistory: $e');
      return [];
    }
  }

  @override
  Future<bool> saveItinerary(SavedItinerary itinerary) async {
    final client = TankSyncClient.client;
    final userId = authenticatedUserId;
    if (client == null || userId == null) return false;
    try {
      await client.from('itineraries').upsert({
        'id': itinerary.id, 'user_id': userId, 'name': itinerary.name,
        'waypoints': itinerary.waypoints, 'distance_km': itinerary.distanceKm,
        'duration_minutes': itinerary.durationMinutes, 'avoid_highways': itinerary.avoidHighways,
        'fuel_type': itinerary.fuelType, 'selected_station_ids': itinerary.selectedStationIds,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'id');
      return true;
    } catch (e) {
      debugPrint('SupabaseSyncRepo.saveItinerary: $e');
      return false;
    }
  }

  @override
  Future<List<SavedItinerary>> fetchItineraries() async {
    final client = TankSyncClient.client;
    final userId = authenticatedUserId;
    if (client == null || userId == null) return [];
    try {
      final rows = await client.from('itineraries').select().eq('user_id', userId).order('updated_at', ascending: false);
      return (rows as List).map((r) => SavedItinerary(
        id: r['id'] as String, name: r['name'] as String,
        waypoints: (r['waypoints'] as List).cast<Map<String, dynamic>>(),
        distanceKm: (r['distance_km'] as num).toDouble(),
        durationMinutes: (r['duration_minutes'] as num).toDouble(),
        avoidHighways: r['avoid_highways'] as bool? ?? false,
        fuelType: r['fuel_type'] as String? ?? 'e10',
        selectedStationIds: (r['selected_station_ids'] as List?)?.cast<String>() ?? [],
        createdAt: DateTime.parse(r['created_at'] as String),
        updatedAt: DateTime.parse(r['updated_at'] as String),
      )).toList();
    } catch (e) {
      debugPrint('SupabaseSyncRepo.fetchItineraries: $e');
      return [];
    }
  }

  @override
  Future<bool> deleteItinerary(String id) async {
    final client = TankSyncClient.client;
    final userId = authenticatedUserId;
    if (client == null || userId == null) return false;
    try {
      await client.from('itineraries').delete().eq('id', id).eq('user_id', userId);
      return true;
    } catch (e) {
      debugPrint('SupabaseSyncRepo.deleteItinerary: $e');
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>> fetchAllUserData() async {
    final client = TankSyncClient.client;
    final userId = authenticatedUserId;
    if (client == null || userId == null) return {'error': 'Not authenticated'};
    try {
      return {
        'favorites': await client.from('favorites').select().eq('user_id', userId),
        'alerts': await client.from('alerts').select().eq('user_id', userId),
        'push_tokens': await client.from('push_tokens').select().eq('user_id', userId),
        'reports': await client.from('price_reports').select().eq('reporter_id', userId),
        'itineraries': await client.from('itineraries').select().eq('user_id', userId),
      };
    } catch (e) {
      debugPrint('SupabaseSyncRepo.fetchAllUserData: $e');
      return {'error': e.toString()};
    }
  }

  @override
  Future<void> deleteAllUserData() async {
    final client = TankSyncClient.client;
    final userId = authenticatedUserId;
    if (client == null || userId == null) return;
    await client.from('favorites').delete().eq('user_id', userId);
    await client.from('alerts').delete().eq('user_id', userId);
    await client.from('push_tokens').delete().eq('user_id', userId);
    await client.from('price_reports').delete().eq('reporter_id', userId);
  }
}
