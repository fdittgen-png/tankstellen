// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../core/domain/gps_calibration_matrix.dart';
import '../domain/gps_driving_features.dart';
import '../domain/services/gps_fuel_estimator.dart';
import '../domain/services/gps_live_estimate_folder.dart';
import '../domain/trip_recorder.dart';

/// Stop-time fuel backfill for trips without OBD2 fuel-rate coverage —
/// extracted from `GpsOnlyRecordingPipeline` (#3576, 400-line guard).
///
/// Two layers, measured-first:
///  1. #2080/#3252 — the batch estimator: GpsDrivingFeatures over the
///     sample stream + the vehicle's GpsCalibrationMatrix impute
///     `avgLPer100Km`/`fuelLitersConsumed` for gpsOnly trips.
///  2. #3576 — when the batch estimator declines (no features / no
///     estimate), the LIVE GpsLiveEstimateFolder figures the user
///     watched during the drive are persisted onto the ESTIMATED
///     fields (`~`-rendered) instead of saving dashes.
TripSummary backfillGpsTripFuel(
  TripSummary summary, {
  required List<TripSample> samples,
  required GpsCalibrationMatrix? vehicleCalibration,
  required GpsLiveEstimateFolder? liveFolder,
}) {
  var s = summary;
  if (s.kind == TripKind.gpsOnly && s.avgLPer100Km == null) {
    final features = GpsDrivingFeatures.from(samples);
    if (features != null) {
      final matrix = vehicleCalibration ?? GpsCalibrationMatrix.coldStart();
      final est = GpsFuelEstimator.estimate(matrix: matrix, features: features);
      if (est != null) {
        s = s.copyWith(
          avgLPer100Km: est.lPer100Km,
          fuelLitersConsumed: est.lPer100Km * s.distanceKm / 100, // #3252
        );
      }
    }
  }
  if (s.avgLPer100Km == null) {
    s = s.copyWith(
      estimatedAvgLPer100Km: liveFolder?.finalAvgLPer100Km,
      estimatedFuelLitersConsumed: liveFolder?.finalFuelLiters,
    );
  }
  return s;
}
