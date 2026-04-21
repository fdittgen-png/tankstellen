import '../../sync/alerts_sync.dart';
import '../../sync/price_history_sync.dart';
import '../../sync/ratings_sync.dart';
import '../../sync/supabase_client.dart';
import '../../sync/sync_service.dart';
import '../sync_repository.dart';

import '../../../features/alerts/data/models/price_alert.dart';
import '../../../features/itinerary/domain/entities/saved_itinerary.dart';

/// Supabase implementation of [SyncRepository].
///
/// Thin adapter that delegates every operation to [SyncService] static methods.
/// This layer exists solely to satisfy the abstract [SyncRepository] interface
/// so the backend can be swapped without changing provider or screen code.
///
/// All Supabase query logic lives in [SyncService] — the single source of truth.
class SupabaseSyncRepository implements SyncRepository {
  @override
  bool get isConnected => TankSyncClient.isConnected;

  @override
  String? get authenticatedUserId =>
      TankSyncClient.client?.auth.currentUser?.id;

  // ── Favorites ──

  @override
  Future<List<String>> syncFavorites(List<String> localIds) =>
      SyncService.syncFavorites(localIds);

  @override
  Future<void> deleteFavorite(String stationId) =>
      SyncService.deleteFavorite(stationId);

  // ── Ignored Stations ──

  @override
  Future<List<String>> syncIgnoredStations(List<String> localIds) =>
      SyncService.syncIgnoredStations(localIds);

  // ── Ratings ──

  @override
  Future<void> syncRating(String stationId, int rating,
          {bool shared = false}) =>
      RatingsSync.upsert(stationId, rating, shared: shared);

  @override
  Future<void> deleteRating(String stationId) =>
      RatingsSync.delete(stationId);

  @override
  Future<Map<String, int>> fetchRatings() => RatingsSync.fetchAll();

  // ── Alerts ──

  @override
  Future<List<PriceAlert>> syncAlerts(List<PriceAlert> localAlerts) =>
      AlertsSync.merge(localAlerts);

  // ── Price History ──

  @override
  Future<List<Map<String, dynamic>>> fetchPriceHistory(String stationId,
          {int days = 30}) =>
      PriceHistorySync.fetch(stationId, days: days);

  // ── Itineraries ──

  @override
  Future<bool> saveItinerary(SavedItinerary itinerary) =>
      SyncService.saveItinerary(itinerary);

  @override
  Future<List<SavedItinerary>> fetchItineraries() =>
      SyncService.fetchItineraries();

  @override
  Future<bool> deleteItinerary(String id) => SyncService.deleteItinerary(id);

  // ── Data Management ──

  @override
  Future<Map<String, dynamic>> fetchAllUserData() =>
      SyncService.fetchAllUserData();

  @override
  Future<void> deleteAllUserData() => SyncService.deleteAllUserData();
}
