// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Turning one journey and several vehicles into one comparison
/// (#4367, Epic #4358 work package H).
///
/// A pure function over explicit inputs. It reads no provider, no
/// clock and no active vehicle — which is how "changing a comparison
/// column must not switch what the driver is driving" stops being a
/// discipline and becomes a property: there is nothing here that could.
///
/// ## The planner is CALLED, never copied
///
/// Every column's numbers come from [RefuelPlanner.plan] over a request
/// built by [tripPlanRequestFor] — the same function the single-vehicle
/// station planner uses. No reachability walk, no quantity rule, no
/// objective and no tie-break is reimplemented in this file; grep it
/// for arithmetic and what is left is the valuation of burned fuel and
/// the choice of a winner.
///
/// ## What differs between columns, and what may not
///
/// The journey is one object shared by every column. The candidate
/// list, the capacity, the level, the reserve, the consumption and the
/// fuel are per column, because those are the vehicle. A candidate list
/// is passed in per vehicle precisely because a station that does not
/// sell THIS car's fuel is not a stop for it, and because two cars on
/// one road legitimately see two different sets of prices.
library;

import 'comparison_eligibility.dart';
import 'data_value.dart';
import 'money.dart';
import 'refuel_plan.dart';
import 'refuel_planner.dart';
import 'vehicle_trip_comparison.dart';

export 'vehicle_trip_comparison.dart';

/// One vehicle's basis together with the stops IT may use.
class VehicleTripInput {
  const VehicleTripInput({
    required this.basis,
    this.candidates = const [],
    this.evidenceIncomplete = false,
    this.excludedForCurrency = false,
  });

  final VehicleTripBasis basis;

  /// Stops allowed for this vehicle's fuel, already normalised into the
  /// journey's currency (#4361) and already stripped of hard
  /// exclusions (#4362). Soft display filters never reach here.
  final List<PlanCandidate> candidates;

  final bool evidenceIncomplete;
  final bool excludedForCurrency;
}

/// Build the same-trip comparison for [inputs] over [key]'s journey.
///
/// [inputs] is in the driver's selection order and that order is kept;
/// the cache identity is [key], whose vehicle half is #4365's
/// normalised [VehicleComparisonKey].
VehicleTripComparison buildVehicleTripComparison({
  required VehicleTripComparisonKey key,
  required DateTime asOf,
  required List<VehicleTripInput> inputs,
  String? referenceVehicleId,
  Iterable<String> missingVehicleIds = const [],
}) {
  final journey = key.journey;
  final columns = [
    for (final input in inputs) _column(journey, input),
  ];
  final reference = referenceVehicleId != null &&
          columns.any((c) => c.vehicleId == referenceVehicleId)
      ? referenceVehicleId
      : (columns.isEmpty ? null : columns.first.vehicleId);

  return VehicleTripComparison(
    key: key,
    asOf: asOf,
    columns: columns,
    referenceVehicleId: reference,
    lowestCostToDrive:
        _moneyWinner(columns, (c) => c.costToDrive),
    lowestCashRequired:
        _moneyWinner(columns, (c) => c.cashRequired),
    shortestTime: _numberWinner(columns, (c) => c.totalMinutes),
    missingVehicleIds: missingVehicleIds,
  );
}

/// One column: plan this vehicle's journey, then value it.
VehicleTripColumn _column(VehicleTripJourney journey, VehicleTripInput input) {
  final basis = input.basis;
  final quals = <ComparisonQualification>{
    // A forecast is a model even when its consumption was measured:
    // the drive has not happened yet.
    ComparisonQualification.estimatedBasis,
    ...basis.qualifications,
    if (basis.isManual && basis.consumptionSource != TripInputSource.manual)
      ComparisonQualification.mixedProvenance,
    if (input.evidenceIncomplete) ComparisonQualification.excludedRecords,
    if (input.excludedForCurrency) ComparisonQualification.excludedRecords,
  };

  final request = tripPlanRequestFor(journey, basis, input.candidates);
  if (request == null) {
    // Nothing may be planned for this vehicle. The road's own duration
    // is still a fact, so it is reported — qualified, and excluded from
    // every ranking by [_numberWinner], because a column with no plan
    // must never become the guaranteed-fastest entry.
    final reason = basis.blocker ?? ComparisonUnavailableReason.noEvidence;
    return VehicleTripColumn(
      basis: basis,
      unavailable: reason,
      fuelUsedLitres: ComparableMetric<double>.unavailable(reason),
      costToDrive: ComparableMetric<Money>.unavailable(reason),
      cashRequired: ComparableMetric<Money>.unavailable(reason),
      stopCount: ComparableMetric<double>.unavailable(reason),
      extraKm: ComparableMetric<double>.unavailable(reason),
      totalMinutes: journey.isComputable
          ? ComparableMetric<double>.qualified(
              DataValue<double>.estimated(journey.drivingMinutes,
                  basis: DataBasis.derived),
              qualifications: const {ComparisonQualification.estimatedBasis},
            )
          : ComparableMetric<double>.unavailable(reason),
      endLitres: ComparableMetric<double>.unavailable(reason),
      evidenceIncomplete: input.evidenceIncomplete,
      excludedForCurrency: input.excludedForCurrency,
      qualifications: quals,
    );
  }

  final plans = RefuelPlanner.plan(request);
  final plan = _planFor(plans, journey.objective);
  if (plan == null) {
    // The planner could not drive this vehicle over the route. Its gap
    // is the answer; the route's bare fuel need stays valid arithmetic
    // and is reported as the estimate it is.
    const noPlan = ComparisonUnavailableReason.noEvidence;
    return VehicleTripColumn(
      basis: basis,
      plans: plans,
      gap: plans.gap,
      unavailable: plans.gap == null ? noPlan : null,
      fuelUsedLitres: ComparableMetric<double>.qualified(
        DataValue<double>.estimated(request.litresFor(journey.routeKm),
            basis: DataBasis.derived),
        qualifications: const {ComparisonQualification.estimatedBasis},
      ),
      costToDrive: ComparableMetric<Money>.unavailable(noPlan),
      cashRequired: ComparableMetric<Money>.unavailable(noPlan),
      stopCount: ComparableMetric<double>.unavailable(noPlan),
      extraKm: ComparableMetric<double>.unavailable(noPlan),
      totalMinutes: ComparableMetric<double>.unavailable(noPlan),
      endLitres: ComparableMetric<double>.unavailable(noPlan),
      searchWasBounded: plans.searchWasBounded,
      evidenceIncomplete: input.evidenceIncomplete,
      excludedForCurrency: input.excludedForCurrency,
      qualifications: quals,
    );
  }

  final currency = journey.currencyCode;
  // The one price this vehicle's burned fuel is valued at: the best
  // price for ITS fuel on THIS route. Null when no station on the road
  // sells it — and then there is no cost to drive, not a free drive.
  final valuation = plans.valuationPricePerLitre;
  final costToDrive = valuation == null
      ? ComparableMetric<Money>.unavailable(
          ComparisonUnavailableReason.missingPrices)
      : ComparableMetric<Money>.qualified(
          DataValue<Money>.estimated(
            Money(plan.consumedLitres * valuation, currency),
            basis: DataBasis.derived,
          ),
          qualifications: quals,
        );

  return VehicleTripColumn(
    basis: basis,
    plans: plans,
    plan: plan,
    objectives: plans.objectivesFor(plan),
    stationIds: [for (final stop in plan.stops) stop.candidate.stationId],
    fuelUsedLitres: _estimate(plan.consumedLitres, quals),
    costToDrive: costToDrive,
    cashRequired: ComparableMetric<Money>.qualified(
      DataValue<Money>.estimated(
        Money(plan.totalCost, currency),
        basis: DataBasis.derived,
      ),
      qualifications: quals,
    ),
    stopCount: _estimate(plan.stops.length.toDouble(), quals),
    extraKm: _estimate(plan.detourKm, quals),
    totalMinutes: _estimate(plan.totalMinutes, quals),
    endLitres: _estimate(plan.endLitres, quals),
    valuationPricePerLitre: valuation,
    searchWasBounded: plans.searchWasBounded,
    evidenceIncomplete: input.evidenceIncomplete,
    excludedForCurrency: input.excludedForCurrency,
    qualifications: quals,
  );
}

/// The plan answering [objective], falling back to the cheapest so a
/// journey with an answer always has one to show.
RefuelPlan? _planFor(RefuelPlanSet plans, RefuelObjective objective) =>
    switch (objective) {
      RefuelObjective.lowestCost => plans.cheapest,
      RefuelObjective.shortestTime => plans.fastest ?? plans.cheapest,
      RefuelObjective.leastExtraDistance =>
        plans.leastDetour ?? plans.cheapest,
    };

ComparableMetric<double> _estimate(
  double value,
  Set<ComparisonQualification> qualifications,
) =>
    ComparableMetric<double>.qualified(
      DataValue<double>.estimated(value, basis: DataBasis.derived),
      qualifications: qualifications,
    );

/// The lowest of [pick] across the columns that HAVE one.
///
/// Only planned columns take part: a vehicle with no plan has no time,
/// no cost and no stops, and must not win by absence. Fewer than two
/// eligible columns means there is nothing to compare, which is stated
/// rather than resolved into a single-entrant winner.
ComparableMetric<String> _numberWinner(
  List<VehicleTripColumn> columns,
  ComparableMetric<double> Function(VehicleTripColumn) pick,
) {
  final eligible = [
    for (final c in columns)
      if (c.isPlanned && pick(c).valueOrNull != null) c,
  ];
  if (eligible.length < 2) {
    return ComparableMetric<String>.unavailable(eligible.isEmpty
        ? ComparisonUnavailableReason.noEvidence
        : ComparisonUnavailableReason.tooFewSamples);
  }
  var winner = eligible.first;
  for (final c in eligible.skip(1)) {
    final a = pick(c).valueOrNull!;
    final b = pick(winner).valueOrNull!;
    if (a < b || (a == b && c.vehicleId.compareTo(winner.vehicleId) < 0)) {
      winner = c;
    }
  }
  return ComparableMetric<String>.qualified(
    DataValue<String>.estimated(winner.vehicleId, basis: DataBasis.derived),
    qualifications: _winnerQualifications(columns, eligible,
        [for (final c in eligible) ...pick(c).qualifications]),
  );
}

/// The same, for a money figure. Withheld across two denominations: a
/// cheapest among amounts in different currencies is not a cheapest.
ComparableMetric<String> _moneyWinner(
  List<VehicleTripColumn> columns,
  ComparableMetric<Money> Function(VehicleTripColumn) pick,
) {
  final eligible = [
    for (final c in columns)
      if (c.isPlanned && pick(c).valueOrNull != null) c,
  ];
  if (eligible.length < 2) {
    return ComparableMetric<String>.unavailable(eligible.isEmpty
        ? ComparisonUnavailableReason.noEvidence
        : ComparisonUnavailableReason.tooFewSamples);
  }
  final currency = pick(eligible.first).valueOrNull!.currencyCode;
  if (eligible.any((c) => pick(c).valueOrNull!.currencyCode != currency)) {
    return ComparableMetric<String>.unavailable(
        ComparisonUnavailableReason.mixedCurrencies);
  }
  var winner = eligible.first;
  for (final c in eligible.skip(1)) {
    final a = pick(c).valueOrNull!.amount;
    final b = pick(winner).valueOrNull!.amount;
    if (a < b || (a == b && c.vehicleId.compareTo(winner.vehicleId) < 0)) {
      winner = c;
    }
  }
  return ComparableMetric<String>.qualified(
    DataValue<String>.estimated(winner.vehicleId, basis: DataBasis.derived),
    qualifications: _winnerQualifications(columns, eligible,
        [for (final c in eligible) ...pick(c).qualifications]),
  );
}

/// Every caveat the winning claim inherits, plus one of its own when
/// some selected vehicle could not take part at all.
Set<ComparisonQualification> _winnerQualifications(
  List<VehicleTripColumn> all,
  List<VehicleTripColumn> eligible,
  Iterable<ComparisonQualification> inherited,
) =>
    {
      ComparisonQualification.estimatedBasis,
      ...inherited,
      if (eligible.length < all.length)
        ComparisonQualification.excludedRecords,
    };
