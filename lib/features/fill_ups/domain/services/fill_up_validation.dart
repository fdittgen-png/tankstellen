// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/foundation.dart';

import '../../../../core/domain/pump_gain_resolution.dart';
import '../../../../core/domain/vehicle_profile.dart';
import '../../../trips/api.dart';
import 'tank_report.dart';

/// How far a validation can be trusted (#4206).
enum ValidationConfidence { low, medium, high }

/// #4206 — what one valid full-to-full window says about the consumption
/// pipeline end to end: the pump truth, what the recordings claimed before
/// and after calibration, how much of the tank they covered, and the
/// residual that remains. Every number carries what produced it; a window
/// with too little evidence says so instead of manufacturing precision.
///
/// The condition-by-condition attribution #4206 also asks for (how much of
/// the residual is speed, grade, temperature, behaviour) needs the model's
/// EXPECTED consumption, which the fuzzy engine owns (#4232/#4233). This is
/// the validation layer it will be measured against.
@immutable
class FillUpValidation {
  const FillUpValidation({
    required this.fuelKey,
    required this.pumpLiters,
    required this.pumpDistanceKm,
    required this.pumpLPer100Km,
    required this.recordedKm,
    required this.coverageShare,
    required this.gain,
    required this.gainSamples,
    required this.gainSource,
    required this.sourceMix,
    required this.missingSignals,
    this.rawRecordedLPer100Km,
    this.calibratedRecordedLPer100Km,
  });

  /// The grade the window burned (#4202).
  final String fuelKey;

  final double pumpLiters;
  final double pumpDistanceKm;

  /// The authoritative reference: litres ÷ distance × 100.
  final double pumpLPer100Km;

  /// Distance the linked recordings covered, and its share of the window.
  final double recordedKm;
  final double coverageShare;

  /// Recorded consumption with every gain stripped, and re-expressed at the
  /// current gain for [fuelKey]. Null when the recordings carry no fuel.
  final double? rawRecordedLPer100Km;
  final double? calibratedRecordedLPer100Km;

  final double gain;
  final int gainSamples;
  final PumpGainSource gainSource;

  /// How many of the window's recordings were measured / estimated / GPS.
  final Map<TripFuelSourceKind, int> sourceMix;

  /// Why this validation is weaker than it looks (empty when it is not).
  final List<String> missingSignals;

  /// Always the odometer delta — a GPS sum of the same recordings would make
  /// coverage 100 % by construction (#4202).
  String get distanceSource => 'odometer';

  double get uncoveredKm =>
      (pumpDistanceKm - recordedKm).clamp(0, pumpDistanceKm).toDouble();

  /// Calibrated recorded − pump, in L/100 km, and as a percentage.
  double? get residualLPer100Km => calibratedRecordedLPer100Km == null
      ? null
      : calibratedRecordedLPer100Km! - pumpLPer100Km;

  double? get residualPct => calibratedRecordedLPer100Km == null
      ? null
      : (calibratedRecordedLPer100Km! / pumpLPer100Km - 1.0) * 100.0;

  ValidationConfidence get confidence {
    if (calibratedRecordedLPer100Km == null ||
        coverageShare < kTankCalibrationMinCoverage ||
        missingSignals.contains('mixedGrades')) {
      return ValidationConfidence.low;
    }
    if (coverageShare >= 0.85 && gainSamples >= 2) {
      return ValidationConfidence.high;
    }
    return ValidationConfidence.medium;
  }

  Map<String, Object?> toTrace() => {
        'fuelKey': fuelKey,
        'distanceSource': distanceSource,
        'pumpLiters': pumpLiters,
        'pumpDistanceKm': pumpDistanceKm,
        'pumpLPer100Km': pumpLPer100Km,
        'recordedKm': recordedKm,
        'uncoveredKm': uncoveredKm,
        'coverageShare': coverageShare,
        'rawRecordedLPer100Km': rawRecordedLPer100Km,
        'calibratedRecordedLPer100Km': calibratedRecordedLPer100Km,
        'residualLPer100Km': residualLPer100Km,
        'residualPct': residualPct,
        'gain': gain,
        'gainSamples': gainSamples,
        'gainSource': gainSource.name,
        'sourceMix': {
          for (final e in sourceMix.entries) e.key.name: e.value,
        },
        'missingSignals': missingSignals,
        'confidence': confidence.name,
      };

  /// Validate one closed window against its recordings.
  factory FillUpValidation.of(
    TankPeriod period,
    Map<String, TripSummary> tripSummariesById,
    VehicleProfile? vehicle,
  ) {
    final fuelKey = burnedFuelKey(period, tripSummariesById);
    final resolution = resolvePumpGain(vehicle, fuelKey: fuelKey);
    final calibrated =
        calibratedTankRecording(period, tripSummariesById, vehicle);
    final mix = <TripFuelSourceKind, int>{};
    final stampedKeys = <String>{};
    var recordedKm = 0.0, rawLiters = 0.0, engineOff = 0;
    for (final id in period.closing.linkedTripIds) {
      final t = tripSummariesById[id];
      if (t == null || t.isVirtual) continue;
      if (isEngineOffTransport(t)) {
        engineOff++;
        continue;
      }
      final kind = tripFuelSourceKind(t);
      mix[kind] = (mix[kind] ?? 0) + 1;
      final key = normalizePumpGainFuelKey(t.pumpGainFuelKey);
      if (key != null) stampedKeys.add(key);
      final liters = t.fuelLitersConsumed;
      if (liters == null || liters <= 0 || t.distanceKm <= 0) continue;
      rawLiters += liters / tripPumpGainCarried(t); // #4321
      recordedKm += t.distanceKm;
    }
    final missing = <String>[
      if (period.closing.linkedTripIds.isEmpty) 'noRecordings',
      if (recordedKm <= 0) 'noRecordedFuel',
      if (recordedKm > 0 &&
          recordedKm / period.distanceKm < kTankCalibrationMinCoverage)
        'lowCoverage',
      if (stampedKeys.length > 1) 'mixedGrades',
      if (stampedKeys.isEmpty && recordedKm > 0) 'noRecordedGrade',
      if (!resolution.isCalibrated) 'uncalibrated',
      if (engineOff > 0) 'engineOffTransportExcluded',
    ];
    return FillUpValidation(
      fuelKey: fuelKey,
      pumpLiters: period.liters,
      pumpDistanceKm: period.distanceKm,
      pumpLPer100Km: period.lPer100Km,
      recordedKm: recordedKm,
      coverageShare:
          (recordedKm / period.distanceKm).clamp(0.0, 1.0).toDouble(),
      rawRecordedLPer100Km:
          recordedKm > 0 ? rawLiters / recordedKm * 100.0 : null,
      calibratedRecordedLPer100Km: calibrated?.recordedLPer100Km,
      gain: resolution.gain,
      gainSamples: resolution.samples,
      gainSource: resolution.source,
      sourceMix: mix,
      missingSignals: missing,
    );
  }
}
