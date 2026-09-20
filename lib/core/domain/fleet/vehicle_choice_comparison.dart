// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Comparing the vehicles assigned to an employee for ONE planned
/// journey (#4214, Epic #4211).
///
/// Four numbers per vehicle — L/100 km, cost per km, CO2e per km and
/// range — each a [ClaimedValue], so the answer carries what it may be
/// used for (ADR 0025's claim taxonomy) instead of arriving as a bare
/// double a widget has to remember to qualify. Three rules this file
/// exists to enforce:
///
///  * **an estimate is never promoted to measured** — the claim class
///    comes from the producing branch ([ConsumptionSourceClass] /
///    [MetricBasis]), and `ClaimedValue.derive` degrades a class-2
///    calculation to a class-3 estimate as soon as any input is
///    qualified. A stale measurement is qualified too;
///  * **CO2e is refused without a published factor** — no factor, or a
///    factor in a unit this arithmetic cannot apply, yields `Unknown`
///    under [ClaimClass.environmentalEstimate]. Never `0`, never a
///    neighbour's factor (#4219);
///  * **no verdict** — the outcomes come back in input order with no
///    winner. Cheapest, cleanest and "actually reaches the destination"
///    are different questions, and which one matters is the caller's.
///
/// [VehicleChoiceOutcome.co2eFactor] is exposed so a consumer can read
/// the scope and version it used. **Do not print its citation** until
/// #4392 closes: the seeded values are labelled well-to-wheel and are
/// under review for being tank-to-wheel figures. The registry records
/// the claim the app makes today; it does not vouch for it.
///
/// Pure Dart: no Flutter, no feature imports, no persistence.
library;

import 'package:meta/meta.dart';

import '../consumption_estimate.dart';
import '../data_value.dart';
import '../fuel/behaviour_metric.dart';
import '../fuel/fuel_behaviour_profile.dart';
import '../fuel/fuel_context.dart';
import 'claim_class.dart';
import 'emission_factor_registry.dart';
import 'fleet_provenance.dart';
import 'fleet_refuel_policy.dart';

/// Whether the vehicle reaches the destination on what is in the tank.
enum RangeFeasibility {
  /// The estimated range covers the planned distance.
  sufficient,

  /// It does not — a refuelling stop is part of the journey. Not a
  /// failure: it is the input the refuel decision exists to answer.
  refuelRequired,

  /// The tank level or the consumption is missing, so nobody can say.
  unknown,
}

/// One assigned vehicle, reduced to what the comparison needs (#4214).
///
/// Consumption may arrive two ways and the richer one wins: a
/// [FuelBehaviourProfile] (#4276) carries a *condition-adjusted* figure,
/// the quantity two vehicles may honestly be compared on because hills,
/// cold starts and traffic have been divided out. A
/// [ConsumptionEstimate] (ADR 0022) is the canonical per-trip figure,
/// used when no profile is available.
@immutable
final class FleetVehicleOption {
  const FleetVehicleOption({
    required this.vehicleId,
    required this.fuelKey,
    this.consumption,
    this.behaviour,
    this.behaviourContext,
    this.pricePerLitre,
    this.usableFuelLitres,
  });

  /// The fleet asset's stable id.
  final String vehicleId;

  /// `FuelType.apiValue` — `'diesel'`, `'e10'`, … Matched against the
  /// policy's approved list and the emission registry.
  final String fuelKey;

  /// The canonical consumption figure, when there is one.
  final ConsumptionEstimate? consumption;

  /// Learned per-fuel behaviour, when this vehicle has enough history.
  final FuelBehaviourProfile? behaviour;

  /// Which context of [behaviour] to read — the tank this journey will
  /// be driven on. Null reads nothing: a profile without a named context
  /// says nothing about *this* journey's fuel.
  final FuelContext? behaviourContext;

  /// What a litre costs, as a claim — a [ClaimedValue] rather than a
  /// double because only the caller knows whether this is a price the
  /// employee paid (a measured fact) or a provider's current quote
  /// (third-party asserted, hence an estimate until confirmed, ADR
  /// 0025). Null: no price, so no cost.
  final ClaimedValue<double>? pricePerLitre;

  /// Litres available for this journey, or null when the tank level is
  /// unknown. Whatever reserve the fleet keeps is already subtracted by
  /// the caller — this layer does not invent one.
  final double? usableFuelLitres;
}

/// What one vehicle would cost, burn and emit on the planned journey.
@immutable
final class VehicleChoiceOutcome {
  const VehicleChoiceOutcome({
    required this.vehicleId,
    required this.fuelKey,
    required this.litresPer100Km,
    required this.litresForJourney,
    required this.costPerKm,
    required this.costForJourney,
    required this.co2eKgPerKm,
    required this.rangeKm,
    required this.feasibility,
    this.co2eFactor,
  });

  final String vehicleId;
  final String fuelKey;

  /// The consumption the rest of the row is built on.
  final ClaimedValue<double> litresPer100Km;
  final ClaimedValue<double> litresForJourney;
  final ClaimedValue<double> costPerKm;
  final ClaimedValue<double> costForJourney;

  /// Class 5: `Unknown` when no usable factor is published.
  final ClaimedValue<double> co2eKgPerKm;

  /// The factor actually applied, or null when none was. See the library
  /// doc before printing anything from it (#4392).
  final EmissionFactor? co2eFactor;

  final ClaimedValue<double> rangeKm;
  final RangeFeasibility feasibility;

  @override
  bool operator ==(Object other) =>
      other is VehicleChoiceOutcome &&
      other.vehicleId == vehicleId &&
      other.fuelKey == fuelKey &&
      other.litresPer100Km == litresPer100Km &&
      other.litresForJourney == litresForJourney &&
      other.costPerKm == costPerKm &&
      other.costForJourney == costForJourney &&
      other.co2eKgPerKm == co2eKgPerKm &&
      other.co2eFactor == co2eFactor &&
      other.rangeKm == rangeKm &&
      other.feasibility == feasibility;

  @override
  int get hashCode => Object.hash(vehicleId, fuelKey, litresPer100Km,
      litresForJourney, costPerKm, costForJourney, co2eKgPerKm, co2eFactor,
      rangeKm, feasibility);

  @override
  String toString() => 'VehicleChoiceOutcome($vehicleId, $fuelKey, '
      '$litresPer100Km, ${feasibility.name})';
}

/// The comparison: every eligible vehicle in input order, and why each
/// of the others was left out.
@immutable
final class VehicleChoiceComparison {
  const VehicleChoiceComparison({
    required this.plannedDistanceKm,
    required this.outcomes,
    required this.excluded,
  });

  final double plannedDistanceKm;

  /// Deliberately unranked — see the library doc.
  final List<VehicleChoiceOutcome> outcomes;

  /// Vehicle id → why the policy left it out.
  final Map<String, PolicyExclusion> excluded;
}

/// Compare [vehicles] over [plannedDistanceKm].
///
/// Deterministic: pure arithmetic over the inputs, in input order, with
/// no clock and no ambient state. [registry] and [scope] default to the
/// fleet default (well-to-wheel, ADR 0025 D8); [geography] selects a
/// region-specific factor when the registry publishes one.
///
/// Throws [ArgumentError] when [plannedDistanceKm] is not positive: a
/// journey of no length has no per-km anything, and returning zeroes
/// would be exactly the invented number this slice refuses.
VehicleChoiceComparison compareVehicleChoices({
  required double plannedDistanceKm,
  required Iterable<FleetVehicleOption> vehicles,
  FleetRefuelPolicy policy = const FleetRefuelPolicy(),
  EmissionFactorRegistry registry = EmissionFactorRegistry.ademeBaseCarbone,
  EmissionScope scope = EmissionFactorRegistry.defaultScope,
  String? geography,
}) {
  if (!(plannedDistanceKm > 0) || !plannedDistanceKm.isFinite) {
    throw ArgumentError.value(
        plannedDistanceKm, 'plannedDistanceKm', 'must be positive');
  }
  final outcomes = <VehicleChoiceOutcome>[];
  final excluded = <String, PolicyExclusion>{};
  for (final vehicle in vehicles) {
    if (!policy.permitsFuel(vehicle.fuelKey)) {
      excluded[vehicle.vehicleId] = const PolicyExclusion(
          reason: PolicyExclusionReason.fuelNotApproved);
      continue;
    }
    outcomes.add(_outcomeFor(
      vehicle,
      plannedDistanceKm: plannedDistanceKm,
      registry: registry,
      scope: scope,
      geography: geography,
    ));
  }
  return VehicleChoiceComparison(
    plannedDistanceKm: plannedDistanceKm,
    outcomes: outcomes,
    excluded: excluded,
  );
}

VehicleChoiceOutcome _outcomeFor(
  FleetVehicleOption vehicle, {
  required double plannedDistanceKm,
  required EmissionFactorRegistry registry,
  required EmissionScope scope,
  required String? geography,
}) {
  final consumption = _consumptionClaim(vehicle);
  final litres = ClaimedValue.derive<double>(
    [consumption],
    (v) => (v[0]! as double) / 100 * plannedDistanceKm,
    claim: ClaimClass.calculatedOperational,
  );
  final price = vehicle.pricePerLitre ??
      ClaimedValue<double>.notCalculated(
        reason: DataUnknownReason.notPublishedForThisItem,
        claim: ClaimClass.estimate,
      );
  final costPerKm = ClaimedValue.derive<double>(
    [consumption, price],
    (v) => (v[0]! as double) / 100 * (v[1]! as double),
    claim: ClaimClass.calculatedOperational,
  );
  final factor = _usableFactor(vehicle.fuelKey, registry, scope, geography);
  final co2e = co2eClaim(litres, factor);
  final rangeKm = _rangeClaim(vehicle, consumption);

  return VehicleChoiceOutcome(
    vehicleId: vehicle.vehicleId,
    fuelKey: vehicle.fuelKey,
    litresPer100Km: consumption,
    litresForJourney: litres,
    costPerKm: costPerKm,
    costForJourney: ClaimedValue.derive<double>(
      [costPerKm],
      (v) => (v[0]! as double) * plannedDistanceKm,
      claim: ClaimClass.calculatedOperational,
    ),
    co2eKgPerKm: ClaimedValue.derive<double>(
      [co2e],
      (v) => (v[0]! as double) / plannedDistanceKm,
      claim: ClaimClass.environmentalEstimate,
    ),
    co2eFactor: factor.valueOrNull,
    rangeKm: rangeKm,
    feasibility: switch (rangeKm.valueOrNull) {
      null => RangeFeasibility.unknown,
      final double range when range >= plannedDistanceKm =>
        RangeFeasibility.sufficient,
      _ => RangeFeasibility.refuelRequired,
    },
  );
}

/// The factor for [fuelKey], or `Unknown` when none applies.
///
/// A published factor in a unit this arithmetic cannot use — CNG is
/// cited per kilogram, and a litre is not a kilogram — is refused rather
/// than misapplied. The reason is the registry's own
/// [DataUnknownReason.notPublishedForThisItem]: no per-litre factor is
/// published for this fuel.
DataValue<EmissionFactor> _usableFactor(
  String fuelKey,
  EmissionFactorRegistry registry,
  EmissionScope scope,
  String? geography,
) {
  final found = registry.lookup(fuelKey, scope, geography: geography);
  final factor = found.valueOrNull;
  if (factor == null || factor.unit != EmissionUnit.kgCo2ePerLitre) {
    return const DataValue<EmissionFactor>.unknown(
        reason: DataUnknownReason.notPublishedForThisItem);
  }
  return found;
}

/// The consumption to compare on: the condition-adjusted profile figure
/// first, then the profile's absolute one, then the canonical estimate,
/// then "not measured yet" — stated, never defaulted.
ClaimedValue<double> _consumptionClaim(FleetVehicleOption vehicle) {
  final profile = vehicle.behaviour;
  final context = vehicle.behaviourContext;
  if (profile != null && context != null) {
    final learned = profile.behaviourOf(context);
    if (learned != null) {
      final metric = learned.conditionAdjustedLPer100Km.isKnown
          ? learned.conditionAdjustedLPer100Km
          : learned.lPer100Km;
      if (metric.isKnown) return _fromMetric(metric);
    }
  }
  final estimate = vehicle.consumption;
  if (estimate != null) return _fromEstimate(estimate);
  return ClaimedValue<double>.notCalculated(
    reason: DataUnknownReason.notMeasuredYet,
    claim: ClaimClass.estimate,
  );
}

/// A #4276 metric as a claim. The [MetricBasis] names the branch, and
/// the branch decides the class — a residual or a derived figure is an
/// estimate however tight its interval is.
ClaimedValue<double> _fromMetric(BehaviourMetric metric) {
  final source = switch (metric.basis) {
    MetricBasis.referenceWindows => FleetMetricSource.measuredFillUp,
    MetricBasis.measuredTrips ||
    MetricBasis.measuredResiduals =>
      FleetMetricSource.obdMeasured,
    MetricBasis.estimatedTrips ||
    MetricBasis.estimatedResiduals =>
      FleetMetricSource.obdEstimated,
    MetricBasis.derived || null => FleetMetricSource.derived,
  };
  final modelled = !source.isMeasured;
  return ClaimedValue<double>(
    modelled
        ? Estimated<double>(metric.value!, basis: DataBasis.derived)
        : Measured<double>(metric.value!),
    // Never class 1: an average over windows or trips is arithmetic over
    // observations, not an observation.
    claim: modelled
        ? ClaimClass.estimate
        : ClaimClass.calculatedOperational,
    sampleCount: metric.sampleCount,
    provenance: [source],
  );
}

/// An ADR 0022 figure as a claim. Class 1 only when the branch observed
/// it AND the value is not qualified — a stale or modelled reading is an
/// estimate, which is the promotion #4219 forbids in one expression.
ClaimedValue<double> _fromEstimate(ConsumptionEstimate estimate) {
  final value = estimate.litresPer100Km;
  final source =
      FleetMetricSource.fromConsumptionSourceClass(estimate.sourceClass);
  if (source == null || value is Unknown<double>) {
    return ClaimedValue<double>.notCalculated(
      reason: value is Unknown<double>
          ? value.reason
          : DataUnknownReason.notMeasuredYet,
      claim: ClaimClass.estimate,
    );
  }
  final measured = source.isMeasured && !value.isQualified;
  return ClaimedValue<double>(
    value,
    claim: measured ? ClaimClass.measuredFact : ClaimClass.estimate,
    provenance: [source],
  );
}

/// `litres ÷ (L/100 km) × 100`, or an explicit unknown.
ClaimedValue<double> _rangeClaim(
  FleetVehicleOption vehicle,
  ClaimedValue<double> consumption,
) {
  final litres = vehicle.usableFuelLitres;
  final rate = consumption.valueOrNull;
  if (litres == null || litres < 0 || rate == null || rate <= 0) {
    return ClaimedValue<double>.notCalculated(
      reason: DataUnknownReason.missingVehicleData,
      claim: ClaimClass.estimate,
    );
  }
  return ClaimedValue.derive<double>(
    [consumption],
    (v) => litres / (v[0]! as double) * 100,
    claim: ClaimClass.calculatedOperational,
  );
}
