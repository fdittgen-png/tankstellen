// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import '../../../vehicle/domain/entities/gps_calibration_matrix.dart';
import '../../../vehicle/domain/entities/vehicle_profile.dart';
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
    required double massKg,
    required double dragCoefficient,
    required double frontalAreaM2,
    required double rollingResistance,
    required double lowerHeatingValueMjPerL,
    required double engineEfficiency,
    required double idleLitersPerHour,
    required double physicsScale,
  })  : _massKg = massKg,
        _dragCoefficient = dragCoefficient,
        _frontalAreaM2 = frontalAreaM2,
        _rollingResistance = rollingResistance,
        _lowerHeatingValueMjPerL = lowerHeatingValueMjPerL,
        _engineEfficiency = engineEfficiency,
        _idleLitersPerHour = idleLitersPerHour,
        _physicsScale = physicsScale;

  // ─── Physical constants ───
  static const double _gravity = 9.81; // m/s²
  static const double _airDensity = 1.225; // kg/m³ at sea level, 15 °C
  static const double _moveThresholdMps = 0.5; // below this v is "stopped"
  static const int _accelWindow = 3; // moving-average low-pass length

  // ─── Per-fuel volumetric energy density (LHV, MJ/L) + driveline params ───
  //
  // The energy→litres step `ṁ = P / (η · LHV · 1e6)` divides tractive
  // energy by a *volumetric* lower heating value, so the LHV must match
  // the fuel actually in the tank. Before #2431 this was a binary
  // diesel-vs-petrol branch, which sent E85 (and LPG) down the petrol
  // LHV (31.9 MJ/L): E85 packs ~25.6 MJ/L — ~20 % less energy per litre
  // — so the same tractive work needs ~25 % MORE litres. Scaling an E85
  // trip by the petrol LHV therefore under-counts its litres / Ø by
  // ~20-25 %. This is the energy-path sibling of #2437's AFR/density fix
  // (which corrected the OBD2 air-mass→litres path but not this physics
  // energy→litres path).
  //
  // Sources (volumetric LHV at ~15 °C, commonly cited road-fuel figures):
  //   * petrol  ≈ 31.9–32 MJ/L (kept at the legacy 31.9 so existing
  //     petrol estimates don't shift),
  //   * diesel  ≈ 35.8–36 MJ/L,
  //   * E85     ≈ 25.6 MJ/L (≈85 % ethanol @ 21.2 MJ/L + 15 % petrol),
  //   * LPG     ≈ 26 MJ/L (propane/butane autogas, liquid).
  static const double petrolLhvMjPerL = 31.9;
  static const double petrolEfficiency = 0.28;
  static const double petrolIdleLPerHour = 0.7;
  static const double dieselLhvMjPerL = 35.8;
  static const double dieselEfficiency = 0.34;
  static const double dieselIdleLPerHour = 0.5;

  /// E85 volumetric LHV (#2431). ~85 % ethanol (≈21.2 MJ/L) + ~15 %
  /// petrol → ≈25.6 MJ/L, ~20 % below petrol. Ethanol's higher knock
  /// resistance also lets flex-fuel engines run a touch more efficiently,
  /// but the dominant correction is the lower energy density, so the
  /// efficiency stays at the petrol value and the LHV carries the fix.
  static const double e85LhvMjPerL = 25.6;

  /// LPG / autogas volumetric LHV (#2431). Liquid propane/butane mix
  /// ≈26 MJ/L — also well below petrol. Same efficiency/idle as petrol
  /// (spark-ignition engine); the LHV carries the correction.
  static const double lpgLhvMjPerL = 26.0;

  // ─── Vehicle-class default table (mass / Cd / frontalArea / Crr) ───
  // Resolved by curb weight when a measured mass is available, else the
  // [_classDefault] catch-all row. VehicleType only distinguishes the
  // powertrain (combustion / hybrid / ev) — it carries no body-size
  // class — so the body-load defaults are bucketed by weight instead.
  static const _VehicleClass _compact =
      _VehicleClass(massKg: 1300, cd: 0.30, areaM2: 2.15, crr: 0.012);
  static const _VehicleClass _midsize =
      _VehicleClass(massKg: 1550, cd: 0.30, areaM2: 2.25, crr: 0.012);
  static const _VehicleClass _suv =
      _VehicleClass(massKg: 1900, cd: 0.38, areaM2: 2.80, crr: 0.013);
  static const _VehicleClass _classDefault =
      _VehicleClass(massKg: 1500, cd: 0.32, areaM2: 2.30, crr: 0.012);

  // Curb-weight bucket thresholds (kg) that map a measured mass to a
  // body-load class for Cd / frontal-area / Crr.
  static const int _compactMaxKg = 1450;
  static const int _midsizeMaxKg = 1750;

  final double _massKg;
  final double _dragCoefficient;
  final double _frontalAreaM2;
  final double _rollingResistance;
  final double _lowerHeatingValueMjPerL;
  final double _engineEfficiency;
  final double _idleLitersPerHour;
  final double _physicsScale;

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
  ) {
    final klass = _resolveClass(vehicle?.curbWeightKg);
    final massKg = (vehicle?.curbWeightKg)?.toDouble() ?? klass.massKg;
    final fuel = _resolveFuel(vehicle?.preferredFuelType);
    final scale = matrix?.physicsScale ?? 1.0;
    return GpsLiveFuelEstimator._(
      massKg: massKg,
      dragCoefficient: klass.cd,
      frontalAreaM2: klass.areaM2,
      rollingResistance: klass.crr,
      lowerHeatingValueMjPerL: fuel.lhvMjPerL,
      engineEfficiency: fuel.efficiency,
      idleLitersPerHour: fuel.idleLPerHour,
      physicsScale: scale,
    );
  }

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
    final mdotLPerS = tractiveLPerS + idleLPerS;

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

  /// Map a curb weight (kg) to a body-load class. Null weight → the
  /// population-default catch-all row.
  static _VehicleClass _resolveClass(int? curbWeightKg) {
    if (curbWeightKg == null) return _classDefault;
    if (curbWeightKg <= _compactMaxKg) return _compact;
    if (curbWeightKg <= _midsizeMaxKg) return _midsize;
    return _suv;
  }

  /// Map a [VehicleProfile.preferredFuelType] free-text string to its
  /// fuel-energy + driveline params (#2431). The match order mirrors
  /// [resolveAfrDensity] in `fuel_rate_estimator.dart` (#2437) so the
  /// physics energy→litres path and the OBD2 air-mass→litres path can
  /// never disagree on which fuel a figure is scaled for:
  ///
  ///   * `diesel` (contains, so `"dieselPremium"` matches) → diesel LHV,
  ///   * `e85` / `ethanol` → E85 LHV (the #2431 fix — was petrol before),
  ///   * `lpg` / `autogas` → LPG LHV,
  ///   * everything else (petrol / e10 / super / cng / null / unknown)
  ///     → petrol defaults. CNG has no meaningful volumetric LHV (sold
  ///     by mass), so it takes the petrol default — matching #2437's
  ///     documented "unknown → petrol, safer to under-count" rule.
  static _FuelParams _resolveFuel(String? preferredFuelType) {
    final key = preferredFuelType?.toLowerCase().trim() ?? '';
    if (key.contains('diesel')) {
      return const _FuelParams(
        lhvMjPerL: dieselLhvMjPerL,
        efficiency: dieselEfficiency,
        idleLPerHour: dieselIdleLPerHour,
      );
    }
    if (key.contains('e85') || key.contains('ethanol')) {
      // E85: lower energy density carries the correction; spark-ignition
      // efficiency + idle stay at the petrol values.
      return const _FuelParams(
        lhvMjPerL: e85LhvMjPerL,
        efficiency: petrolEfficiency,
        idleLPerHour: petrolIdleLPerHour,
      );
    }
    if (key.contains('lpg') || key.contains('autogas')) {
      return const _FuelParams(
        lhvMjPerL: lpgLhvMjPerL,
        efficiency: petrolEfficiency,
        idleLPerHour: petrolIdleLPerHour,
      );
    }
    return const _FuelParams(
      lhvMjPerL: petrolLhvMjPerL,
      efficiency: petrolEfficiency,
      idleLPerHour: petrolIdleLPerHour,
    );
  }
}

/// Body-load defaults for one vehicle class.
class _VehicleClass {
  const _VehicleClass({
    required this.massKg,
    required this.cd,
    required this.areaM2,
    required this.crr,
  });

  final double massKg;
  final double cd;
  final double areaM2;
  final double crr;
}

/// Fuel-energy + driveline params for one fuel type.
class _FuelParams {
  const _FuelParams({
    required this.lhvMjPerL,
    required this.efficiency,
    required this.idleLPerHour,
  });

  final double lhvMjPerL;
  final double efficiency;
  final double idleLPerHour;
}
