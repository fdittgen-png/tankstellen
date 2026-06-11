// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../domain/search_params.dart';
import '../domain/station.dart';
import '../cache/cache_manager.dart';
import '../data/storage_repository.dart';
import '../services/country_service_registry.dart';
import '../services/diagnostics/data_access_recorder.dart';
import '../services/fuel_service_policy.dart';
import 'bulk_dataset_alert_strategy.dart';
import 'polled_alert_strategy.dart';
import 'provider_request_budget.dart';

/// The per-country **specialization seam** a background alert scan resolves to
/// (Epic #2860, child #2863).
///
/// A scan groups its active alerts by derived country
/// (`groupAlertsByCountry`), then asks the registry for **one** strategy per
/// country and fetches once. Where a country's prices come from — and at what
/// network cost — is the strategy's concern; the price **evaluation** + euro /
/// fuel-set notification copy is deliberately untouched here (that is child
/// #2864). A strategy only answers two questions the evaluator already
/// consumes:
///
///  - [fetchPrices] — current prices for a set of station ids in this country,
///    as the Tankerkönig-shaped `id → {status, e5, e10, diesel, …}` map the
///    per-station / velocity runners read unchanged.
///  - [searchArea] — a radius search returning the priced [Station]s the
///    radius-alert runner turns into samples.
///
/// ## Why branch on `FuelServicePolicy.model`, not country code
///
/// The split between the two concrete strategies is **how the data is
/// delivered**, not which flag is on the map. A country is polled or bulk
/// purely by its [SourceModel]:
///
///  - [PolledAlertStrategy] — [SourceModel.polledApi]: build the country's
///    `StationService` and query it within the provider's `minInterval`
///    (DE/AT/PT/GB-legacy/LU/SI/GR/RO/MX/KR/CL).
///  - [BulkDatasetAlertStrategy] — [SourceModel.bulkFile]: refresh a cached
///    whole-country dataset at most per its `datasetTtl`, then answer EVERY
///    alert by local geo-filter over that dataset — zero per-alert network
///    (ES/IT/AR/DK).
///
/// GB and FR each flip between the two via [BulkMigrationFlags] — their policy
/// model is `bulkFile` or `polledApi` depending on the compile-time flag — so
/// branching on `policy.model` (the resolved truth) moves them between
/// strategies automatically, where branching on country code would not.
abstract class CountryAlertStrategy {
  /// ISO 3166-1 alpha-2 code this strategy serves.
  String get countryCode;

  /// Fetch current prices for [stationIds] in [countryCode], returning the
  /// Tankerkönig-shaped `id → {status, e5, e10, diesel, …}` map the existing
  /// per-station / velocity runners consume unchanged.
  ///
  /// Returns an empty map for no ids or any fetch fault (spooled, never
  /// thrown — this runs in an OS-spawned isolate). The keys are the original
  /// (prefixed) station ids; only the ids the source can resolve are present.
  Future<Map<String, Map<String, dynamic>>> fetchPrices(Set<String> stationIds);

  /// Run a radius search in [countryCode], returning the priced stations the
  /// radius-alert runner converts to samples. Returns an empty list on any
  /// fetch fault.
  Future<List<Station>> searchArea(SearchParams params);

  /// Resolve the right [CountryAlertStrategy] for [countryCode] from the
  /// registry's [FuelServicePolicy.model] — **not** the country code, so
  /// GB/FR follow [BulkMigrationFlags] (a flag flip moves them between the
  /// polled and bulk strategies because it flips their resolved `policy.model`).
  ///
  /// Returns null when:
  ///  - the country has no registry entry, or
  ///  - it is the AU throwing stub (#804 — excluded from background scans), or
  ///  - it is a polled country [PolledAlertStrategy] cannot serve (its
  ///    `serviceFor` yields no service this scan).
  ///
  /// [apiKey] is the user's key threaded into the isolate (DE needs it on the
  /// Dio; KR/CL read theirs from [storage] inside the registry factory).
  ///
  /// [recorder] is the #2824 data-access tracer and [budget] the #2866 shared
  /// per-provider request budget — both threaded through so the chain each
  /// strategy builds counts its background traffic and shares one minInterval
  /// gate with the foreground. The [polledDeps] (when supplied) already carry
  /// these for the polled branch; the bulk branch reads them here.
  static CountryAlertStrategy? forCountry(
    String countryCode, {
    required StorageRepository storage,
    required CacheStrategy cache,
    String? apiKey,
    DataAccessRecorder? recorder,
    ProviderRequestBudget? budget,
    PolledAlertStrategyDeps? polledDeps,
  }) {
    // AU is a documented throwing stub (#804) — never scanned in the BG isolate.
    if (countryCode == 'AU') return null;

    final policy = CountryServiceRegistry.policyFor(countryCode);
    if (policy == null) return null;

    switch (policy.model) {
      case SourceModel.bulkFile:
        return BulkDatasetAlertStrategy(
          countryCode: countryCode,
          storage: storage,
          cache: cache,
          policy: policy,
          recorder: recorder,
          budget: budget,
        );
      case SourceModel.polledApi:
        return PolledAlertStrategy.forCountry(
          countryCode,
          storage: storage,
          cache: cache,
          apiKey: apiKey,
          deps: polledDeps ??
              PolledAlertStrategyDeps(recorder: recorder, budget: budget),
        );
    }
  }
}
