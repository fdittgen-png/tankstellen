// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:freezed_annotation/freezed_annotation.dart';

part 'gps_calibration_matrix.freezed.dart';
part 'gps_calibration_matrix.g.dart';

/// Per-vehicle GPS driving-style calibration matrix (ADR 0010 / #2079).
///
/// The lean 4-coefficient linear model that maps GPS-derivable
/// driving features to an estimated L/100 km:
///
/// ```
/// L/100 km = baseline
///          + idleCost          × idleShare
///          + highSpeedPenalty  × highSpeedShare
///          + accelEventCost    × accelEventsPerKm
/// ```
///
/// The matrix is fit per-fill-up via closed-form least-squares from
/// the user's actual GPS-only trajets between fill-ups (#2081). Its
/// maturity ratchets cold → warming → converged as the variance over
/// recent fill-ups narrows (#2082).
///
/// Three additional coefficient slots are reserved for the
/// expand-on-demand 7-coef model (ADR 0010 § "expand-on-demand"):
/// they stay null until the cold maturity persists past 8 fill-ups,
/// at which point the reconciler seeds them and grows the design
/// matrix. Until then the lean fit ignores them.
///
/// All numeric bounds come from ADR 0010 § "feature set" — the
/// reconciler clamps to these to keep a single outlier fill-up from
/// crashing the model into nonsense (e.g. `baseline = 0.1`).
@freezed
abstract class GpsCalibrationMatrix with _$GpsCalibrationMatrix {
  /// Lean-model lower / upper bounds — clamp the reconciler so a
  /// single rogue fill-up can't push the matrix into nonsense.
  static const double baselineMin = 3.0;
  static const double baselineMax = 15.0;
  static const double idleCostMin = 0.0;
  static const double idleCostMax = 5.0;
  static const double highSpeedPenaltyMin = 0.0;
  static const double highSpeedPenaltyMax = 6.0;
  static const double accelEventCostMin = 0.0;
  static const double accelEventCostMax = 3.0;

  /// Population-median seeds for cold-start when no WLTP is set.
  static const double defaultBaselineLPer100Km = 6.5;
  static const double defaultIdleCost = 1.2;
  static const double defaultHighSpeedPenalty = 2.0;
  static const double defaultAccelEventCost = 0.5;

  const factory GpsCalibrationMatrix({
    /// Constant L/100 km term. Seeded from the vehicle's declared
    /// WLTP at cold start, refined per fill-up. Default matches
    /// [defaultBaselineLPer100Km] (literal here because freezed's
    /// generator can't resolve static-const names in `@Default`).
    @Default(6.5) double baseline,

    /// L/100 km penalty per share-of-idle (idle_seconds / total).
    /// Default matches [defaultIdleCost].
    @Default(1.2) double idleCost,

    /// L/100 km penalty per share-of-≥110-km/h. Default matches
    /// [defaultHighSpeedPenalty].
    @Default(2.0) double highSpeedPenalty,

    /// L/100 km penalty per accel-event-per-km. Default matches
    /// [defaultAccelEventCost].
    @Default(0.5) double accelEventCost,

    // ─── Reserved 7-coef expansion slots — null in the lean model ───
    /// Brake event cost (proxy for missed regen / coasting
    /// opportunity). Null until the expand-on-demand trigger fires
    /// (cold maturity + variance > threshold after 8 fill-ups).
    double? brakeEventCost,

    /// Grade-climb cost per 100 m climbed. Null until expansion.
    double? gradeClimbCost,

    /// Corner-load cost per integral unit. Null until expansion.
    double? cornerLoadCost,

    // ─── Reconciliation bookkeeping ───
    /// How many fill-ups have contributed an LSQ update to this
    /// matrix. Drives the maturity tier (cold < 3, warming 3–7,
    /// converged ≥ 8 per ADR 0010).
    @Default(0) int fillUpReconciliationCount,

    /// Mean squared residual over the last 5 fill-up windows
    /// in (L/100 km)². Drives the maturity tier alongside the count.
    @Default(0.0) double residualVariance,

    /// Wall-clock timestamp of the most recent reconciliation, or
    /// null when the matrix has never been refined.
    DateTime? lastReconciledAt,
  }) = _GpsCalibrationMatrix;

  factory GpsCalibrationMatrix.fromJson(Map<String, dynamic> json) =>
      _$GpsCalibrationMatrixFromJson(json);

  /// Cold-start seed from the vehicle's declared WLTP fuel
  /// consumption. Falls back to the population median when [wltp]
  /// is null or out-of-bounds. Other coefficients use the defaults
  /// declared above.
  ///
  /// Per ADR 0010 §"cold-start seeding" — the matrix is created
  /// lazily by [GpsCalibrationMatrix.coldStart] on first GPS-only
  /// trajet, never proactively on vehicle creation.
  factory GpsCalibrationMatrix.coldStart({double? wltp}) {
    final clamped = (wltp != null && wltp >= baselineMin && wltp <= baselineMax)
        ? wltp
        : defaultBaselineLPer100Km;
    return GpsCalibrationMatrix(baseline: clamped);
  }

  const GpsCalibrationMatrix._();

  /// Maturity tier per ADR 0010 §"maturity tier rules".
  /// Drives the A/B/C badge (#2082).
  GpsCalibrationMaturity get maturity {
    if (fillUpReconciliationCount < 3) return GpsCalibrationMaturity.cold;
    if (fillUpReconciliationCount >= 8 && residualVariance <= 0.5) {
      return GpsCalibrationMaturity.converged;
    }
    if (residualVariance <= 1.5) return GpsCalibrationMaturity.warming;
    return GpsCalibrationMaturity.cold;
  }

  /// Apply per-field bounds — called by the reconciler after every
  /// LSQ fit so a wild fill-up can't push the matrix out of the
  /// physically-plausible band.
  GpsCalibrationMatrix clamped() => copyWith(
        baseline: baseline.clamp(baselineMin, baselineMax),
        idleCost: idleCost.clamp(idleCostMin, idleCostMax),
        highSpeedPenalty:
            highSpeedPenalty.clamp(highSpeedPenaltyMin, highSpeedPenaltyMax),
        accelEventCost:
            accelEventCost.clamp(accelEventCostMin, accelEventCostMax),
      );

  /// Whether the 7-coef expansion has been activated yet.
  bool get isExpanded7Coef =>
      brakeEventCost != null &&
      gradeClimbCost != null &&
      cornerLoadCost != null;
}

/// Maturity tier of a [GpsCalibrationMatrix] — drives the badge
/// rendered by #2082 and the trust ceiling on the post-trip L/100 km
/// figure rendered by #2080.
enum GpsCalibrationMaturity {
  /// Fewer than 3 fill-up reconciliations OR variance > 1.5
  /// (L/100 km)² — the prediction is provisional and the UI should
  /// label it as such (~ prefix, "cold" chip).
  cold,

  /// 3–7 reconciliations with variance ≤ 1.5 — predictions are
  /// usable but still warming up. "B" badge.
  warming,

  /// 8+ reconciliations with variance ≤ 0.5 — converged.
  /// "A" badge.
  converged,
}
