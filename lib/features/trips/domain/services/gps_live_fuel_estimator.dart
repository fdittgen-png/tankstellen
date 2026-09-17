// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import 'package:meta/meta.dart';

import '../../../../core/domain/gps_calibration_matrix.dart';
import '../../../../core/domain/vehicle_profile.dart';
import '../fuzzy_consumption/fuzzy_consumption_engine.dart';
import '../fuzzy_consumption/fuzzy_fuel_rate_stage.dart';
import '../vehicle_road_load_parameters.dart';
import 'gps_fuel_estimator.dart';

/// GPS-only **live** fuel-consumption estimator — a calibrated physics
/// road-load hybrid (Epic #2385 / #2387). Pure domain: no I/O, no
/// providers, fully unit-testable.
///
/// Unlike the lean post-trip [GpsFuelEstimator] (which fits a 4-coef
/// linear model to whole-trajet driving features and can only emit an
/// average), this class consumes one GPS sample per ~1 Hz tick and
/// emits an **instantaneous** L/100 km plus a running average and the
/// litres burned so far. The trip recorder feeds it `_onGpsOnlyPosition`
/// samples; the PiP/banner render its [instantLPer100Km] with the `~`
/// estimated-figure prefix.
///
/// ## The road-load model
///
/// For each tick the tractive force at the wheels is
///
/// ```
/// F = Crr·m·g                       (rolling resistance)
///   + ½·ρ·Cd·A·v²                   (aerodynamic drag, ρ = 1.225 kg/m³)
///   + m·a                           (inertia — a is the low-passed accel)
///   + m·g·grade   (only when grade is confident)
/// ```
///
/// Power `P = max(0, F·v)` (no negative-power credit — coasting/braking
/// just burns idle fuel, it doesn't put fuel back in the tank). Fuel
/// mass-flow combines tractive burn and a constant idle draw:
///
/// ```
/// ṁ [L/s] = P / (η · LHV · 1e6) + idleLPerHour / 3600
/// ```
///
/// Instantaneous L/100 km = ṁ / v · 1e5 · physicsScale, valid only when
/// the vehicle is actually moving (v > 0.5 m/s) — at a standstill the
/// figure is undefined (null) and only the idle litres accumulate.
///
/// ## Calibration & robustness
///
///   * A single per-vehicle [GpsCalibrationMatrix.physicsScale] (#2388)
///     anchors the raw physics to measured ground truth (default 1.0).
///   * Acceleration is the finite difference of speed run through a
///     **3-sample moving-average low-pass** — mandatory to stop GPS
///     speed jitter from injecting phantom inertial spikes into the
///     instant figure.
///   * Both the instant and average figures are clamped to
///     [GpsFuelEstimator.minLPer100Km] / [GpsFuelEstimator.maxLPer100Km]
///     — the same plausibility band the post-trip estimator uses.
class GpsLiveFuelEstimator {
  GpsLiveFuelEstimator._({
    required this._massKg,
    required this._dragCoefficient,
    required this._frontalAreaM2,
    required this._rollingResistance,
    required this._lowerHeatingValueMjPerL,
    required this._engineEfficiency,
    required this._idleLitersPerHour,
    required this._physicsScale,
    required this.parameters,
    required this._engine,
  });

  // ─── Physical constants ───
  static const double _gravity = 9.81; // m/s²
  static const double _airDensity = 1.225; // kg/m³ at sea level, 15 °C
  static const double _moveThresholdMps = 0.5; // below this v is "stopped"
  static const int _accelWindow = 3; // moving-average low-pass length

  // ─── Energy constants — owned by [VehicleRoadLoadParameters] (#4209) ───
  static const double petrolLhvMjPerL =
      VehicleRoadLoadParameters.petrolLhvMjPerL;
  static const double petrolEfficiency =
      VehicleRoadLoadParameters.petrolEfficiency;
  static const double petrolIdleLPerHour =
      VehicleRoadLoadParameters.petrolIdleLPerHour;
  static const double dieselLhvMjPerL =
      VehicleRoadLoadParameters.dieselLhvMjPerL;
  static const double dieselEfficiency =
      VehicleRoadLoadParameters.dieselEfficiency;
  static const double dieselIdleLPerHour =
      VehicleRoadLoadParameters.dieselIdleLPerHour;
  static const double e85LhvMjPerL = VehicleRoadLoadParameters.e85LhvMjPerL;
  static const double lpgLhvMjPerL = VehicleRoadLoadParameters.lpgLhvMjPerL;

  final double _massKg;
  final double _dragCoefficient;
  final double _frontalAreaM2;
  final double _rollingResistance;
  final double _lowerHeatingValueMjPerL;
  final double _engineEfficiency;
  final double _idleLitersPerHour;
  final double _physicsScale;

  /// #4233 — always [kProductionFuzzyEngine] outside tests.
  final FuzzyConsumptionEngine _engine;

  /// #4209 — the parameter set behind every figure, with its provenance,
  /// for the debug trace and the calibration.
  final VehicleRoadLoadParameters parameters;

  // ─── Accumulated state ───
  final List<double> _accelWindowSamples = <double>[];
  double _litersSoFar = 0;
  double _distanceMeters = 0;
  double? _instantLPer100Km;

  /// The most recent tick's instantaneous estimate, clamped to the
  /// plausibility band, or null when the vehicle is stationary (no
  /// meaningful per-distance figure at a standstill) or before the
  /// first moving sample.
  double? get instantLPer100Km => _instantLPer100Km;

  /// Running trip-average L/100 km = litres / distance, clamped to the
  /// plausibility band. Null until the vehicle has covered distance.
  double? get runningAvgLPer100Km {
    final km = _distanceMeters / 1000.0;
    if (km <= 0) return null;
    final raw = _litersSoFar / km * 100.0;
    return raw.clamp(
      GpsFuelEstimator.minLPer100Km,
      GpsFuelEstimator.maxLPer100Km,
    );
  }

  /// Total litres burned across every sample fed so far (tractive +
  /// idle). Never clamped — this is a true running integral.
  double get litersSoFar => _litersSoFar;

  /// Resolve the physics parameters for [vehicle] + its calibration
  /// [matrix] and build a fresh estimator. Both are nullable: a null
  /// vehicle falls back to the population-default class and petrol
  /// fuel params; a null matrix uses physicsScale 1.0.
  factory GpsLiveFuelEstimator.forVehicle(
    VehicleProfile? vehicle,
    GpsCalibrationMatrix? matrix,
  ) =>
      GpsLiveFuelEstimator.withParameters(
        VehicleRoadLoadParameters.resolve(
          curbWeightKg: vehicle?.curbWeightKg,
          preferredFuelType: vehicle?.preferredFuelType,
        ),
        physicsScale: matrix?.physicsScale ?? 1.0,
      );

  /// #4209 — an estimator over an explicit parameter set (sensitivity
  /// analysis, replay with a candidate parameter version).
  ///
  /// [engine] is a test seam only (#4233): production always runs
  /// [kProductionFuzzyEngine].
  factory GpsLiveFuelEstimator.withParameters(
    VehicleRoadLoadParameters parameters, {
    double physicsScale = 1.0,
    @visibleForTesting FuzzyConsumptionEngine engine = kProductionFuzzyEngine,
  }) =>
      GpsLiveFuelEstimator._(
        massKg: parameters.massKg,
        dragCoefficient: parameters.dragCoefficient,
        frontalAreaM2: parameters.frontalAreaM2,
        rollingResistance: parameters.rollingResistance,
        lowerHeatingValueMjPerL: parameters.lowerHeatingValueMjPerL,
        engineEfficiency: parameters.engineEfficiency,
        idleLitersPerHour: parameters.idleLitersPerHour,
        physicsScale: physicsScale,
        parameters: parameters,
        engine: engine,
      );

  /// Fold one GPS sample into the estimate and return the new instant
  /// L/100 km (also exposed via [instantLPer100Km]).
  ///
  ///   * [speedMps]      — current ground speed (m/s).
  ///   * [prevSpeedMps]  — previous tick's speed (m/s); the finite-diff
  ///                       basis for acceleration.
  ///   * [dtSeconds]     — elapsed time since the previous sample (s).
  ///   * [gradeFraction] — road grade as rise/run (e.g. 0.05 = 5 %).
  ///   * [gradeConfident]— whether [gradeFraction] is trustworthy; the
  ///                       grade term is gated off entirely when false
  ///                       (GPS altitude is too noisy to use blindly).
  double? onSample({
    required double speedMps,
    required double prevSpeedMps,
    required double dtSeconds,
    double gradeFraction = 0,
    bool gradeConfident = false,
  }) {
    if (dtSeconds <= 0) return _instantLPer100Km;

    final v = math.max(0.0, speedMps);

    // Raw finite-difference acceleration, then a 3-sample moving-average
    // low-pass to kill GPS speed jitter before it hits the inertial term.
    final rawAccel = (v - math.max(0.0, prevSpeedMps)) / dtSeconds;
    final accel = _lowPassAccel(rawAccel);

    // Tractive force (N).
    final rolling = _rollingResistance * _massKg * _gravity;
    final aero = 0.5 * _airDensity * _dragCoefficient * _frontalAreaM2 * v * v;
    final inertia = _massKg * accel;
    final grade =
        gradeConfident ? _massKg * _gravity * gradeFraction : 0.0;
    final force = rolling + aero + inertia + grade;

    final power = math.max(0.0, force * v); // W

    // Fuel mass-flow (L/s): tractive burn + constant idle draw.
    final tractiveLPerS =
        power / (_engineEfficiency * _lowerHeatingValueMjPerL * 1e6);
    final idleLPerS = _idleLitersPerHour / 3600.0;
    final physicsLPerS = tractiveLPerS + idleLPerS;
    // #4233 — through the fuzzy stage (no pump gain: ADR 0022 §2). Applied
    // as "unchanged → the physics L/s itself" so the L/s ↔ L/h round trip
    // can never move a bit.
    final physicsLPerHour = physicsLPerS * 3600;
    final refinedLPerHour = refinedFuelRateLPerHour(
        physicsLPerHour, FuzzyPhysicsBasis.gpsRoadLoad,
        context: _fuzzyContext(v, accel, gradeFraction, gradeConfident),
        engine: _engine);
    final mdotLPerS = refinedLPerHour == physicsLPerHour
        ? physicsLPerS
        : refinedLPerHour / 3600;

    // Integrate litres + distance.
    _litersSoFar += mdotLPerS * dtSeconds;
    _distanceMeters += v * dtSeconds;

    // Instant figure only meaningful while actually moving.
    if (v > _moveThresholdMps) {
      final raw = mdotLPerS / v * 1e5 * _physicsScale;
      _instantLPer100Km = raw.clamp(
        GpsFuelEstimator.minLPer100Km,
        GpsFuelEstimator.maxLPer100Km,
      );
    } else {
      _instantLPer100Km = null;
    }
    return _instantLPer100Km;
  }

  /// #4233 — this tick's inputs as fuzzy context, all at age 0: speed, the
  /// low-passed accel, the grade only when confident, and the mass only
  /// when it is this vehicle's (a class-prior mass is not evidence).
  FuzzyConsumptionInput _fuzzyContext(
          double v, double accel, double gradeFraction, bool gradeConfident) =>
      FuzzyConsumptionInput(
        speedKmh: FuzzyReading(v * 3.6),
        accelMps2: FuzzyReading(accel),
        gradePercent:
            gradeConfident ? FuzzyReading(gradeFraction * 100) : null,
        vehicleMassKg:
            parameters.massSource == RoadLoadParameterSource.vehicle
                ? FuzzyReading(_massKg)
                : null,
      );

  /// Push [rawAccel] into the moving-average window and return the
  /// smoothed value (mean of the last up-to-[_accelWindow] samples).
  double _lowPassAccel(double rawAccel) {
    _accelWindowSamples.add(rawAccel);
    if (_accelWindowSamples.length > _accelWindow) {
      _accelWindowSamples.removeAt(0);
    }
    final sum = _accelWindowSamples.reduce((a, b) => a + b);
    return sum / _accelWindowSamples.length;
  }
}
