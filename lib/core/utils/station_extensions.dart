// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../domain/fuel_type.dart';
import '../domain/station.dart';

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

/// Truncate [brand] to [maxLength] characters, appending an ellipsis when
/// it overflows. Shared by the map and driving marker builders (#2196).
String truncateBrand(String brand, {required int maxLength}) {
  if (brand.length <= maxLength) return brand;
  return '${brand.substring(0, maxLength - 1)}…';
}

/// Short, language-neutral pump code for [fuel] — the same abbreviations
/// the all-prices card uses (`E5`, `E10`, `Diesel`, `Diesel+`, `E85`,
/// `GPL`, `GNV`). Used on the map marker to label a fallback price whose
/// fuel differs from the user's selection (#2400). These are
/// language-neutral fuel codes (brand-style proper nouns), not
/// translatable prose.
String shortFuelLabel(FuelType fuel) => switch (fuel) {
      FuelTypeE5() => 'E5', // i18n-ignore: language-neutral fuel code
      FuelTypeE10() => 'E10', // i18n-ignore: language-neutral fuel code
      FuelTypeE98() => 'E98', // i18n-ignore: language-neutral fuel code
      FuelTypeDiesel() => 'Diesel', // i18n-ignore: language-neutral fuel code
      FuelTypeDieselPremium() =>
        'Diesel+', // i18n-ignore: language-neutral fuel code
      FuelTypeE85() => 'E85', // i18n-ignore: language-neutral fuel code
      FuelTypeLpg() => 'GPL', // i18n-ignore: language-neutral fuel code
      FuelTypeCng() => 'GNV', // i18n-ignore: language-neutral fuel code
      FuelTypeHydrogen() => 'H2', // i18n-ignore: language-neutral fuel code
      FuelTypeElectric() => 'EV', // i18n-ignore: language-neutral fuel code
      FuelTypeAll() => '', // no label for the wildcard
    };

/// Country-aware pump label for [fuel] (#2717).
///
/// Mexico's CRE feed has no European E5/E98 grades — its pumps are
/// PEMEX **Magna** (~87-oct regular, mapped to the e5 family by #2704)
/// and **Premium** (~91-92 oct, mapped to e98). The underlying mapping
/// is physically correct (eco/CO₂ factor, fuel colour and compatibility
/// family all match), so this only fixes the rendered *string*: for
/// `countryCode == 'MX'` it returns the real PEMEX grade name, and for
/// every other country (and `null`) it falls straight through to
/// [shortFuelLabel] — guaranteeing zero change for FR/DE/etc. Diesel,
/// e10, lpg, … always use [shortFuelLabel], even in Mexico.
String fuelDisplayLabel(FuelType fuel, {String? countryCode}) {
  if (countryCode == 'MX') {
    return switch (fuel) {
      FuelTypeE5() => 'Magna', // i18n-ignore: PEMEX fuel-grade proper noun
      FuelTypeE98() => 'Premium', // i18n-ignore: PEMEX fuel-grade proper noun
      _ => shortFuelLabel(fuel),
    };
  }
  return shortFuelLabel(fuel);
}

