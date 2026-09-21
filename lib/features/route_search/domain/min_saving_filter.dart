// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import '../../../core/country/country_bounding_box.dart';
import '../../../core/domain/fuel_type.dart';
import '../../../core/domain/search_result_item.dart';
import '../../../core/utils/station_extensions.dart';

/// Keeps only fuel stations priced within [minSaving] €/L of the
/// cheapest station found along the route (#1872).
///
/// The cheapest priced station is the anchor; a station survives when its
/// price is at most `cheapest + minSaving`. Stations with no price are
/// kept — an unknown price is not a reason to hide a stop — and the list
/// is returned unchanged when no station carries a comparable price. EV
/// results never reach here (the caller gates on a non-electric fuel
/// type).
///
/// #2595 — each station is priced by ITS country's profile fuel via
/// [profileFuelByCountry] (resolved offline from the station's lat/lng),
/// falling back to [fuelType] for a country with no profile or a station
/// outside every bbox. This keeps the cross-border min-saving compare
/// like-for-like (FR→E85 vs ES→E10) instead of pricing every station by a
/// single fuel one country may not even sell. When [profileFuelByCountry]
/// is empty (the historical single-country path) every station is priced
/// by [fuelType], preserving the original behaviour exactly.
List<SearchResultItem> filterRouteResultsByMinSaving(
  List<SearchResultItem> results,
  FuelType fuelType,
  double minSaving, {
  Map<String, FuelType> profileFuelByCountry = const {},
}) {
  FuelType fuelFor(FuelStationResult item) {
    if (profileFuelByCountry.isEmpty) return fuelType;
    final code =
        countryCodeFromLatLng(item.station.lat, item.station.lng)?.toUpperCase();
    if (code == null) return fuelType;
    return profileFuelByCountry[code] ?? fuelType;
  }

  double? cheapest;
  for (final item in results) {
    if (item is FuelStationResult) {
      final price = item.station.priceFor(fuelFor(item));
      if (price != null && (cheapest == null || price < cheapest)) {
        cheapest = price;
      }
    }
  }
  if (cheapest == null) return results;
  final ceiling = cheapest + minSaving;
  return results.where((item) {
    if (item is! FuelStationResult) return true;
    final price = item.station.priceFor(fuelFor(item));
    return price == null || price <= ceiling;
  }).toList();
}
