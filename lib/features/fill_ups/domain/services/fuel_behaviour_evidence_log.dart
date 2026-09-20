// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../../core/domain/consumption_estimate.dart';
import '../../../../core/domain/data_value.dart';
import '../../../../core/domain/fuel/blend_timeline.dart';
import '../../../../core/domain/fuel/fuel_behaviour_analyzer.dart';
import '../../../../core/domain/fuel/fuel_behaviour_evidence.dart';
import '../../../../core/domain/fuel/fuel_behaviour_profile.dart';
import '../../../../core/domain/fuel/fuel_grade.dart';
import '../../../../core/domain/fuel/tank_blend_engine.dart';
import '../../../../core/domain/fuel_type.dart';
import '../../../../core/domain/money_tally.dart';
import '../../../../core/domain/pump_gain_resolution.dart';
import '../../../../core/domain/vehicle_profile.dart';
import '../../../../core/services/co2_calculator.dart';
import '../../../trips/api.dart';
import '../entities/fill_up.dart';
import 'tank_blend_event_log.dart';
import 'tank_report.dart';

/// Learns [vehicleId]'s [FuelBehaviourProfile] from the recorded history
/// (#4276). Read-only over fill-ups and trips; nothing is persisted, so an
/// edit, a delete or a restart converges on the same profile.
///
/// The blend each trip and window burned is replayed from the same event
/// log `tankBlendProvider` folds (#4279), and the CO2e factors are
/// [ademeWtwCo2eFactor]'s.
FuelBehaviourProfile deriveFuelBehaviourProfile({
  required String vehicleId,
  required VehicleProfile? vehicle,
  required Iterable<FillUp> fillUps,
  required Iterable<TripHistoryEntry> trips,
}) {
  final capacity = vehicle?.tankCapacityL;
  final usable = capacity != null && capacity.isFinite && capacity > 0;
  final engine = TankBlendEngine(tankCapacityLitres: usable ? capacity : null);
  final timeline = BlendTimeline.fold(
    engine,
    tankBlendEventsFor(vehicleId: vehicleId, fillUps: fillUps, trips: trips),
  );
  return FuelBehaviourAnalyzer.analyze(
    timeline: timeline,
    trips: tripFuelEvidenceFor(
        vehicleId: vehicleId, vehicle: vehicle, trips: trips),
    windows: fillWindowEvidenceFor(vehicleId: vehicleId, fillUps: fillUps),
    tankCapacityLitres: usable ? capacity : null,
    co2eFactors: ademeWtwCo2eFactor,
  );
}

/// [vehicleId]'s recorded trips as behaviour evidence (#4276).
///
/// The figure is the one every surface shows — [CalibratedTripFigures]
/// at today's gain for the grade the trip was recorded on — with its
/// source class. No litre is recomputed. Virtual reconciliation trips and
/// engine-off transport are not drives and are left out; a trip without a
/// start time or distance cannot be placed and is left out too.
///
/// Two things are honestly absent today:
///  * `expectedLPer100Km` — no production path stamps a per-trip,
///    blend-independent expectation yet; the fuzzy engine's integration
///    (#4233) is where it comes from. Until then every context reports
///    [ConfounderControl.uncontrolled] or [ConfounderControl.none].
///  * versions — legacy trip figures carry none, and none is invented.
///
/// Conditions: only [DrivingCondition.coldStart] is on the summary
/// (`coldStartSurcharge`); grade and stop-and-go are not. Since #4364
/// that gap is STATED — `observedConditions` names the one condition
/// production evaluates — so the analyzer withholds any
/// condition-adjusted claim instead of implying hills and traffic were
/// accounted for. The uncontrolled observation still ships.
List<TripFuelEvidence> tripFuelEvidenceFor({
  required String vehicleId,
  required VehicleProfile? vehicle,
  required Iterable<TripHistoryEntry> trips,
}) {
  final seen = <String>{};
  final out = <TripFuelEvidence>[];
  for (final entry in trips) {
    if (entry.vehicleId != vehicleId || !seen.add(entry.id)) continue;
    final summary = entry.summary;
    if (summary.isVirtual || isEngineOffTransport(summary)) continue;
    final at = summary.startedAt ?? summary.endedAt;
    if (at == null || !(summary.distanceKm > 0)) continue;
    final figures = CalibratedTripFigures.of(summary, vehicle);
    final source = figures.kind.asConsumptionSourceClass;
    final value = figures.lPer100Km ??
        (figures.kind == TripFuelSourceKind.gps
            ? summary.estimatedAvgLPer100Km
            : null);
    final DataValue<double> figure = value == null || !value.isFinite
        ? const DataValue.unknown(reason: DataUnknownReason.notMeasuredYet)
        : source.isMeasured
            ? DataValue.measured(value)
            : DataValue.estimated(value, basis: DataBasis.derived);
    final key = normalizePumpGainFuelKey(summary.pumpGainFuelKey);
    out.add(TripFuelEvidence(
      id: entry.id,
      at: at,
      distanceKm: summary.distanceKm,
      litresPer100Km: figure,
      sourceClass: source,
      calibrationGrade: source.pumpGainApplies && key != null
          ? FuelGrade.fromKey(key)
          : null,
      conditions: {
        if (summary.coldStartSurcharge) DrivingCondition.coldStart,
      },
      // #4364 — what production actually LOOKED AT. Not the same as the
      // empty set above: "no hills recorded" and "hills never evaluated"
      // must not read alike.
      observedConditions: const {DrivingCondition.coldStart},
    ));
  }
  return out;
}

/// [vehicleId]'s valid full-to-full windows as reference evidence (#4276):
/// the tank report's own walk ([closedTankPeriods]), kept only when the
/// window OPENS on a real full tank — a window opening on the first,
/// partial fill does not know what was already in the tank.
///
/// Strictly attributed: a fill with no vehicle belongs to no vehicle's
/// windows, so one legacy record can never open a window for two cars.
///
/// #4364 — the window's money is SEGREGATED by the currency each fill
/// recorded. A window whose fills span two denominations has no single
/// cost, exactly as a window with a missing price has none.
List<FillWindowEvidence> fillWindowEvidenceFor({
  required String vehicleId,
  required Iterable<FillUp> fillUps,
}) {
  final seen = <String>{};
  final scoped = [
    for (final f in fillUps)
      if (f.vehicleId == vehicleId && seen.add(f.id)) f,
  ];
  bool inside(FillUp f, TankPeriod p) =>
      !f.isCorrection &&
      f.date.isAfter(p.opening.date) &&
      !f.date.isAfter(p.closing.date);
  // A fill without a price makes the window's cost a partial sum, which
  // would read as a cheap tank. Its cost is unknown instead.
  bool fullyPriced(TankPeriod p) =>
      scoped.every((f) => !inside(f, p) || f.totalCost > 0);
  MoneyTally tallyOf(TankPeriod p) => MoneyTally.of([
        for (final f in scoped)
          if (inside(f, p) && f.totalCost > 0) (f.totalCost, f.currency),
      ]);
  return [
    for (final p in closedTankPeriods(scoped))
      if (p.opening.isFullTank &&
          !p.opening.isCorrection &&
          p.closing.date.isAfter(p.opening.date) &&
          p.liters > 0)
        _windowEvidence(p, fullyPriced(p) ? tallyOf(p) : null),
  ];
}

/// One window, with a cost only when [tally] names a single denomination
/// — never a cross-currency sum and never today's currency assumed.
FillWindowEvidence _windowEvidence(TankPeriod p, MoneyTally? tally) {
  final denominable = tally != null && tally.isSingleDenomination;
  return FillWindowEvidence(
    id: p.closing.id,
    openedAt: p.opening.date,
    closedAt: p.closing.date,
    litres: p.liters,
    distanceKm: p.distanceKm,
    pumpedCost: denominable ? tally.soleAmount : null,
    costCurrency: denominable ? (tally.soleCurrency ?? kUnknownCurrency) : null,
  );
}

/// The factors the app ships in [Co2Calculator] (ADEME Base Carbone
/// v23.6, well-to-wheel), stamped with that source, version and
/// boundary so a CO2e figure is traceable (#4219, #4392). Null for a
/// grade the calculator has no per-litre factor for.
Co2eFactor? ademeWtwCo2eFactor(FuelGrade grade) {
  if (!grade.isLiquid) return null;
  final factor = Co2Calculator.emissionFactorFor(FuelType.fromString(grade.key));
  if (factor == null) return null;
  return Co2eFactor(
    kgCo2ePerLitre: factor,
    source: 'ADEME Base Carbone',
    version: 'v23.6-2026',
    boundary: Co2eBoundary.wellToWheel,
  );
}
