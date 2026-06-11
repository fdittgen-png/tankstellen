// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../core/cache/cache_manager.dart';
import '../../../core/data/storage_repository.dart';
import '../../../core/services/diagnostics/data_access_recorder.dart';
import 'country_alert_strategy.dart';
import 'polled_alert_strategy.dart';
import '../../../core/background/provider_request_budget.dart';

/// Per-scan cache of [CountryAlertStrategy] instances, one per country (Epic
/// #2860, child #2863).
///
/// A background scan groups its alerts by derived country (`alert_country_
/// grouping.dart`) and then asks this resolver for the strategy that serves
/// each country. Polled countries get a [PolledAlertStrategy], bulk-dataset
/// countries a [BulkDatasetAlertStrategy] — the resolver branches on
/// `FuelServicePolicy.model` inside [CountryAlertStrategy.forCountry], so GB/FR
/// follow [BulkMigrationFlags] and AU (#804 stub) resolves to null.
///
/// Caching per country means a scan that fetches per-station prices AND runs a
/// radius search for the same country reuses one strategy — and so, for a bulk
/// country, one in-memory whole-country dataset (downloaded at most once per
/// scan, then local-filtered). A `null` result is cached too so a country with
/// no buildable strategy is resolved only once.
class CountryAlertStrategyResolver {
  CountryAlertStrategyResolver({
    required StorageRepository storage,
    required CacheStrategy cache,
    String? apiKey,
    DataAccessRecorder? recorder,
    ProviderRequestBudget? budget,
    PolledAlertStrategyDeps? polledDeps,
  })  : _storage = storage,
        _cache = cache,
        _apiKey = apiKey,
        _recorder = recorder,
        _budget = budget,
        _polledDeps = polledDeps;

  final StorageRepository _storage;
  final CacheStrategy _cache;
  final String? _apiKey;

  /// #2824 tracer + #2866 shared budget threaded into every strategy this
  /// resolver builds, so the whole BG scan shares one trace and one
  /// per-provider gate. Both null outside an instrumented / gated scan.
  final DataAccessRecorder? _recorder;
  final ProviderRequestBudget? _budget;
  final PolledAlertStrategyDeps? _polledDeps;

  final Map<String, CountryAlertStrategy?> _byCountry = {};

  /// The strategy serving [countryCode], built once per scan and cached, or
  /// null when the country has no buildable strategy (no entry, AU stub, an
  /// unbuildable polled service).
  CountryAlertStrategy? strategyFor(String countryCode) {
    if (_byCountry.containsKey(countryCode)) return _byCountry[countryCode];
    final strategy = CountryAlertStrategy.forCountry(
      countryCode,
      storage: _storage,
      cache: _cache,
      apiKey: _apiKey,
      recorder: _recorder,
      budget: _budget,
      polledDeps: _polledDeps,
    );
    _byCountry[countryCode] = strategy;
    return strategy;
  }
}
