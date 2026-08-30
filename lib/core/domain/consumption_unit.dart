// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// The unit a fuel-consumption figure is displayed in (#3883).
///
/// Every consumption value in the app is COMPUTED in L/100 km (the
/// recorder, the estimators, the persisted summaries); this enum only
/// changes how it is rendered. `kmPerL` and both `mpg` variants are
/// reciprocal units — a lower L/100 km is a higher mpg — so the
/// conversion guards the zero/near-zero case.
enum ConsumptionUnit {
  lPer100Km,
  kmPerL,
  mpgUs,
  mpgUk;

  /// Litres per US gallon / per imperial gallon.
  static const double _litresPerUsGallon = 3.785411784;
  static const double _litresPerUkGallon = 4.54609;
  static const double _milesPerKm = 0.621371;

  /// True for a "distance per volume" unit (higher = better).
  bool get isReciprocal => this != ConsumptionUnit.lPer100Km;

  /// Convert a value in L/100 km into this unit. A zero / negative
  /// L/100 km has no finite reciprocal — returns null for those (the
  /// caller renders the no-data placeholder).
  double? fromLPer100Km(double lPer100Km) {
    switch (this) {
      case ConsumptionUnit.lPer100Km:
        return lPer100Km;
      case ConsumptionUnit.kmPerL:
        return lPer100Km <= 0 ? null : 100.0 / lPer100Km;
      case ConsumptionUnit.mpgUs:
        return lPer100Km <= 0
            ? null
            : 100.0 * _milesPerKm * _litresPerUsGallon / lPer100Km;
      case ConsumptionUnit.mpgUk:
        return lPer100Km <= 0
            ? null
            : 100.0 * _milesPerKm * _litresPerUkGallon / lPer100Km;
    }
  }

  /// The language-neutral unit mask shown after the figure (#2185/#3883).
  String get mask => switch (this) {
        ConsumptionUnit.lPer100Km => 'L/100 km',
        ConsumptionUnit.kmPerL => 'km/L',
        ConsumptionUnit.mpgUs => 'mpg (US)',
        ConsumptionUnit.mpgUk => 'mpg (UK)',
      };

  /// The short unit token for narrow live surfaces (banner / PiP).
  String get shortMask => switch (this) {
        ConsumptionUnit.lPer100Km => 'L/100',
        ConsumptionUnit.kmPerL => 'km/L',
        ConsumptionUnit.mpgUs => 'mpg',
        ConsumptionUnit.mpgUk => 'mpg',
      };

  /// Decimals that keep the figure readable: one for L/100 km and
  /// km/L, none for mpg (a 34.7 → 35 mpg rounding is how drivers read it).
  int get fractionDigits => switch (this) {
        ConsumptionUnit.lPer100Km => 1,
        ConsumptionUnit.kmPerL => 1,
        ConsumptionUnit.mpgUs => 0,
        ConsumptionUnit.mpgUk => 0,
      };

  /// The country default: imperial-distance countries read mpg — the UK
  /// in imperial gallons, the US in US gallons — everyone else L/100 km.
  static ConsumptionUnit defaultFor(String? countryCode) =>
      switch (countryCode?.toUpperCase()) {
        'GB' => ConsumptionUnit.mpgUk,
        'US' => ConsumptionUnit.mpgUs,
        _ => ConsumptionUnit.lPer100Km,
      };

  String get wireName => name;

  static ConsumptionUnit? parse(String? raw) {
    for (final u in values) {
      if (u.name == raw) return u;
    }
    return null;
  }
}
