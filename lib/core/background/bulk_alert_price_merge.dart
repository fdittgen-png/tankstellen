// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../services/country_service_registry.dart';
import 'bulk_dataset_alert_strategy.dart';
import 'country_alert_strategy_resolver.dart';

/// #2863 — fetch per-station alert prices for **bulk-dataset** countries via
/// their [BulkDatasetAlertStrategy] (resolved per country by [resolver]).
///
/// Groups the alert station ids by derived country (the same lazy derivation
/// the polled grouping uses), keeps only the bulk-policy countries (polled
/// ones were already fetched by the polled source), and asks each country's
/// strategy for its prices — answered by local geo-filter over the cached
/// whole-country dataset (≤1 dataset download per country per scan, then zero
/// per-alert network). Each strategy swallows + spools its own faults (its
/// documented boundary, fault-tested in `country_alert_strategy_test.dart`),
/// so a bulk-country fault degrades to "no fresh prices this scan" rather than
/// failing the scan. Extracted from the coordinator (#2866) to keep it under
/// the 400-line file-size norm.
Future<Map<String, Map<String, dynamic>>> fetchBulkAlertPrices({
  required Set<String> alertStationIds,
  required String? fallbackCountryCode,
  required CountryAlertStrategyResolver resolver,
}) async {
  final byCountry = <String, Set<String>>{};
  for (final id in alertStationIds) {
    final code =
        CountryServiceRegistry.countryForStationId(id) ?? fallbackCountryCode;
    // Only the bulk-dataset countries; polled ids were already fetched.
    if (code == null || !BulkDatasetAlertStrategy.isBulk(code)) continue;
    byCountry.putIfAbsent(code, () => <String>{}).add(id);
  }

  final merged = <String, Map<String, dynamic>>{};
  for (final entry in byCountry.entries) {
    final strategy = resolver.strategyFor(entry.key);
    if (strategy == null) continue;
    merged.addAll(await strategy.fetchPrices(entry.value));
  }
  return merged;
}
