// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/foundation.dart';

import '../entities/fill_up.dart';
import 'physical_tank_windows.dart';

/// Tank-to-tank consumption derived from fill-ups alone (#3645).
///
/// ## Why this exists
///
/// Every refuel hands us the one physically true consumption measurement
/// available to the app: between two FULL fills, the litres pumped (the
/// closing plein plus any partial top-ups in between) are — by
/// construction — exactly what the car burned, and the odometer delta is
/// exactly how far it drove. No integrator drift, no GPS-model bias, and
/// crucially **no dependence on trips being recorded at all**: the pump
/// and the odometer see the unrecorded commute that the trip aggregate
/// misses entirely.
///
/// Before #3645 the tank-level estimator's decay/range average came
/// exclusively from recorded-trip aggregates (hard fallback 7.0), so the
/// gauge and the range drifted whenever recording was incomplete or the
/// integrator ran hot/cold — and the refuel, the moment of ground truth,
/// never corrected it. This service is that correction: the fill itself
/// re-evaluates the tank, "so real und richtig wie möglich".
@immutable
class FillAnchoredConsumption {
  /// km-weighted average across the considered windows:
  /// `totalLiters / totalKm × 100`.
  final double avgLPer100Km;

  /// Number of valid plein-to-plein windows folded in.
  final int windows;

  /// Total odometer kilometres across the considered windows.
  final double totalKm;

  /// Total pumped litres across the considered windows.
  final double totalLiters;

  const FillAnchoredConsumption({
    required this.avgLPer100Km,
    required this.windows,
    required this.totalKm,
    required this.totalLiters,
  });
}

/// Derive the vehicle's true consumption from its fill-up history.
///
/// [fillUps] is the vehicle's fill list in ANY order (the provider hands
/// newest-first; the estimator-history walk uses oldest-first — this
/// function sorts internally so both callers stay simple).
///
/// Window semantics (mirrors the #1361 Reconciler):
/// * a window is `(fullFillₙ, fullFillₙ₊₁]` over consecutive FULL fills;
/// * window litres = closing plein + every non-correction fill strictly
///   inside the window. `isCorrection` entries (#1361) are synthetic
///   book-keeping, not pumped fuel — the closing plein's litres already
///   physically include what they model, so counting them would double
///   the missed consumption;
/// * window km = odometer delta between the two fulls.
///
/// Guards — a window is skipped (never "repaired") when:
/// * either odometer reading is `<= 0` (unset / not captured), or the
///   delta is `<= 0` (typo, odometer reset, same-value quick logs);
/// * the per-window L/100 km falls outside
///   the shared physical-window plausibility bounds.
///
/// Only the most recent [maxWindows] valid windows are averaged, so the
/// figure tracks the car as it drives TODAY (matching the 3–8 fill-up
/// convergence the calibration matrix promises) instead of blending in
/// its whole life. Returns null when no valid window exists — callers
/// fall back rather than receive a fabricated number.
///
/// The stats card and tank report use the same [physicalTankWindows]
/// reconstruction; only their presentation and lookback differ (#4469).
///
/// Compatible single-tank petrol blends remain valid aggregate fuel.
/// Independent fuel families or non-litre quantities cannot establish this
/// litre-based reference; the rejection is available in [physicalTankWindows].
FillAnchoredConsumption? fillAnchoredAvgLPer100Km(
  List<FillUp> fillUps, {
  int maxWindows = 8,
}) {
  if (maxWindows <= 0) return null;
  final windows = physicalTankWindows(fillUps).closed;
  if (windows.isEmpty) return null;
  final recent = windows.skip(
    windows.length > maxWindows ? windows.length - maxWindows : 0,
  );
  final totalKm = recent.fold(0.0, (sum, w) => sum + w.distanceKm);
  final totalLiters = recent.fold(0.0, (sum, w) => sum + w.liters);
  return FillAnchoredConsumption(
    avgLPer100Km: totalLiters / totalKm * 100,
    windows: recent.length,
    totalKm: totalKm,
    totalLiters: totalLiters,
  );
}
