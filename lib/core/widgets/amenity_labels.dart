// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../l10n/app_localizations.dart';
import '../domain/station_amenity.dart' hide amenityLabel;

/// The localized name of an amenity — ONE switch, so the detail screen's
/// chips, the result card's compact summary (#4091) and the map's station
/// sheet (#4093) can never drift apart on what a facility is called.
///
/// It lives in core because three different features render it, and
/// `lib/core/` must never depend on `lib/features/` — the worst
/// inversion direction (epic #3129). The switch was briefly in
/// `features/search`, which made the core summary widget import a
/// feature to read it.
///
/// Not to be confused with the English-only `amenityLabel` in
/// `core/domain/station_amenity.dart`, which predates localization and
/// has no production caller left.
String localizedAmenityLabel(StationAmenity a, AppLocalizations l10n) {
  return switch (a) {
    StationAmenity.shop => l10n.amenityShop,
    StationAmenity.carWash => l10n.amenityCarWash,
    StationAmenity.airPump => l10n.amenityAirPump,
    StationAmenity.toilet => l10n.amenityToilet,
    StationAmenity.restaurant => l10n.amenityRestaurant,
    StationAmenity.atm => l10n.amenityAtm,
    StationAmenity.wifi => l10n.amenityWifi,
    StationAmenity.ev => l10n.amenityEv,
  };
}
