// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../core/domain/fuel_type.dart';
import '../../../core/constants/field_names.dart';
import '../../../core/services/country_service_registry.dart';

/// Maps a [FuelType] to the JSON field key it occupies in the country-agnostic
/// background price map (`background_price_shape.dart`) — the single source of
/// truth shared by the per-station / velocity alert evaluators and the
/// price-history writer (Epic #2860, child #2864).
///
/// ## Why a dedicated mapping, not `FuelType.apiValue`
///
/// The price-map keys are mostly the [FuelType.apiValue] (`e5`, `e10`,
/// `diesel`, `e98`, `e85`, `lpg`, `cng`), but **diesel-premium** is carried as
/// camelCase `dieselPremium` in the map while its `apiValue` is snake_case
/// `diesel_premium`. Reading the field by `apiValue` would silently miss
/// diesel-premium, so the key is resolved explicitly here, kept in lock-step
/// with the keys both `stationPricesToTankerkoenigShape` and
/// `stationToTankerkoenigShape` emit.
///
/// Electric / hydrogen / the `all` wildcard have no price field in the map
/// (the providers don't publish them through this feed), so they map to null —
/// an alert on one of those simply finds no fresh price this scan, exactly as
/// the old `e5/e10/diesel`-only switch returned null for everything else.
String? priceFieldKeyFor(FuelType fuelType) => switch (fuelType) {
      FuelTypeE5() => TankerkoenigFields.e5,
      FuelTypeE10() => TankerkoenigFields.e10,
      FuelTypeDiesel() => TankerkoenigFields.diesel,
      FuelTypeE98() => TankerkoenigFields.e98,
      FuelTypeDieselPremium() => TankerkoenigFields.dieselPremium,
      FuelTypeE85() => TankerkoenigFields.e85,
      FuelTypeLpg() => TankerkoenigFields.lpg,
      FuelTypeCng() => TankerkoenigFields.cng,
      FuelTypeHydrogen() || FuelTypeElectric() || FuelTypeAll() => null,
    };

/// Resolve the price-map field key for [fuelType] **only when [countryCode]'s
/// provider exposes that fuel** (#2864).
///
/// Gates [priceFieldKeyFor] by [CountryServiceRegistry.fuelTypesFor] so an
/// alert evaluates against a country's actual fuel set: a French LPG alert
/// resolves `lpg`, an Italian CNG alert resolves `cng`, but an LPG alert in a
/// country whose feed has no LPG returns null (no spurious fire). DE's
/// e5/e10/diesel resolution is unchanged — those three are in DE's fuel set and
/// keep their historical keys.
///
/// Returns null when the fuel has no price field at all (electric/…), or when
/// the country's provider does not list the fuel.
String? priceFieldKeyForCountry(FuelType fuelType, String countryCode) {
  final key = priceFieldKeyFor(fuelType);
  if (key == null) return null;
  if (!CountryServiceRegistry.fuelTypesFor(countryCode).contains(fuelType)) {
    return null;
  }
  return key;
}

/// The fuels an alert in [countryCode] can actually be evaluated against
/// (Epic #2860, child #2865) — i.e. every fuel that country's provider
/// exposes *and* which carries a comparable per-litre price in the
/// background price map.
///
/// This is exactly the set for which [priceFieldKeyForCountry] is non-null:
/// it drops [FuelType.all] (a search wildcard, not a concrete fuel) and the
/// no-price-field fuels (electric / hydrogen), so the creation UI never
/// offers a fuel whose alert could only ever silently never fire. Ordering
/// follows [CountryServiceRegistry.fuelTypesFor]'s provider-declared order.
List<FuelType> alertEvaluableFuelsFor(String countryCode) => [
      for (final fuel in CountryServiceRegistry.fuelTypesFor(countryCode))
        if (priceFieldKeyForCountry(fuel, countryCode) != null) fuel,
    ];
