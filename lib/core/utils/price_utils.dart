// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../constants/app_constants.dart';
import '../../features/search/domain/entities/fuel_type.dart';
import '../../features/search/domain/entities/station.dart';
import 'station_extensions.dart';

/// Returns the price of the given [fuelType] for [station], or null if unavailable.
///
/// Delegates to the canonical [StationDisplay.priceFor] extension so the
/// FuelType→price-field mapping lives in exactly one place (#2170).
double? priceForFuelType(Station station, FuelType fuelType) =>
    station.priceFor(fuelType);

/// Fallback fuel order for [bestDisplayPrice] when the selected fuel has
/// no price. Most-common pump fuels first so the marker shows the most
/// representative price for a typical driver: E10 → E5 → Diesel →
/// Diesel Premium → E85 → LPG → CNG.
const List<FuelType> _displayFallbackOrder = [
  FuelType.e10,
  FuelType.e5,
  FuelType.diesel,
  FuelType.dieselPremium,
  FuelType.e85,
  FuelType.lpg,
  FuelType.cng,
];

/// The price to SHOW for [station] given the user's [selected] fuel, and
/// which fuel produced it (#2400).
///
/// Tankerkönig returns only the queried fuel's price, so after a fuel-chip
/// change the map markers would read `null` for the new fuel until a
/// re-search lands — rendering "--" even though the station clearly has a
/// price for another fuel. This resolver returns:
///   - the [selected]-fuel price when it is non-null, else
///   - the first non-null price in [_displayFallbackOrder],
/// reporting the [shownFuel] that produced it so the caller can label a
/// fallback. Returns `null` ONLY when the station has no usable price for
/// any fuel — the sole legitimate "--" case.
({double price, FuelType shownFuel})? bestDisplayPrice(
  Station station,
  FuelType selected,
) {
  final selectedPrice = station.priceFor(selected);
  if (selectedPrice != null) {
    return (price: selectedPrice, shownFuel: selected);
  }
  for (final fuel in _displayFallbackOrder) {
    final p = station.priceFor(fuel);
    if (p != null) return (price: p, shownFuel: fuel);
  }
  return null;
}

/// (min, max) price for [fuel] across [stations], for colour-gradient /
/// price-tier classification. Returns `(0, 0)` when no station has a
/// usable price.
///
/// Single source for the three identical loops that previously lived in
/// the map layer, the driving map, and the search list (#2182). With
/// [requirePositive] (default `false`) any non-null price counts — the
/// map/driving layers' historical behaviour; the search list passes
/// `true` to exclude zero / sentinel prices from its tiers.
(double, double) priceRange(
  Iterable<Station> stations,
  FuelType fuel, {
  bool requirePositive = false,
}) {
  double minP = double.infinity;
  double maxP = 0;
  for (final s in stations) {
    final p = s.priceFor(fuel);
    if (p != null && (!requirePositive || p > 0)) {
      if (p < minP) minP = p;
      if (p > maxP) maxP = p;
    }
  }
  if (minP == double.infinity) return (0, 0);
  return (minP, maxP);
}

/// (min, max) over each station's RESOLVED display price for [selected]
/// (see [bestDisplayPrice]) — i.e. the selected fuel where present, else
/// the fallback. Returns `(0, 0)` when no station resolves to a price.
///
/// The map marker colours by relative price (#2400); colouring over the
/// resolved prices keeps a fallback-priced marker's colour consistent
/// with the value it actually shows, instead of grey because the
/// selected fuel was null.
(double, double) resolvedPriceRange(
  Iterable<Station> stations,
  FuelType selected,
) {
  double minP = double.infinity;
  double maxP = 0;
  for (final s in stations) {
    final p = bestDisplayPrice(s, selected)?.price;
    if (p != null) {
      if (p < minP) minP = p;
      if (p > maxP) maxP = p;
    }
  }
  if (minP == double.infinity) return (0, 0);
  return (minP, maxP);
}

/// (min, max) over each station's price for the fuel its [resolver] picks —
/// the cross-border case (#2631) where each station is priced by ITS country's
/// profile fuel. Returns `(0, 0)` when none resolve to a price.
(double, double) resolvedPriceRangeWith(
  Iterable<Station> stations,
  FuelType Function(Station) resolver,
) {
  double minP = double.infinity;
  double maxP = 0;
  for (final s in stations) {
    final p = priceForFuelType(s, resolver(s));
    if (p != null) {
      if (p < minP) minP = p;
      if (p > maxP) maxP = p;
    }
  }
  return minP == double.infinity ? (0, 0) : (minP, maxP);
}

/// Compares two stations by price for [fuelType]. Stations without a price sort last.
int compareByPrice(Station a, Station b, FuelType fuelType) {
  final pa = priceForFuelType(a, fuelType) ?? AppConstants.noPriceSentinel;
  final pb = priceForFuelType(b, fuelType) ?? AppConstants.noPriceSentinel;
  return pa.compareTo(pb);
}

/// Compares two stations alphabetically by display name.
int compareByName(Station a, Station b) {
  final na = a.displayName;
  final nb = b.displayName;
  return na.toLowerCase().compareTo(nb.toLowerCase());
}

/// Compares two stations by 24h availability first, then by distance.
/// Stations open 24h sort before those that are not.
int compareByOpen24h(Station a, Station b) {
  if (a.is24h && !b.is24h) return -1;
  if (!a.is24h && b.is24h) return 1;
  return a.dist.compareTo(b.dist);
}

/// Compares two stations by user rating (highest first).
/// Unrated stations sort after rated ones. Ties break by distance.
int compareByRating(Station a, Station b, Map<String, int> ratings) {
  final ra = ratings[a.id] ?? 0;
  final rb = ratings[b.id] ?? 0;
  if (ra != rb) return rb.compareTo(ra); // descending
  return a.dist.compareTo(b.dist);
}

/// Compares two stations by price/distance ratio (lower is better).
/// Ratio = price / max(dist, 0.1) to avoid division by zero.
/// Stations without a price sort last.
int compareByPriceDistance(
    Station a, Station b, FuelType fuelType) {
  final pa = priceForFuelType(a, fuelType);
  final pb = priceForFuelType(b, fuelType);

  final ratioA = pa != null ? pa / a.dist.clamp(0.1, double.infinity) : AppConstants.noPriceSentinel;
  final ratioB = pb != null ? pb / b.dist.clamp(0.1, double.infinity) : AppConstants.noPriceSentinel;
  return ratioA.compareTo(ratioB);
}
