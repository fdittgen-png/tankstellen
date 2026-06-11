// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/domain/search_params.dart';
import '../../../core/domain/station.dart';
import '../../../core/cache/cache_manager.dart';
import '../../../core/data/storage_repository.dart';
import '../../../core/logging/error_logger.dart';
import '../../../core/services/country_service_registry.dart';
import '../../../core/services/diagnostics/data_access_recorder.dart';
import '../../../core/services/dio_factory.dart';
import '../../../core/services/fuel_service_policy.dart';
import '../../../core/services/service_config.dart';
import '../../../core/services/station_service.dart';
import 'background_price_shape.dart';
import 'country_alert_strategy.dart';
import '../../../core/background/provider_request_budget.dart';

/// The 11 polled / realtime providers a background scan may query directly,
/// reusing the per-country `StationServiceChain` within each provider's
/// `FuelServicePolicy.minInterval` (Epic #2860, children #2862 / #2863).
///
/// Bulk-dataset countries (ES, IT, AR, DK + the flag-gated FR/GB bulk paths)
/// are served by [BulkDatasetAlertStrategy] instead — they download a
/// whole-country dataset once and local-filter every alert, never a per-alert
/// network hit. AU is excluded entirely (throwing stub #804).
const Set<String> kBackgroundPolledCountries = {
  'DE', 'AT', 'PT', 'GB', 'LU', 'SI', 'GR', 'RO', 'MX', 'KR', 'CL',
};

/// Resolved dependencies + test seams for the polled strategy / source, kept
/// in one record so the [BackgroundPriceSource] orchestrator and an individual
/// [PolledAlertStrategy] thread the same knobs without a wide constructor.
///
/// [serviceBuilder] is the #2862 test seam: a fake per-country service builder.
/// Production leaves it null and goes through
/// [CountryServiceRegistry.buildBackgroundService].
///
/// [recorder] is the #2824 data-access tracer, threaded through the BG isolate
/// by #2866 so background traffic is counted (it was previously null in the
/// isolate — only the foreground saw it). [budget] is the #2866 shared
/// per-provider request budget the BG scan consults before firing and the
/// chain stamps on a hit.
class PolledAlertStrategyDeps {
  const PolledAlertStrategyDeps({
    this.connectTimeout = const Duration(seconds: 10),
    this.receiveTimeout = const Duration(seconds: 15),
    this.serviceBuilder,
    this.recorder,
    this.budget,
  });

  final Duration connectTimeout;
  final Duration receiveTimeout;

  /// #2824 data-access tracer threaded into the BG isolate (#2866). Null
  /// outside an instrumented scan.
  final DataAccessRecorder? recorder;

  /// #2866 shared foreground+background per-provider request budget. Null in
  /// the legacy/test call sites that don't gate.
  final ProviderRequestBudget? budget;

  @visibleForTesting
  final StationService? Function(String code, {String? apiKey})? serviceBuilder;
}

/// [CountryAlertStrategy] for a single [SourceModel.polledApi] country (#2863).
///
/// This is the *which-service-fetches* seam, extracted from the #2862 polled
/// path: build the country's [StationService] once (Riverpod-free, via
/// [CountryServiceRegistry.buildBackgroundService]) and answer alerts through
/// it — `getPrices` for per-station alerts (the country service chunks to its
/// batch size internally), `searchStations` for radius alerts — within the
/// provider's `minInterval`. The built service is cached so a scan that fetches
/// prices AND runs a radius search for the same country reuses one service.
class PolledAlertStrategy implements CountryAlertStrategy {
  PolledAlertStrategy._(
    this.countryCode,
    this._service, {
    this.minInterval,
    ProviderRequestBudget? budget,
  }) : _budget = budget;

  @override
  final String countryCode;

  final StationService _service;

  /// The provider's configured min inter-request spacing (#2866), read from
  /// the registry policy. Used with [_budget] to skip a too-soon BG poll.
  final Duration? minInterval;

  /// Shared foreground+background per-provider request budget (#2866). When
  /// present, a fetch / search is skipped if the provider was hit (by EITHER
  /// isolate) within [minInterval]; the cache then answers from the last hit.
  final ProviderRequestBudget? _budget;

  /// The built country [StationService] backing this strategy. Exposed for the
  /// nearest-widget search (#609 / #2862), which needs a raw service handle
  /// rather than the strategy facade.
  StationService get service => _service;

  /// `true` when the shared budget allows a fresh provider request for this
  /// country right now — i.e. no budget is wired, or the last request is at
  /// least [minInterval] old. A blocked request leaves the previous prices in
  /// place (the foreground / a prior scan already populated the cache).
  bool get _budgetAllows =>
      _budget?.canFire(countryCode, minInterval) ?? true;

  /// Whether [countryCode] is one of the polled providers this strategy serves.
  static bool isPolled(String countryCode) =>
      kBackgroundPolledCountries.contains(countryCode);

  /// Build the polled strategy for [countryCode], or null when the country is
  /// not a polled provider / its service cannot be built (no key, etc.).
  ///
  /// [apiKey] is the user's key threaded into the isolate. Only DE needs it on
  /// the Dio (sent as the `apikey` query param — the isolate has no Dio
  /// interceptor); KR/CL read their key from [storage] inside the registry
  /// factory.
  static PolledAlertStrategy? forCountry(
    String countryCode, {
    required StorageRepository storage,
    required CacheStrategy cache,
    String? apiKey,
    PolledAlertStrategyDeps? deps,
  }) {
    if (!isPolled(countryCode)) return null;
    final d = deps ?? const PolledAlertStrategyDeps();
    final service = d.serviceBuilder != null
        ? d.serviceBuilder!(countryCode, apiKey: apiKey)
        : CountryServiceRegistry.buildBackgroundService(
            countryCode,
            storage: storage,
            cache: cache,
            tankerkoenigDio: countryCode == 'DE'
                ? _buildTankerkoenigDio(apiKey, d)
                : null,
            // #2866 — count BG traffic + share the per-provider budget with the
            // foreground; both null outside an instrumented / gated scan.
            recorder: d.recorder,
            budget: d.budget,
          );
    if (service == null) return null;
    // #2866 — the provider's configured minInterval, fed to the shared budget
    // so a too-soon BG poll after a foreground hit is skipped. The recorder
    // also notes it (in buildBackgroundService) so the trace can judge
    // compliance against it. A fake serviceBuilder may yield no policy.
    final minInterval =
        CountryServiceRegistry.policyFor(countryCode)?.minInterval;
    d.recorder?.notePolicy(countryCode, minInterval);
    return PolledAlertStrategy._(
      countryCode,
      service,
      minInterval: minInterval,
      budget: d.budget,
    );
  }

  /// Tankerkönig Dio for the background isolate: rate-limited + conditional
  /// GET (via [DioFactory]) with the API key baked into the query parameters,
  /// since there is no Riverpod interceptor here.
  static Dio _buildTankerkoenigDio(String? apiKey, PolledAlertStrategyDeps d) {
    final dio = DioFactory.create(
      baseUrl: ServiceConfigs.tankerkoenig.baseUrl,
      connectTimeout: d.connectTimeout,
      receiveTimeout: d.receiveTimeout,
    );
    if (apiKey != null && apiKey.isNotEmpty) {
      dio.options.queryParameters = {'apikey': apiKey};
    }
    return dio;
  }

  /// Fetch current prices for [stationIds] via the country service's batch
  /// `getPrices` (which chunks to the provider's batch size internally), mapped
  /// to the Tankerkönig-shaped map. A provider with no batch endpoint returns
  /// an empty map (per-station alerts for it find no fresh price this scan;
  /// radius alerts still work via [searchArea]).
  ///
  /// Returns an empty map for no ids or any fetch fault (spooled, never
  /// thrown).
  @override
  Future<Map<String, Map<String, dynamic>>> fetchPrices(
    Set<String> stationIds,
  ) async {
    if (stationIds.isEmpty) return const {};
    // #2866 — shared-budget gate: skip a too-soon poll the foreground (or a
    // prior scan) already covered within minInterval. The cache still holds
    // those prices, so per-station alerts evaluate against the last fetch.
    if (!_budgetAllows) {
      debugPrint('PolledAlertStrategy.fetchPrices($countryCode): skipped — '
          'within shared minInterval budget');
      return const {};
    }
    try {
      final result = await _service.getPrices(stationIds.toList());
      final out = <String, Map<String, dynamic>>{};
      for (final entry in result.data.entries) {
        out[entry.key] = stationPricesToTankerkoenigShape(entry.value);
      }
      return out;
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.other, e, st, context: {
        'where': 'PolledAlertStrategy.fetchPrices($countryCode)',
        'ids': stationIds.length,
      }));
      return const {};
    }
  }

  /// Run a radius search via the country provider. Returns the priced stations,
  /// or an empty list on a fetch fault.
  @override
  Future<List<Station>> searchArea(SearchParams params) async {
    // #2866 — same shared-budget gate as fetchPrices: a radius search is a
    // provider request, so skip it when the shared minInterval is not yet up.
    if (!_budgetAllows) {
      debugPrint('PolledAlertStrategy.searchArea($countryCode): skipped — '
          'within shared minInterval budget');
      return const [];
    }
    try {
      final result = await _service.searchStations(params);
      return result.data;
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.other, e, st, context: {
        'where': 'PolledAlertStrategy.searchArea($countryCode)',
      }));
      return const [];
    }
  }
}
