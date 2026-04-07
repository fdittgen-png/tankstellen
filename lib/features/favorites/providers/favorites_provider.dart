import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/services/service_providers.dart';
import '../../../core/services/service_result.dart';
import '../../../core/storage/storage_providers.dart';
import '../../../core/sync/sync_helper.dart';
import '../../../core/sync/sync_service.dart';
import '../../search/domain/entities/station.dart';
import '../../search/providers/station_rating_provider.dart';

part 'favorites_provider.g.dart';

/// Manages the user's list of favorite station IDs.
///
/// ## Local-first pattern:
/// - **Writes**: Save to Hive immediately, then sync to Supabase asynchronously.
/// - **Reads**: Load from Hive on startup (instant), then merge with server data.
/// - **Deletes**: Remove locally + from server (exception to "sync never deletes" rule
///   because this is an explicit user action).
///
/// Uses `keepAlive: true` because favorites persist across the entire app lifecycle.
@Riverpod(keepAlive: true)
class Favorites extends _$Favorites {
  @override
  List<String> build() {
    final storage = ref.watch(storageRepositoryProvider);
    return storage.getFavoriteIds();
  }

  /// Add a station to favorites.
  ///
  /// Persists both the station ID and the full Station JSON permanently
  /// in Hive. The JSON never expires (unlike CacheManager entries) so
  /// the favorites screen always has data to display.
  Future<void> add(String stationId, {Station? stationData}) async {
    final storage = ref.read(storageRepositoryProvider);
    await storage.addFavorite(stationId);

    // Persist full station data permanently (survives cache eviction / app restart)
    if (stationData != null) {
      await storage.saveFavoriteStationData(stationId, stationData.toJson());
    }

    state = storage.getFavoriteIds();

    // Non-blocking server sync (local operation already complete)
    await SyncHelper.syncIfEnabled(ref, 'Favorites.add',
      () => SyncService.syncFavorites(state),
    );
  }

  /// Remove a station from favorites.
  ///
  /// This is the ONE exception to the "sync never deletes" rule:
  /// when the user explicitly removes a favorite, we delete from
  /// local storage, server, and all associated data (rating, history).
  Future<void> remove(String stationId) async {
    final storage = ref.read(storageRepositoryProvider);
    await storage.removeFavorite(stationId);
    await storage.removeFavoriteStationData(stationId);
    state = storage.getFavoriteIds();

    // Clean up associated data (rating + price history)
    try { ref.read(stationRatingsProvider.notifier).remove(stationId); } catch (e) { debugPrint('Cleanup: $e'); }
    try { await storage.clearPriceHistoryForStation(stationId); } catch (e) { debugPrint('Cleanup: $e'); }

    // Delete from server explicitly
    await SyncHelper.fireAndForget(ref, 'Favorites.remove',
      () => SyncService.deleteFavorite(stationId),
    );
  }

  /// Toggle favorite status. Pass [stationData] when adding from search results.
  Future<void> toggle(String stationId, {Station? stationData}) async {
    if (state.contains(stationId)) {
      await remove(stationId);
    } else {
      await add(stationId, stationData: stationData);
    }
  }
}

/// Whether a specific station is favorited. Rebuilds when favorites change.
@riverpod
bool isFavorite(Ref ref, String stationId) {
  final favorites = ref.watch(favoritesProvider);
  return favorites.contains(stationId);
}

/// Loads station data for favorites and refreshes prices.
///
/// ## Data flow (local-first):
/// 1. Load persisted Station objects from Hive (permanent, never expires)
/// 2. Check connectivity — if offline, return persisted data with `isStale: true`
/// 3. If online, refresh prices via StationService.getPrices()
/// 4. Merge fresh prices into stations, persist updated data back
/// 5. On API failure, serve persisted data with stale flag
@riverpod
class FavoriteStations extends _$FavoriteStations {
  @override
  AsyncValue<ServiceResult<List<Station>>> build() {
    return AsyncValue.data(ServiceResult(
      data: const [],
      source: ServiceSource.cache,
      fetchedAt: DateTime.now(),
    ));
  }

  Future<void> loadAndRefresh() async {
    final favoriteIds = ref.read(favoritesProvider);
    if (favoriteIds.isEmpty) {
      state = AsyncValue.data(ServiceResult(
        data: const [],
        source: ServiceSource.cache,
        fetchedAt: DateTime.now(),
      ));
      return;
    }

    state = const AsyncValue.loading();

    try {
      final storage = ref.read(storageRepositoryProvider);

      // Step 1: Load persisted station data from Hive (permanent, never expires)
      final stations = <Station>[];
      for (final id in favoriteIds) {
        final data = storage.getFavoriteStationData(id);
        if (data != null) {
          try {
            stations.add(Station.fromJson(data));
          } catch (e) {
            debugPrint('FavoriteStations: parse error for $id: $e');
          }
        } else {
          debugPrint('FavoriteStations: no persisted data for $id');
        }
      }

      // Step 1b: For IDs with no persisted data, try to fetch from API
      final missingIds = favoriteIds.where((id) => !stations.any((s) => s.id == id)).toList();

      debugPrint('FavoriteStations: loaded ${stations.length}/${favoriteIds.length} from storage'
          '${missingIds.isNotEmpty ? ', ${missingIds.length} missing' : ''}');

      // Step 2: Check connectivity
      final connectivity = await Connectivity().checkConnectivity();
      final isOffline = connectivity.contains(ConnectivityResult.none);

      if (isOffline) {
        state = AsyncValue.data(ServiceResult(
          data: stations,
          source: ServiceSource.cache,
          fetchedAt: DateTime.now(),
          isStale: true,
        ));
        return;
      }

      // Step 3: Online — fetch missing station details + refresh prices
      final stationService = ref.read(stationServiceProvider);
      try {
        // Fetch full station data for IDs that had no persisted data
        if (missingIds.isNotEmpty) {
          for (final id in missingIds) {
            try {
              final detail = await stationService.getStationDetail(id);
              final s = detail.data.station;
              stations.add(s);
              await storage.saveFavoriteStationData(id, s.toJson());
            } catch (e) {
              debugPrint('FavoriteStations: could not fetch detail for $id: $e');
            }
          }
        }

        final pricesResult = await stationService.getPrices(favoriteIds);

        // Step 4: Merge fresh prices into stations
        final updated = stations.map((s) {
          final fresh = pricesResult.data[s.id];
          if (fresh == null) return s;
          return s.copyWith(
            e5: fresh.e5 ?? s.e5,
            e10: fresh.e10 ?? s.e10,
            diesel: fresh.diesel ?? s.diesel,
            isOpen: fresh.isOpen,
          );
        }).toList();

        // Persist updated data back to Hive
        for (final s in updated) {
          await storage.saveFavoriteStationData(s.id, s.toJson());
        }

        state = AsyncValue.data(ServiceResult(
          data: updated,
          source: pricesResult.source,
          fetchedAt: pricesResult.fetchedAt,
          isStale: pricesResult.isStale,
          errors: pricesResult.errors,
        ));
      } on Exception catch (e) {
        // Step 5: Price API failed — serve persisted data with stale flag
        debugPrint('Favorites price refresh failed: $e');
        state = AsyncValue.data(ServiceResult(
          data: stations,
          source: ServiceSource.cache,
          fetchedAt: DateTime.now(),
          isStale: true,
        ));
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
