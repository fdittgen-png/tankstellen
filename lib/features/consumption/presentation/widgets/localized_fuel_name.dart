// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../../l10n/app_localizations.dart';
import '../../../../core/domain/fuel_type.dart';

/// ARB-localized display name for a [FuelType] (#2887, Epic #2881).
///
/// Distinct from the non-localized [FuelType.displayName] (which carries
/// hard-coded English/French strings like "Super E5" / "GPL / LPG") and
/// from `shortFuelLabel` (language-neutral grade CODES like "E10"). The
/// per-fuel efficiency card needs a full, translated fuel name, so this
/// routes every grade through an ARB key and falls back to the
/// non-localized [FuelType.displayName] only when no localization is
/// available (the standard defensive-fallback pattern).
String localizedFuelName(AppLocalizations? l, FuelType fuel) {
  if (l == null) return fuel.displayName;
  return switch (fuel) {
    FuelTypeE5() => l.fuelNameE5,
    FuelTypeE10() => l.fuelNameE10,
    FuelTypeE98() => l.fuelNameE98,
    FuelTypeDiesel() => l.fuelNameDiesel,
    FuelTypeDieselPremium() => l.fuelNameDieselPremium,
    FuelTypeE85() => l.fuelNameE85,
    FuelTypeLpg() => l.fuelNameLpg,
    FuelTypeCng() => l.fuelNameCng,
    FuelTypeHydrogen() => l.fuelNameHydrogen,
    FuelTypeElectric() => l.fuelNameElectric,
    // The synthetic "all" wildcard has no real fuel name; fall back to
    // its non-localized label (the card never renders it anyway).
    FuelTypeAll() => fuel.displayName,
  };
}
