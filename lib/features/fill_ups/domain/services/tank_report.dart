// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Per-tank insight loop (#3616): the latest closed plein-to-plein window
/// as a first-class report — its true pump consumption, the evolution
/// since the previous tank, the recorded-behavior deltas that might
/// EXPLAIN that evolution, and the residual gap between recorded
/// estimates and pump truth.
///
/// Design constraints, straight from the field reality:
///  * Recordings are SPONTANEOUS — they cover whatever slice of the tank
///    the user happened to record. Behavior deltas therefore only ever
///    *suggest* an explanation: they are gated on minimum coverage, on
///    moving in the SAME direction as the consumption delta, and are
///    always accompanied by the coverage figure below
///    [kTankCaveatCoverage].
///  * Window semantics mirror `ConsumptionStats.fromFillUps` (#1362)
///    exactly: a window opens at a plein (or the very first fill), closes
///    at the next plein, litres count every fill strictly after the
///    opening up to and including the closing plein, distance is the
///    odometer delta. Divergent math here would make the two surfaces
///    disagree on the same tank.
///  * Pump truth flows recording-ward already (the η_v learner, #815);
///    this report surfaces the RESIDUAL factor so the user can see how
///    far recorded estimates still sit from the pump.
library;

import '../entities/fill_up.dart';
import '../../../consumption/domain/trip_summary.dart';
import 'tank_behavior.dart';

export 'tank_behavior.dart' show TankBehavior, TankExplanation, TankFactor;


/// Minimum recorded-distance share of a tank before behavior deltas may
/// be offered as explanations at all.
const double kTankExplainMinCoverage = 0.25;

/// Below this coverage every explanation carries the "recordings are
/// partial — indicative only" caveat.
const double kTankCaveatCoverage = 0.8;

/// Minimum coverage before a tank period contributes to the pump-truth
/// calibration factor — a thin slice of recorded driving cannot speak
/// for the whole tank's litres.
const double kTankCalibrationMinCoverage = 0.6;

/// Plausibility bounds for a closed window (guards odometer typos):
/// distance within (3, 3000] km and consumption within (1, 40] L/100km.
bool _plausiblePeriod(double distanceKm, double lPer100Km) =>
    distanceKm > 3 &&
    distanceKm <= 3000 &&
    lPer100Km > 1 &&
    lPer100Km <= 40;

/// One CLOSED plein-to-plein window.
class TankPeriod {
  const TankPeriod({
    required this.opening,
    required this.closing,
    required this.distanceKm,
    required this.liters,
    required this.pumpedCost,
  });

  /// The plein (or very first fill) that opened the window.
  final FillUp opening;

  /// The plein that closed the window — its `linkedTripIds` carry the
  /// window's recordings (#888/#1361).
  final FillUp closing;

  /// Odometer delta opening → closing, km.
  final double distanceKm;

  /// Σ litres of every fill strictly after the opening up to and
  /// including the closing plein (partials + corrections included —
  /// identical to the #1362 walker).
  final double liters;

  /// Σ pumped cost over the same fills (corrections carry cost 0).
  final double pumpedCost;

  /// The tank's true pump consumption.
  double get lPer100Km => liters / distanceKm * 100.0;
}

/// The residual gap between pump truth and recorded estimates, EWMA'd
/// over recent well-covered tank windows.
class PumpCalibration {
  const PumpCalibration({required this.factor, required this.samples});

  /// pump L/100km ÷ recorded L/100km. > 1: recordings under-estimate.
  final double factor;
  final int samples;

  /// Signed percent the recordings deviate from pump truth (positive =
  /// recordings run UNDER the pump).
  double get gapPct => (factor - 1.0) * 100.0;
}

class TankEvolution {
  const TankEvolution({
    required this.current,
    required this.currentBehavior,
    required this.previous,
    required this.previousBehavior,
    required this.explanations,
  });

  final TankPeriod current;
  final TankBehavior currentBehavior;
  final TankPeriod previous;
  final TankBehavior previousBehavior;

  /// Same-direction behavior deltas, highest salience first (the caller
  /// truncates for display). Empty when coverage was too thin on either
  /// side — silence over speculation.
  final List<TankExplanation> explanations;

  double get deltaLPer100Km => current.lPer100Km - previous.lPer100Km;

  /// Whether the explanation lines must carry the partial-coverage
  /// caveat (#3616): recordings below [kTankCaveatCoverage] on either
  /// window tell an incomplete story by construction.
  bool get needsCoverageCaveat =>
      currentBehavior.coverageShare < kTankCaveatCoverage ||
      previousBehavior.coverageShare < kTankCaveatCoverage;
}

class TankReport {
  const TankReport({
    required this.latest,
    required this.latestBehavior,
    required this.evolution,
    required this.calibration,
  });

  static const TankReport empty = TankReport(
    latest: null,
    latestBehavior: TankBehavior.none,
    evolution: null,
    calibration: null,
  );

  /// The most recent closed, plausible window — null when fewer than
  /// two pleins exist (nothing closed yet).
  final TankPeriod? latest;
  final TankBehavior latestBehavior;

  /// Present once TWO closed plausible windows exist.
  final TankEvolution? evolution;

  /// Present once at least one window met the calibration bar.
  final PumpCalibration? calibration;
}

/// Build the report. [fillUps] must already be scoped to one vehicle
/// (the provider layer owns that); [tripSummariesById] resolves the
/// closing pleins' `linkedTripIds`.
TankReport buildTankReport({
  required List<FillUp> fillUps,
  required Map<String, TripSummary> tripSummariesById,
}) {
  if (fillUps.length < 2) return TankReport.empty;
  final sorted = [...fillUps]..sort((a, b) => a.date.compareTo(b.date));

  // Walk the #1362 windows: opening plein/first fill → closing plein.
  final periods = <TankPeriod>[];
  FillUp opening = sorted.first;
  var liters = 0.0, cost = 0.0;
  for (final f in sorted.skip(1)) {
    liters += f.liters;
    if (!f.isCorrection) cost += f.totalCost;
    if (f.isFullTank && !f.isCorrection) {
      final distance = f.odometerKm - opening.odometerKm;
      if (distance > 0) {
        final period = TankPeriod(
          opening: opening,
          closing: f,
          distanceKm: distance,
          liters: liters,
          pumpedCost: cost,
        );
        if (_plausiblePeriod(distance, period.lPer100Km)) {
          periods.add(period);
        }
      }
      opening = f;
      liters = 0.0;
      cost = 0.0;
    }
  }
  if (periods.isEmpty) return TankReport.empty;

  TankBehavior behaviorOf(TankPeriod p) => TankBehavior.fromTrips(
        p,
        p.closing.linkedTripIds
            .map((id) => tripSummariesById[id])
            .whereType<TripSummary>(),
      );

  final latest = periods.last;
  final latestBehavior = behaviorOf(latest);

  TankEvolution? evolution;
  if (periods.length >= 2) {
    final previous = periods[periods.length - 2];
    final previousBehavior = behaviorOf(previous);
    evolution = TankEvolution(
      current: latest,
      currentBehavior: latestBehavior,
      previous: previous,
      previousBehavior: previousBehavior,
      explanations: explainTankDelta(
        deltaLPer100Km: latest.lPer100Km - previous.lPer100Km,
        current: latestBehavior,
        previous: previousBehavior,
      ),
    );
  }

  return TankReport(
    latest: latest,
    latestBehavior: latestBehavior,
    evolution: evolution,
    calibration: _calibration(periods, behaviorOf),
  );
}

/// EWMA (α = 0.4, oldest → newest) of pump/recorded over the last up-to-5
/// windows meeting the calibration bar; implausible ratios (outside
/// [0.5, 2.0] — a broken figure, not a residual) are skipped.
PumpCalibration? _calibration(
  List<TankPeriod> periods,
  TankBehavior Function(TankPeriod) behaviorOf,
) {
  const alpha = 0.4;
  double? ewma;
  var samples = 0;
  final tail = periods.length <= 5
      ? periods
      : periods.sublist(periods.length - 5);
  for (final p in tail) {
    final b = behaviorOf(p);
    final recorded = b.recordedLPer100Km;
    if (recorded == null || b.coverageShare < kTankCalibrationMinCoverage) {
      continue;
    }
    final ratio = p.lPer100Km / recorded;
    if (ratio < 0.5 || ratio > 2.0) continue;
    ewma = ewma == null ? ratio : alpha * ratio + (1 - alpha) * ewma;
    samples++;
  }
  if (ewma == null) return null;
  return PumpCalibration(factor: ewma, samples: samples);
}
