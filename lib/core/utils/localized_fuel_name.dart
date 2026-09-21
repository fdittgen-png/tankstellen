// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import '../../l10n/app_localizations.dart';
import '../domain/fuel_type.dart';

/// ARB-localized display name for a [FuelType] (#2887, Epic #2881).
///
/// Lives in `core/` because `core/widgets/fuel_type_dropdown.dart` needs
/// it and `core -> feature` is the one boundary the ratchet holds at
/// zero — "the api.dart barrel does not excuse it" (#3129). It was in
/// `fill_ups/presentation/widgets/` while only that feature used it;
/// #4283 made it the label for every fuel surface in the app.
///
/// Distinct from the non-localized [FuelType.displayName] (which carries
/// hard-coded English/French strings like "Super E5" / "GPL / LPG") and
/// from `shortFuelLabel` (language-neutral grade CODES like "E10"). The
/// per-fuel efficiency card needs a full, translated fuel name, so this
/// routes every grade through an ARB key.
String localizedFuelName(AppLocalizations l, FuelType fuel) {
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
