// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../data/models/price_alert.dart';
import '../domain/entities/radius_alert.dart';
import '../../../core/services/country_service_registry.dart';

/// The work for ONE country in a background scan (#2861): the per-station
/// price-alert station ids whose prices must be refreshed, plus the radius
/// alerts whose centres fall in this country.
///
/// Grouping by country is the core ToS safeguard for the multi-country
/// background scan (Epic #2860): each provider is queried **at most once per
/// scan** for all of its alerts, never once per alert.
class CountryAlertGroup {
  CountryAlertGroup(this.countryCode);

  /// ISO 3166-1 alpha-2 code this group's provider serves.
  final String countryCode;

  /// Station ids of active per-station price alerts in this country. A set so
  /// the same station behind two alerts (e.g. E5 + Diesel) is fetched once.
  final Set<String> stationIds = <String>{};

  /// Active radius alerts whose centre resolves to this country.
  final List<RadiusAlert> radiusAlerts = <RadiusAlert>[];

  bool get isEmpty => stationIds.isEmpty && radiusAlerts.isEmpty;
}

/// Groups the active per-station + radius alerts by their **derived** country
/// (#2861) so a background scan hits each provider at most once.
///
/// Country derivation is lazy — neither [PriceAlert] nor [RadiusAlert] stores
/// a country, so we never migrate Hive:
///
///  - per-station: the station-id prefix
///    ([CountryServiceRegistry.countryForStationId]); when the id carries no
///    recognised prefix (a raw DE Tankerkönig UUID, an FR numeric id, …) we
///    fall back to [fallbackCountryCode] (the active country) so legacy
///    favorites saved before the #753 prefix scheme are still scanned.
///  - radius: the centre's bounding box
///    ([CountryServiceRegistry.countryForLatLng]); a centre outside every
///    registered box is dropped (we have no provider to ask).
///
/// Only `isActive` price alerts and `enabled` radius alerts are considered.
/// The returned map is keyed by country code; iteration order is the insertion
/// order so a scan is deterministic.
Map<String, CountryAlertGroup> groupAlertsByCountry({
  required List<PriceAlert> priceAlerts,
  required List<RadiusAlert> radiusAlerts,
  String? fallbackCountryCode,
}) {
  final groups = <String, CountryAlertGroup>{};

  CountryAlertGroup groupFor(String code) =>
      groups.putIfAbsent(code, () => CountryAlertGroup(code));

  for (final alert in priceAlerts) {
    if (!alert.isActive) continue;
    final code = CountryServiceRegistry.countryForStationId(alert.stationId) ??
        fallbackCountryCode;
    if (code == null) continue;
    groupFor(code).stationIds.add(alert.stationId);
  }

  for (final alert in radiusAlerts) {
    if (!alert.enabled) continue;
    final code =
        CountryServiceRegistry.countryForLatLng(alert.centerLat, alert.centerLng);
    if (code == null) continue;
    groupFor(code).radiusAlerts.add(alert);
  }

  return groups;
}
