// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../../core/domain/gps_calibration_matrix.dart';
import '../../../../core/domain/vehicle_profile.dart';
import '../../data/obd2/trip_live_reading.dart';
import '../driving_coaching.dart'
    show DrivingCoachingHint, gpsCoachingHint, recentSamplesWithin;
import '../road_grade_calculator.dart';
import '../trip_recorder.dart' show TripSample;
import 'gps_live_fuel_estimator.dart';

/// The per-fix GPS-physics estimate + coaching triplet produced by
/// [GpsLiveEstimateFolder.fold] (#2506). All fields are nullable — the
/// estimator returns null at a standstill / before its accel low-pass has
/// warmed up, and the coaching hint is null when no hint applies.
class GpsLiveEstimate {
  const GpsLiveEstimate({
    this.instantLPer100Km,
    this.avgLPer100Km,
    this.fuelLitersSoFar,
    this.coachingHint,
  });

  /// Per-tick instantaneous L/100 km (the estimator's `instantLPer100Km`).
  final double? instantLPer100Km;

  /// Running-average L/100 km (the estimator's `runningAvgLPer100Km`).
  final double? avgLPer100Km;

  /// Running litres burned so far (the estimator's `litersSoFar`), or null
  /// before any litres have accumulated.
  final double? fuelLitersSoFar;

  /// GPS-derived coaching hint over the most recent few seconds, or null.
  final DrivingCoachingHint? coachingHint;

  /// The all-null estimate — what callers use before the first foldable
  /// fix lands.
  static const GpsLiveEstimate none = GpsLiveEstimate();
}

/// Shared GPS-physics live-estimate + coaching folder (#2506).
///
/// Owns the calibrated [GpsLiveFuelEstimator], the finite-diff accel basis
/// (previous fix's speed + timestamp), and the bounded coaching-sample
/// buffer. Both [GpsOnlyRecordingPipeline] and the OBD2
/// `TripRecordingController` feed each GPS-stamped [TripSample] through
/// [fold]; the folder returns the estimate triplet + coaching hint they
/// publish onto the live `TripLiveReading`.
///
/// ## Why this exists
///
/// Before #2506 the GPS-physics estimate (`gpsEstimatedLPer100Km/Avg/
/// FuelLitersSoFar`) and the GPS coaching hint were populated in exactly
/// ONE place — the GPS-only pipeline's `_onPosition` — and never on the
/// OBD2 live path. A car with no measurable fuel-rate PID therefore showed
/// "—" the whole drive live, while at stop the post-trip fallback
/// (`Obd2GpsEstimateFallback`) back-filled the *saved* trip (the
/// "~ estimated" chart). Folding the identical math into a single shared
/// collaborator removes that asymmetry at the root and makes it impossible
/// for the two pipelines to drift apart again — there is only one
/// implementation.
///
/// Pure domain: no I/O, no providers, fully unit-testable.
class GpsLiveEstimateFolder {
  GpsLiveEstimateFolder._({
    required GpsLiveFuelEstimator estimator,
    required Duration coachingWindow,
  })  : _estimator = estimator,
        _coachingWindow = coachingWindow;

  /// Build the folder for [vehicle] + its calibration [matrix]. Both are
  /// nullable — a null vehicle falls back to the population-default class
  /// and petrol fuel params; a null matrix uses physicsScale 1.0 (mirrors
  /// [GpsLiveFuelEstimator.forVehicle]).
  factory GpsLiveEstimateFolder.forVehicle(
    VehicleProfile? vehicle,
    GpsCalibrationMatrix? matrix, {
    Duration coachingWindow = const Duration(seconds: 5),
  }) {
    return GpsLiveEstimateFolder._(
      estimator: GpsLiveFuelEstimator.forVehicle(vehicle, matrix),
      coachingWindow: coachingWindow,
    );
  }

  final GpsLiveFuelEstimator _estimator;
  final Duration _coachingWindow;

  /// Road-grade estimator (#2654) — driven IDENTICALLY to
  /// [BaselineRollingState]: 150 m window, 0.2 exp-smoothing,
  /// minSamplesInWindow=5 confidence gate. Fed the running horizontal
  /// distance + each fix's GPS altitude in [fold]; its confident grade is
  /// passed straight into [GpsLiveFuelEstimator.onSample] so the existing
  /// `m·g·gradeFraction` term (previously always zeroed because the folder
  /// never supplied a grade) finally bites on hilly GPS-only trips.
  final RoadGradeCalculator _gradeCalc = RoadGradeCalculator();

  /// Running horizontal distance (metres) since the first fix — the grade
  /// calculator's window axis. Accumulated from `speedMps · dt` per fold,
  /// mirroring the estimator's own internal distance integral.
  double _cumulativeDistanceM = 0;

  /// Previous fix's ground speed (m/s) + timestamp — the finite-diff basis
  /// the estimator needs for acceleration. Null before the first fix.
  double? _prevSpeedMps;
  DateTime? _prevSampleAt;

  /// Bounded buffer of recent GPS-stamped samples for the coaching hint.
  /// Only the trailing [_coachingWindow] of samples is consulted per fold;
  /// the buffer is trimmed to that tail so it never grows with trip length.
  final List<TripSample> _coachingBuffer = <TripSample>[];

  /// Fold one GPS-stamped [sample] into the estimate + coaching state and
  /// return the new triplet. The sample's `speedKmh` drives the physics;
  /// its `altitudeM` (with the running horizontal distance) drives the
  /// road-grade term (#2654) and feeds the coaching window alongside its
  /// `timestamp`.
  ///
  /// The first fold (no previous fix yet) only seeds the finite-diff basis
  /// (and the grade window's first altitude point) and returns null estimate
  /// figures, matching the GPS-only pipeline's behaviour verbatim.
  GpsLiveEstimate fold(TripSample sample) {
    final speedMps = sample.speedKmh / 3.6;
    double? instant;
    double? avg;
    double? litersSoFar;
    final prevSpeed = _prevSpeedMps;
    final prevAt = _prevSampleAt;
    final dt = prevAt == null
        ? null
        : sample.timestamp.difference(prevAt).inMilliseconds / 1000.0;
    // Advance the running horizontal distance, then fold this fix's
    // altitude in at the new cumulative distance — identical to how
    // BaselineRollingState drives the calculator (#2654). A null altitude
    // adds no point, so confidence never rises and the grade term stays
    // gated off (honest); the first fix seeds the window at distance 0.
    if (dt != null && dt > 0) _cumulativeDistanceM += speedMps * dt;
    _gradeCalc.addSample(
      cumulativeDistanceKm: _cumulativeDistanceM / 1000.0,
      altitudeM: sample.altitudeM,
    );
    final grade = _gradeCalc.current;
    if (prevSpeed != null && dt != null) {
      instant = _estimator.onSample(
        speedMps: speedMps,
        prevSpeedMps: prevSpeed,
        dtSeconds: dt,
        gradeFraction: grade.gradeFraction,
        gradeConfident: grade.confident,
      );
      avg = _estimator.runningAvgLPer100Km;
      final liters = _estimator.litersSoFar;
      litersSoFar = liters > 0 ? liters : null;
    }
    _prevSpeedMps = speedMps;
    _prevSampleAt = sample.timestamp;

    // #2058 / #2174 — coaching hint from the most recent window of
    // samples. recentSamplesWithin scans only a bounded tail, so trimming
    // the buffer to that tail keeps the per-fold cost O(window).
    _coachingBuffer.add(sample);
    final recent = recentSamplesWithin(
      _coachingBuffer,
      _coachingWindow,
      sample.timestamp,
    );
    if (recent.length < _coachingBuffer.length) {
      _coachingBuffer.removeRange(0, _coachingBuffer.length - recent.length);
    }
    final coaching = gpsCoachingHint(recent);

    return GpsLiveEstimate(
      instantLPer100Km: instant,
      avgLPer100Km: avg,
      fuelLitersSoFar: litersSoFar,
      coachingHint: coaching,
    );
  }

  /// #2506 — overlay the GPS-physics estimate onto [base] for the OBD2 live
  /// path. Folds one GPS-stamped sample (built from the effective speed +
  /// GPS altitude) and returns [base] with the
  /// `gpsEstimatedLPer100Km/Avg/FuelLitersSoFar` fields filled, plus the
  /// computed coaching hint for the caller to publish onto
  /// `state.gpsCoachingHint`.
  ///
  /// Pulls the per-tick fold + overlay out of the (god-class)
  /// `TripRecordingController._emit` so both the data and the
  /// divergence-prevention seam live in one place.
  ({TripLiveReading reading, DrivingCoachingHint? coachingHint}) overlay({
    required TripLiveReading base,
    required DateTime now,
    required double effectiveSpeedKmh,
    required double? rpm,
    required double? altitudeM,
  }) {
    final estimate = fold(TripSample(
      timestamp: now,
      speedKmh: effectiveSpeedKmh,
      rpm: rpm ?? 0,
      altitudeM: altitudeM,
    ));
    return (
      reading: base.copyWith(
        gpsEstimatedLPer100Km: estimate.instantLPer100Km,
        gpsEstimatedAvgLPer100Km: estimate.avgLPer100Km,
        gpsEstimatedFuelLitersSoFar: estimate.fuelLitersSoFar,
      ),
      coachingHint: estimate.coachingHint,
    );
  }
}
