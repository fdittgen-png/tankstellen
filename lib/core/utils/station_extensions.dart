import '../../features/search/domain/entities/fuel_type.dart';
import '../../features/search/domain/entities/station.dart';

extension StationDisplay on Station {
  /// User-facing station name: brand if meaningful, otherwise street or place.
  /// Used everywhere a station needs a short label (cards, maps, navigation).
  String get displayName =>
      brand.isNotEmpty && brand != 'Station' && brand != 'Autoroute'
          ? brand
          : street.isNotEmpty ? street : name.isNotEmpty ? name : place;

  /// Label for navigation apps (maps, Android Auto, CarPlay).
  String get navLabel => displayName;

  String get displayAddress =>
      houseNumber != null ? '$street $houseNumber' : street;

  String get fullLocation => '$postCode $place';

  /// Returns the price for a specific [FuelType], or null if unavailable.
  ///
  /// For [FuelType.all], returns the first available price in priority
  /// order: E10 → E5 → Diesel.
  double? priceFor(FuelType fuelType) {
    return switch (fuelType) {
      FuelTypeE5() => e5,
      FuelTypeE10() => e10,
      FuelTypeE98() => e98,
      FuelTypeDiesel() => diesel,
      FuelTypeDieselPremium() => dieselPremium,
      FuelTypeE85() => e85,
      FuelTypeLpg() => lpg,
      FuelTypeCng() => cng,
      FuelTypeHydrogen() => null,
      FuelTypeElectric() => null,
      FuelTypeAll() => e10 ?? e5 ?? diesel,
    };
  }
}

