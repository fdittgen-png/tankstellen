import '../../sync/alerts_sync.dart';
import '../../sync/favorites_sync.dart';
import '../../sync/ignored_stations_sync.dart';
import '../../sync/itineraries_sync.dart';
import '../../sync/price_history_sync.dart';
import '../../sync/ratings_sync.dart';
import '../../sync/supabase_client.dart';
import '../../sync/user_data_sync.dart';
import '../sync_repository.dart';

import '../../../features/alerts/data/models/price_alert.dart';
import '../../../features/itinerary/domain/entities/saved_itinerary.dart';

/// Supabase implementation of [SyncRepository].
///
/// Thin adapter that delegates every operation to one of the
/// per-concern sync classes in `core/sync/*_sync.dart`. This layer
/// exists solely to satisfy the abstract [SyncRepository] interface
/// so the backend can be swapped without changing provider or screen
/// code — all Supabase query logic lives in the individual sync
/// classes, each owning a single table / concern (#727 — retired
/// the former `SyncService` god-class).
class SupabaseSyncRepository implements SyncRepository {
  @override
  bool get isConnected => TankSyncClient.isConnected;

  @override
  String? get authenticatedUserId =>
      TankSyncClient.client?.auth.currentUser?.id;

  // ── Favorites ──

  @override
  Future<List<String>> syncFavorites(List<String> localIds) =>
      FavoritesSync.merge(localIds);

  @override
  Future<void> deleteFavorite(String stationId) =>
      FavoritesSync.delete(stationId);

  // ── Ignored Stations ──

  @override
  Future<List<String>> syncIgnoredStations(List<String> localIds) =>
      IgnoredStationsSync.merge(localIds);

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
      ItinerariesSync.save(itinerary);

  @override
  Future<List<SavedItinerary>> fetchItineraries() =>
      ItinerariesSync.fetchAll();

  @override
  Future<bool> deleteItinerary(String id) => ItinerariesSync.delete(id);

  // ── Data Management ──

  @override
  Future<Map<String, dynamic>> fetchAllUserData() =>
      UserDataSync.fetchAll();

  @override
  Future<void> deleteAllUserData() => UserDataSync.deleteAll();
}
