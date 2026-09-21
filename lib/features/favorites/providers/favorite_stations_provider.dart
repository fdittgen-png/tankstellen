// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/country/country_config.dart';
import '../../../core/country/country_provider.dart';
import '../../../core/services/service_providers.dart';
import '../../../core/services/service_result.dart';
import '../../../core/services/station_service.dart';
import '../../../core/storage/storage_providers.dart';
import '../../../core/domain/station.dart';
import 'favorites_provider.dart';
import '../../../core/logging/error_logger.dart';

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
          unawaited(errorLogger.log(ErrorLayer.providers, e, st, context: {'where': 'Skipping corrupt favorite $id'}));
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
            unawaited(errorLogger.log(ErrorLayer.providers, e, st, context: {'where': 'FavoriteStations: parse error for $id'}));
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
      // #4388 — DROP. Everything below reads `ref` and writes `state`, and
      // a favorites refresh has no value once the screen that asked for it
      // is gone.
      if (!ref.mounted) return;
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

        // #4388 — resolve every per-country service BEFORE the fetch loops
        // below start awaiting. `serviceFor` reaches into `ref` for a
        // non-active country, and from the second loop iteration onward
        // that read sits after an await. Resolving up front keeps the
        // loops ref-free, so the fetches COMPLETE (they still persist to
        // storage, which outlives this provider) even if the favorites
        // screen goes away mid-refresh; only the `state =` writes below
        // are dropped.
        final servicesByCountry = <String, StationService>{
          for (final code in idsByCountry.keys) code: serviceFor(code),
        };

        // Fetch missing details per-country.
        for (final entry in idsByCountry.entries) {
          final code = entry.key;
          final missingInCountry =
              entry.value.where(missingIds.contains).toList();
          if (missingInCountry.isEmpty) continue;
          final service = servicesByCountry[code]!;
          for (final id in missingInCountry) {
            try {
              final detail = await service.getStationDetail(id);
              final s = detail.data.station;
              stations.add(s);
              await storage.saveFavoriteStationData(id, s.toJson());
            } catch (e, st) {
              unawaited(errorLogger.log(ErrorLayer.providers, e, st, context: {'where': 'FavoriteStations: fetch detail $id ($code)'}));
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
          final service = servicesByCountry[entry.key]!;
          try {
            final result = await service.getPrices(ids);
            freshPrices.addAll(result.data);
            lastResult = result;
            successCountries++;
          } on Exception catch (e, st) {
            unawaited(errorLogger.log(ErrorLayer.providers, e, st, context: {'where': 'FavoriteStations: prices for ${entry.key} failed'}));
          }
        }

        final updated = stations.map((s) {
          final fresh = freshPrices[s.id];
          if (fresh == null) return s;
          // #2249 — merge the full fuel set so a refresh no longer drops
          // LPG / CNG / E98 / diesel-premium / E85 for fuel-rich countries.
          return s.copyWith(
            e5: fresh.e5 ?? s.e5,
            e10: fresh.e10 ?? s.e10,
            e98: fresh.e98 ?? s.e98,
            diesel: fresh.diesel ?? s.diesel,
            dieselPremium: fresh.dieselPremium ?? s.dieselPremium,
            e85: fresh.e85 ?? s.e85,
            lpg: fresh.lpg ?? s.lpg,
            cng: fresh.cng ?? s.cng,
            isOpen: fresh.isOpen,
          );
        }).toList();

        for (final s in updated) {
          try {
            await storage.saveFavoriteStationData(s.id, s.toJson());
          } catch (e, st) {
            unawaited(errorLogger.log(ErrorLayer.providers, e, st, context: {'where': 'FavoriteStations: re-persist ${s.id} failed'}));
          }
        }

        // Mark stale when every per-country fetch failed — this matches
        // the pre-#695 contract where a single failed getPrices produced
        // stale-cache state so the user knows prices may be outdated.
        final allFailed =
            attemptedCountries > 0 && successCountries == 0;
        // #4388 — the fetches above were allowed to finish; the result
        // write is not, because there is nobody left to render it.
        if (!ref.mounted) return;
        state = AsyncValue.data(ServiceResult(
          data: updated,
          source: lastResult?.source ?? ServiceSource.cache,
          fetchedAt: lastResult?.fetchedAt ?? DateTime.now(),
          isStale: allFailed ? true : (lastResult?.isStale ?? false),
          errors: lastResult?.errors ?? const [],
        ));
      } on Exception catch (e, st) {
        unawaited(errorLogger.log(ErrorLayer.providers, e, st, context: const {'where': 'Favorites price refresh failed'}));
        if (!ref.mounted) return;
        state = AsyncValue.data(ServiceResult(
          data: stations,
          source: ServiceSource.cache,
          fetchedAt: DateTime.now(),
          isStale: true,
        ));
      }
    } catch (e, st) {
      // #4388 — trace BEFORE the mounted guard. The guard stops the error
      // reaching a disposed `state =`, and without this line it would also
      // stop it reaching anyone at all: a swallowed disposed-Ref
      // `StateError` is exactly the silent no-op this issue is about.
      unawaited(errorLogger.log(ErrorLayer.providers, e, st,
          context: const {'where': 'FavoriteStations.loadAndRefresh'}));
      if (!ref.mounted) return;
      state = AsyncValue.error(e, st);
    }
  }
}
