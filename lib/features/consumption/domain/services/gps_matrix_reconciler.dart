// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../../core/utils/num_extensions.dart';
import '../../../vehicle/domain/entities/gps_calibration_matrix.dart';
import '../gps_driving_features.dart';
import '../gps_driving_features_shares.dart';

/// Refines a [GpsCalibrationMatrix] against the ground truth fuel
/// burn observed at a fill-up (ADR 0010 § "update rule" / #2081 /
/// Epic #2055).
///
/// **Lean MVP** — refines only the `baseline` coefficient on each
/// fill-up window. ADR 0010's full closed-form LSQ on 4 coefficients
/// requires accumulating multiple fill-up windows and solving a
/// 4×4 system; that's a follow-up. The lean version still converges
/// because `baseline` is the dominant term — driving-style
/// coefficients only modulate it by ±20 % in typical patterns.
///
/// Algorithm (per fill-up):
///
/// 1. Sum the matrix's predicted L/100 km across the trajets in the
///    window (weighted by trajet distance).
/// 2. Compare to the actual L/100 km from the fill-up:
///    `actual = litersBurned / totalDistanceKm × 100`.
/// 3. Update baseline by the multiplicative residual with damping
///    alpha = 0.3 — softer steps prevent a single outlier fill-up
///    from yanking the matrix around.
/// 4. Clamp the result to ADR 0010 bounds.
/// 5. Bump `fillUpReconciliationCount`, recompute `residualVariance`
///    on the rolling-5 window, stamp `lastReconciledAt`.
///
/// Pure function — no I/O, no providers. The caller resolves the
/// vehicle, the trajets-in-window, the fuel-up's litres + distance,
/// then writes the returned matrix back via
/// `VehicleProfile.copyWith(gpsCalibration: …)`.
class GpsMatrixReconciler {
  GpsMatrixReconciler._();

  /// EWMA smoothing factor — how aggressively each fill-up tugs the
  /// baseline toward the observed value. 0.3 ≈ "trust the new sample
  /// 30 %, the prior 70 %". Chosen so a single bad fill-up doesn't
  /// dominate; convergence takes ~3 fill-ups for a 30 % drift.
  static const double dampingAlpha = 0.3;

  /// How many fill-up residuals to retain when computing variance.
  /// Matches ADR 0010 § "maturity tier rules" — variance averaged
  /// over the last 5 fill-ups.
  static const int residualWindow = 5;

  /// Apply [actualLitersBurned] over [totalDistanceKm] to [matrix],
  /// weighting against [trajets]. Returns null when the inputs are
  /// degenerate (no distance, no trajets).
  ///
  /// [recentResiduals] is the rolling history of the last
  /// [residualWindow] residuals in (L/100 km)² — passed in so the
  /// caller manages persistence. The returned matrix's
  /// `residualVariance` is recomputed against `[...recentResiduals,
  /// thisResidual]` truncated to the window.
  static GpsCalibrationMatrix? reconcile({
    required GpsCalibrationMatrix matrix,
    required List<GpsDrivingFeatures> trajets,
    required double actualLitersBurned,
    required double totalDistanceKm,
    required List<double> recentResiduals,
    DateTime? now,
  }) {
    if (trajets.isEmpty || totalDistanceKm <= 0 || actualLitersBurned <= 0) {
      return null;
    }

    // Predicted L/100 km per trajet, distance-weighted into a single
    // window-level figure that's comparable to the fill-up's actual.
    double weightedPred = 0;
    double weight = 0;
    for (final t in trajets) {
      if (t.distanceKm <= 0) continue;
      final pred = matrix.baseline +
          matrix.idleCost * t.idleShare +
          matrix.highSpeedPenalty * t.highSpeedShare +
          matrix.accelEventCost * t.accelEventsPerKm;
      weightedPred += pred * t.distanceKm;
      weight += t.distanceKm;
    }
    if (weight <= 0) return null;
    final predicted = weightedPred / weight;
    final actual = actualLitersBurned / totalDistanceKm * 100.0;

    // Multiplicative residual — baseline scales by the ratio of
    // (actual / predicted), softened by the damping factor.
    final ratio = actual / predicted;
    final newBaseline = matrix.baseline * (1 + dampingAlpha * (ratio - 1));

    // Recompute residual-variance window: append the squared
    // (actual - predicted), keep last [residualWindow].
    final residual = actual - predicted;
    final updatedResiduals = [
      ...recentResiduals.skip(
        recentResiduals.length >= residualWindow ? 1 : 0,
      ),
      residual * residual,
    ];
    final variance = updatedResiduals.average;

    return matrix
        .copyWith(
          baseline: newBaseline,
          fillUpReconciliationCount: matrix.fillUpReconciliationCount + 1,
          residualVariance: variance,
          lastReconciledAt: now ?? DateTime.now(),
        )
        .clamped();
  }
}
