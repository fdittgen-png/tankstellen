// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';

/// Where one road-load parameter came from (#4209 fallback hierarchy).
enum RoadLoadParameterSource {
  /// Known for THIS vehicle (the profile's curb weight).
  vehicle,

  /// A body-class prior picked from the vehicle's curb weight.
  vehicleClassPrior,

  /// The population default — nothing about this vehicle was known.
  genericDefault,
}

/// How far a parameter set can be trusted.
enum RoadLoadConfidence {
  /// The mass is this vehicle's; the body terms are a class prior.
  medium,

  /// Every term is a population default.
  low,
}

/// The physical parameters of the road-load model, with provenance (#4209).
///
/// Extracted from `GpsLiveFuelEstimator`'s private tables so the estimator,
/// its calibration and the debug trace share ONE parameter set. The values
/// are the ones the GPS-only estimate has shipped since #2387 / #2431 —
/// unchanged. [version] must bump whenever a value changes: every GPS-only
/// estimate AND the learned `physicsScale` are relative to these numbers.
///
/// Fallback hierarchy — vehicle catalogue → user-confirmed → class prior →
/// generic default. The catalogue carries no Cd / frontal area / Crr today
/// and the profile only a curb weight, so the aerodynamic and rolling terms
/// are at best a class prior and are labelled as such: nothing here claims
/// a measurement it does not have.
@immutable
class VehicleRoadLoadParameters {
  const VehicleRoadLoadParameters({
    required this.massKg,
    required this.dragCoefficient,
    required this.frontalAreaM2,
    required this.rollingResistance,
    required this.lowerHeatingValueMjPerL,
    required this.engineEfficiency,
    required this.idleLitersPerHour,
    required this.fuelBasis,
    required this.massSource,
    required this.bodySource,
  });

  /// Bump on ANY value change below (see the class doc).
  static const int version = 1;

  // ─── Per-fuel volumetric energy density (LHV, MJ/L) + driveline ───
  //
  // The energy→litres step `ṁ = P / (η · LHV · 1e6)` divides tractive
  // energy by a VOLUMETRIC lower heating value, so it must match the fuel
  // in the tank (#2431: E85 was once scaled by the petrol LHV and
  // under-counted its litres by ~20-25 %). Commonly cited road-fuel
  // figures at ~15 °C: petrol ≈ 31.9 MJ/L (the legacy value, so petrol
  // estimates never shifted), diesel ≈ 35.8, E85 ≈ 25.6 (≈85 % ethanol at
  // 21.2 + 15 % petrol), LPG ≈ 26.0. E85 and LPG keep the petrol
  // efficiency and idle draw: the LHV carries the correction.
  static const double petrolLhvMjPerL = 31.9;
  static const double petrolEfficiency = 0.28;
  static const double petrolIdleLPerHour = 0.7;
  static const double dieselLhvMjPerL = 35.8;
  static const double dieselEfficiency = 0.34;
  static const double dieselIdleLPerHour = 0.5;
  static const double e85LhvMjPerL = 25.6;
  static const double lpgLhvMjPerL = 26.0;

  /// Curb-weight bucket bounds (kg) mapping a mass to a body class. The
  /// profile's `VehicleType` distinguishes only the powertrain, not a body
  /// size, so the body terms are bucketed by weight.
  static const int compactMaxKg = 1450;
  static const int midsizeMaxKg = 1750;

  final double massKg;
  final double dragCoefficient;
  final double frontalAreaM2;
  final double rollingResistance;
  final double lowerHeatingValueMjPerL;
  final double engineEfficiency;
  final double idleLitersPerHour;

  /// `petrol` / `diesel` / `e85` / `lpg` — the energy basis in use.
  final String fuelBasis;

  final RoadLoadParameterSource massSource;

  /// Source of Cd, frontal area and Crr (never better than a class prior).
  final RoadLoadParameterSource bodySource;

  /// Aerodynamic drag area (m²).
  double get cdA => dragCoefficient * frontalAreaM2;

  RoadLoadConfidence get confidence =>
      massSource == RoadLoadParameterSource.vehicle
          ? RoadLoadConfidence.medium
          : RoadLoadConfidence.low;

  /// Resolve the parameter set for a vehicle's curb weight and fuel.
  factory VehicleRoadLoadParameters.resolve({
    int? curbWeightKg,
    String? preferredFuelType,
  }) {
    final body = _bodyFor(curbWeightKg);
    final fuel = _fuelFor(preferredFuelType);
    final known = curbWeightKg != null;
    return VehicleRoadLoadParameters(
      massKg: curbWeightKg?.toDouble() ?? body.massKg,
      dragCoefficient: body.cd,
      frontalAreaM2: body.areaM2,
      rollingResistance: body.crr,
      lowerHeatingValueMjPerL: fuel.lhv,
      engineEfficiency: fuel.efficiency,
      idleLitersPerHour: fuel.idle,
      fuelBasis: fuel.basis,
      massSource: known
          ? RoadLoadParameterSource.vehicle
          : RoadLoadParameterSource.genericDefault,
      bodySource: known
          ? RoadLoadParameterSource.vehicleClassPrior
          : RoadLoadParameterSource.genericDefault,
    );
  }

  /// A variant for sensitivity analysis; provenance is kept as-is.
  VehicleRoadLoadParameters copyWith({
    double? massKg,
    double? dragCoefficient,
    double? frontalAreaM2,
    double? rollingResistance,
  }) =>
      VehicleRoadLoadParameters(
        massKg: massKg ?? this.massKg,
        dragCoefficient: dragCoefficient ?? this.dragCoefficient,
        frontalAreaM2: frontalAreaM2 ?? this.frontalAreaM2,
        rollingResistance: rollingResistance ?? this.rollingResistance,
        lowerHeatingValueMjPerL: lowerHeatingValueMjPerL,
        engineEfficiency: engineEfficiency,
        idleLitersPerHour: idleLitersPerHour,
        fuelBasis: fuelBasis,
        massSource: massSource,
        bodySource: bodySource,
      );

  /// The debug-trace view: every value with its provenance and version.
  Map<String, Object> toTrace() => {
        'version': version,
        'massKg': massKg,
        'massSource': massSource.name,
        'cd': dragCoefficient,
        'frontalAreaM2': frontalAreaM2,
        'crr': rollingResistance,
        'bodySource': bodySource.name,
        'fuelBasis': fuelBasis,
        'lhvMjPerL': lowerHeatingValueMjPerL,
        'efficiency': engineEfficiency,
        'idleLPerHour': idleLitersPerHour,
        'confidence': confidence.name,
      };

  static ({double massKg, double cd, double areaM2, double crr}) _bodyFor(
      int? curbWeightKg) {
    if (curbWeightKg == null) {
      return (massKg: 1500, cd: 0.32, areaM2: 2.30, crr: 0.012); // default
    }
    if (curbWeightKg <= compactMaxKg) {
      return (massKg: 1300, cd: 0.30, areaM2: 2.15, crr: 0.012); // compact
    }
    if (curbWeightKg <= midsizeMaxKg) {
      return (massKg: 1550, cd: 0.30, areaM2: 2.25, crr: 0.012); // midsize
    }
    return (massKg: 1900, cd: 0.38, areaM2: 2.80, crr: 0.013); // SUV
  }

  /// Free-text fuel → energy basis. The match order mirrors
  /// `resolveAfrDensity` (#2437) so the physics energy path and the OBD2
  /// air-mass path never disagree on which fuel a figure is for; CNG and
  /// unknown fuels take the petrol default (safer to under-count).
  static ({String basis, double lhv, double efficiency, double idle})
      _fuelFor(String? preferredFuelType) {
    final key = preferredFuelType?.toLowerCase().trim() ?? '';
    if (key.contains('diesel')) {
      return (
        basis: 'diesel',
        lhv: dieselLhvMjPerL,
        efficiency: dieselEfficiency,
        idle: dieselIdleLPerHour,
      );
    }
    if (key.contains('e85') || key.contains('ethanol')) {
      return (
        basis: 'e85',
        lhv: e85LhvMjPerL,
        efficiency: petrolEfficiency,
        idle: petrolIdleLPerHour,
      );
    }
    if (key.contains('lpg') || key.contains('autogas')) {
      return (
        basis: 'lpg',
        lhv: lpgLhvMjPerL,
        efficiency: petrolEfficiency,
        idle: petrolIdleLPerHour,
      );
    }
    return (
      basis: 'petrol',
      lhv: petrolLhvMjPerL,
      efficiency: petrolEfficiency,
      idle: petrolIdleLPerHour,
    );
  }
}
