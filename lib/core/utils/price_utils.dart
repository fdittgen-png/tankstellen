import '../constants/app_constants.dart';
import '../../features/search/domain/entities/fuel_type.dart';
import '../../features/search/domain/entities/station.dart';
import 'station_extensions.dart';

/// Returns the price of the given [fuelType] for [station], or null if unavailable.
double? priceForFuelType(Station station, FuelType fuelType) {
  return switch (fuelType) {
    FuelTypeE5() => station.e5,
    FuelTypeE10() => station.e10,
    FuelTypeE98() => station.e98,
    FuelTypeDiesel() => station.diesel,
    FuelTypeDieselPremium() => station.dieselPremium,
    FuelTypeE85() => station.e85,
    FuelTypeLpg() => station.lpg,
    FuelTypeCng() => station.cng,
    FuelTypeHydrogen() => null,
    FuelTypeElectric() => null,
    FuelTypeAll() => station.e10 ?? station.e5 ?? station.diesel,
  };
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
