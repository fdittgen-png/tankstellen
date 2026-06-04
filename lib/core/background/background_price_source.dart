// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../features/search/data/models/search_params.dart';
import '../../features/search/domain/entities/station.dart';
import '../cache/cache_manager.dart';
import '../constants/field_names.dart';
import '../data/storage_repository.dart';
import '../logging/error_logger.dart';
import '../services/country_service_registry.dart';
import '../services/dio_factory.dart';
import '../services/service_config.dart';
import '../services/station_service.dart';

/// The 11 polled / realtime providers a background scan may query directly,
/// reusing the per-country `StationServiceChain` within each provider's
/// `FuelServicePolicy.minInterval` (Epic #2860, child #2862).
///
/// Bulk-dataset countries (ES, IT, AR, DK + the flag-gated FR/GB bulk paths)
/// are deliberately **excluded** here — they need the download-once +
/// local-filter flow of child #2863, never a per-alert network hit. Until
/// then those countries simply are not scanned (no regression vs today, where
/// only DE was). AU is excluded as a throwing stub (#804).
const Set<String> kBackgroundPolledCountries = {
  'DE', 'AT', 'PT', 'GB', 'LU', 'SI', 'GR', 'RO', 'MX', 'KR', 'CL',
};

/// Builds the right country [StationService] (Riverpod-free, via
/// [CountryServiceRegistry.buildBackgroundService]) inside the WorkManager /
/// BGAppRefresh isolate and fetches current prices through it — replacing the
/// three hardcoded Tankerkönig instantiations (#2862).
///
/// This is the *which-service-fetches* seam, grouped per country so each
/// provider is hit at most once per scan. The price **evaluation** stays as
/// it is today (euro / e5-e10-diesel); making it country/currency-aware is
/// child #2864.
///
/// Construction is per-country and cheap, but the source caches the built
/// service per country code so a scan that fetches station prices AND runs a
/// radius search for the same country reuses one service (and so a test can
/// assert each provider is built exactly once).
class BackgroundPriceSource {
  BackgroundPriceSource({
    required StorageRepository storage,
    Duration connectTimeout = const Duration(seconds: 10),
    Duration receiveTimeout = const Duration(seconds: 15),
    @visibleForTesting StationService? Function(String code, {String? apiKey})?
        serviceBuilder,
  })  : _storage = storage,
        _connectTimeout = connectTimeout,
        _receiveTimeout = receiveTimeout,
        _cache = CacheManager(storage),
        _serviceBuilder = serviceBuilder;

  final StorageRepository _storage;
  final CacheStrategy _cache;
  final Duration _connectTimeout;
  final Duration _receiveTimeout;

  /// Test seam (#2862): a fake per-country service builder. Production leaves
  /// this null and goes through [CountryServiceRegistry.buildBackgroundService].
  /// Called at most once per country (the result is cached), so a test can
  /// assert each provider is built exactly once per scan.
  final StationService? Function(String code, {String? apiKey})? _serviceBuilder;

  /// Per-scan service cache so each country's provider is built at most once.
  final Map<String, StationService> _services = {};

  /// Whether [countryCode] is one of the polled providers this source serves.
  static bool isPolled(String countryCode) =>
      kBackgroundPolledCountries.contains(countryCode);

  /// Builds (once per scan) and returns the chained [StationService] for
  /// [countryCode], or null when the country is not a polled provider.
  ///
  /// [apiKey] is the user's key from the shared encrypted Hive box, threaded
  /// into the isolate. Only DE needs it on the Dio (sent as the `apikey`
  /// query param, since the isolate has no Dio interceptor); KR/CL read their
  /// key from [_storage] inside the registry factory.
  StationService? serviceFor(String countryCode, {String? apiKey}) {
    if (!isPolled(countryCode)) return null;
    final cached = _services[countryCode];
    if (cached != null) return cached;
    final built = _serviceBuilder != null
        ? _serviceBuilder(countryCode, apiKey: apiKey)
        : CountryServiceRegistry.buildBackgroundService(
            countryCode,
            storage: _storage,
            cache: _cache,
            tankerkoenigDio:
                countryCode == 'DE' ? _buildTankerkoenigDio(apiKey) : null,
          );
    if (built != null) _services[countryCode] = built;
    return built;
  }

  /// Tankerkönig Dio for the background isolate: rate-limited + conditional
  /// GET (via [DioFactory]) with the API key baked into the query parameters,
  /// since there is no Riverpod interceptor here.
  Dio _buildTankerkoenigDio(String? apiKey) {
    final dio = DioFactory.create(
      baseUrl: ServiceConfigs.tankerkoenig.baseUrl,
      connectTimeout: _connectTimeout,
      receiveTimeout: _receiveTimeout,
    );
    if (apiKey != null && apiKey.isNotEmpty) {
      dio.options.queryParameters = {'apikey': apiKey};
    }
    return dio;
  }

  /// Fetch current prices for [stationIds] in [countryCode], returning the
  /// Tankerkönig-shaped `id → {status, e5, e10, diesel, …}` map the existing
  /// downstream price-history + alert evaluation consume unchanged.
  ///
  /// Batches where the provider supports it (the country service's
  /// [StationService.getPrices] chunks internally — DE Tankerkönig batch is
  /// the template); a provider with no batch endpoint returns an empty map
  /// and per-station alerts for that country simply find no fresh price this
  /// scan (radius alerts still work via [searchStations]).
  ///
  /// Returns an empty map for an unpolled country, no station ids, or any
  /// fetch error (spooled, never thrown — this runs in an OS-spawned isolate).
  Future<Map<String, Map<String, dynamic>>> fetchPrices({
    required String countryCode,
    required Set<String> stationIds,
    String? apiKey,
  }) async {
    if (stationIds.isEmpty) return const {};
    final service = serviceFor(countryCode, apiKey: apiKey);
    if (service == null) return const {};
    try {
      final result = await service.getPrices(stationIds.toList());
      final out = <String, Map<String, dynamic>>{};
      for (final entry in result.data.entries) {
        out[entry.key] = _toTankerkoenigShape(entry.value);
      }
      return out;
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.other, e, st, context: {
        'where': 'BackgroundPriceSource.fetchPrices($countryCode)',
        'ids': stationIds.length,
      }));
      return const {};
    }
  }

  /// Fetch prices for a mixed-country [stationIds] set, grouping by derived
  /// country so each polled provider is queried **at most once** (#2862).
  ///
  /// Country is derived lazily from each id's prefix
  /// ([CountryServiceRegistry.countryForStationId]); a prefix-less id (a raw
  /// DE Tankerkönig UUID, an FR numeric id, …) falls back to
  /// [fallbackCountryCode] (the active country) so legacy favorites saved
  /// before the #753 prefix scheme are still refreshed. Ids whose country is
  /// not a polled provider (e.g. bulk-dataset ES/IT — child #2863) are
  /// silently skipped this scan.
  ///
  /// Returns one merged Tankerkönig-shaped map across all countries, keyed by
  /// the original (prefixed) station id.
  Future<Map<String, Map<String, dynamic>>> fetchPricesGrouped({
    required List<String> stationIds,
    String? fallbackCountryCode,
    String? apiKey,
  }) async {
    final byCountry = <String, Set<String>>{};
    for (final id in stationIds) {
      final code =
          CountryServiceRegistry.countryForStationId(id) ?? fallbackCountryCode;
      if (code == null || !isPolled(code)) continue;
      byCountry.putIfAbsent(code, () => <String>{}).add(id);
    }

    final merged = <String, Map<String, dynamic>>{};
    for (final entry in byCountry.entries) {
      final prices = await fetchPrices(
        countryCode: entry.key,
        stationIds: entry.value,
        apiKey: apiKey,
      );
      merged.addAll(prices);
    }
    return merged;
  }

  /// Run a radius search in [countryCode] via its provider — the registry-
  /// driven replacement for the hardcoded Tankerkönig search the radius-alert
  /// runner used. Returns the priced stations, or an empty list for an
  /// unpolled country / a fetch error.
  Future<List<Station>> searchStations({
    required String countryCode,
    required SearchParams params,
    String? apiKey,
  }) async {
    final service = serviceFor(countryCode, apiKey: apiKey);
    if (service == null) return const [];
    try {
      final result = await service.searchStations(params);
      return result.data;
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.other, e, st, context: {
        'where': 'BackgroundPriceSource.searchStations($countryCode)',
      }));
      return const [];
    }
  }

  /// Adapt a country-agnostic [StationPrices] back to the legacy
  /// Tankerkönig-shaped map the per-station / velocity runners read today.
  /// Carries every priced fuel so #2864 can widen the evaluation without
  /// re-touching this seam.
  static Map<String, dynamic> _toTankerkoenigShape(StationPrices prices) => {
        TankerkoenigFields.status:
            prices.isOpen ? TankerkoenigFields.statusOpen : 'closed',
        TankerkoenigFields.e5: prices.e5,
        TankerkoenigFields.e10: prices.e10,
        TankerkoenigFields.diesel: prices.diesel,
        'e98': prices.e98,
        'dieselPremium': prices.dieselPremium,
        'e85': prices.e85,
        'lpg': prices.lpg,
        'cng': prices.cng,
      };
}
