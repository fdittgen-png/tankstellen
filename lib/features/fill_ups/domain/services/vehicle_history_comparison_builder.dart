// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Builds a #4365 [VehicleHistoryComparison] — a PURE function of the
/// records, the key and an injected report instant.
///
/// ## It cannot change the active vehicle, by shape
///
/// The compared ids arrive in the [VehicleComparisonKey]; there is no
/// `Ref`, no container and no repository here, so selecting a column
/// has no path to `activeVehicleProfileProvider`. That is the #4364
/// property this file inherits and must keep: the rest of the app goes
/// on showing the car the driver actually selected, whatever they put
/// side by side in a report.
///
/// ## What it refuses to crown
///
/// A winner is withheld — never defaulted, never zero-filled — when
/// fewer than two subjects are comparable, when any ranked subject
/// rests on fewer than [kMinComparableWindows] closed windows (a
/// shorter history is not a confident winner), when denominations
/// differ with no conversion selected, or when the selected conversion
/// has no fresh rate. The per-column observations always ship anyway:
/// that is the whole point of metric-level eligibility.
library;

import '../../../../core/domain/comparison_eligibility.dart';
import '../../../../core/domain/data_value.dart';
import '../../../../core/domain/money.dart';
import '../../../../core/domain/money_tally.dart';
import '../../../../core/domain/vehicle_profile.dart';
import '../../../trips/api.dart';
import '../entities/fill_up.dart';
import 'vehicle_history_column_builder.dart';
import 'vehicle_history_comparison.dart';

/// Build the comparison [key] asks for.
///
/// [asOf] is injected (never the wall clock) and decides only whether
/// an observation is presented as current or stale, plus exchange-rate
/// freshness under [valuation]. Without a [valuation] no conversion
/// happens at all and vehicles in different currencies simply have no
/// combined winner.
VehicleHistoryComparison buildVehicleHistoryComparison({
  required VehicleComparisonKey key,
  required Iterable<FillUp> fillUps,
  required Iterable<TripHistoryEntry> trips,
  required DateTime asOf,
  Map<String, VehicleProfile> vehicles = const {},
  MoneyValuationPolicy? valuation,
  String? referenceVehicleId,
}) {
  final allFills = fillUps.toList(growable: false);
  final allTrips = trips.toList(growable: false);
  final ambiguous = _ambiguousFillIds(key.vehicleIds, allFills, vehicles);

  final columns = [
    for (final id in key.vehicleIds)
      buildVehicleHistoryColumn(ColumnInputs(
        vehicleId: id,
        vehicle: vehicles[id],
        fillUps: allFills,
        trips: allTrips,
        period: key.period,
        asOf: asOf,
        selectedVehicleCount: key.vehicleIds.length,
        ambiguousFillIds: ambiguous,
      )),
  ];

  final reference = key.vehicleIds.contains(referenceVehicleId)
      ? referenceVehicleId
      : (key.vehicleIds.isEmpty ? null : key.vehicleIds.first);

  return VehicleHistoryComparison(
    key: key,
    asOf: asOf,
    columns: columns,
    referenceVehicleId: reference,
    lowestConsumption: _lowest(columns, ComparisonFigure.consumption, null),
    lowestCostPerKm: _lowest(columns, ComparisonFigure.costPerKm, valuation),
    unassignedFillCount:
        allFills.where((f) => f.vehicleId == null).length - ambiguous.length,
    ambiguousFillCount: ambiguous.length,
    unassignedTripCount: allTrips.where((t) => t.vehicleId == null).length,
    missingVehicleIds: [
      for (final id in key.vehicleIds)
        if (!vehicles.containsKey(id)) id,
    ],
    valuation: valuation,
  );
}

/// Unassigned fills whose odometer falls inside the recorded range of
/// two or more selected vehicles (#4364: overlapping odometers).
///
/// Such a record belongs to exactly one car and nobody can say which,
/// so it enters NO total and is reported once. Crediting it to every
/// selected vehicle would inflate both sides of the comparison at the
/// same time.
Set<String> _ambiguousFillIds(List<String> vehicleIds, List<FillUp> fills,
    Map<String, VehicleProfile> vehicles) {
  if (vehicleIds.length < 2) return const {};
  final ranges = <String, (double, double)>{};
  for (final id in vehicleIds) {
    final odos = [
      for (final f in fills)
        if (f.vehicleId == id) f.odometerKm,
    ];
    if (odos.isEmpty) continue;
    odos.sort();
    ranges[id] = (odos.first, odos.last);
  }
  if (ranges.length < 2) return const {};
  final out = <String>{};
  for (final f in fills) {
    if (f.vehicleId != null) continue;
    var hits = 0;
    for (final r in ranges.values) {
      if (f.odometerKm >= r.$1 && f.odometerKm <= r.$2) hits += 1;
    }
    if (hits >= 2) out.add(f.id);
  }
  return out;
}

/// The vehicle with the lowest [figure], or the reason none may be
/// crowned.
ComparableMetric<String> _lowest(
  List<VehicleHistoryColumn> columns,
  ComparisonFigure figure,
  MoneyValuationPolicy? valuation,
) {
  final ranked = [
    for (final c in columns)
      if (c.metricFor(figure)?.isComparable ?? false)
        if (c.metricFor(figure)?.valueOrNull != null) c,
  ];
  if (ranked.length < 2) {
    return ComparableMetric.unavailable(ComparisonUnavailableReason.noEvidence);
  }
  // A shorter or lower-quality history must not become a confident
  // winner: below the minimum sample the ranking is withheld, and the
  // observations stay on their columns.
  if (ranked.any((c) => c.matchedWindowCount < kMinComparableWindows)) {
    return ComparableMetric.unavailable(
        ComparisonUnavailableReason.tooFewSamples);
  }
  if (ranked.map((c) => c.quantityUnit).toSet().length > 1) {
    return ComparableMetric.unavailable(
        ComparisonUnavailableReason.incompatibleUnits);
  }
  final isMoney = figure != ComparisonFigure.consumption;
  final currencies = {for (final c in ranked) c.matchedSpend.soleCurrency};
  if (isMoney && currencies.length > 1) {
    return _convertedRanking(ranked, figure, valuation);
  }
  if (isMoney && currencies.contains(kUnknownCurrency)) {
    return ComparableMetric.unavailable(
        ComparisonUnavailableReason.unknownCurrency);
  }
  final best = _best(ranked, figure);
  return ComparableMetric.qualified(
    DataValue.measured(best.vehicleId),
    qualifications: _rankQualifications(ranked, best, figure),
    coverage: best.coverage,
  );
}

/// The ranking after an explicit, dated conversion — or the reason the
/// conversion could not decide it.
ComparableMetric<String> _convertedRanking(
  List<VehicleHistoryColumn> ranked,
  ComparisonFigure figure,
  MoneyValuationPolicy? valuation,
) {
  if (valuation == null) {
    return ComparableMetric.unavailable(
        ComparisonUnavailableReason.mixedCurrencies);
  }
  VehicleHistoryColumn? best;
  var bestCost = double.infinity;
  for (final c in ranked) {
    final native = c.matchedSpend.soleCurrency;
    if (native == null || native == kUnknownCurrency) {
      return ComparableMetric.unavailable(
          ComparisonUnavailableReason.unknownCurrency);
    }
    final conversion = valuation.rates.convert(
        Money(c.metricFor(figure)!.valueOrNull!, native),
        valuation.targetCurrency,
        valuation.asOf);
    final converted = conversion.converted;
    if (converted == null) {
      return ComparableMetric.unavailable(
          conversion.refusal == MoneyConversionRefusal.rateStale
              ? ComparisonUnavailableReason.exchangeRateStale
              : ComparisonUnavailableReason.exchangeRateUnavailable);
    }
    if (converted.amount < bestCost) {
      bestCost = converted.amount;
      best = c;
    }
  }
  if (best == null) {
    return ComparableMetric.unavailable(
        ComparisonUnavailableReason.exchangeRateUnavailable);
  }
  return ComparableMetric.qualified(
    DataValue.measured(best.vehicleId),
    qualifications: {
      ComparisonQualification.convertedCurrency,
      ..._rankQualifications(ranked, best, figure),
    },
    coverage: best.coverage,
  );
}

VehicleHistoryColumn _best(
        List<VehicleHistoryColumn> ranked, ComparisonFigure figure) =>
    ranked.reduce((a, b) =>
        a.metricFor(figure)!.valueOrNull! <= b.metricFor(figure)!.valueOrNull!
            ? a
            : b);

/// Every caveat a crowned winner must carry.
Set<ComparisonQualification> _rankQualifications(
  List<VehicleHistoryColumn> ranked,
  VehicleHistoryColumn best,
  ComparisonFigure figure,
) {
  final counts = [for (final c in ranked) c.matchedWindowCount];
  final low = counts.reduce((a, b) => a < b ? a : b);
  final high = counts.reduce((a, b) => a > b ? a : b);
  return {
    ComparisonQualification.uncontrolledConditions,
    if (high >= low * 2) ComparisonQualification.unequalSampleSizes,
    for (final c in ranked)
      ...?c.metricFor(figure)?.qualifications.where(_travelsToTheRanking),
  };
}

/// Caveats that survive aggregation into a ranking. A per-column
/// exclusion count does not describe the ranking; a stale basis, a
/// reconstructed valuation or an unknown blend share does.
bool _travelsToTheRanking(ComparisonQualification q) =>
    q == ComparisonQualification.staleBasis ||
    q == ComparisonQualification.mixedProvenance ||
    q == ComparisonQualification.unknownBlendShare ||
    q == ComparisonQualification.reconstructedValuation;
