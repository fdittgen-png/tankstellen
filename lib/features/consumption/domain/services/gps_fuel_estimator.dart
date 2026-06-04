// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../vehicle/domain/entities/gps_calibration_matrix.dart';
import '../gps_driving_features.dart';
import '../gps_driving_features_shares.dart';

/// Maps GPS-only driving features through a per-vehicle calibration
/// matrix to an estimated L/100 km + total litres for a trajet
/// (ADR 0010 / #2080 / Epic #2055).
///
/// Pure function — no I/O, no providers. The caller resolves the
/// vehicle's matrix (cold-starting it if null) and passes both the
/// matrix and the trip's [GpsDrivingFeatures]; the estimator returns
/// the figures the trip recorder writes back onto [TripSummary] as
/// `avgLPer100Km` + `fuelLitersConsumed`.
///
/// The model is the lean linear form from ADR 0010 § "feature set":
///
/// ```
/// L/100 km = baseline
///          + idleCost          × idleShare
///          + highSpeedPenalty  × highSpeedShare
///          + accelEventCost    × accelEventsPerKm
/// ```
class GpsFuelEstimator {
  GpsFuelEstimator._();

  /// Plausibility bounds on the final figure. Even a wildly-mis-fit
  /// matrix shouldn't produce a number outside this band — saves the
  /// UI from rendering `0.0 L/100 km` or `45 L/100 km` on a stray
  /// outlier trajet (e.g. ~100 m at idle).
  static const double minLPer100Km = 0.5;
  static const double maxLPer100Km = 30.0;

  /// Estimate the trajet's fuel figures from [features] using
  /// [matrix]. Returns null when the features lack distance (a
  /// stationary "trajet" — no fuel math is meaningful).
  ///
  /// First element of the tuple is L/100 km; second is the total
  /// litres burned over the trajet's distance.
  static ({double lPer100Km, double litersConsumed})? estimate({
    required GpsCalibrationMatrix matrix,
    required GpsDrivingFeatures features,
  }) {
    if (features.distanceKm <= 0) return null;
    final raw = matrix.baseline +
        matrix.idleCost * features.idleShare +
        matrix.highSpeedPenalty * features.highSpeedShare +
        matrix.accelEventCost * features.accelEventsPerKm;
    final lPer100Km = raw.clamp(minLPer100Km, maxLPer100Km);
    final liters = lPer100Km * features.distanceKm / 100.0;
    return (lPer100Km: lPer100Km, litersConsumed: liters);
  }
}
