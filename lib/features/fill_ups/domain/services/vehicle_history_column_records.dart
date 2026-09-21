// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// The record-shaped half of a #4365 comparison column: which trips
/// count, how the vehicle was refuelled, where it was refuelled, and
/// which records back each displayed number.
///
/// Attribution here is STRICT (#4364): `tripIsAttributedTo`, never the
/// lenient `tripsForVehicle`, which matches an unassigned trip against
/// every vehicle and would count one legacy drive twice in a two-car
/// comparison.
library;

import '../../../../core/domain/fuel/fuel_behaviour_evidence.dart';
import '../../../../core/domain/vehicle_comparison_key.dart';
import '../../../../core/domain/vehicle_profile.dart';
import '../../../trips/api.dart';
import '../entities/fill_up.dart';
import 'fuel_behaviour_evidence_log.dart';
import 'tank_report.dart';
import 'vehicle_comparison_facts.dart';

/// The trip evidence one column rests on.
class ColumnTrips {
  const ColumnTrips({
    required this.drivenCount,
    required this.drivenIds,
    required this.virtualCount,
    required this.estimatedCount,
    required this.recordedTime,
  });

  factory ColumnTrips.of({
    required String vehicleId,
    required VehicleProfile? vehicle,
    required Iterable<TripHistoryEntry> trips,
    required ComparisonPeriod period,
  }) {
    final attributed = [
      for (final t in trips)
        if (tripIsAttributedTo(t, vehicleId) && _inPeriod(t, period)) t,
    ];
    final driven = [
      for (final t in attributed)
        if (!t.summary.isVirtual && t.summary.distanceKm > 0) t,
    ];
    final evidence = tripFuelEvidenceFor(
        vehicleId: vehicleId, vehicle: vehicle, trips: attributed);
    var total = Duration.zero;
    var any = false;
    for (final t in driven) {
      final start = t.summary.startedAt;
      final end = t.summary.endedAt;
      if (start == null || end == null || !end.isAfter(start)) continue;
      total += end.difference(start);
      any = true;
    }
    return ColumnTrips(
      drivenCount: driven.length,
      drivenIds: [for (final t in driven) t.id],
      virtualCount: attributed.where((t) => t.summary.isVirtual).length,
      estimatedCount:
          evidence.where((e) => e.tier == EvidenceTier.estimated).length,
      recordedTime: any ? total : null,
    );
  }

  static bool _inPeriod(TripHistoryEntry t, ComparisonPeriod period) {
    final at = t.summary.startedAt ?? t.summary.endedAt;
    return at == null ? period.isAllHistory : period.contains(at);
  }

  final int drivenCount;
  final List<String> drivenIds;
  final int virtualCount;

  /// Trips whose fuel figure is modelled rather than measured. Non-zero
  /// beside a measured window count is what makes a column
  /// [ComparisonQualification.mixedProvenance].
  final int estimatedCount;
  final Duration? recordedTime;
}

/// The fills a window actually counted: strictly after the opening, up
/// to and including the closing plein — the #1362 walker's own rule.
List<FillUp> fillsInsideWindow(List<FillUp> scoped, TankPeriod w) => [
      for (final f in scoped)
        if (f.date.isAfter(w.opening.date) && !f.date.isAfter(w.closing.date))
          f,
    ];

/// Fills logged after the period's last full tank — the in-progress
/// window, excluded from every average.
int openWindowFillCount(List<FillUp> scoped, ComparisonPeriod period) {
  final inside = [
    for (final f in scoped)
      if (period.contains(f.date)) f,
  ]..sort((a, b) => a.date.compareTo(b.date));
  var lastFull = -1;
  for (var i = inside.length - 1; i >= 0; i--) {
    if (inside[i].isFullTank && !inside[i].isCorrection) {
      lastFull = i;
      break;
    }
  }
  return lastFull < 0 ? 0 : inside.length - 1 - lastFull;
}

/// Odometer span of [fills]. Context only — it covers distance no
/// closed window speaks for, so it is never used as a divisor.
double odometerSpan(List<FillUp> fills) {
  if (fills.length < 2) return 0;
  final odos = [for (final f in fills) f.odometerKm]..sort();
  return (odos.last - odos.first).clamp(0, double.infinity).toDouble();
}

/// The refuelling pattern of [real] pump visits, with [all] supplying
/// the correction count.
RefuellingPattern refuellingPattern(List<FillUp> real, List<FillUp> all) {
  final corrections = all.where((f) => f.isCorrection).length;
  if (real.isEmpty) {
    return RefuellingPattern.empty(correctionCount: corrections);
  }
  final sorted = [...real]..sort((a, b) => a.date.compareTo(b.date));
  final gapsKm = <double>[];
  final gapsSeconds = <double>[];
  for (var i = 1; i < sorted.length; i++) {
    final km = sorted[i].odometerKm - sorted[i - 1].odometerKm;
    if (km > 0) gapsKm.add(km);
    final secs =
        sorted[i].date.difference(sorted[i - 1].date).inSeconds.toDouble();
    if (secs > 0) gapsSeconds.add(secs);
  }
  final medianSeconds = medianOf(gapsSeconds);
  return RefuellingPattern(
    fillCount: sorted.length,
    fullFillCount: sorted.where((f) => f.isFullTank).length,
    partialFillCount: sorted.where((f) => !f.isFullTank).length,
    correctionCount: corrections,
    totalQuantity: sorted.fold<double>(0, (s, f) => s + f.liters),
    typicalQuantity: medianOf([for (final f in sorted) f.liters]),
    medianDistanceBetweenFillsKm: medianOf(gapsKm),
    medianTimeBetweenFills:
        medianSeconds == null ? null : Duration(seconds: medianSeconds.round()),
  );
}

/// The median of [values], or null when there are none. The median and
/// not the mean: one holiday fill must not redefine a driver.
double? medianOf(List<double> values) {
  if (values.isEmpty) return null;
  final sorted = [...values]..sort();
  final mid = sorted.length ~/ 2;
  return sorted.length.isOdd
      ? sorted[mid]
      : (sorted[mid - 1] + sorted[mid]) / 2;
}

/// Recorded station name → visit count. A fill-up records no brand and
/// no country, so neither is claimed.
Map<String, int> stationFillCounts(List<FillUp> fills) {
  final out = <String, int>{};
  for (final f in fills) {
    final name = f.stationName;
    if (name == null || name.isEmpty) continue;
    out[name] = (out[name] ?? 0) + 1;
  }
  return out;
}

/// The tank the first counted window opened on — the carry-forward
/// context a period beginning between two fills must preserve.
OpeningTankContext? openingContext(
    List<TankPeriod> matched, ComparisonPeriod period) {
  if (matched.isEmpty) return null;
  final opening = matched.first.opening;
  final price = opening.liters > 0 && opening.totalCost > 0
      ? opening.totalCost / opening.liters
      : null;
  return OpeningTankContext(
    openingFillId: opening.id,
    openedAt: opening.date,
    openingFuel: opening.fuelType,
    openingOdometerKm: opening.odometerKm,
    precedesPeriodStart: !period.contains(opening.date),
    openingUnitPrice: price,
    openingCurrency: price == null ? null : opening.currency,
  );
}

/// Which records back each displayed figure (#4365 drilldown).
Map<ComparisonFigure, FigureSources> figureSources({
  required List<TankPeriod> matched,
  required Map<String, List<FillUp>> windowFills,
  required List<FillUp> periodFills,
  required List<String> tripIds,
}) {
  final windowIds = [for (final w in matched) w.closing.id];
  final countedFillIds = <String>[
    for (final w in matched)
      for (final f in windowFills[w.closing.id] ?? const <FillUp>[]) f.id,
  ];
  final openingIds = [for (final w in matched) w.opening.id];
  final periodIds = [for (final f in periodFills) f.id];
  final windowSources =
      FigureSources(fillIds: countedFillIds, windowIds: windowIds);
  return {
    ComparisonFigure.consumption: windowSources,
    ComparisonFigure.costPerKm: windowSources,
    ComparisonFigure.consumedFuelCost: FigureSources(
        fillIds: [...openingIds, ...countedFillIds], windowIds: windowIds),
    ComparisonFigure.recordedSpend: FigureSources(fillIds: periodIds),
    ComparisonFigure.pricePerUnit: FigureSources(fillIds: periodIds),
    ComparisonFigure.refuelling:
        FigureSources(fillIds: periodIds, tripIds: tripIds),
    ComparisonFigure.range: windowSources,
  };
}
