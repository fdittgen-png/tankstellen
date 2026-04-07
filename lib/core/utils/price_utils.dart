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
