import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/cache/cache_manager.dart';
import '../../../core/services/service_providers.dart';
import '../../../core/services/service_result.dart';
import '../../../core/storage/hive_storage.dart';
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
    final storage = ref.watch(hiveStorageProvider);
    return storage.getFavoriteIds();
  }

  /// Add a station to favorites.
  ///
  /// If [stationData] is provided, the full station object is cached in
  /// [CacheManager] so the favorites screen can show details even offline.
  Future<void> add(String stationId, {Station? stationData}) async {
    final storage = ref.read(hiveStorageProvider);
    await storage.addFavorite(stationId);

    // Cache full station data for offline display on favorites screen
    if (stationData != null) {
      final cache = ref.read(cacheManagerProvider);
      await cache.put(
        CacheKey.stationData(stationId),
        stationData.toJson(),
        ttl: CacheTtl.stationData,
        source: ServiceSource.cache,
      );
    }

    state = storage.getFavoriteIds();

    // Non-blocking server sync (local operation already complete)
    await SyncHelper.syncIfEnabled(ref, 'Favorites.add',
      (userId) => SyncService.syncFavorites(state, userId),
    );
  }

  /// Remove a station from favorites.
  ///
  /// This is the ONE exception to the "sync never deletes" rule:
  /// when the user explicitly removes a favorite, we delete from
  /// local storage, server, and all associated data (rating, history).
  Future<void> remove(String stationId) async {
    final storage = ref.read(hiveStorageProvider);
    await storage.removeFavorite(stationId);
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

/// Loads cached station data for favorites and refreshes prices.
///
/// ## Data flow:
/// 1. Read cached Station objects from CacheManager (30-min TTL)
/// 2. Check connectivity — if offline, return cached data with `isStale: true`
/// 3. If online, batch-refresh prices via StationService.getPrices()
/// 4. Merge fresh prices into cached stations, update cache
/// 5. On API failure, fall back to cached data with stale flag
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
      final cache = ref.read(cacheManagerProvider);

      // Step 1: Load from local cache (instant, works offline)
      final stations = <Station>[];
      for (final id in favoriteIds) {
        final cached = cache.get(CacheKey.stationData(id));
        if (cached != null) {
          try {
            stations.add(Station.fromJson(cached.payload));
          } on FormatException catch (_) {}
        }
      }

      // Step 2: Check connectivity
      final connectivity = await Connectivity().checkConnectivity();
      final isOffline = connectivity.contains(ConnectivityResult.none);

      if (isOffline) {
        debugPrint('FavoriteStations: offline, serving ${stations.length} cached');
        state = AsyncValue.data(ServiceResult(
          data: stations,
          source: ServiceSource.cache,
          fetchedAt: DateTime.now(),
          isStale: true,
        ));
        return;
      }

      // Step 3: Online — refresh prices via batch API
      final stationService = ref.read(stationServiceProvider);
      try {
        final pricesResult = await stationService.getPrices(favoriteIds);

        // Step 4: Merge fresh prices into cached stations
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

        // Update cache with fresh data
        for (final s in updated) {
          await cache.put(
            CacheKey.stationData(s.id),
            s.toJson(),
            ttl: CacheTtl.stationData,
            source: ServiceSource.cache,
          );
        }

        state = AsyncValue.data(ServiceResult(
          data: updated,
          source: pricesResult.source,
          fetchedAt: pricesResult.fetchedAt,
          isStale: pricesResult.isStale,
          errors: pricesResult.errors,
        ));
      } on Exception catch (e) {
        // Step 5: API failed — serve cached data with stale flag
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
