// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';

import '../../../../core/domain/pump_gain_entry.dart';
import '../../../../core/domain/pump_gain_resolution.dart';
import '../../../trips/api.dart' show TripSummary;
import '../../../vehicle/data/repositories/vehicle_profile_repository.dart';
import '../entities/fill_up.dart';
import 'tank_report.dart';

/// Why a fill did NOT calibrate the pump gain (#3917) — surfaced verbatim
/// on the "Bilan du plein" so a skipped window is explained, not silent.
enum PumpGainSkipReason {
  /// A partial fill extends the open window; only a full tank closes it.
  notFullTank,

  /// A synthetic correction is not a pumped fill.
  correction,

  /// The fill carries no vehicle (or an unknown one).
  noVehicle,

  /// No full-to-full window closes on this fill — the first full tank,
  /// or an implausible window (odometer typo).
  noWindow,

  /// Recorded trips cover less than [PumpGainLearner.minCoverage] of
  /// the window's km.
  coverageTooLow,

  /// Fewer than [PumpGainLearner.minRecordedKm] recorded km.
  recordedTooShort,

  /// The linked recordings carry no fuel figure at all.
  noRecordedFuel,

  /// pump ÷ recorded sits outside the bounds by more than
  /// [PumpGainLearner.maxImplausibleRatio] — a typo'd receipt, not a
  /// calibration signal.
  implausibleTarget,
}

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
    this.fuelKey,
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

  /// #3918 — the per-fuel entry the update was keyed under (a multi-fuel
  /// vehicle: the closing fill's `FuelType.apiValue`); null when only the
  /// scalar gain was updated (single-fuel vehicle).
  final String? fuelKey;

  /// Signed change of the estimate this update makes, in percent
  /// (negative = the estimates come down).
  double get changePct => (newGain / previousGain - 1.0) * 100.0;
}

/// Everything one fill taught us (#3917): the calibration when it ran,
/// the reason when it did not, and the window figures either way so the
/// "Bilan du plein" can show the inventory even for a skipped window.
@immutable
class PumpGainOutcome {
  const PumpGainOutcome({
    required this.fuelKey,
    this.result,
    this.skipReason,
    this.period,
    this.coverageShare = 0.0,
    this.recordedKm = 0.0,
    this.rawRecordedLPer100Km,
  });

  /// The closing fill's normalised fuel key.
  final String fuelKey;
  final PumpGainResult? result;
  final PumpGainSkipReason? skipReason;

  /// The closed full-to-full window, when one closes on the fill.
  final TankPeriod? period;
  final double coverageShare;
  final double recordedKm;

  /// Recorded L/100 km with every gain stripped (null without fuel).
  final double? rawRecordedLPer100Km;

  bool get calibrated => result != null;
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
/// #3918 — on a `multiFuelCapable` vehicle the update is keyed by the
/// closing fill's fuel (`pumpGainByFuel`), each grade blending against
/// its own history, and the scalar is blended too as the fallback for a
/// grade without an entry. Single-fuel vehicles keep the scalar only.
///
/// Skipped (returns null, nothing written) when the closing fill is not
/// a full tank, no full-to-full window closes on it, the window's
/// recording coverage is below [minCoverage], the recorded distance is
/// below [minRecordedKm], or the target is outside the bounds by more
/// than [maxImplausibleRatio] (a typo'd receipt / forgotten fill, not a
/// calibration signal). [evaluate] returns the reason (#3917).
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
  }) async =>
      (await evaluate(
        vehicleId: vehicleId,
        closing: closing,
        fillUps: fillUps,
        tripSummariesById: tripSummariesById,
      ))
          .result;

  /// [reconcileAfterFillUp] with the skip reason and the window figures
  /// kept (#3917).
  Future<PumpGainOutcome> evaluate({
    required String vehicleId,
    required FillUp closing,
    required List<FillUp> fillUps,
    required Map<String, TripSummary> tripSummariesById,
  }) async {
    final fuelKey =
        normalizePumpGainFuelKey(closing.fuelType.apiValue) ?? 'unknown';
    PumpGainOutcome skip(PumpGainSkipReason why,
            {TankPeriod? period,
            double coverage = 0.0,
            double recordedKm = 0.0,
            double? raw}) =>
        PumpGainOutcome(
          fuelKey: fuelKey,
          skipReason: why,
          period: period,
          coverageShare: coverage,
          recordedKm: recordedKm,
          rawRecordedLPer100Km: raw,
        );
    if (closing.isCorrection) return skip(PumpGainSkipReason.correction);
    if (!closing.isFullTank) return skip(PumpGainSkipReason.notFullTank);
    final profile = profileRepository.getById(vehicleId);
    if (profile == null) return skip(PumpGainSkipReason.noVehicle);
    final report = buildTankReport(
      fillUps: fillUps,
      tripSummariesById: tripSummariesById,
    );
    final period = report.latest;
    if (period == null || period.closing.id != closing.id) {
      return skip(PumpGainSkipReason.noWindow);
    }

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
    final rawLPer100 =
        recordedKm > 0 ? rawLiters / recordedKm * 100.0 : null;
    if (recordedKm < minRecordedKm) {
      _skip('recorded $recordedKm km');
      return skip(PumpGainSkipReason.recordedTooShort,
          period: period, coverage: coverage, recordedKm: recordedKm, raw: rawLPer100);
    }
    if (coverage < minCoverage) {
      _skip('coverage $coverage');
      return skip(PumpGainSkipReason.coverageTooLow,
          period: period, coverage: coverage, recordedKm: recordedKm, raw: rawLPer100);
    }
    if (rawLPer100 == null || rawLPer100 <= 0) {
      return skip(PumpGainSkipReason.noRecordedFuel,
          period: period, coverage: coverage, recordedKm: recordedKm);
    }
    final target = period.lPer100Km / rawLPer100;
    if (target > maxGain * maxImplausibleRatio ||
        target < minGain / maxImplausibleRatio) {
      _skip('implausible target $target');
      return skip(PumpGainSkipReason.implausibleTarget,
          period: period, coverage: coverage, recordedKm: recordedKm, raw: rawLPer100);
    }
    final now = _now();
    // The scalar always blends — it is the fallback every reader ends on.
    final previousScalar = profile.pumpGain;
    final scalarSamples = profile.pumpGainSamples;
    final ws = blendWeight(scalarSamples);
    final blendedScalar =
        (ws * target + (1 - ws) * previousScalar).clamp(minGain, maxGain);
    var updated = profile.copyWith(
      pumpGain: blendedScalar,
      pumpGainSamples: scalarSamples + 1,
      pumpGainUpdatedAt: now,
    );
    var previous = previousScalar, blended = blendedScalar;
    var samples = scalarSamples;
    String? keyedFuel;
    // #3918 — a multi-fuel vehicle learns per grade on top of that.
    if (profile.multiFuelCapable) {
      final entry = profile.pumpGainByFuel[fuelKey] ?? const PumpGainEntry();
      final we = blendWeight(entry.samples);
      final blendedEntry =
          (we * target + (1 - we) * entry.gain).clamp(minGain, maxGain);
      updated = updated.copyWith(pumpGainByFuel: {
        ...profile.pumpGainByFuel,
        fuelKey: PumpGainEntry(
          gain: blendedEntry,
          samples: entry.samples + 1,
          updatedAt: now,
        ),
      });
      previous = entry.gain;
      blended = blendedEntry;
      samples = entry.samples;
      keyedFuel = fuelKey;
    }
    await profileRepository.save(updated);
    return PumpGainOutcome(
      fuelKey: fuelKey,
      period: period,
      coverageShare: coverage,
      recordedKm: recordedKm,
      rawRecordedLPer100Km: rawLPer100,
      result: PumpGainResult(
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
        fuelKey: keyedFuel,
      ),
    );
  }

  static void _skip(String why) {
    if (kDebugMode) debugPrint('PumpGainLearner: skip — $why');
  }
}
