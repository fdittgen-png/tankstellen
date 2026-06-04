// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../search/domain/entities/fuel_type.dart';
import '../../vehicle/domain/entities/vehicle_profile.dart';
import 'add_fill_up_fuel_resolver.dart';
import 'entities/fill_up.dart';

/// Non-blocking data-quality warnings for the Add-Fill-up form (#2836).
///
/// A real backup logged an **e10 (petrol) fill-up on a diesel vehicle**
/// and an **odometer that went backwards** (a later-dated diesel fill at
/// 83178 km after an earlier e10 fill at 83485 km, −307 km), which breaks
/// fuel-economy-between-fills. The form had no guard against either, so
/// both slipped in silently. These are *warnings*, not hard errors — the
/// user may genuinely have refilled a borrowed car or reset the trip
/// odometer — so the UI confirms rather than blocks.
enum FillUpWarning {
  /// The chosen fuel belongs to a different engine family than the
  /// vehicle's configured fuel (e.g. petrol on a diesel car).
  fuelEngineMismatch,

  /// The entered odometer is below the most recent prior fill-up's
  /// odometer for the same vehicle — distance can't go backwards.
  odometerBelowPrevious,
}

/// Compute the data-quality warnings for a pending fill-up (#2836).
///
/// * [vehicle] — the selected vehicle (drives the engine-family check).
/// * [chosenFuel] — the fuel the form currently has selected.
/// * [enteredOdometerKm] — the odometer the user typed (already parsed).
/// * [previousOdometerKm] — the most recent prior real (non-correction)
///   fill-up's odometer for the same vehicle, or null when there is none.
///
/// Returns the warnings in a stable order. An empty list means the entry
/// is clean and the form may save without a confirmation prompt.
List<FillUpWarning> computeFillUpWarnings({
  required VehicleProfile vehicle,
  required FuelType chosenFuel,
  required double enteredOdometerKm,
  double? previousOdometerKm,
}) {
  final warnings = <FillUpWarning>[];

  // Fuel ⇄ engine mismatch. Only meaningful when the vehicle actually
  // declares a fuel — a vehicle with nothing configured can't mismatch.
  // EVs resolve to FuelType.electric, which is its own family, so a
  // petrol/diesel selection on an EV trips this too.
  final vehicleFuel = AddFillUpFuelResolver.fuelForVehicle(vehicle);
  if (vehicleFuel != null &&
      fuelCompatibilityFamily(chosenFuel) !=
          fuelCompatibilityFamily(vehicleFuel)) {
    warnings.add(FillUpWarning.fuelEngineMismatch);
  }

  // Odometer monotonicity. The odometer is cumulative distance, so a new
  // reading below the previous one is almost always a typo or a wrong
  // vehicle. Equal readings are allowed (two fills the same day at the
  // same indicated km can happen with rounding); only strictly-below
  // warns.
  if (previousOdometerKm != null && enteredOdometerKm < previousOdometerKm) {
    warnings.add(FillUpWarning.odometerBelowPrevious);
  }

  return warnings;
}

/// The most recent prior real (non-correction) fill-up's odometer for the
/// vehicle [vehicleId], across [allFillUps], strictly before [date] — the
/// baseline the new entry's odometer must not fall below (#2836).
///
/// Mirrors the "previous fill-up" selection the consumption provider uses
/// to close a plein-to-plein window: same vehicle, excludes correction
/// fills, latest date wins. Returns null when the vehicle has no prior
/// real fill-up (the first entry can't go backwards).
double? previousFillUpOdometerKm({
  required String? vehicleId,
  required DateTime date,
  required List<FillUp> allFillUps,
}) {
  if (vehicleId == null) return null;
  FillUp? best;
  for (final f in allFillUps) {
    if (f.vehicleId != vehicleId) continue;
    if (f.isCorrection) continue;
    if (!f.date.isBefore(date)) continue;
    if (best == null || f.date.isAfter(best.date)) best = f;
  }
  return best?.odometerKm;
}
