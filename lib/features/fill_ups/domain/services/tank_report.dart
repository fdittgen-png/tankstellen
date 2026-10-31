// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

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
///    exactly: a window opens at a physical plein, closes
///    at the next plein, litres count every fill strictly after the
///    opening up to and including the closing plein, distance is the
///    odometer delta. Divergent math here would make the two surfaces
///    disagree on the same tank.
///  * Pump truth flows recording-ward already (the η_v learner, #815);
///    this report surfaces the RESIDUAL factor so the user can see how
///    far recorded estimates still sit from the pump.
library;

import '../../../../core/domain/money_tally.dart';
import '../../../../core/domain/pump_gain_resolution.dart';
import '../../../../core/domain/vehicle_profile.dart';
import '../entities/fill_up.dart';
import '../../../trips/api.dart';
import 'tank_behavior.dart';
import 'physical_tank_windows.dart';

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

/// One CLOSED plein-to-plein window.
class TankPeriod {
  /// #4038 — the window carries its own distance invariant. [lPer100Km]
  /// divides by [distanceKm] and is itself used as a divisor by the
  /// residual maths, and a zero divisor on `double` does not throw in
  /// Dart: it yields `Infinity` (or `NaN` for `0/0`), which would reach
  /// the UI as a garbage figure that looks like a real one. Today every
  /// construction site gates on `distance > 0` before calling this; the
  /// asserts keep that guarantee attached to the type, so a construction
  /// site added later inherits it instead of having to remember it.
  const TankPeriod({
    required this.opening,
    required this.closing,
    required this.distanceKm,
    required this.liters,
    required this.pumpedCost,
    this.pumpedSpend = MoneyTally.empty,
    this.hasMixedPhysicalFuel = false,
  }) : assert(distanceKm > 0, 'a tank window needs a positive distance'),
       assert(liters >= 0, 'a tank window cannot consume negative litres');

  /// The physical full tank that opened the window.
  final FillUp opening;

  /// The plein that closed the window — its `linkedTripIds` carry the
  /// window's recordings (#888/#1361).
  final FillUp closing;

  /// Odometer delta opening → closing, km.
  final double distanceKm;

  /// Σ litres of every fill strictly after the opening up to and
  /// including the closing plein. Physical partials count; synthetic
  /// bookkeeping corrections never count as pumped fuel (#4469).
  final double liters;

  /// Σ pumped cost over the same fills (corrections carry cost 0).
  ///
  /// A bare sum that knows no currency — kept for the arithmetic that
  /// predates #4437. Anything SHOWN as money reads [pumpedSpend].
  final double pumpedCost;

  /// The same spend segregated by denomination (#4437): a window that
  /// straddles a foreign fill has no single cost to print, and a settled
  /// foreign fill counts as what the card statement charged. Empty on a
  /// period built by hand (tests), where [pumpedCost] is all there is.
  final MoneyTally pumpedSpend;

  /// A physical partial changed the tank's grade before the closing fill.
  /// Aggregate litres remain valid, but one grade cannot own its calibration.
  final bool hasMixedPhysicalFuel;

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

/// Every closed, plausible plein-to-plein window of [fillUps], oldest
/// first — the shared physical reference (#4469), used by the tank report and fuel
/// behaviour evidence (#4276) so the two can never disagree on a window.
/// [fillUps] must already be scoped to one vehicle.
List<TankPeriod> closedTankPeriods(List<FillUp> fillUps) => [
  for (final window in physicalTankWindows(fillUps).closed)
    TankPeriod(
      opening: window.opening,
      closing: window.closing,
      distanceKm: window.distanceKm,
      liters: window.liters,
      hasMixedPhysicalFuel: window.fills.any(
        (f) =>
            !f.isCorrection &&
            f.id != window.closing.id &&
            f.fuelType != window.opening.fuelType,
      ),
      pumpedCost: window.fills
          .where((f) => !f.isCorrection)
          .fold(0.0, (sum, f) => sum + f.totalCost),
      pumpedSpend: MoneyTally.of([
        for (final f in window.fills)
          if (!f.isCorrection && f.totalCost > 0) f.bookedSpend,
      ]),
    ),
];

/// Build the report. [fillUps] must already be scoped to one vehicle
/// (the provider layer owns that); [tripSummariesById] resolves the
/// closing pleins' `linkedTripIds`.
TankReport buildTankReport({
  required List<FillUp> fillUps,
  required Map<String, TripSummary> tripSummariesById,
}) {
  final periods = closedTankPeriods(fillUps);
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
    if (p.hasMixedPhysicalFuel) continue;
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

/// #3918 — the window's recorded consumption RE-EXPRESSED at [vehicle]'s
/// current pump gain ([CalibratedTripFigures] — display only), and the
/// residual against the pump that remains after that calibration. Null
/// when the recordings carry no fuel.
///
/// #4202 — at the gain of the fuel the window BURNED (the grade its
/// recordings were stamped with, else the opening fill's), never the
/// closing fill's: a tank of E10 followed by an E85 fill is an E10 window.
/// #4202 — the normalised grade a window BURNED: the key its recordings
/// were resolved under (#4220), else the opening fill's fuel. Null-safe for
/// legacy recordings that carry no key.
String burnedFuelKey(
  TankPeriod period,
  Map<String, TripSummary> tripSummariesById,
) {
  final keys = <String>{};
  for (final id in period.closing.linkedTripIds) {
    final key = normalizePumpGainFuelKey(
      tripSummariesById[id]?.pumpGainFuelKey,
    );
    if (key != null) keys.add(key);
  }
  if (keys.length == 1) return keys.single;
  return normalizePumpGainFuelKey(period.opening.fuelType.apiValue) ??
      period.opening.fuelType.apiValue;
}

({double recordedLPer100Km, double residualPct})? calibratedTankRecording(
  TankPeriod period,
  Map<String, TripSummary> tripSummariesById,
  VehicleProfile? vehicle,
) {
  // A known physical blend has no single grade whose gain may restate
  // every linked recording. The card keeps the stored aggregate instead.
  if (period.hasMixedPhysicalFuel) return null;
  var liters = 0.0, km = 0.0;
  final fuelKey = burnedFuelKey(period, tripSummariesById);
  for (final id in period.closing.linkedTripIds) {
    final t = tripSummariesById[id];
    if (t == null || t.isVirtual || isEngineOffTransport(t)) continue;
    final l =
        CalibratedTripFigures.of(t, vehicle, fuelKey: fuelKey).liters ??
        tripConsumedLitersOrNull(t);
    if (l == null || l <= 0 || t.distanceKm <= 0) continue;
    liters += l;
    km += t.distanceKm;
  }
  if (liters <= 0 || km < 5) return null;
  final recorded = liters / km * 100.0;
  return (
    recordedLPer100Km: recorded,
    residualPct: (recorded / period.lPer100Km - 1.0) * 100.0,
  );
}
