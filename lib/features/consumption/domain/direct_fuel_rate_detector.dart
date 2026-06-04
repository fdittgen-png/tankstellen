// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../data/trip_history_repository.dart';

/// Detects whether a vehicle reports its fuel rate DIRECTLY (PID 5E or a
/// MAF-derived rate) rather than via the speed-density (η_v) model
/// (#2837).
///
/// When the ECU streams fuel rate directly, the volumetric-efficiency
/// calibration is irrelevant noise: η_v only scales the speed-density
/// branch, never the PID-5E / MAF branch. A real backup showed a car
/// stuck at η_v 1.0 (2 samples, rule calibrator) while reporting
/// FuelRateLPerHour for 40,029 samples — the VE-calibration UI and its
/// "samples" nudge were pure misdirection there. The edit-vehicle screen
/// uses this signal to hide / de-emphasise that UI.
///
/// Signal: a recorded trip's [TripSummary.volumetricEfficiencyUsed] is
/// non-null EXACTLY when every litre was speed-density-derived (#1858).
/// It is null whenever any fuel came from PID 5E or MAF. So a vehicle
/// that has at least one trip which burned real fuel
/// (`fuelLitersConsumed != null`) WITHOUT an η_v stamp
/// (`volumetricEfficiencyUsed == null`) is, by construction, a
/// direct-fuel-rate car — the η_v learner has no influence on its
/// consumption figures.

/// Minimum direct-fuel-rate trips before we treat the vehicle as a
/// confirmed direct-fuel-rate car. One trip could be a fluke (a single
/// MAF tick on an otherwise speed-density car); requiring two trips, OR
/// one trip with a healthy sample count, keeps the de-emphasis honest.
const int _minDirectFuelRateTrips = 2;

/// Whether [trips] (already filtered to a single vehicle, or pass the
/// whole list with [vehicleId]) show the vehicle reporting fuel rate
/// directly (PID 5E / MAF), so the η_v calibration is irrelevant (#2837).
///
/// Counts trips that burned fuel without an η_v stamp. Returns true once
/// at least [_minDirectFuelRateTrips] such trips exist — a stable signal
/// that the car's consumption never leans on the speed-density model.
bool vehicleReportsDirectFuelRate(
  Iterable<TripHistoryEntry> trips, {
  String? vehicleId,
}) {
  var directTrips = 0;
  for (final entry in trips) {
    if (vehicleId != null && entry.vehicleId != vehicleId) continue;
    final s = entry.summary;
    // Fuel was measured, and it did NOT come from the η_v (speed-density)
    // branch → it was a direct PID-5E / MAF reading.
    if (s.fuelLitersConsumed != null &&
        s.fuelLitersConsumed! > 0 &&
        s.volumetricEfficiencyUsed == null) {
      directTrips++;
      if (directTrips >= _minDirectFuelRateTrips) return true;
    }
  }
  return false;
}
