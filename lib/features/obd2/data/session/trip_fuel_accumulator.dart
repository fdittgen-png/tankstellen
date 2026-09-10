// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// The trip's fuel bookkeeping, owned by [TripRecordingController]
/// instead of held as five bare fields in its shared `part` scope
/// (#4034, epic #4032).
///
/// Two things are accumulated here, both per emit tick:
///
///  * how much fuel the trip has burned so far and whether ANY real
///    fuel-rate sample was ever seen — the latter is what decides
///    whether the trip carries measured litres or the #3576 GPS-physics
///    estimate the driver watched all drive;
///  * #1858 — the η_v recompute provenance. `_veWeightedFuelSum` is
///    Σ(η_v_i × fuelRate_i) and `_veDerivedFuelRateSum` is Σ(fuelRate_i),
///    both over speed-density ticks only; `_sawNonVeDerivedFuel` flips
///    true the moment any fuel is integrated from PID 5E or the MAF
///    branch (neither uses η_v). At trip end they collapse into
///    [volumetricEfficiencyUsed].
///
/// A fresh controller is built per trip, so declaration-time zero is the
/// only reset needed — the values carry correctly across pause/resume,
/// because that is all one trip.
class TripFuelAccumulator {
  double _litersSoFar = 0;
  bool _fuelRateSeen = false;
  double _veWeightedFuelSum = 0;
  double _veDerivedFuelRateSum = 0;
  bool _sawNonVeDerivedFuel = false;

  /// Whether any real fuel-rate sample has been integrated this trip.
  bool get fuelRateSeen => _fuelRateSeen;

  /// Litres burned so far, or null while no fuel rate has ever been
  /// seen — a zero would read as "measured nothing", which is a
  /// different claim from "never measured".
  double? get litersSoFarOrNull => _fuelRateSeen ? _litersSoFar : null;

  /// A tick that integrated fuel through the speed-density (η_v) branch.
  void addVeDerived({required double veUsed, required double fuelRate}) {
    _veWeightedFuelSum += veUsed * fuelRate;
    _veDerivedFuelRateSum += fuelRate;
  }

  /// A tick that integrated fuel from PID 5E or the MAF branch — neither
  /// uses η_v, so the trip is no longer recalculable.
  void markNonVeDerived() => _sawNonVeDerivedFuel = true;

  /// The recorder's running total after a tick that saw real fuel. A
  /// null total keeps the previous one rather than resetting to zero.
  void observeMeasured(double? litersConsumed) {
    _fuelRateSeen = true;
    _litersSoFar = litersConsumed ?? _litersSoFar;
  }

  /// #1858 — the fuel-weighted mean η_v applied across the trip.
  /// Non-null ONLY when every litre was speed-density-derived
  /// (η_v-scalable) and some fuel was burned; any PID 5E / MAF fuel — or
  /// no fuel — leaves it null, marking the trip "not recalculable".
  double? get volumetricEfficiencyUsed =>
      (!_sawNonVeDerivedFuel && _veDerivedFuelRateSum > 0)
          ? _veWeightedFuelSum / _veDerivedFuelRateSum
          : null;
}
