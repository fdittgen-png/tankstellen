// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';

import '../../../trips/api.dart' show TripSummary;
import '../../../vehicle/data/repositories/vehicle_profile_repository.dart';
import '../entities/fill_up.dart';
import 'tank_report.dart';

/// Outcome of one [PumpGainLearner.reconcileAfterFillUp] (#3887).
@immutable
class PumpGainResult {
  const PumpGainResult({
    required this.vehicleId,
    required this.previousGain,
    required this.newGain,
    required this.pumpLPer100Km,
    required this.rawRecordedLPer100Km,
    required this.coverageShare,
    required this.sampleCount,
    required this.proposedEta,
  });

  final String vehicleId;
  final double previousGain;
  final double newGain;

  /// The window's pump truth (litres pumped ÷ odometer km × 100).
  final double pumpLPer100Km;

  /// The window's recordings with every gain stripped — what the
  /// estimator produced on its own.
  final double rawRecordedLPer100Km;

  /// Recorded km ÷ window km.
  final double coverageShare;
  final int sampleCount;

  /// The η_v the speed-density branch would need to land on the pump
  /// on its own (`η_v × target`) — the broken-MAP belief's plausibility
  /// input (#1423): far above 1 means the MAP under-reads, not the gain.
  final double proposedEta;

  /// Signed change of the estimate this update makes, in percent
  /// (negative = the estimates come down).
  double get changePct => (newGain / previousGain - 1.0) * 100.0;
}

/// Pump-anchored fuel gain (#3887, Epic #3886) — the pump is the single
/// source of truth for OBD2 consumption.
///
/// Every **full-to-full** tank window hands us one physically true
/// figure: litres pumped ÷ odometer km. The recordings inside that
/// window (the closing plein's `linkedTripIds`) give the estimator's own
/// figure over the km it actually saw. Comparing the two **per km** makes
/// recording coverage cancel out (the 19 % of the tank nobody recorded
/// does not bias the ratio, only lowers its weight), and stripping the
/// gain each trip was recorded with ([TripSummary.pumpGainApplied])
/// recovers the raw estimator output, so the target is absolute:
///
///     target = pumpLPer100Km / rawRecordedLPer100Km
///
/// The gain is blended (sample-dependent weight — the first window is
/// taken at face value, later ones smooth) and bounded to
/// [[minGain], [maxGain]]; it multiplies every ESTIMATED fuel-rate branch
/// (speed-density, MAF) in the live chain and the pull-mode reader, while
/// ECU-reported fuel (PID 5E / 9D) stays untouched. η_v is no longer the
/// compensation knob (the #815 learner mutated it in the wrong direction
/// whenever coverage was partial).
///
/// Skipped (returns null, nothing written) when the closing fill is not
/// a full tank, no full-to-full window closes on it, the window's
/// recording coverage is below [minCoverage], the recorded distance is
/// below [minRecordedKm], or the target is outside the bounds by more
/// than [maxImplausibleRatio] (a typo'd receipt / forgotten fill, not a
/// calibration signal).
class PumpGainLearner {
  PumpGainLearner({
    required this.profileRepository,
    this.minCoverage = kTankCalibrationMinCoverage,
    this.minRecordedKm = 40.0,
    this.minGain = 0.5,
    this.maxGain = 2.0,
    this.maxImplausibleRatio = 3.0,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final VehicleProfileRepository profileRepository;
  final double minCoverage;
  final double minRecordedKm;
  final double minGain;
  final double maxGain;
  final double maxImplausibleRatio;
  final DateTime Function() _now;

  /// Weight of the new target in the blend, by prior sample count: the
  /// first window sets the gain outright, then 0.5, then 0.4 — one odd
  /// tank cannot whipsaw a settled value.
  @visibleForTesting
  static double blendWeight(int samples) {
    if (samples == 0) return 1.0;
    if (samples == 1) return 0.5;
    return 0.4;
  }

  /// Reconcile after [closing] was saved. [fillUps] is the vehicle's
  /// whole fill list (any order); [tripSummariesById] resolves the
  /// closing plein's linked recordings.
  Future<PumpGainResult?> reconcileAfterFillUp({
    required String vehicleId,
    required FillUp closing,
    required List<FillUp> fillUps,
    required Map<String, TripSummary> tripSummariesById,
  }) async {
    if (!closing.isFullTank || closing.isCorrection) return null;
    final profile = profileRepository.getById(vehicleId);
    if (profile == null) return null;
    final report = buildTankReport(
      fillUps: fillUps,
      tripSummariesById: tripSummariesById,
    );
    final period = report.latest;
    if (period == null || period.closing.id != closing.id) return null;

    var recordedKm = 0.0, rawLiters = 0.0;
    for (final id in closing.linkedTripIds) {
      final t = tripSummariesById[id];
      if (t == null || t.isVirtual) continue;
      final liters = t.fuelLitersConsumed;
      if (liters == null || liters <= 0 || t.distanceKm <= 0) continue;
      rawLiters += liters / (t.pumpGainApplied ?? 1.0);
      recordedKm += t.distanceKm;
    }
    final coverage = (recordedKm / period.distanceKm).clamp(0.0, 1.0);
    if (recordedKm < minRecordedKm || coverage < minCoverage) {
      _skip('coverage $coverage / recorded $recordedKm km');
      return null;
    }
    final rawLPer100 = rawLiters / recordedKm * 100.0;
    if (rawLPer100 <= 0) return null;
    final target = period.lPer100Km / rawLPer100;
    if (target > maxGain * maxImplausibleRatio ||
        target < minGain / maxImplausibleRatio) {
      _skip('implausible target $target');
      return null;
    }
    final previous = profile.pumpGain;
    final samples = profile.pumpGainSamples;
    final w = blendWeight(samples);
    final blended = (w * target + (1 - w) * previous).clamp(minGain, maxGain);
    await profileRepository.save(profile.copyWith(
      pumpGain: blended,
      pumpGainSamples: samples + 1,
      pumpGainUpdatedAt: _now(),
    ));
    return PumpGainResult(
      vehicleId: vehicleId,
      previousGain: previous,
      newGain: blended,
      pumpLPer100Km: period.lPer100Km,
      rawRecordedLPer100Km: rawLPer100,
      coverageShare: coverage,
      sampleCount: samples + 1,
      proposedEta: (profile.manualVolumetricEfficiencyOverride ??
              profile.volumetricEfficiency) *
          target,
    );
  }

  static void _skip(String why) {
    if (kDebugMode) debugPrint('PumpGainLearner: skip — $why');
  }
}

