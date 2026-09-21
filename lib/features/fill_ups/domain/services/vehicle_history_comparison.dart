// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// The shape of a period-scoped, multi-vehicle historical comparison
/// (#4365, Epic #4358 work package F) — the read model the personal
/// surface renders and #4367's same-trip comparison reuses.
///
/// It is a READ MODEL only: every field here was computed by
/// `buildVehicleHistoryComparison` (a pure function) from records that
/// already existed. Nothing in this file walks a fill window, prices a
/// litre or decides a winner — #4364 owns that, and this composes it.
///
/// ## The three money bases never collapse into one number
///
/// [VehicleHistoryColumn] carries all three of #4364's
/// [MoneyValuationBasis] values side by side and labels each:
///
///  * [VehicleHistoryColumn.recordedSpend] — what was paid at the pump
///    for the period's fills. The only fact about money here.
///  * [VehicleHistoryColumn.costPerKm] — the counted windows' purchase
///    cost over the distance those windows covered.
///  * [VehicleHistoryColumn.consumedFuelCostPerKm] — the litres those
///    windows burned, valued at what the tank was filled with when each
///    window OPENED. A model, flagged
///    [ComparisonQualification.reconstructedValuation].
///
/// ## What a column is not
///
/// A historical observation uses the price environment that was
/// actually recorded. It does not establish a vehicle's intrinsic
/// efficiency, it does not predict what a future route will cost, and
/// it is not a saving against a station price the app never saw.
library;

import 'package:meta/meta.dart';

import '../../../../core/domain/comparison_eligibility.dart';
import '../../../../core/domain/fuel/fuel_quantity_unit.dart';
import '../../../../core/domain/fuel_type.dart';
import '../../../../core/domain/money.dart';
import '../../../../core/domain/money_tally.dart';
import '../../../../core/domain/vehicle_comparison_key.dart';
import 'vehicle_comparison_facts.dart';

export '../../../../core/domain/vehicle_comparison_key.dart';
export 'vehicle_comparison_facts.dart';

/// One selected vehicle's period-scoped history.
@immutable
final class VehicleHistoryColumn {
  VehicleHistoryColumn({
    required this.vehicleId,
    required this.quantityUnit,
    required this.coverage,
    required this.matchedDistanceKm,
    required this.recordedDistanceKm,
    required this.matchedWindowCount,
    required this.boundaryWindowsIncluded,
    required this.boundaryWindowsExcluded,
    required this.consumptionPer100Km,
    required this.conditionAdjustedPer100Km,
    required this.costPerKm,
    required this.consumedFuelCostPerKm,
    required this.recordedSpend,
    required this.matchedSpend,
    required this.purchaseSpend,
    required this.pricePerUnit,
    required this.estimatedRangeKm,
    required this.refuelling,
    required this.opening,
    Map<FuelType, double> fuelShares = const {},
    Map<String, int> stationFillCounts = const {},
    this.unnamedStationFillCount = 0,
    Map<ComparisonFigure, FigureSources> sources = const {},
  })  : fuelShares = Map.unmodifiable(fuelShares),
        stationFillCounts = Map.unmodifiable(stationFillCounts),
        sources = Map.unmodifiable(sources);

  final String vehicleId;

  /// The unit this vehicle's quantities are measured in. A kg or kWh
  /// history keeps its native spend and gets no L/100 km (#4364).
  final FuelQuantityUnit quantityUnit;

  final ComparisonCoverage coverage;

  /// Σ distance of the COUNTED windows — the denominator of
  /// [consumptionPer100Km], [costPerKm] and [consumedFuelCostPerKm].
  final double matchedDistanceKm;

  /// Odometer span of the period's fills. Context only: it includes
  /// distance no closed window speaks for, so it is never a divisor.
  final double recordedDistanceKm;

  final int matchedWindowCount;

  /// Counted windows that straddle the period edge, and straddling
  /// windows the policy left out. Both shown, so the inclusion rule is
  /// visible rather than implied.
  final int boundaryWindowsIncluded;
  final int boundaryWindowsExcluded;

  /// Observed consumption per 100 km over the matched windows —
  /// Σ quantity ÷ Σ distance, never the mean of per-window means.
  final ComparableMetric<double> consumptionPer100Km;

  /// Consumption with hills, cold and traffic controlled for. Always
  /// unavailable today: production supplies no blend-independent
  /// expected consumption, so there is nothing to adjust against
  /// ([ComparisonUnavailableReason.noExpectedConsumption]).
  final ComparableMetric<double> conditionAdjustedPer100Km;

  /// [MoneyValuationBasis.closingWindowPurchaseCost].
  final ComparableMetric<double> costPerKm;

  /// [MoneyValuationBasis.modelledConsumedFuel] — a model, always
  /// carrying [ComparisonQualification.reconstructedValuation].
  final ComparableMetric<double> consumedFuelCostPerKm;

  /// [MoneyValuationBasis.recordedPurchaseSpend] — the period's actual
  /// pump spend, never derived from `FuelTypeEfficiencyStats.totalSpent`.
  final ComparableMetric<Money> recordedSpend;

  /// Per-denomination breakdown over the matched windows.
  final MoneyTally matchedSpend;

  /// Per-denomination breakdown of the period's purchases.
  final MoneyTally purchaseSpend;

  /// Observed price actually paid per litre/kg/kWh.
  final ComparableMetric<double> pricePerUnit;

  /// Tank range, only when the vehicle's capacity and an observed
  /// consumption both exist. Always an estimate, and labelled one.
  final ComparableMetric<double> estimatedRangeKm;

  final RefuellingPattern refuelling;

  /// The tank the first counted window opened on, or null when no
  /// window was counted.
  final OpeningTankContext? opening;

  /// Share of matched quantity by grade. Sums to 1 when any quantity
  /// was matched.
  final Map<FuelType, double> fuelShares;

  /// Recorded station name → visit count. Brand and country are not
  /// fields of a fill-up, so neither is claimed here.
  final Map<String, int> stationFillCounts;
  final int unnamedStationFillCount;

  final Map<ComparisonFigure, FigureSources> sources;

  /// The records behind [figure] — empty when nothing backs it.
  FigureSources sourcesFor(ComparisonFigure figure) =>
      sources[figure] ?? FigureSources();

  /// Which basis [costPerKm] values. Stated, never assumed.
  MoneyValuationBasis get costValuationBasis =>
      MoneyValuationBasis.closingWindowPurchaseCost;

  /// The metric named by [figure], for a generic renderer or a delta.
  ComparableMetric<double>? metricFor(ComparisonFigure figure) =>
      switch (figure) {
        ComparisonFigure.consumption => consumptionPer100Km,
        ComparisonFigure.costPerKm => costPerKm,
        ComparisonFigure.consumedFuelCost => consumedFuelCostPerKm,
        ComparisonFigure.pricePerUnit => pricePerUnit,
        ComparisonFigure.range => estimatedRangeKm,
        ComparisonFigure.recordedSpend || ComparisonFigure.refuelling => null,
      };
}

/// Several vehicles' period-scoped histories, side by side.
@immutable
final class VehicleHistoryComparison {
  VehicleHistoryComparison({
    required this.key,
    required this.asOf,
    required List<VehicleHistoryColumn> columns,
    required this.referenceVehicleId,
    required this.lowestConsumption,
    required this.lowestCostPerKm,
    required this.unassignedFillCount,
    required this.ambiguousFillCount,
    required this.unassignedTripCount,
    Iterable<String> missingVehicleIds = const [],
    this.valuation,
  })  : columns = List.unmodifiable(columns),
        missingVehicleIds = List.unmodifiable(missingVehicleIds);

  /// What was asked: which vehicles, which period, which rules.
  final VehicleComparisonKey key;

  /// The report instant freshness was judged against — injected through
  /// the `AppClock` seam, never the wall clock.
  final DateTime asOf;

  final List<VehicleHistoryColumn> columns;

  /// The column every delta is measured against, or null when there is
  /// nothing to reference.
  final String? referenceVehicleId;

  /// The winning vehicle id, or the reason no winner may be named. A
  /// withheld winner never suppresses the columns.
  final ComparableMetric<String> lowestConsumption;
  final ComparableMetric<String> lowestCostPerKm;

  /// Records belonging to no vehicle, counted once and credited to
  /// none; and records whose vehicle could not be resolved to exactly
  /// one selected subject.
  final int unassignedFillCount;
  final int ambiguousFillCount;
  final int unassignedTripCount;

  /// Selected ids with no vehicle profile on record — a deleted car.
  /// Kept in the key so the selection stays recoverable.
  final List<String> missingVehicleIds;

  final MoneyValuationPolicy? valuation;

  ComparisonPeriod get period => key.period;

  VehicleHistoryColumn? columnFor(String vehicleId) {
    for (final c in columns) {
      if (c.vehicleId == vehicleId) return c;
    }
    return null;
  }

  VehicleHistoryColumn? get reference {
    final id = referenceVehicleId;
    return id == null ? null : columnFor(id);
  }

  /// [vehicleId]'s [figure] against the default reference's.
  ComparisonDelta? deltaFor(String vehicleId, ComparisonFigure figure) =>
      deltaBetween(vehicleId, referenceVehicleId, figure);

  /// [vehicleId]'s [figure] against [referenceId]'s, or null when
  /// either side is unavailable — an absent metric is not a zero, and a
  /// delta against nothing is not a difference.
  ComparisonDelta? deltaBetween(
      String vehicleId, String? referenceId, ComparisonFigure figure) {
    final ref = referenceId == null ? null : columnFor(referenceId);
    final subject = columnFor(vehicleId);
    if (ref == null || subject == null || ref.vehicleId == vehicleId) {
      return null;
    }
    final a = subject.metricFor(figure);
    final b = ref.metricFor(figure);
    final av = a?.valueOrNull;
    final bv = b?.valueOrNull;
    if (a == null || b == null || av == null || bv == null) return null;
    // Money figures only compare inside one denomination; a cross-
    // currency "difference" is not a difference.
    if (_isMoney(figure) &&
        subject.matchedSpend.soleCurrency != ref.matchedSpend.soleCurrency) {
      return null;
    }
    if (subject.quantityUnit != ref.quantityUnit) return null;
    return ComparisonDelta(
      figure: figure,
      absolute: av - bv,
      percent: bv == 0 ? null : (av - bv) / bv,
      qualifications: {...a.qualifications, ...b.qualifications},
    );
  }

  static bool _isMoney(ComparisonFigure figure) =>
      figure == ComparisonFigure.costPerKm ||
      figure == ComparisonFigure.consumedFuelCost ||
      figure == ComparisonFigure.pricePerUnit;
}
