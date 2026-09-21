// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// The one owner of a historical multi-vehicle comparison (#4364, Epic
/// #4358 work package I) — what #4365, #4366 and #4367 consume, and what
/// #4214's fleet comparison adopts.
///
/// ## Why this file exists rather than three of them
///
/// Three consumer features are about to need "vehicle A against vehicle
/// B over the same period". Each of them could walk the fill windows,
/// price the litres and decide a winner — and each would get the
/// currency, the attribution or the missing prices subtly differently.
/// So this composes what already exists and adds nothing:
///
///  * `ConsumptionStats.fromFillUps` — the #1362 plein-to-plein walker
///    and, since #4364, the currency-segregated spend;
///  * `scopeFillUpsToVehicle` — the #3945 legacy-fill policy, which
///    claims unassigned fills ONLY for a single-vehicle driver;
///  * `tripIsAttributedTo` — the strict trip predicate (#4364);
///  * `MoneyTally` / `MoneyValuationPolicy` — the #4361 money semantics;
///  * `ComparableMetric` — the #4364 eligibility contract.
///
/// There is no fill-window walker here, no estimator, no currency table
/// and no second confidence system.
///
/// ## What it refuses to say
///
/// The cost figure is `MoneyValuationBasis.closingWindowPurchaseCost`:
/// what the counted full-tank windows actually cost, over the distance
/// they actually covered. It is an OBSERVED cost of two histories, not
/// a measurement of either vehicle's intrinsic efficiency and not a cost
/// of ownership. Two vehicles driven differently will differ here for
/// reasons that have nothing to do with the cars.
library;

import '../../../../core/domain/comparison_eligibility.dart';
import '../../../../core/domain/data_value.dart';
import '../../../../core/domain/fuel/fuel_quantity_unit.dart';
import '../../../../core/domain/money.dart';
import '../../../../core/domain/money_tally.dart';
import '../../../../core/domain/vehicle_profile.dart';
import '../../../trips/api.dart';
import '../entities/consumption_stats.dart';
import '../entities/fill_up.dart';
import 'fill_up_vehicle_scope.dart';

/// One selected vehicle's comparable history.
class VehicleComparisonSubject {
  const VehicleComparisonSubject({
    required this.vehicleId,
    required this.consumptionL100Km,
    required this.costPerKm,
    required this.recordedSpend,
    required this.spend,
    required this.quantityUnit,
    required this.coverage,
    required this.stats,
  });

  final String vehicleId;

  /// Observed L/100 km over the closed windows — unavailable, never
  /// zero, for a vehicle whose fuel is not sold by the litre.
  final ComparableMetric<double> consumptionL100Km;

  /// Observed cost per km in [spend]'s single denomination.
  /// [MoneyValuationBasis.closingWindowPurchaseCost].
  final ComparableMetric<double> costPerKm;

  /// Recorded purchase spend — [MoneyValuationBasis.recordedPurchaseSpend],
  /// the only figure here that is a fact about money.
  final ComparableMetric<Money> recordedSpend;

  /// The full per-denomination breakdown, always present even when no
  /// single total is.
  final MoneyTally spend;

  final FuelQuantityUnit quantityUnit;
  final ComparisonCoverage coverage;

  /// The canonical summary this subject was derived from, so a consumer
  /// never recomputes one.
  final ConsumptionStats stats;

  /// What [costPerKm] values. Stated, never assumed.
  MoneyValuationBasis get costValuationBasis =>
      MoneyValuationBasis.closingWindowPurchaseCost;
}

/// Several vehicles' histories, each metric carrying its own eligibility.
class VehicleCostComparison {
  const VehicleCostComparison({
    required this.subjects,
    required this.cheapestPerKm,
    required this.unassignedTripCount,
    required this.unassignedFillCount,
    required this.valuation,
  });

  final List<VehicleComparisonSubject> subjects;

  /// The winning vehicle id, or the reason no winner may be named.
  ///
  /// A withheld winner never suppresses the per-subject observations
  /// above — that is the whole point of metric-level eligibility.
  final ComparableMetric<String> cheapestPerKm;

  /// Records belonging to no vehicle. Reported once, credited to none —
  /// counting a legacy trip for every selected vehicle would inflate
  /// both sides of the comparison at once.
  final int unassignedTripCount;
  final int unassignedFillCount;

  /// The conversion policy applied, or null when every figure stayed in
  /// its native currency.
  final MoneyValuationPolicy? valuation;
}

/// Build the comparison for [vehicleIds] from the recorded history.
///
/// [asOf] is injected (never the wall clock) and is only used to judge
/// exchange-rate freshness under [valuation]. Without a [valuation] no
/// conversion happens at all and vehicles in different currencies simply
/// have no combined winner.
VehicleCostComparison buildVehicleCostComparison({
  required List<String> vehicleIds,
  required Iterable<FillUp> fillUps,
  required Iterable<TripHistoryEntry> trips,
  Map<String, VehicleProfile> vehicles = const {},
  MoneyValuationPolicy? valuation,
}) {
  final allFills = fillUps.toList(growable: false);
  final allTrips = trips.toList(growable: false);
  final subjects = [
    for (final id in vehicleIds)
      _subject(id, allFills, allTrips, vehicles[id], vehicleIds.length),
  ];
  return VehicleCostComparison(
    subjects: subjects,
    cheapestPerKm: _cheapest(subjects, valuation),
    unassignedTripCount: allTrips.where((t) => t.vehicleId == null).length,
    unassignedFillCount: allFills.where((f) => f.vehicleId == null).length,
    valuation: valuation,
  );
}

VehicleComparisonSubject _subject(
  String vehicleId,
  List<FillUp> allFills,
  List<TripHistoryEntry> allTrips,
  VehicleProfile? vehicle,
  int vehicleCount,
) {
  // #3945's legacy-fill policy, unchanged: a single-vehicle driver keeps
  // their pre-profile history; two or more vehicles exclude it, because
  // an unassigned fill of the other car must never move this car's
  // number. The excluded records are counted, not hidden.
  final scoped = scopeFillUpsToVehicle(
    allFills,
    vehicle: vehicle ?? VehicleProfile(id: vehicleId, name: vehicleId),
    vehicleCount: vehicleCount,
  );
  final stats = ConsumptionStats.fromFillUps(scoped);

  final unit = commonFuelQuantityUnit([
        for (final f in scoped)
          if (!f.isCorrection) FuelQuantityUnit.fromPriceUnit(f.fuelType.unit),
      ]) ??
      FuelQuantityUnit.unknown;

  final attributed = [
    for (final t in allTrips)
      if (tripIsAttributedTo(t, vehicleId)) t,
  ];
  final driven = [
    for (final t in attributed)
      if (!t.summary.isVirtual && t.summary.distanceKm > 0) t,
  ];
  final coverage = ComparisonCoverage(
    tripCount: driven.length,
    windowCount: stats.closedWindowCount,
    coveredKm: driven.fold<double>(0, (s, t) => s + t.summary.distanceKm),
    coveredTime: _recordedTime(driven),
    periodStart: stats.periodStart,
    periodEnd: stats.periodEnd,
    // Production evaluates cold starts alone, so no drive has its FULL
    // condition context; claiming otherwise is what #4364 forbids.
    conditionCoverage: 0,
    exclusions: {
      ComparisonExclusion.unassignedVehicle:
          vehicleCount > 1 ? allFills.where((f) => f.vehicleId == null).length : 0,
      ComparisonExclusion.virtualRecord:
          attributed.where((t) => t.summary.isVirtual).length,
      ComparisonExclusion.missingPrice: stats.unpricedFillCount,
      ComparisonExclusion.correction: scoped.where((f) => f.isCorrection).length,
      ComparisonExclusion.openWindow: stats.openWindowFillCount,
      ComparisonExclusion.nonLitreUnit: unit.isLitreBased ? 0 : scoped.length,
    },
  );

  final extra = <ComparisonQualification>{
    // No blend-independent expectation reaches production, so every
    // observation here is uncontrolled for hills, cold and traffic.
    ComparisonQualification.uncontrolledConditions,
    ComparisonQualification.partialConditionCoverage,
    if (stats.openWindowFillCount > 0)
      ComparisonQualification.openWindowExcluded,
    if (coverage.excludedCount > 0) ComparisonQualification.excludedRecords,
  };

  return VehicleComparisonSubject(
    vehicleId: vehicleId,
    consumptionL100Km:
        _consumption(stats, unit, coverage).qualifiedBy(extra),
    costPerKm: _costPerKm(stats, coverage).qualifiedBy(extra),
    recordedSpend: _recordedSpend(stats, coverage),
    spend: stats.spend,
    quantityUnit: unit,
    coverage: coverage,
    stats: stats,
  );
}

/// Total recorded driving time, or null when no trip carries both ends.
Duration? _recordedTime(List<TripHistoryEntry> trips) {
  var total = Duration.zero;
  var any = false;
  for (final t in trips) {
    final start = t.summary.startedAt;
    final end = t.summary.endedAt;
    if (start == null || end == null || !end.isAfter(start)) continue;
    total += end.difference(start);
    any = true;
  }
  return any ? total : null;
}

ComparableMetric<double> _consumption(
    ConsumptionStats stats, FuelQuantityUnit unit, ComparisonCoverage coverage) {
  if (!unit.isLitreBased) {
    // #4364 — kg and kWh histories keep their native spend and get NO
    // L/100 km. A suffix swap does not convert a quantity.
    return ComparableMetric.unavailable(
        unit == FuelQuantityUnit.unknown
            ? ComparisonUnavailableReason.incompatibleUnits
            : ComparisonUnavailableReason.unsupportedUnit,
        coverage: coverage);
  }
  final value = stats.avgConsumptionL100km;
  if (value == null || !value.isFinite || value <= 0) {
    return ComparableMetric.unavailable(
        stats.closedWindowCount == 0
            ? ComparisonUnavailableReason.noEvidence
            : ComparisonUnavailableReason.noMatchedDistance,
        coverage: coverage);
  }
  return ComparableMetric.comparable(DataValue.measured(value),
      coverage: coverage);
}

ComparableMetric<double> _costPerKm(
    ConsumptionStats stats, ComparisonCoverage coverage) {
  final reason = _moneyRefusal(stats.closedWindowSpend,
      unpriced: stats.unpricedClosedWindowFillCount);
  if (reason != null) {
    return ComparableMetric.unavailable(reason, coverage: coverage);
  }
  final value = stats.avgCostPerKm;
  if (value == null || !value.isFinite) {
    return ComparableMetric.unavailable(
        stats.closedWindowCount == 0
            ? ComparisonUnavailableReason.noEvidence
            : ComparisonUnavailableReason.noMatchedDistance,
        coverage: coverage);
  }
  return ComparableMetric.comparable(DataValue.measured(value),
      coverage: coverage);
}

ComparableMetric<Money> _recordedSpend(
    ConsumptionStats stats, ComparisonCoverage coverage) {
  final reason = _moneyRefusal(stats.spend, unpriced: 0);
  if (reason != null) {
    return ComparableMetric.unavailable(reason, coverage: coverage);
  }
  final money = stats.spend.soleMoney;
  if (money == null) {
    return ComparableMetric.unavailable(ComparisonUnavailableReason.noEvidence,
        coverage: coverage);
  }
  return ComparableMetric.comparable(DataValue.measured(money),
      coverage: coverage);
}

/// Why [tally] may not produce one comparable number, or null when it
/// may. Unknown currency is refused BEFORE mixing: an amount whose
/// currency was never recorded cannot enter a euro figure, and the
/// active country's currency is not evidence of what was paid.
ComparisonUnavailableReason? _moneyRefusal(MoneyTally tally,
    {required int unpriced}) {
  if (unpriced > 0) return ComparisonUnavailableReason.missingPrices;
  if (!tally.isSingleDenomination) {
    return ComparisonUnavailableReason.mixedCurrencies;
  }
  if (tally.hasUnknownCurrency) {
    return ComparisonUnavailableReason.unknownCurrency;
  }
  return null;
}

/// The cheapest vehicle per km, or the reason none may be crowned.
ComparableMetric<String> _cheapest(
    List<VehicleComparisonSubject> subjects, MoneyValuationPolicy? valuation) {
  final ranked = [
    for (final s in subjects)
      if (s.costPerKm.isComparable && s.costPerKm.valueOrNull != null) s,
  ];
  if (ranked.length < 2) {
    return ComparableMetric.unavailable(
        ComparisonUnavailableReason.noEvidence);
  }
  final currencies = {for (final s in ranked) s.spend.soleCurrency};
  if (currencies.length > 1) {
    final converted = _convertedRanking(ranked, valuation);
    if (converted != null) return converted;
    return ComparableMetric.unavailable(
        valuation == null
            ? ComparisonUnavailableReason.mixedCurrencies
            : ComparisonUnavailableReason.exchangeRateUnavailable);
  }
  final qualifications = <ComparisonQualification>{
    ComparisonQualification.uncontrolledConditions,
    if (_unequalSamples(ranked)) ComparisonQualification.unequalSampleSizes,
  };
  final best = ranked.reduce(
      (a, b) => a.costPerKm.valueOrNull! <= b.costPerKm.valueOrNull! ? a : b);
  return ComparableMetric.qualified(DataValue.measured(best.vehicleId),
      qualifications: qualifications, coverage: best.coverage);
}

/// The ranking after an explicit, dated conversion — or null when any
/// side refused to convert.
ComparableMetric<String>? _convertedRanking(
    List<VehicleComparisonSubject> ranked, MoneyValuationPolicy? valuation) {
  if (valuation == null) return null;
  VehicleComparisonSubject? best;
  var bestCost = double.infinity;
  for (final s in ranked) {
    final native = s.spend.soleCurrency;
    if (native == null) return null;
    final conversion = valuation.rates.convert(
        Money(s.costPerKm.valueOrNull!, native),
        valuation.targetCurrency,
        valuation.asOf);
    final converted = conversion.converted;
    if (converted == null) return null;
    if (converted.amount < bestCost) {
      bestCost = converted.amount;
      best = s;
    }
  }
  if (best == null) return null;
  return ComparableMetric.qualified(
    DataValue.measured(best.vehicleId),
    qualifications: {
      ComparisonQualification.convertedCurrency,
      ComparisonQualification.uncontrolledConditions,
      if (_unequalSamples(ranked)) ComparisonQualification.unequalSampleSizes,
    },
    coverage: best.coverage,
  );
}

/// True when one subject rests on at least twice the windows of another
/// — comparable, but not on equal evidence.
bool _unequalSamples(List<VehicleComparisonSubject> ranked) {
  final counts = [for (final s in ranked) s.coverage.windowCount];
  final low = counts.reduce((a, b) => a < b ? a : b);
  final high = counts.reduce((a, b) => a > b ? a : b);
  return low == 0 || high >= low * 2;
}
