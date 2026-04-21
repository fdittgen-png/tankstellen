import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/storage/storage_providers.dart';
import '../../../core/sync/ratings_sync.dart';
import '../../../core/sync/sync_helper.dart';
import '../../profile/providers/profile_provider.dart';

part 'station_rating_provider.g.dart';

/// Manages station ratings (1-5 stars) with three privacy levels:
///
/// - **local**: Saved only on this device (no sync)
/// - **private**: Synced with user's Supabase database (only visible to user)
/// - **shared**: Synced and visible to all users of the database
///
/// The rating mode is configured in the user profile (`ratingMode` field).
/// When mode changes, existing ratings are not retroactively synced/unsynced.
@Riverpod(keepAlive: true)
class StationRatings extends _$StationRatings {
  @override
  Map<String, int> build() {
    final storage = ref.watch(storageRepositoryProvider);
    return storage.getRatings();
  }

  /// Rate a station (1-5 stars). Syncs based on profile rating mode.
  Future<void> rate(String stationId, int rating) async {
    final clamped = rating.clamp(1, 5);
    final storage = ref.read(storageRepositoryProvider);
    await storage.setRating(stationId, clamped);
    state = storage.getRatings();

    // Only sync if rating mode is not 'local'
    final profile = ref.read(activeProfileProvider);
    final mode = profile?.ratingMode ?? 'local';
    if (mode != 'local') {
      final isShared = mode == 'shared';
      await SyncHelper.fireAndForget(ref, 'Ratings.rate',
        () => RatingsSync.upsert(stationId, clamped, shared: isShared),
      );
    }
  }

  /// Remove a rating. Called when station is removed from favorites.
  Future<void> remove(String stationId) async {
    final storage = ref.read(storageRepositoryProvider);
    await storage.removeRating(stationId);
    state = storage.getRatings();

    // Always delete from server when removing (cleanup)
    await SyncHelper.fireAndForget(ref, 'Ratings.remove',
      () => RatingsSync.delete(stationId),
    );
  }
}

/// Get the rating for a specific station (null if not rated).
@riverpod
int? stationRating(Ref ref, String stationId) {
  final ratings = ref.watch(stationRatingsProvider);
  return ratings[stationId];
}
