import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/services/service_providers.dart';
import '../../../core/services/service_result.dart';
import '../../../core/storage/storage_providers.dart';
import '../../../core/sync/sync_helper.dart';
import '../../../core/sync/sync_service.dart';
import '../../ev/domain/entities/charging_station.dart' as ev;
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
    // Merge fuel + EV favorite IDs into a single unified list.
    return [...storage.getFavoriteIds(), ...storage.getEvFavoriteIds()];
  }

  /// Reload state from storage (call after any mutation).
  void _reload() {
    final storage = ref.read(storageRepositoryProvider);
    state = [...storage.getFavoriteIds(), ...storage.getEvFavoriteIds()];
  }

  /// Whether a station ID belongs to an EV charging station.
  ///
  /// OpenChargeMap IDs are prefixed with `ocm-` by EVChargingService.
  static bool _isEvId(String id) => id.startsWith('ocm-');

  /// Add a station to favorites. Detects EV stations by ID prefix and
  /// routes to the correct storage automatically.
  ///
  /// Pass [stationData] for fuel stations or [rawJson] for any station
  /// type (used by the EV detail screen which has a search/ ChargingStation).
  Future<void> add(String stationId, {Station? stationData, Map<String, dynamic>? rawJson}) async {
    final storage = ref.read(storageRepositoryProvider);

    if (_isEvId(stationId)) {
      await storage.addEvFavorite(stationId);
      final json = rawJson ?? stationData?.toJson();
      if (json != null) {
        await storage.saveEvFavoriteStationData(stationId, json);
      }
    } else {
      await storage.addFavorite(stationId);
      final json = rawJson ?? stationData?.toJson();
      if (json != null) {
        await storage.saveFavoriteStationData(stationId, json);
      }
      await SyncHelper.syncIfEnabled(ref, 'Favorites.add',
        () => SyncService.syncFavorites(storage.getFavoriteIds()),
      );
    }

    _reload();
  }

  /// Add an EV charging station to favorites (explicit ev/ entity).
  Future<void> addEv(String stationId, {ev.ChargingStation? stationData}) async {
    final storage = ref.read(storageRepositoryProvider);
    await storage.addEvFavorite(stationId);

    if (stationData != null) {
      await storage.saveEvFavoriteStationData(stationId, stationData.toJson());
    }

    _reload();
  }

  /// Remove a station from favorites (checks both fuel and EV storage).
  Future<void> remove(String stationId) async {
    final storage = ref.read(storageRepositoryProvider);

    // Try fuel storage
    if (storage.isFavorite(stationId)) {
      await storage.removeFavorite(stationId);
      await storage.removeFavoriteStationData(stationId);

      try {
        await ref.read(stationRatingsProvider.notifier).remove(stationId);
      } catch (e) {
        debugPrint('Cleanup: $e');
      }
      try {
        await storage.clearPriceHistoryForStation(stationId);
      } catch (e) {
        debugPrint('Cleanup: $e');
      }

      await SyncHelper.fireAndForget(ref, 'Favorites.remove',
        () => SyncService.deleteFavorite(stationId),
      );
    }

    // Try EV storage
    if (storage.isEvFavorite(stationId)) {
      await storage.removeEvFavorite(stationId);
      await storage.removeEvFavoriteStationData(stationId);
    }

    _reload();
  }

  /// Toggle a station's favorite status. EV stations (ocm- prefix) are
  /// automatically routed to EV storage.
  ///
  /// Pass [stationData] for fuel stations or [rawJson] for any type.
  Future<void> toggle(String stationId, {Station? stationData, Map<String, dynamic>? rawJson}) async {
    if (state.contains(stationId)) {
      await remove(stationId);
    } else {
      await add(stationId, stationData: stationData, rawJson: rawJson);
    }
  }

  /// Toggle an EV station's favorite status.
  Future<void> toggleEv(String stationId, {ev.ChargingStation? stationData}) async {
    if (state.contains(stationId)) {
      await remove(stationId);
    } else {
      await addEv(stationId, stationData: stationData);
    }
  }
}

/// Whether a specific station is favorited (checks both fuel and EV).
@riverpod
bool isFavorite(Ref ref, String stationId) {
  final favorites = ref.watch(favoritesProvider);
  return favorites.contains(stationId);
}

/// Whether a specific EV station is favorited (backward compatibility alias).
@riverpod
bool isEvFavorite(Ref ref, String stationId) {
  return ref.watch(isFavoriteProvider(stationId));
}

/// Loads fuel station data for favorites and refreshes prices.
///
/// Returns fuel favorites as [List<Station>]. EV favorites are loaded
/// separately via [evFavoriteStationsProvider] (different entity format).
/// The UI merges both into a single list.
@riverpod
class FavoriteStations extends _$FavoriteStations {
  @override
  AsyncValue<ServiceResult<List<Station>>> build() {
    final allIds = ref.watch(favoritesProvider);
    final storage = ref.read(storageRepositoryProvider);
    final fuelIds = storage.getFavoriteIds();

    if (fuelIds.isEmpty) {
      return AsyncValue.data(ServiceResult(
        data: const [],
        source: ServiceSource.cache,
        fetchedAt: DateTime.now(),
      ));
    }

    final stations = <Station>[];
    for (final id in fuelIds) {
      final data = storage.getFavoriteStationData(id);
      if (data != null) {
        try {
          stations.add(Station.fromJson(data));
        } catch (_) {}
      }
    }

    // Reference allIds to ensure rebuild on any favorite change.
    debugPrint('FavoriteStations: ${stations.length} fuel / ${allIds.length - fuelIds.length} EV');

    return AsyncValue.data(ServiceResult(
      data: stations,
      source: ServiceSource.cache,
      fetchedAt: DateTime.now(),
      isStale: true,
    ));
  }

  Future<void> loadAndRefresh() async {
    final storage = ref.read(storageRepositoryProvider);
    final fuelIds = storage.getFavoriteIds();

    if (fuelIds.isEmpty) {
      state = AsyncValue.data(ServiceResult(
        data: const [],
        source: ServiceSource.cache,
        fetchedAt: DateTime.now(),
      ));
      return;
    }

    try {
      final stations = <Station>[];
      for (final id in fuelIds) {
        final data = storage.getFavoriteStationData(id);
        if (data != null) {
          try {
            stations.add(Station.fromJson(data));
          } catch (e) {
            debugPrint('FavoriteStations: parse error for $id: $e');
          }
        }
      }

      final missingIds = fuelIds.where((id) => !stations.any((s) => s.id == id)).toList();

      if (stations.isNotEmpty) {
        state = AsyncValue.data(ServiceResult(
          data: List.from(stations),
          source: ServiceSource.cache,
          fetchedAt: DateTime.now(),
          isStale: true,
        ));
      }

      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity.contains(ConnectivityResult.none)) {
        state = AsyncValue.data(ServiceResult(
          data: stations,
          source: ServiceSource.cache,
          fetchedAt: DateTime.now(),
          isStale: true,
        ));
        return;
      }

      final stationService = ref.read(stationServiceProvider);
      try {
        if (missingIds.isNotEmpty) {
          for (final id in missingIds) {
            try {
              final detail = await stationService.getStationDetail(id);
              final s = detail.data.station;
              stations.add(s);
              await storage.saveFavoriteStationData(id, s.toJson());
            } catch (e) {
              debugPrint('FavoriteStations: fetch detail $id: $e');
            }
          }
        }

        final pricesResult = await stationService.getPrices(fuelIds);

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

