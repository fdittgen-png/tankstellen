// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// One column of the #4365 comparison: one vehicle, one period.
///
/// ## The order of operations is the correctness
///
/// Windows are walked over the vehicle's **entire** recorded history
/// first ([closedTankPeriods], the #1362 walker — no second walker is
/// written here), and only THEN filtered by the report period. Doing it
/// the other way round would start the walk mid-tank: the first window
/// of the period would open on whatever fill happened to fall inside
/// it, and the litres already in the tank would be charged to a
/// distance they did not cover.
///
/// A window that straddles the period boundary is therefore counted
/// WHOLE or not at all, under the stated [BoundaryWindowPolicy]. There
/// is no proration: nothing measured the litres burned before a
/// calendar date, and inventing that split would be a fabricated
/// allocation dressed as an observation. Both boundary counts travel on
/// the column so the rule is visible rather than implied.
///
/// ## Every ratio is Σ numerator ÷ Σ denominator
///
/// Consumption is Σ matched quantity ÷ Σ matched distance, never the
/// mean of per-window means (600 km/36 L and 400 km/28 L are 6.4, not
/// 6.5), and cost per km divides the counted WINDOWS' purchases by the
/// distance those windows covered — never all of the period's purchases
/// by only the closed-window distance.
library;

import '../../../../core/domain/comparison_eligibility.dart';
import '../../../../core/domain/data_value.dart';
import '../../../../core/domain/fuel/fuel_behaviour_evidence.dart';
import '../../../../core/domain/fuel/fuel_quantity_unit.dart';
import '../../../../core/domain/fuel_type.dart';
import '../../../../core/domain/vehicle_profile.dart';
import '../../../trips/api.dart';
import '../entities/fill_up.dart';
import 'fill_up_vehicle_scope.dart';
import 'tank_report.dart';
import 'vehicle_history_column_money.dart';
import 'vehicle_history_column_records.dart';
import 'vehicle_history_comparison.dart';

/// Everything one column needs that is not derivable from the records.
class ColumnInputs {
  const ColumnInputs({
    required this.vehicleId,
    required this.vehicle,
    required this.fillUps,
    required this.trips,
    required this.period,
    required this.asOf,
    required this.selectedVehicleCount,
    required this.ambiguousFillIds,
  });

  final String vehicleId;
  final VehicleProfile? vehicle;

  /// The FULL history, unfiltered — the window walker needs it.
  final List<FillUp> fillUps;
  final List<TripHistoryEntry> trips;
  final ComparisonPeriod period;

  /// Report instant, injected. Decides staleness, nothing else.
  final DateTime asOf;
  final int selectedVehicleCount;

  /// Fills that cannot be resolved to exactly one selected vehicle.
  final Set<String> ambiguousFillIds;
}

/// Build [inputs]' column.
VehicleHistoryColumn buildVehicleHistoryColumn(ColumnInputs inputs) {
  // #3945's legacy-fill policy, unchanged: a single-vehicle driver keeps
  // their pre-profile history; two or more vehicles exclude it, because
  // an unassigned fill of the other car must never move this car's
  // number. The excluded records are counted, not hidden.
  final scoped = scopeFillUpsToVehicle(
    inputs.fillUps,
    vehicle: inputs.vehicle ??
        VehicleProfile(id: inputs.vehicleId, name: inputs.vehicleId),
    vehicleCount: inputs.selectedVehicleCount,
  );
  final unit = commonFuelQuantityUnit([
        for (final f in scoped)
          if (!f.isCorrection) FuelQuantityUnit.fromPriceUnit(f.fuelType.unit),
      ]) ??
      FuelQuantityUnit.unknown;

  final selection = _selectWindows(scoped, inputs.period);
  final matched = selection.matched;
  final windowFills = {
    for (final w in matched) w.closing.id: fillsInsideWindow(scoped, w),
  };
  final matchedDistance = matched.fold<double>(0, (s, w) => s + w.distanceKm);
  final matchedQuantity = matched.fold<double>(0, (s, w) => s + w.liters);

  final periodFills = [
    for (final f in scoped)
      if (inputs.period.contains(f.date)) f,
  ];
  final realPeriodFills = [
    for (final f in periodFills)
      if (!f.isCorrection) f,
  ];

  final money = ColumnMoney.of(matched, windowFills, realPeriodFills);
  final trips = ColumnTrips.of(
    vehicleId: inputs.vehicleId,
    vehicle: inputs.vehicle,
    trips: inputs.trips,
    period: inputs.period,
  );

  final lastClosedAt = matched.isEmpty ? null : matched.last.closing.date;
  final age = lastClosedAt == null
      ? Duration.zero
      : inputs.asOf.difference(lastClosedAt);
  final stale = lastClosedAt != null && age > kComparisonStaleAfter;

  final grades = <FuelType, double>{};
  for (final fills in windowFills.values) {
    for (final f in fills) {
      grades[f.fuelType] = (grades[f.fuelType] ?? 0) + f.liters;
    }
  }
  // Part of a counted tank is not attributable to any single grade the
  // moment the window mixed grades, or the fuel already in the tank at
  // the opening is not one of the grades pumped inside it.
  final blendUnknown = grades.length > 1 ||
      (matched.isNotEmpty &&
          grades.isNotEmpty &&
          !grades.containsKey(matched.first.opening.fuelType));

  // A subject that owns no record at all while ambiguous records exist
  // has not "no evidence" — it has evidence nobody can attribute.
  final ambiguous = scoped.isEmpty && inputs.ambiguousFillIds.isNotEmpty;

  final coverage = _coverage(inputs, selection, trips, money, scoped, unit,
      matchedDistance, periodFills);

  final extra = <ComparisonQualification>{
    // No blend-independent expectation reaches production, so every
    // observation here is uncontrolled for hills, cold and traffic.
    ComparisonQualification.uncontrolledConditions,
    ComparisonQualification.partialConditionCoverage,
    if (stale) ComparisonQualification.staleBasis,
    if (blendUnknown) ComparisonQualification.unknownBlendShare,
    if (matched.isNotEmpty && trips.estimatedCount > 0)
      ComparisonQualification.mixedProvenance,
    if (coverage.exclusions.containsKey(ComparisonExclusion.openWindow))
      ComparisonQualification.openWindowExcluded,
    if (coverage.excludedCount > 0) ComparisonQualification.excludedRecords,
  };

  DataValue<double> figure(double value) =>
      stale ? DataValue.stale(value, age: age) : DataValue.measured(value);

  final consumption = _ratio(
    numerator: matchedQuantity * 100,
    denominator: matchedDistance,
    coverage: coverage,
    unit: unit,
    ambiguous: ambiguous,
    wrap: figure,
  ).qualifiedBy(extra);

  return VehicleHistoryColumn(
    vehicleId: inputs.vehicleId,
    quantityUnit: unit,
    coverage: coverage,
    matchedDistanceKm: matchedDistance,
    recordedDistanceKm: odometerSpan(realPeriodFills),
    matchedWindowCount: matched.length,
    boundaryWindowsIncluded: selection.straddlingIncluded,
    boundaryWindowsExcluded: selection.straddlingExcluded,
    consumptionPer100Km: consumption,
    // No blend-independent expectation reaches production (#4364), so
    // there is nothing to adjust against. Stated, not approximated.
    conditionAdjustedPer100Km: ComparableMetric.unavailable(
        ComparisonUnavailableReason.noExpectedConsumption,
        coverage: coverage),
    costPerKm: money
        .costPerKm(matchedDistance, coverage, ambiguous, figure)
        .qualifiedBy(extra),
    consumedFuelCostPerKm:
        money.consumedFuelCostPerKm(matchedDistance, coverage, figure)
            .qualifiedBy({
      ...extra,
      ComparisonQualification.reconstructedValuation,
      ComparisonQualification.estimatedBasis,
    }),
    recordedSpend: money.recordedSpend(coverage),
    matchedSpend: money.matchedSpend,
    purchaseSpend: money.purchaseSpend,
    pricePerUnit: money.pricePerUnit(coverage, figure).qualifiedBy(extra),
    estimatedRangeKm:
        _range(inputs.vehicle, consumption.valueOrNull, unit, coverage, extra),
    refuelling: refuellingPattern(realPeriodFills, periodFills),
    opening: openingContext(matched, inputs.period),
    fuelShares: {
      if (matchedQuantity > 0)
        for (final e in grades.entries) e.key: e.value / matchedQuantity,
    },
    stationFillCounts: stationFillCounts(realPeriodFills),
    unnamedStationFillCount:
        realPeriodFills.where((f) => (f.stationName ?? '').isEmpty).length,
    sources: figureSources(
      matched: matched,
      windowFills: windowFills,
      periodFills: realPeriodFills,
      tripIds: trips.drivenIds,
    ),
  );
}

/// Which whole windows the period's boundary policy counts.
class _WindowSelection {
  const _WindowSelection(
      this.matched, this.straddlingIncluded, this.straddlingExcluded);

  final List<TankPeriod> matched;
  final int straddlingIncluded;
  final int straddlingExcluded;
}

_WindowSelection _selectWindows(List<FillUp> scoped, ComparisonPeriod period) {
  final matched = <TankPeriod>[];
  var included = 0;
  var excluded = 0;
  for (final w in closedTankPeriods(scoped)) {
    final opensInside = period.contains(w.opening.date);
    final closesInside = period.contains(w.closing.date);
    final straddles = opensInside != closesInside;
    final take = switch (period.boundaryPolicy) {
      BoundaryWindowPolicy.closingFillInPeriod => closesInside,
      BoundaryWindowPolicy.whollyContained => opensInside && closesInside,
    };
    if (take) {
      matched.add(w);
      if (straddles) included += 1;
    } else if (straddles) {
      excluded += 1;
    }
  }
  return _WindowSelection(matched, included, excluded);
}

ComparisonCoverage _coverage(
  ColumnInputs inputs,
  _WindowSelection selection,
  ColumnTrips trips,
  ColumnMoney money,
  List<FillUp> scoped,
  FuelQuantityUnit unit,
  double matchedDistance,
  List<FillUp> periodFills,
) {
  final matched = selection.matched;
  final unassigned = inputs.selectedVehicleCount > 1
      ? inputs.fillUps.where((f) => f.vehicleId == null).length -
          inputs.ambiguousFillIds.length
      : 0;
  return ComparisonCoverage(
    tripCount: trips.drivenCount,
    windowCount: matched.length,
    coveredKm: matchedDistance,
    coveredTime: trips.recordedTime,
    periodStart: matched.isEmpty ? null : matched.first.opening.date,
    periodEnd: matched.isEmpty ? null : matched.last.closing.date,
    // Production evaluates cold starts alone, so no drive has its FULL
    // confounding context. Claiming otherwise is what #4364 forbids.
    conditionCoverage: 0,
    exclusions: {
      ComparisonExclusion.unassignedVehicle: unassigned < 0 ? 0 : unassigned,
      ComparisonExclusion.ambiguousVehicle: inputs.ambiguousFillIds.length,
      ComparisonExclusion.virtualRecord: trips.virtualCount,
      ComparisonExclusion.missingPrice: money.unpricedPeriodFills,
      ComparisonExclusion.correction:
          periodFills.where((f) => f.isCorrection).length,
      ComparisonExclusion.openWindow:
          openWindowFillCount(scoped, inputs.period),
      ComparisonExclusion.nonLitreUnit: unit.isLitreBased ? 0 : scoped.length,
    },
    provenance: {
      if (matched.isNotEmpty) EvidenceTier.measured: matched.length,
      if (trips.estimatedCount > 0) EvidenceTier.estimated: trips.estimatedCount,
    },
  );
}

/// Σ numerator ÷ Σ denominator, or the reason there is no figure.
ComparableMetric<double> _ratio({
  required double numerator,
  required double denominator,
  required ComparisonCoverage coverage,
  required FuelQuantityUnit unit,
  required bool ambiguous,
  required DataValue<double> Function(double) wrap,
}) {
  // Attribution is decided first: "nobody can say whose these records
  // are" is a stronger and more actionable statement than "this
  // subject has no unit", which is only true because it has no record.
  if (ambiguous) {
    return ComparableMetric.unavailable(
        ComparisonUnavailableReason.ambiguousAttribution,
        coverage: coverage);
  }
  if (!unit.isLitreBased) {
    // kg and kWh histories keep their native spend and get no L/100 km:
    // a suffix swap does not convert a quantity (#4364).
    return ComparableMetric.unavailable(
        unit == FuelQuantityUnit.unknown
            ? ComparisonUnavailableReason.incompatibleUnits
            : ComparisonUnavailableReason.unsupportedUnit,
        coverage: coverage);
  }
  if (denominator <= 0 || !denominator.isFinite || !numerator.isFinite) {
    return ComparableMetric.unavailable(
        coverage.windowCount == 0
            ? ComparisonUnavailableReason.noEvidence
            : ComparisonUnavailableReason.noMatchedDistance,
        coverage: coverage);
  }
  return ComparableMetric.comparable(wrap(numerator / denominator),
      coverage: coverage);
}

/// Range only when the tank's size AND an observed consumption are both
/// on record. Always an estimate, and labelled one.
ComparableMetric<double> _range(
  VehicleProfile? vehicle,
  double? consumption,
  FuelQuantityUnit unit,
  ComparisonCoverage coverage,
  Set<ComparisonQualification> extra,
) {
  final capacity = vehicle?.tankCapacityL;
  final usable =
      unit.isLitreBased && capacity != null && capacity.isFinite && capacity > 0;
  if (!usable ||
      consumption == null ||
      !consumption.isFinite ||
      consumption <= 0) {
    return ComparableMetric.unavailable(ComparisonUnavailableReason.noEvidence,
        coverage: coverage);
  }
  return ComparableMetric.qualified(
    DataValue.estimated(capacity / consumption * 100, basis: DataBasis.derived),
    qualifications: {...extra, ComparisonQualification.estimatedBasis},
    coverage: coverage,
  );
}
