// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../entities/fill_up.dart';
import '../trip_summary.dart';
import 'trip_consumed_liters.dart';

/// The agreed comparison basis for the guided reconciliation workflow
/// (Epic #2439, child #2440).
///
/// Today the two consumption surfaces (fill-ups vs trajets) don't
/// reconcile, and the legacy silent auto-correction (#1361) makes them
/// diverge MORE. This record is the SINGLE SOURCE OF TRUTH the cross-view
/// invariant test asserts against: it puts both sides of the comparison
/// on the basis the maintainer validated (2026-05-30) so the figures
/// "conclude with the same results".
///
/// The semantics encoded here (Epic decisions #3 + #4):
/// - **Total L honesty** — [fuelTotalLiters] is what the user actually
///   pumped (real fills only); correction litres are NOT folded in.
/// - **Corrections + virtual trips both count on the TRAJETS side** — a
///   correction fill and a virtual trip are each an explicit stand-in for
///   unrecorded burn, so both belong to [trajetsTotalLiters] even though
///   a correction physically lives in the fill-up store.
/// - **Signed [residualLiters]** — `fuelTotal − trajetsTotal`. The hard
///   invariant is `residual == 0` AFTER reconciliation, and
///   `residual == gap` BEFORE any correction/virtual is added.
typedef ReconciliationBasis = ({
  /// Σ real pumped litres — fills where NOT [FillUp.isCorrection].
  /// Mirrors the "Total L" the user sees; correction entries are
  /// excluded so Total L stays honest about what came out of the pump.
  double fuelTotalLiters,

  /// Σ canonical [tripConsumedLiters] (#2447 — measured litres, else the
  /// GPS estimate, else 0) **+** Σ correction-fill litres **+** Σ
  /// virtual-trip litres. The trajets side of the comparison: recorded
  /// burn (counting GPS estimates for null-fuel trips) plus every
  /// explicit stand-in for unrecorded burn.
  double trajetsTotalLiters,

  /// `fuelTotalLiters − trajetsTotalLiters`, signed. `0` once the window
  /// reconciles; equal to the pre-correction gap otherwise. Negative
  /// when the trajets side exceeds real pumped litres (integrator ran
  /// hot, or an over-large virtual/correction was attributed).
  double residualLiters,
});

/// Computes the agreed [ReconciliationBasis] for ONE tank window.
///
/// PURE: inputs in, value out. No repository, no provider, no
/// persistence, no widget — and it does NOT alter detector behaviour or
/// any save path (that stays in #2441). Callers pass the window's fills
/// (including any correction entries) and trips (including any
/// virtual/reconciliation trips); classification is by [FillUp.isCorrection]
/// and the [isVirtualTrip] predicate.
///
/// [isVirtualTrip] defaults to "never virtual". `TripSummary` has no
/// virtual flag yet, so #2444 injects synthetic trips and wires this
/// predicate (e.g. by id-set membership or a future `isVirtual` field)
/// WITHOUT changing this function's contract — the basis math is already
/// correct regardless of how a trip is identified as virtual.
///
/// Both [windowFills] and [windowTrips] are expected to already be scoped
/// to a single tank window by the caller (e.g. via [Reconciler]'s window
/// logic). This function does no windowing of its own — it only classifies
/// and sums.
ReconciliationBasis reconciliationBasis({
  required List<FillUp> windowFills,
  required List<TripSummary> windowTrips,
  bool Function(TripSummary trip) isVirtualTrip = _neverVirtual,
}) {
  var fuelTotal = 0.0;
  var correctionTotal = 0.0;
  for (final fill in windowFills) {
    if (fill.isCorrection) {
      correctionTotal += fill.liters;
    } else {
      fuelTotal += fill.liters;
    }
  }

  var recordedConsumed = 0.0;
  var virtualTotal = 0.0;
  for (final trip in windowTrips) {
    // #2447 — canonical trip litres: a null-fuel GPS/EV trip that still
    // carries a GPS estimate contributes that estimate, not zero, so it
    // no longer under-counts the trajets side against the pump.
    final liters = tripConsumedLiters(trip);
    if (isVirtualTrip(trip)) {
      virtualTotal += liters;
    } else {
      recordedConsumed += liters;
    }
  }

  final trajetsTotal = recordedConsumed + correctionTotal + virtualTotal;
  return (
    fuelTotalLiters: fuelTotal,
    trajetsTotalLiters: trajetsTotal,
    residualLiters: fuelTotal - trajetsTotal,
  );
}

bool _neverVirtual(TripSummary trip) => false;
