import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/storage/storage_providers.dart';
import '../../ev/domain/entities/charging_station.dart';
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
    // writes to EV storage (#552). Without this, the Favorites tab never sees
    // newly-added EV favorites.
    ref.watch(favoritesProvider);
    final favoriteIds = ref.watch(evFavoritesProvider);
    if (favoriteIds.isEmpty) return const [];

    final storage = ref.read(storageRepositoryProvider);
    final stations = <ChargingStation>[];

    for (final id in favoriteIds) {
      final data = storage.getEvFavoriteStationData(id);
      if (data != null) {
        try {
          stations.add(ChargingStation.fromJson(data));
        } catch (e) {
          debugPrint('EvFavoriteStations: parse error for $id: $e');
        }
      }
    }

    return stations;
  }
}
