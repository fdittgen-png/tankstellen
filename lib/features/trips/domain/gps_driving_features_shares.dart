// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'gps_driving_features.dart';

/// Derived ratio accessors for [GpsDrivingFeatures] (#2796 C7).
///
/// Split out of `gps_driving_features.dart` so the model file stays under
/// the project's 400-line file-length norm: the class holds the raw
/// integrals; this extension exposes the normalised shares the matrix
/// terms + the trip-detail road-use panel read. All guard a degenerate
/// zero-time / zero-distance trajet by returning 0.
extension GpsDrivingFeaturesShares on GpsDrivingFeatures {
  /// Idle share of the trajet (0.0–1.0). Used by the matrix's `idleCost`
  /// term. Returns 0 when the trajet has zero seconds (degenerate stream).
  double get idleShare =>
      totalSeconds > 0 ? idleSeconds / totalSeconds : 0.0;

  /// Low-speed (urban / start-stop) share of the trajet (0.0–1.0, #2796 C7).
  /// The road-use panel surfaces it; the speed band edge (`5 ≤ v < 50`) is
  /// the same one [GpsDrivingFeatures.from] integrates against.
  double get lowSpeedShare =>
      totalSeconds > 0 ? lowSpeedSeconds / totalSeconds : 0.0;

  /// Cruise (extra-urban) share of the trajet (0.0–1.0, #2796 C7). Speed band
  /// edge `50 ≤ v < 110` — matches the integration in
  /// [GpsDrivingFeatures.from].
  double get cruiseShare =>
      totalSeconds > 0 ? cruiseSeconds / totalSeconds : 0.0;

  /// High-speed share (0.0–1.0). Used by the matrix's `highSpeedPenalty`
  /// term.
  double get highSpeedShare =>
      totalSeconds > 0 ? highSpeedSeconds / totalSeconds : 0.0;

  /// Acceleration events per km. Used by the matrix's `accelEventCost`
  /// term. Returns 0 for zero-distance trajets.
  double get accelEventsPerKm =>
      distanceKm > 0 ? accelEvents / distanceKm : 0.0;

  /// Sharp-corner events per km (#2655) — the cornering analogue of
  /// [accelEventsPerKm], normalised so a long calm motorway leg with one
  /// brisk exit ramp doesn't read worse than a short twisty drive.
  /// Returns 0 for zero-distance trajets.
  double get sharpCornersPerKm =>
      distanceKm > 0 ? sharpCornerEvents / distanceKm : 0.0;
}
