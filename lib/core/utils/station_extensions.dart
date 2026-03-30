import '../../features/search/domain/entities/fuel_type.dart';
import '../../features/search/domain/entities/station.dart';

extension StationDisplay on Station {
  String get displayName =>
      brand.isNotEmpty && brand != 'Station' ? brand : place;

  String get displayAddress =>
      houseNumber != null ? '$street $houseNumber' : street;

  String get fullLocation => '$postCode $place';

  /// Returns the price for a specific [FuelType], or null if unavailable.
  ///
  /// For [FuelType.all], returns the first available price in priority
  /// order: E10 → E5 → Diesel.
  double? priceFor(FuelType fuelType) {
    return switch (fuelType) {
      FuelType.e5 => e5,
      FuelType.e10 => e10,
      FuelType.e98 => e98,
      FuelType.diesel => diesel,
      FuelType.dieselPremium => dieselPremium,
      FuelType.e85 => e85,
      FuelType.lpg => lpg,
      FuelType.cng => cng,
      FuelType.hydrogen => null,
      FuelType.electric => null,
      FuelType.all => e10 ?? e5 ?? diesel,
    };
  }
}

