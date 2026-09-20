// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// The read model of a same-trip, multi-vehicle forecast (#4367, Epic
/// #4358 work package H).
///
/// A sibling of #4365's [VehicleHistoryComparison], deliberately NOT a
/// replacement for it: that one reports what each vehicle DID consume
/// and cost in recorded driving, this one estimates what each would
/// consume and cost on one proposed journey. Neither is evidence for
/// the other, and the surfaces say so.
///
/// ## Cost to drive and cash required are two different questions
///
/// A vehicle that starts with a full tank pays nothing at the pump on a
/// short trip. That makes it cheaper to REFUEL today; it says nothing
/// about what the drive costs. So every column carries both, named:
///
///  * [VehicleTripColumn.costToDrive] — the fuel the journey actually
///    burns, valued at the best price available to THAT vehicle's fuel
///    on THIS route. Independent of what happens to be in the tank, so
///    it is the figure the vehicles may be ranked on.
///  * [VehicleTripColumn.cashRequired] — what leaves the driver's
///    wallet given the tank as it is now, plus the known charges of the
///    stops this plan makes. It is what the trip costs TODAY, and it is
///    never used to name a more efficient vehicle.
///
/// The worked case in the issue: 200 km with no detours, vehicle A at
/// 6 L/100 km with €1.80/L fuel burns 12 L for €21.60; vehicle B at
/// 8 L/100 km with €1.60/L burns 16 L for €25.60. The cheaper pump
/// price is not the cheaper journey, and only [costToDrive] can say so.
///
/// ## What is NOT in any total here
///
/// This is a fuel and refuelling comparison. Maintenance, depreciation,
/// insurance and tyres are not estimated, not approximated and not
/// folded into an unlabelled "trip total" — there is no field for them,
/// which is the only way to be sure none leaked in. Known incremental
/// routing charges (a stop's access toll, a transaction fee) DO belong,
/// and they arrive inside [RefuelPlan.chargesCost] with every other
/// trip estimate.
library;

import 'package:meta/meta.dart';

import 'comparison_eligibility.dart';
import 'money.dart';
import 'refuel_plan.dart';
import 'vehicle_trip_basis.dart';

export 'vehicle_trip_basis.dart';

/// A figure a same-trip column reports, for a generic renderer.
enum TripComparisonFigure {
  /// Fuel the whole journey burns, detours included.
  fuelUsed,

  /// Standardised cost of the fuel burned. The ranking figure.
  costToDrive,

  /// New pump spend with the tank as it is now, charges included.
  cashRequired,

  /// Refuelling stops the plan makes.
  stops,

  /// Extra road kilometres over the baseline drive.
  extraKm,

  /// Expected total minutes, stop overheads included.
  totalMinutes,

  /// Litres left at the destination.
  endInventory,
}

/// One vehicle's forecast for the shared journey.
@immutable
final class VehicleTripColumn {
  VehicleTripColumn({
    required this.basis,
    required this.fuelUsedLitres,
    required this.costToDrive,
    required this.cashRequired,
    required this.stopCount,
    required this.extraKm,
    required this.totalMinutes,
    required this.endLitres,
    this.plans,
    this.plan,
    Set<RefuelObjective> objectives = const {},
    Iterable<String> stationIds = const [],
    this.gap,
    this.unavailable,
    this.valuationPricePerLitre,
    this.searchWasBounded = false,
    this.evidenceIncomplete = false,
    this.excludedForCurrency = false,
    Set<ComparisonQualification> qualifications = const {},
  })  : objectives = Set.unmodifiable(objectives),
        stationIds = List.unmodifiable(stationIds),
        qualifications = Set.unmodifiable(qualifications);

  final VehicleTripBasis basis;

  /// Every objective's plan for this vehicle, or null when the journey
  /// could not be planned at all.
  final RefuelPlanSet? plans;

  /// The plan the comparison is reported on — the one that answers the
  /// journey's selected objective.
  final RefuelPlan? plan;

  /// The objectives [plan] happens to be the minimum of, so a surface
  /// can say "cheapest AND fastest" on one result.
  final Set<RefuelObjective> objectives;

  /// The plan's stops in route order, as station ids — what "select
  /// this plan" hands to the route boundary.
  final List<String> stationIds;

  final ComparableMetric<double> fuelUsedLitres;

  /// Fuel burned × the best price for this vehicle's fuel on this
  /// route. See the library doc.
  final ComparableMetric<Money> costToDrive;

  /// New pump spend plus known charges, given this tank.
  final ComparableMetric<Money> cashRequired;

  final ComparableMetric<double> stopCount;
  final ComparableMetric<double> extraKm;
  final ComparableMetric<double> totalMinutes;

  /// Litres in the tank at the destination — the inventory basis that
  /// makes [cashRequired] and [costToDrive] tell different stories.
  final ComparableMetric<double> endLitres;

  /// Where this vehicle's range breaks, when it cannot drive the route.
  final RefuelPlanGap? gap;

  /// Why this column has no plan at all. Its still-valid metrics are
  /// reported anyway; "unsupported" is not "nothing is known".
  final ComparisonUnavailableReason? unavailable;

  /// The price [costToDrive] valued the burned fuel at.
  final double? valuationPricePerLitre;

  /// The planner hit its documented work limit: the best FOUND, not
  /// provably the best that exists (#4362).
  final bool searchWasBounded;

  /// A source that lists only part of its country, or a station the
  /// driver hid, shaped this vehicle's candidate set (#4348/#4362).
  final bool evidenceIncomplete;

  /// At least one station selling this vehicle's fuel quoted a currency
  /// the journey could not be expressed in (#4361).
  final bool excludedForCurrency;

  final Set<ComparisonQualification> qualifications;

  String get vehicleId => basis.vehicleId;

  bool get isPlanned => plan != null;

  /// True when the route cannot be driven by this vehicle at all.
  bool get isInfeasible => gap != null;

  /// The metric named by [figure], or null when the figure is money
  /// (money compares only inside one denomination — use
  /// [moneyFor]).
  ComparableMetric<double>? metricFor(TripComparisonFigure figure) =>
      switch (figure) {
        TripComparisonFigure.fuelUsed => fuelUsedLitres,
        TripComparisonFigure.stops => stopCount,
        TripComparisonFigure.extraKm => extraKm,
        TripComparisonFigure.totalMinutes => totalMinutes,
        TripComparisonFigure.endInventory => endLitres,
        TripComparisonFigure.costToDrive ||
        TripComparisonFigure.cashRequired =>
          null,
      };

  /// The money metric named by [figure], or null for a non-money one.
  ComparableMetric<Money>? moneyFor(TripComparisonFigure figure) =>
      switch (figure) {
        TripComparisonFigure.costToDrive => costToDrive,
        TripComparisonFigure.cashRequired => cashRequired,
        _ => null,
      };
}

/// Several vehicles' forecasts for ONE journey, side by side.
@immutable
final class VehicleTripComparison {
  VehicleTripComparison({
    required this.key,
    required this.asOf,
    required List<VehicleTripColumn> columns,
    required this.referenceVehicleId,
    required this.lowestCostToDrive,
    required this.lowestCashRequired,
    required this.shortestTime,
    Iterable<String> missingVehicleIds = const [],
  })  : columns = List.unmodifiable(columns),
        missingVehicleIds = List.unmodifiable(missingVehicleIds);

  /// An answer to nothing: the shape a surface renders before a journey
  /// or a selection exists.
  static VehicleTripComparison empty(
    VehicleTripComparisonKey key,
    DateTime asOf,
  ) =>
      VehicleTripComparison(
        key: key,
        asOf: asOf,
        columns: const [],
        referenceVehicleId: null,
        lowestCostToDrive: ComparableMetric<String>.unavailable(
            ComparisonUnavailableReason.noEvidence),
        lowestCashRequired: ComparableMetric<String>.unavailable(
            ComparisonUnavailableReason.noEvidence),
        shortestTime: ComparableMetric<String>.unavailable(
            ComparisonUnavailableReason.noEvidence),
      );

  /// Which vehicles, which journey, under which assumptions.
  final VehicleTripComparisonKey key;

  /// The instant the forecast speaks for — injected, never read from
  /// the wall clock.
  final DateTime asOf;

  /// In the driver's selection order.
  final List<VehicleTripColumn> columns;

  final String? referenceVehicleId;

  /// The winning vehicle id per question, or the reason none may be
  /// named. A withheld winner never suppresses the columns.
  final ComparableMetric<String> lowestCostToDrive;
  final ComparableMetric<String> lowestCashRequired;
  final ComparableMetric<String> shortestTime;

  /// Selected ids with no vehicle on record.
  final List<String> missingVehicleIds;

  VehicleTripJourney get journey => key.journey;

  bool get isEmpty => columns.isEmpty;

  VehicleTripColumn? columnFor(String vehicleId) {
    for (final c in columns) {
      if (c.vehicleId == vehicleId) return c;
    }
    return null;
  }

  VehicleTripColumn? get reference {
    final id = referenceVehicleId;
    return id == null ? null : columnFor(id);
  }

  /// [vehicleId]'s [figure] against [referenceId]'s.
  ///
  /// Null when either side has no value — an absent metric is not a
  /// zero — and null across two currencies or two quantity units,
  /// because neither difference is a difference.
  TripComparisonDelta? deltaBetween(
    String vehicleId,
    String? referenceId,
    TripComparisonFigure figure,
  ) {
    final ref = referenceId == null ? null : columnFor(referenceId);
    final subject = columnFor(vehicleId);
    if (ref == null || subject == null || ref.vehicleId == vehicleId) {
      return null;
    }
    if (subject.basis.quantityUnit != ref.basis.quantityUnit) return null;
    final money = subject.moneyFor(figure);
    if (money != null) {
      final refMoney = ref.moneyFor(figure);
      final a = money.valueOrNull;
      final b = refMoney?.valueOrNull;
      if (a == null || b == null || !a.isSameCurrencyAs(b)) return null;
      return TripComparisonDelta(
        figure: figure,
        absolute: a.amount - b.amount,
        percent: b.amount == 0 ? null : (a.amount - b.amount) / b.amount,
        qualifications: {
          ...money.qualifications,
          ...?refMoney?.qualifications,
        },
      );
    }
    final a = subject.metricFor(figure);
    final b = ref.metricFor(figure);
    final av = a?.valueOrNull;
    final bv = b?.valueOrNull;
    if (a == null || b == null || av == null || bv == null) return null;
    return TripComparisonDelta(
      figure: figure,
      absolute: av - bv,
      percent: bv == 0 ? null : (av - bv) / bv,
      qualifications: {...a.qualifications, ...b.qualifications},
    );
  }

  /// [vehicleId]'s [figure] against the default reference's.
  TripComparisonDelta? deltaFor(
          String vehicleId, TripComparisonFigure figure) =>
      deltaBetween(vehicleId, referenceVehicleId, figure);
}

/// One column's figure against another's.
///
/// Carries the union of both sides' qualifications: a difference
/// between two estimates is an estimated difference, and dropping the
/// caveat on the way to a widget is how a forecast starts reading like
/// a measurement.
@immutable
final class TripComparisonDelta {
  TripComparisonDelta({
    required this.figure,
    required this.absolute,
    required this.percent,
    Set<ComparisonQualification> qualifications = const {},
  }) : qualifications = Set.unmodifiable(qualifications);

  final TripComparisonFigure figure;

  /// Positive: this column's figure is HIGHER than the reference's.
  final double absolute;

  /// The same difference as a share of the reference, or null when the
  /// reference is zero.
  final double? percent;

  final Set<ComparisonQualification> qualifications;

  bool get isMaterial => absolute.abs() > 1e-9;
}
