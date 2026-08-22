// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../../core/domain/gps_calibration_matrix.dart';
import '../../../../core/domain/vehicle_profile.dart';
import '../trip_recorder.dart'; // TripSample + re-exported TripSummary/TripKind
import 'gps_fuel_estimator.dart';
import 'gps_live_fuel_estimator.dart';

/// Refines a vehicle's [GpsCalibrationMatrix.physicsScale] from an
/// **OBD2 ground-truth trip** (Epic #2385 / #2392, ADR 0012).
///
/// The GPS-only live estimator ([GpsLiveFuelEstimator]) emits a physics
/// road-load L/100 km that is only as good as its class-default body
/// params (mass / Cd / frontal area / Crr). On a trip recorded *with* an
/// OBD2 dongle the measured per-100 km consumption is ground truth, so
/// we can ask: "what would the physics model have predicted for this
/// exact drive?" — by replaying the trip's stored GPS samples through
/// [GpsLiveFuelEstimator] — and nudge `physicsScale` toward
/// `measured / predicted`. That single per-vehicle scalar then carries
/// over to the same vehicle's GPS-only trips (where no dongle is present)
/// so the live number tracks measured reality.
///
/// This service ONLY touches `physicsScale`. It never re-measures the
/// OBD2 fuel (that's the recorder's job and stays the source of truth)
/// and never changes the live estimator's math — it feeds the estimator
/// a better scale.
///
/// ## Update rule (smoothed, clamped)
///
/// A multiplicative EWMA so one noisy trip can't snap the scale around:
///
/// ```
/// ratio    = obd2Avg / physicsPredicted     (predicted incl. current scale)
/// newScale = oldScale × (1 + α·(ratio − 1))
///          = oldScale + α·(oldScale·ratio − oldScale)
/// ```
///
/// with α = [alpha] (0.3 — matches [GpsMatrixReconciler.dampingAlpha]).
/// Because `physicsPredicted` already includes `oldScale`, at steady
/// state `physicsPredicted → obd2Avg`, the ratio → 1, and the scale
/// stops moving — i.e. it converges to `obd2Avg / rawPhysics`. The
/// result is [GpsCalibrationMatrix.clamped] to the
/// `[physicsScaleMin, physicsScaleMax]` band.
///
/// ## Gating (skip degenerate trips)
///
/// [calibrate] returns the matrix **unchanged** (never null) when the
/// trip carries no usable ground truth or signal:
///
/// - not a [TripKind.gpsPlusObd2] trip (GPS-only has no ground truth);
/// - [TripSummary.avgLPer100Km] null or non-positive;
/// - [TripSummary.fuelRateSuspect] (the OBD2 fuel cross-check tripped);
/// - measured average outside the plausibility band;
/// - shorter than [minDistanceKm] or [minDurationSeconds];
/// - fewer than [minSamples] replayable GPS samples, or the replay
///   produced no moving distance (predicted average undefined / ≤ 0).
///
/// Pure: no I/O, no providers. The caller resolves the vehicle + its
/// matrix, calls [calibrate], and persists the returned matrix back via
/// `VehicleProfile.copyWith(gpsCalibration: …)`.
class PhysicsScaleCalibrator {
  const PhysicsScaleCalibrator._();

  /// EWMA smoothing factor — how hard one ground-truth trip tugs the
  /// scale toward the observed ratio. 0.3 ≈ "trust this trip 30 %, the
  /// prior scale 70 %"; ~3 consistent trips close a 30 % gap. Mirrors
  /// `GpsMatrixReconciler.dampingAlpha` so both calibration paths feel
  /// the same.
  static const double alpha = 0.3;

  /// Minimum trip distance (km) worth calibrating from. Shorter trips
  /// are dominated by cold-start enrichment + GPS warm-up noise, so
  /// their measured average is a poor physics target.
  static const double minDistanceKm = 2.0;

  /// Minimum trip duration (s) worth calibrating from.
  static const double minDurationSeconds = 120.0;

  /// Minimum replayable GPS samples — need at least a handful of ticks
  /// for the road-load integral to mean anything.
  static const int minSamples = 10;

  /// Largest sample-to-sample gap (s) still replayed. A longer gap is a
  /// GPS dropout / pause; integrating across it fabricates distance, so
  /// we skip the interval (mirrors the recorder's gap guard).
  static const double _maxGapSeconds = 60.0;

  /// Compute an updated calibration [matrix] for [vehicle] from the
  /// just-completed [summary] + its stored [samples]. Returns the
  /// matrix UNCHANGED when the trip is not a valid ground-truth source
  /// (see the gating list in the class doc) — callers can always persist
  /// the result; it's a no-op when nothing was learned.
  ///
  /// [matrix] may be null (cold-start): the calibrator seeds from
  /// [GpsCalibrationMatrix.coldStart] (physicsScale 1.0) so the first
  /// ground-truth trip still steps a real scale off the default.
  static GpsCalibrationMatrix calibrate({
    required VehicleProfile? vehicle,
    required GpsCalibrationMatrix? matrix,
    required TripSummary summary,
    required List<TripSample> samples,
  }) {
    final base = matrix ?? GpsCalibrationMatrix.coldStart();

    // ─── Ground-truth gating ───
    if (summary.kind != TripKind.gpsPlusObd2) return base;
    if (summary.fuelRateSuspect) return base;
    final obd2Avg = summary.avgLPer100Km;
    if (obd2Avg == null || obd2Avg <= 0) return base;
    if (obd2Avg < GpsFuelEstimator.minLPer100Km ||
        obd2Avg > GpsFuelEstimator.maxLPer100Km) {
      return base;
    }

    // ─── Signal gating ───
    if (summary.distanceKm < minDistanceKm) return base;
    final durationSeconds = _durationSeconds(summary, samples);
    if (durationSeconds < minDurationSeconds) return base;
    if (samples.length < minSamples) return base;

    // ─── Replay the trip through the physics estimator (with the
    // current scale) to get what it WOULD have predicted ───
    final predicted = _replayPredictedAvg(vehicle, base, samples);
    if (predicted == null || predicted <= 0) return base;

    // ─── Smoothed multiplicative EWMA toward measured / predicted ───
    final ratio = obd2Avg / predicted;
    final newScale = base.physicsScale * (1 + alpha * (ratio - 1));

    return base.copyWith(physicsScale: newScale).clamped();
  }

  /// Replay [samples] through a [GpsLiveFuelEstimator] built for
  /// [vehicle] + [matrix] (so the current `physicsScale` is applied) and
  /// return the scaled predicted trip-average L/100 km, or null when the
  /// replay covered no moving distance.
  ///
  /// The estimator integrates litres WITHOUT the scale (see
  /// [GpsLiveFuelEstimator.runningAvgLPer100Km]), so we multiply by the
  /// matrix scale here to make `predicted` comparable to the scaled
  /// instant figure the user actually sees — keeping the EWMA a true
  /// self-correcting residual update.
  static double? _replayPredictedAvg(
    VehicleProfile? vehicle,
    GpsCalibrationMatrix matrix,
    List<TripSample> samples,
  ) {
    final ordered = [...samples]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final estimator = GpsLiveFuelEstimator.forVehicle(vehicle, matrix);

    for (var i = 1; i < ordered.length; i++) {
      final prev = ordered[i - 1];
      final cur = ordered[i];
      final dt =
          cur.timestamp.difference(prev.timestamp).inMilliseconds / 1000.0;
      if (dt <= 0 || dt > _maxGapSeconds) continue; // gap — skip
      estimator.onSample(
        speedMps: cur.speedKmh / 3.6,
        prevSpeedMps: prev.speedKmh / 3.6,
        dtSeconds: dt,
        // Grade is gated off: replaying stored GPS altitude blind is the
        // same noise the live path refuses to feed (ADR 0012). The OBD2
        // ground truth already baked grade into the measured average, so
        // the scale absorbs the systematic part.
      );
    }

    final rawAvg = estimator.runningAvgLPer100Km;
    if (rawAvg == null || rawAvg <= 0) return null;
    return rawAvg * matrix.physicsScale;
  }

  /// Trip duration in seconds — prefers the summary's start/end stamps,
  /// falling back to the sample span when those are absent.
  static double _durationSeconds(
    TripSummary summary,
    List<TripSample> samples,
  ) {
    final start = summary.startedAt;
    final end = summary.endedAt;
    if (start != null && end != null) {
      final s = end.difference(start).inMilliseconds / 1000.0;
      if (s > 0) return s;
    }
    if (samples.length < 2) return 0;
    final ordered = [...samples]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return ordered.last.timestamp
            .difference(ordered.first.timestamp)
            .inMilliseconds /
        1000.0;
  }
}
