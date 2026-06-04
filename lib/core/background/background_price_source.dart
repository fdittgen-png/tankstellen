// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../features/search/data/models/search_params.dart';
import '../../features/search/domain/entities/station.dart';
import '../cache/cache_manager.dart';
import '../data/storage_repository.dart';
import '../services/country_service_registry.dart';
import '../services/station_service.dart';
import 'country_alert_strategy.dart';
import 'polled_alert_strategy.dart';

// `kBackgroundPolledCountries` now lives in `polled_alert_strategy.dart` (the
// per-country polled specialization, #2863). Re-exported here so existing
// imports (`background_price_source.dart`) keep compiling.
export 'polled_alert_strategy.dart' show kBackgroundPolledCountries;

/// Multi-country price-fetch orchestrator for a background scan, grouping a
/// mixed-country station-id set by derived country so each polled provider is
/// queried **at most once per scan** (Epic #2860, child #2862).
///
/// Since #2863 the per-country work is delegated to a [PolledAlertStrategy] —
/// the [SourceModel.polledApi] specialization of [CountryAlertStrategy] — built
/// once per country and cached, so a scan that fetches station prices AND runs
/// a radius search for the same country reuses one strategy (and one provider
/// service). Bulk-dataset countries (ES/IT/AR/DK + flag-gated FR/GB) are NOT
/// handled here; they flow through [BulkDatasetAlertStrategy], resolved by the
/// scan coordinator via [CountryAlertStrategy.forCountry]. This source remains
/// the polled-only seam the velocity/per-station price refresh + nearest-widget
/// search use.
///
/// The price **evaluation** stays as it is today (euro / e5-e10-diesel); making
/// it country/currency/fuel-set aware is child #2864.
class BackgroundPriceSource {
  BackgroundPriceSource({
    required StorageRepository storage,
    Duration connectTimeout = const Duration(seconds: 10),
    Duration receiveTimeout = const Duration(seconds: 15),
    @visibleForTesting StationService? Function(String code, {String? apiKey})?
        serviceBuilder,
  })  : _storage = storage,
        _cache = CacheManager(storage),
        _deps = PolledAlertStrategyDeps(
          connectTimeout: connectTimeout,
          receiveTimeout: receiveTimeout,
          serviceBuilder: serviceBuilder,
        );

  final StorageRepository _storage;
  final CacheStrategy _cache;
  final PolledAlertStrategyDeps _deps;

  /// Per-scan strategy cache so each country's polled provider is built at most
  /// once. Keyed by country code; a `null` value records a country we already
  /// determined has no buildable polled strategy this scan.
  final Map<String, PolledAlertStrategy?> _strategies = {};

  /// Whether [countryCode] is one of the polled providers this source serves.
  static bool isPolled(String countryCode) =>
      PolledAlertStrategy.isPolled(countryCode);

  /// Build (once per scan) and return the [PolledAlertStrategy] for
  /// [countryCode], or null when the country is not a polled provider / its
  /// service cannot be built.
  PolledAlertStrategy? _strategyFor(String countryCode, {String? apiKey}) {
    if (_strategies.containsKey(countryCode)) return _strategies[countryCode];
    final strategy = PolledAlertStrategy.forCountry(
      countryCode,
      storage: _storage,
      cache: _cache,
      apiKey: apiKey,
      deps: _deps,
    );
    _strategies[countryCode] = strategy;
    return strategy;
  }

  /// Builds (once per scan) and returns the chained [StationService] for
  /// [countryCode], or null when the country is not a polled provider.
  ///
  /// Kept for the nearest-widget search (#609 / #2862), which needs a raw
  /// [StationService] handle rather than the strategy facade. [apiKey] is the
  /// user's key threaded into the isolate.
  StationService? serviceFor(String countryCode, {String? apiKey}) =>
      _strategyFor(countryCode, apiKey: apiKey)?.service;

  /// Fetch current prices for [stationIds] in [countryCode], returning the
  /// Tankerkönig-shaped `id → {status, e5, e10, diesel, …}` map the existing
  /// downstream price-history + alert evaluation consume unchanged.
  ///
  /// Delegates to the country's [PolledAlertStrategy] (which chunks to the
  /// provider's batch size internally). Returns an empty map for an unpolled
  /// country, no station ids, or any fetch error (spooled, never thrown — this
  /// runs in an OS-spawned isolate).
  Future<Map<String, Map<String, dynamic>>> fetchPrices({
    required String countryCode,
    required Set<String> stationIds,
    String? apiKey,
  }) async {
    if (stationIds.isEmpty) return const {};
    final strategy = _strategyFor(countryCode, apiKey: apiKey);
    if (strategy == null) return const {};
    return strategy.fetchPrices(stationIds);
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
  /// silently skipped here (the scan coordinator scans them via
  /// [BulkDatasetAlertStrategy]).
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

  /// Run a radius search in [countryCode] via its polled provider — the
  /// registry-driven replacement for the hardcoded Tankerkönig search the
  /// radius-alert runner used. Returns the priced stations, or an empty list
  /// for an unpolled country / a fetch error.
  Future<List<Station>> searchStations({
    required String countryCode,
    required SearchParams params,
    String? apiKey,
  }) async {
    final strategy = _strategyFor(countryCode, apiKey: apiKey);
    if (strategy == null) return const [];
    return strategy.searchArea(params);
  }
}
