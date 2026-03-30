import '../../features/alerts/data/models/price_alert.dart';
import '../../features/itinerary/domain/entities/saved_itinerary.dart';

/// Abstract interface for cloud sync operations.
///
/// ## Reusability
/// Decouples the app from Supabase. Implementations can use
/// Firebase, custom REST API, or any backend. The app only
/// interacts with this interface via Riverpod providers.
///
/// ## Pattern
/// All sync methods are fire-and-forget: they return results
/// but failures never block local operations. The local-first
/// pattern means data is always saved locally before sync.
///
/// ## Car Platform
/// Car processes don't sync — only the main app process does.
/// This interface is not needed in the car module.
abstract class SyncRepository {
  /// Whether the sync backend is connected and authenticated.
  bool get isConnected;

  /// The authenticated user's ID (null if not connected).
  String? get authenticatedUserId;

  // ── Favorites ──
  Future<List<String>> syncFavorites(List<String> localIds);
  Future<void> deleteFavorite(String stationId);

  // ── Ignored Stations ──
  Future<List<String>> syncIgnoredStations(List<String> localIds);

  // ── Ratings ──
  Future<void> syncRating(String stationId, int rating, {bool shared = false});
  Future<void> deleteRating(String stationId);
  Future<Map<String, int>> fetchRatings();

  // ── Alerts ──
  Future<List<PriceAlert>> syncAlerts(List<PriceAlert> localAlerts);

  // ── Price History ──
  Future<List<Map<String, dynamic>>> fetchPriceHistory(String stationId, {int days = 30});

  // ── Itineraries ──
  Future<bool> saveItinerary(SavedItinerary itinerary);
  Future<List<SavedItinerary>> fetchItineraries();
  Future<bool> deleteItinerary(String id);

  // ── Data Management ──
  Future<Map<String, dynamic>> fetchAllUserData();
  Future<void> deleteAllUserData();
}
