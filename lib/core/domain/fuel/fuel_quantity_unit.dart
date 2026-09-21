// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// The physical unit a fuel quantity is measured in (#4364).
///
/// `FuelType.unit` already distinguishes `EUR/L`, `EUR/kg` and `EUR/kWh`,
/// but every historical consumption path in the app computes a
/// litre-based quantity (litres pumped, L/100 km, €/L). Relabelling the
/// suffix on such a figure does not make 5 kg of CNG and 5 L of E10
/// interchangeable, and running kWh through an L/100 km formula produces
/// a number that is true in no unit at all.
///
/// This enum exists so a comparison can *refuse* rather than relabel:
/// liquid-fuel consumption ships, kg/kWh consumption is explicitly
/// unavailable, and the native spend of a kg/kWh record stays visible on
/// its own terms.
library;

import 'fuel_grade.dart';

/// What one unit of a fuel is counted in.
enum FuelQuantityUnit {
  /// Litres — every grade the historical consumption walkers can speak
  /// for (petrol grades, diesel grades, LPG at the European pump).
  litre,

  /// Kilograms — CNG, hydrogen.
  kilogram,

  /// Kilowatt-hours — electricity.
  kilowattHour,

  /// No quantity unit at all: the search wildcard, or a grade nothing on
  /// record names.
  unknown;

  /// True only for the unit the app's L/100 km, €/L and litre-window
  /// arithmetic is defined in.
  bool get isLitreBased => this == FuelQuantityUnit.litre;

  /// The unit named by a `EUR/L` / `EUR/kg` / `EUR/kWh` price mask.
  ///
  /// Parsed from the denominator so one table (`FuelType.unit`) stays the
  /// single source of truth — a new fuel gets its quantity unit from the
  /// price unit it already declares, with no second table to forget.
  static FuelQuantityUnit fromPriceUnit(String priceUnit) {
    final slash = priceUnit.lastIndexOf('/');
    if (slash < 0 || slash == priceUnit.length - 1) {
      return FuelQuantityUnit.unknown;
    }
    return switch (priceUnit.substring(slash + 1).toLowerCase()) {
      'l' => FuelQuantityUnit.litre,
      'kg' => FuelQuantityUnit.kilogram,
      'kwh' => FuelQuantityUnit.kilowattHour,
      _ => FuelQuantityUnit.unknown,
    };
  }

  /// The unit [grade] is sold in.
  static FuelQuantityUnit ofGrade(FuelGrade grade) => switch (grade) {
        FuelGrade.e5 ||
        FuelGrade.e10 ||
        FuelGrade.e98 ||
        FuelGrade.e85 ||
        FuelGrade.diesel ||
        FuelGrade.dieselPremium ||
        FuelGrade.lpg =>
          FuelQuantityUnit.litre,
        FuelGrade.cng || FuelGrade.hydrogen => FuelQuantityUnit.kilogram,
        FuelGrade.electric => FuelQuantityUnit.kilowattHour,
        FuelGrade.wildcard || FuelGrade.unknown => FuelQuantityUnit.unknown,
      };
}

/// The one unit [units] share, or null when they do not share one.
///
/// Null is the point: quantities in different units may never be added,
/// nor divided by a common distance. An empty iterable has no unit either
/// (there is nothing to be true of) and also answers null.
FuelQuantityUnit? commonFuelQuantityUnit(Iterable<FuelQuantityUnit> units) {
  FuelQuantityUnit? shared;
  for (final unit in units) {
    if (shared == null) {
      shared = unit;
    } else if (shared != unit) {
      return null;
    }
  }
  return shared;
}
