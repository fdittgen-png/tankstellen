import '../constants/app_constants.dart';
import '../../features/search/domain/entities/fuel_type.dart';
import '../../features/search/domain/entities/station.dart';
import 'station_extensions.dart';

/// Returns the price of the given [fuelType] for [station], or null if unavailable.
double? priceForFuelType(Station station, FuelType fuelType) {
  switch (fuelType) {
    case FuelType.e5: return station.e5;
    case FuelType.e10: return station.e10;
    case FuelType.e98: return station.e98;
    case FuelType.diesel: return station.diesel;
    case FuelType.dieselPremium: return station.dieselPremium;
    case FuelType.e85: return station.e85;
    case FuelType.lpg: return station.lpg;
    case FuelType.cng: return station.cng;
    case FuelType.hydrogen: return null;
    case FuelType.electric: return null;
    case FuelType.all: return station.e10 ?? station.e5 ?? station.diesel;
  }
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
