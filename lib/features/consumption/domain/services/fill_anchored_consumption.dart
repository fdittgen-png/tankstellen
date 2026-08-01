// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';

import '../entities/fill_up.dart';

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

/// Per-window plausibility band, in L/100 km. A window outside the band
/// is an odometer typo, a forgotten fill, or a reset — never a reading.
/// The band is deliberately generous (a loaded van uphill is real; a
/// 80 L/100 km "window" is not) so honest outliers survive and data
/// errors do not.
const double _minPlausibleLPer100Km = 1.0;
const double _maxPlausibleLPer100Km = 35.0;

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
///   [_minPlausibleLPer100Km, _maxPlausibleLPer100Km].
///
/// Only the most recent [maxWindows] valid windows are averaged, so the
/// figure tracks the car as it drives TODAY (matching the 3–8 fill-up
/// convergence the calibration matrix promises) instead of blending in
/// its whole life. Returns null when no valid window exists — callers
/// fall back rather than receive a fabricated number.
///
/// Related-but-different: [ConsumptionStats] walks closed plein windows
/// too, with richer semantics (cost, CO₂, correction-litre shares,
/// fuel-type awareness) for the stats card. This service is deliberately
/// the minimal, guard-heavy variant the LIVE tank/range math needs —
/// merging the two walkers is a possible follow-up, not a given.
///
/// Known boundary (same as the estimator's level walk): fuel types are
/// not separated, matching the one-tank-per-vehicle model
/// (`tankCapacityL` is singular). A bi-fuel LPG+petrol vehicle would
/// need per-tank modelling everywhere first.
FillAnchoredConsumption? fillAnchoredAvgLPer100Km(
  List<FillUp> fillUps, {
  int maxWindows = 8,
}) {
  if (fillUps.length < 2) return null;

  final sorted = [...fillUps]..sort((a, b) => a.date.compareTo(b.date));

  // Walk oldest→newest, collecting valid windows; keep only the most
  // recent [maxWindows] of them.
  final windowKm = <double>[];
  final windowLiters = <double>[];

  FillUp? openingFull;
  var pumpedSinceOpening = 0.0;

  for (final f in sorted) {
    if (openingFull == null) {
      if (f.isFullTank && !f.isCorrection) openingFull = f;
      continue;
    }
    if (f.isCorrection) {
      // Synthetic entry — ignored for pumped litres. A correction that
      // is ALSO flagged full-tank must not close a window either: it
      // was never a physical visit to a pump.
      continue;
    }
    pumpedSinceOpening += f.liters;
    if (!f.isFullTank) continue;

    // A full fill closes the window opened by [openingFull].
    final km = f.odometerKm - openingFull.odometerKm;
    final liters = pumpedSinceOpening;
    final valid = openingFull.odometerKm > 0 &&
        f.odometerKm > 0 &&
        km > 0 &&
        liters > 0 &&
        (liters / km * 100) >= _minPlausibleLPer100Km &&
        (liters / km * 100) <= _maxPlausibleLPer100Km;
    if (valid) {
      windowKm.add(km);
      windowLiters.add(liters);
    }
    // Every full fill re-opens the next window regardless of validity —
    // a skipped window must not merge two windows into one giant span.
    openingFull = f;
    pumpedSinceOpening = 0.0;
  }

  if (windowKm.isEmpty) return null;

  final start = windowKm.length > maxWindows ? windowKm.length - maxWindows : 0;
  var totalKm = 0.0;
  var totalLiters = 0.0;
  for (var i = start; i < windowKm.length; i++) {
    totalKm += windowKm[i];
    totalLiters += windowLiters[i];
  }

  return FillAnchoredConsumption(
    avgLPer100Km: totalLiters / totalKm * 100.0,
    windows: windowKm.length - start,
    totalKm: totalKm,
    totalLiters: totalLiters,
  );
}
