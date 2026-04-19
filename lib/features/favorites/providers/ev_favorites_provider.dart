import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/storage/storage_providers.dart';
import '../../search/domain/entities/charging_station.dart';
import 'favorites_provider.dart';

part 'ev_favorites_provider.g.dart';

/// Manages the user's list of favorite EV charging station IDs.
///
/// Mirrors [Favorites] but for [ChargingStation] entities.
@Riverpod(keepAlive: true)
class EvFavorites extends _$EvFavorites {
  @override
  List<String> build() {
    final storage = ref.watch(storageRepositoryProvider);
    return storage.getEvFavoriteIds();
  }

  Future<void> add(String stationId, {ChargingStation? stationData}) async {
    final storage = ref.read(storageRepositoryProvider);
    await storage.addEvFavorite(stationId);

    if (stationData != null) {
      await storage.saveEvFavoriteStationData(
          stationId, stationData.toJson());
    }

    state = storage.getEvFavoriteIds();
  }

  Future<void> remove(String stationId) async {
    final storage = ref.read(storageRepositoryProvider);
    await storage.removeEvFavorite(stationId);
    await storage.removeEvFavoriteStationData(stationId);
    state = storage.getEvFavoriteIds();
  }

  Future<void> toggle(String stationId, {ChargingStation? stationData}) async {
    if (state.contains(stationId)) {
      await remove(stationId);
    } else {
      await add(stationId, stationData: stationData);
    }
  }
}

/// Whether a specific EV station is favorited.
@riverpod
bool isEvFavorite(Ref ref, String stationId) {
  final favorites = ref.watch(evFavoritesProvider);
  return favorites.contains(stationId);
}

/// Loads persisted EV station data for favorites.
@riverpod
class EvFavoriteStations extends _$EvFavoriteStations {
  @override
  List<ChargingStation> build() {
    // Watch the unified provider so we rebuild when favoritesProvider.toggleEv()
    // writes to EV storage (#552). The evFavoritesProvider is keepAlive and
    // never re-reads storage after its initial build, so we read EV IDs
    // directly from storage here to get fresh data after every mutation.
    ref.watch(favoritesProvider);
    final storage = ref.read(storageRepositoryProvider);
    final favoriteIds = storage.getEvFavoriteIds();
    debugPrint('[EvFavoriteStations.build] favoriteIds=$favoriteIds');
    if (favoriteIds.isEmpty) return const [];

    final stations = <ChargingStation>[];
    final orphaned = <String>[];

    for (final id in favoriteIds) {
      final data = storage.getEvFavoriteStationData(id);
      debugPrint('[EvFavoriteStations.build] id=$id dataKeys=${data?.keys.toList()}');
      if (data != null) {
        try {
          stations.add(ChargingStation.fromJson(data));
          continue;
        } catch (e) {
          debugPrint('[EvFavoriteStations.build] fromJson failed for $id: $e — falling back');
        }
        // Fallback: manually construct from JSON fields that may use either
        // lat/lng (search/ format) or latitude/longitude (ev/ format).
        try {
          stations.add(ChargingStation(
            id: data['id']?.toString() ?? id,
            name: data['name']?.toString() ?? '',
            operator: data['operator']?.toString() ?? '',
            lat: (data['lat'] ?? data['latitude'] as num?)?.toDouble() ?? 0,
            lng: (data['lng'] ?? data['longitude'] as num?)?.toDouble() ?? 0,
            address: data['address']?.toString() ?? '',
            connectors: const [],
          ));
        } catch (e) {
          debugPrint('[EvFavoriteStations.build] fallback parse failed for $id: $e');
          orphaned.add(id);
        }
      } else {
        debugPrint('[EvFavoriteStations.build] MISSING DATA for id=$id');
        orphaned.add(id);
      }
    }

    if (orphaned.isNotEmpty) {
      debugPrint('[EvFavoriteStations.build] ${orphaned.length} orphan id(s) skipped: $orphaned');
    }
    debugPrint('[EvFavoriteStations.build] returning ${stations.length} stations');
    return stations;
  }
}
