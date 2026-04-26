import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/country/country_config.dart';
import '../../../core/country/country_provider.dart';
import '../../../core/services/service_providers.dart';
import '../../../core/services/service_result.dart';
import '../../../core/services/station_service.dart';
import '../../../core/storage/storage_providers.dart';
import '../../search/domain/entities/station.dart';
import 'favorites_provider.dart';

part 'favorite_stations_provider.g.dart';

/// Loads fuel station data for favorites and refreshes prices.
///
/// Returns fuel favorites as [List<Station>]. EV favorites are loaded
/// separately via the EV favorites provider (different entity format).
/// The UI merges both into a single list.
///
/// Split out of `favorites_provider.dart` in #727 — the file had grown
/// past 300 LOC; this notifier's per-country refresh logic is the
/// biggest chunk and stands on its own.
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
        } catch (e, st) {
          debugPrint('Skipping corrupt favorite $id: $e\n$st');
        }
      }
    }

    // Reference allIds to ensure rebuild on any favorite change.
    debugPrint(
        'FavoriteStations: ${stations.length} fuel / ${allIds.length - fuelIds.length} EV');

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
          } catch (e, st) {
            debugPrint('FavoriteStations: parse error for $id: $e\n$st');
          }
        }
      }

      final missingIds =
          fuelIds.where((id) => !stations.any((s) => s.id == id)).toList();

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
        final activeCountryCode = ref.read(activeCountryProvider).code;
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
            } catch (e, st) {
              debugPrint('FavoriteStations: fetch detail $id ($code): $e\n$st');
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
          } on Exception catch (e, st) {
            debugPrint('FavoriteStations: prices for ${entry.key} failed: $e\n$st');
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
          } catch (e, st) {
            debugPrint('FavoriteStations: re-persist ${s.id} failed: $e\n$st');
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
      } on Exception catch (e, st) {
        debugPrint('Favorites price refresh failed: $e\n$st');
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
