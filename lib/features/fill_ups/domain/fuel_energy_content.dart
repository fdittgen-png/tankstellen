// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../../core/domain/fuel_type.dart';

/// Volumetric energy content (lower heating value, MJ/L) per road fuel —
/// the physics behind the all-prices table's labelled estimate (#3945).
///
/// A litre of E85 carries ~20 % less energy than a litre of petrol, so the
/// same drive needs ~25 % more of it. That ratio is what turns a vehicle's
/// MEASURED consumption on one grade into a MODELLED consumption on another
/// grade the driver has never burned pure:
///
/// ```
/// L100_target = L100_base × (energy_base / energy_target)
/// ```
///
/// The values mirror the ones the GPS live-fuel estimator has used since
/// #2431 (`GpsLiveFuelEstimator.*LhvMjPerL`, `lib/features/trips/`) — the
/// same physics, restated here because `fill_ups` may not import `trips`.
/// `test/features/fill_ups/domain/fuel_energy_content_test.dart` pins the two
/// tables to each other so they can never drift apart.
///
/// Sources (volumetric LHV at ~15 °C, commonly cited road-fuel figures):
///   * petrol (E5 / E10 / E98) ≈ 31.9–32 MJ/L,
///   * diesel (incl. premium)  ≈ 35.8–36 MJ/L,
///   * E85                     ≈ 25.6 MJ/L (≈85 % ethanol @ 21.2 MJ/L + 15 %
///     petrol),
///   * LPG / autogas (liquid)  ≈ 26 MJ/L.
///
/// CNG is sold by mass (kg), not by litre, so it has no meaningful
/// volumetric figure here — [mjPerLitre] returns null and the estimate is
/// simply not made for it. Electric / hydrogen / the `all` wildcard are not
/// liquid road fuels and return null as well.
abstract final class FuelEnergyContent {
  /// Petrol grades (E5, E10, E98) — the ethanol splash in E5/E10 moves the
  /// figure by well under 1 MJ/L, below the precision of the estimate.
  static const double petrolMjPerL = 31.9;

  /// Diesel and premium diesel.
  static const double dieselMjPerL = 35.8;

  /// E85 (superethanol).
  static const double e85MjPerL = 25.6;

  /// LPG / autogas, liquid.
  static const double lpgMjPerL = 26.0;

  /// The volumetric energy content of [fuel], or null when the fuel has no
  /// meaningful per-litre figure (CNG, electric, hydrogen, the wildcard).
  static double? mjPerLitre(FuelType fuel) {
    if (fuel == FuelType.e5 || fuel == FuelType.e10 || fuel == FuelType.e98) {
      return petrolMjPerL;
    }
    if (fuel == FuelType.diesel || fuel == FuelType.dieselPremium) {
      return dieselMjPerL;
    }
    if (fuel == FuelType.e85) return e85MjPerL;
    if (fuel == FuelType.lpg) return lpgMjPerL;
    return null;
  }

  /// `energy_base / energy_target` — multiply a litres/100 km measured on
  /// [base] by this to model the litres/100 km the same drive needs on
  /// [target]. Null when either fuel has no volumetric figure.
  static double? litreRatio({required FuelType base, required FuelType target}) {
    final eBase = mjPerLitre(base);
    final eTarget = mjPerLitre(target);
    if (eBase == null || eTarget == null || eTarget <= 0) return null;
    return eBase / eTarget;
  }
}
