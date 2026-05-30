// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../trip_summary.dart';

/// The SINGLE canonical answer to "how many litres did this trip burn?"
/// (#2447 / Epic #2439).
///
/// Before this helper the trajets side of the fuel⇄trajets comparison was
/// computed THREE different ways that didn't even agree with each other:
///   * [reconciliationBasis] / [Reconciler] summed `fuelLitersConsumed`
///     and treated null as 0,
///   * the Carbon charts ([aggregateByTripLength]) summed
///     `fuelLitersConsumed` and dropped null trips entirely,
///   * the monthly card re-integrated per-tick `fuelRateLPerHour` samples
///     and dropped trips without samples.
///
/// A GPS-only / EV / no-fuel-PID trip has `fuelLitersConsumed == null`
/// in the FIRST two paths, so it contributed ZERO and systematically
/// under-counted the trajets total against the pump — pulling the views
/// apart even before the reconciliation dialog ran.
///
/// Since #2080 (GPS-only pipeline) and #2431/#2438 (OBD2 GPS-estimate
/// fallback) BOTH back-fill `fuelLitersConsumed` from the calibrated
/// GPS-physics estimate at save time, a freshly-recorded fuel-less trip
/// already carries an estimate. But legacy trips recorded before those
/// landed kept `fuelLitersConsumed == null` while still carrying an
/// [TripSummary.avgLPer100Km] estimate, and the estimate↔litres identity
/// (`litres = avgLPer100Km / 100 × distanceKm`, see [GpsFuelEstimator])
/// lets us recover their litres on the fly. Routing every trajets surface
/// through this one helper makes them all count that estimate — and
/// therefore agree with each other and with the fill-up total to within
/// estimate error.

/// A trip's litres if KNOWN, else null — never fabricated.
///
/// Resolution order (first non-null wins):
///   1. [TripSummary.fuelLitersConsumed] — a real measured / already
///      back-filled figure. Used verbatim.
///   2. the GPS-physics estimate recovered from
///      [TripSummary.avgLPer100Km] × [TripSummary.distanceKm] — for
///      legacy fuel-less trips whose litres field was never written but
///      whose average estimate was.
///
/// Returns null only when the trip carries NEITHER a litres figure NOR an
/// average estimate (honest "no data" — e.g. a sub-distance trip the
/// estimator declined, or a pre-#2080 GPS-only trip). Callers that need a
/// summable number use [tripConsumedLiters]; callers that must distinguish
/// "no data" from "zero litres" use this nullable form.
double? tripConsumedLitersOrNull(TripSummary summary) {
  final measured = summary.fuelLitersConsumed;
  if (measured != null) return measured;

  // Recover the litres the estimate implies. avgLPer100Km is itself the
  // GPS-physics estimate (#2080 / #2431); litres = avg/100 × km is the
  // exact inverse of how GpsFuelEstimator produced both figures, so this
  // is the SAME estimate, not a second guess.
  final avg = summary.avgLPer100Km;
  if (avg != null && avg > 0 && summary.distanceKm > 0) {
    return avg / 100.0 * summary.distanceKm;
  }
  return null;
}

/// A trip's litres as a summable double — the canonical trajets-side
/// contribution. Equals [tripConsumedLitersOrNull], with a genuine
/// "no data" trip folding in as 0 (it has no estimate to count).
///
/// This is what every trajets-total surface sums so null-fuel trips that
/// DO carry a GPS estimate contribute that estimate instead of dropping
/// to zero, and so the surfaces agree with each other.
double tripConsumedLiters(TripSummary summary) =>
    tripConsumedLitersOrNull(summary) ?? 0.0;
