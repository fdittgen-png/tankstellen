import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/country/country_config.dart';
import '../../../core/country/country_provider.dart';
import '../../../core/services/service_providers.dart';
import '../../../core/services/service_result.dart';
import '../../../core/services/station_service.dart';
import '../../../core/storage/storage_providers.dart';
import '../../../core/sync/sync_helper.dart';
import '../../../core/sync/sync_service.dart';
import '../../search/domain/entities/charging_station.dart' as search_ev;
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
    final isEv = _isEvId(stationId);
    debugPrint('[Favorites.add] id=$stationId isEv=$isEv rawJsonKeys=${rawJson?.keys.toList()}');

    if (isEv) {
      // Persist JSON BEFORE the id so a crash between the two writes
      // cannot leave an id without data (#690). The id is what drives
      // the reactive rebuild chain; writing it last means every observer
      // sees a consistent state.
      final json = rawJson ?? stationData?.toJson();
      if (json != null) {
        await storage.saveEvFavoriteStationData(stationId, json);
        // Verify the write actually landed. On encrypted Hive boxes
        // with deeply-nested freezed types, put() can silently drop
        // unsupported payloads. If the readback fails, bail out before
        // writing the id so we don't leave an orphan.
        final verify = storage.getEvFavoriteStationData(stationId);
        if (verify == null) {
          debugPrint(
            '[Favorites.add] CRITICAL: JSON save succeeded but readback '
            'returned null for $stationId. Hive may have dropped the '
            'payload. Skipping id write to avoid orphan.',
          );
          return;
        }
        debugPrint(
          '[Favorites.add] JSON verified for $stationId '
          '(${verify.keys.length} keys)',
        );
      } else {
        debugPrint('[Favorites.add] WARNING: EV favorite added WITHOUT station JSON');
      }
      await storage.addEvFavorite(stationId);
      debugPrint('[Favorites.add] EV storage now has ids=${storage.getEvFavoriteIds()}');
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
    debugPrint('[Favorites.add] state after reload=$state');
  }

  /// Add an EV charging station to favorites (explicit ev/ entity).
  Future<void> addEv(String stationId, {search_ev.ChargingStation? stationData}) async {
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
  Future<void> toggleEv(String stationId, {search_ev.ChargingStation? stationData}) async {
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
        } catch (e) {
          debugPrint('Skipping corrupt favorite $id: $e');
        }
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

      // #695 — favorites can span countries. Refresh each country's
      // stations with its OWN service, so a favorite from Italy keeps
      // refreshing even when the active profile is Germany. The active
      // country's service is reused (not re-resolved) so test overrides
      // on stationServiceProvider still drive the right instance.
      try {
        final activeCountryCode =
            ref.read(activeCountryProvider).code;
        final activeService = ref.read(stationServiceProvider);
        StationService serviceFor(String code) =>
            (code.isEmpty || code == activeCountryCode)
                ? activeService
                : stationServiceForCountry(ref, code);

        String countryOf(String id, {double? lat, double? lng}) {
          final c = (lat != null && lng != null)
              ? Countries.countryForStation(id: id, lat: lat, lng: lng)
              : Countries.countryForStationId(id);
          return c?.code ?? '';
        }

        final Map<String, List<String>> idsByCountry = {};
        final Map<String, String> idToCountry = {};
        for (final s in stations) {
          final code = countryOf(s.id, lat: s.lat, lng: s.lng);
          idToCountry[s.id] = code;
          idsByCountry.putIfAbsent(code, () => []).add(s.id);
        }
        for (final id in missingIds) {
          final code = countryOf(id);
          idToCountry[id] = code;
          idsByCountry.putIfAbsent(code, () => []).add(id);
        }

        // Fetch missing details per-country.
        for (final entry in idsByCountry.entries) {
          final code = entry.key;
          final missingInCountry =
              entry.value.where(missingIds.contains).toList();
          if (missingInCountry.isEmpty) continue;
          final service = serviceFor(code);
          for (final id in missingInCountry) {
            try {
              final detail = await service.getStationDetail(id);
              final s = detail.data.station;
              stations.add(s);
              await storage.saveFavoriteStationData(id, s.toJson());
            } catch (e) {
              debugPrint('FavoriteStations: fetch detail $id ($code): $e');
            }
          }
        }

        // Fetch fresh prices per-country, merge results.
        final freshPrices = <String, StationPrices>{};
        ServiceResult<Map<String, StationPrices>>? lastResult;
        var attemptedCountries = 0;
        var successCountries = 0;
        for (final entry in idsByCountry.entries) {
          final ids = entry.value;
          if (ids.isEmpty) continue;
          attemptedCountries++;
          final service = serviceFor(entry.key);
          try {
            final result = await service.getPrices(ids);
            freshPrices.addAll(result.data);
            lastResult = result;
            successCountries++;
          } on Exception catch (e) {
            debugPrint('FavoriteStations: prices for ${entry.key} failed: $e');
          }
        }

        final updated = stations.map((s) {
          final fresh = freshPrices[s.id];
          if (fresh == null) return s;
          return s.copyWith(
            e5: fresh.e5 ?? s.e5,
            e10: fresh.e10 ?? s.e10,
            diesel: fresh.diesel ?? s.diesel,
            isOpen: fresh.isOpen,
          );
        }).toList();

        for (final s in updated) {
          try {
            await storage.saveFavoriteStationData(s.id, s.toJson());
          } catch (e) {
            debugPrint('FavoriteStations: re-persist ${s.id} failed: $e');
          }
        }

        // Mark stale when every per-country fetch failed — this matches
        // the pre-#695 contract where a single failed getPrices produced
        // stale-cache state so the user knows prices may be outdated.
        final allFailed =
            attemptedCountries > 0 && successCountries == 0;
        state = AsyncValue.data(ServiceResult(
          data: updated,
          source: lastResult?.source ?? ServiceSource.cache,
          fetchedAt: lastResult?.fetchedAt ?? DateTime.now(),
          isStale: allFailed ? true : (lastResult?.isStale ?? false),
          errors: lastResult?.errors ?? const [],
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

