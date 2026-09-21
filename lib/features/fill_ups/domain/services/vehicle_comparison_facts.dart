// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// The small facts a #4365 comparison column is made of — what backs a
/// figure, what the tank held when the period opened, how the vehicle
/// was refuelled, and how one column differs from the reference.
///
/// Split from `vehicle_history_comparison.dart` (which re-exports it)
/// so both stay inside the #1680 400-line cap; the two are one contract.
library;

import 'package:meta/meta.dart';

import '../../../../core/domain/comparison_eligibility.dart';
import '../../../../core/domain/fuel_type.dart';

/// One displayed number, so a drilldown can name the records behind it.
enum ComparisonFigure {
  consumption,
  costPerKm,
  consumedFuelCost,
  recordedSpend,
  pricePerUnit,
  refuelling,
  range,
}

/// The records one [ComparisonFigure] was computed from (#4365 — the
/// summary→source drilldown). Ids, never copies: the records live in
/// their repositories and a comparison must not fork them.
@immutable
final class FigureSources {
  FigureSources({
    Iterable<String> fillIds = const [],
    Iterable<String> windowIds = const [],
    Iterable<String> tripIds = const [],
  })  : fillIds = List.unmodifiable(fillIds),
        windowIds = List.unmodifiable(windowIds),
        tripIds = List.unmodifiable(tripIds);

  /// Every fill-up that entered the figure.
  final List<String> fillIds;

  /// The CLOSING fill id of every counted window — a window's identity.
  final List<String> windowIds;

  final List<String> tripIds;

  bool get isEmpty => fillIds.isEmpty && windowIds.isEmpty && tripIds.isEmpty;

  int get recordCount => fillIds.length + tripIds.length;
}

/// The tank a period's first counted window opened on.
///
/// Derived from the FULL history before the period was selected, so a
/// report that begins between two fills still knows what was in the
/// tank — and says so rather than pretending the period started empty.
@immutable
final class OpeningTankContext {
  const OpeningTankContext({
    required this.openingFillId,
    required this.openedAt,
    required this.openingFuel,
    required this.openingOdometerKm,
    required this.precedesPeriodStart,
    required this.openingUnitPrice,
    required this.openingCurrency,
  });

  final String openingFillId;
  final DateTime openedAt;
  final FuelType openingFuel;
  final double openingOdometerKm;

  /// True when the opening fill is older than the report period — the
  /// carry-forward case the boundary policy exists for.
  final bool precedesPeriodStart;

  /// What that tank cost per unit, or null when the fill carried no
  /// price. Feeds the consumed-fuel valuation, nothing else.
  final double? openingUnitPrice;
  final String? openingCurrency;
}

/// How often, how much and how far apart this vehicle was refuelled.
///
/// Counts of REAL pump visits: corrections are bookkeeping, not visits,
/// and are reported on their own line.
@immutable
final class RefuellingPattern {
  const RefuellingPattern({
    required this.fillCount,
    required this.fullFillCount,
    required this.partialFillCount,
    required this.correctionCount,
    required this.totalQuantity,
    required this.typicalQuantity,
    required this.medianDistanceBetweenFillsKm,
    required this.medianTimeBetweenFills,
  });

  /// No pump visit at all; [correctionCount] may still be non-zero.
  const RefuellingPattern.empty({this.correctionCount = 0})
      : fillCount = 0,
        fullFillCount = 0,
        partialFillCount = 0,
        totalQuantity = 0,
        typicalQuantity = null,
        medianDistanceBetweenFillsKm = null,
        medianTimeBetweenFills = null;

  /// Real pump visits in the period.
  final int fillCount;
  final int fullFillCount;
  final int partialFillCount;

  /// Correction entries — counted apart, never a visit.
  final int correctionCount;

  /// Σ quantity pumped in the period, in the column's quantity unit.
  final double totalQuantity;

  /// The MEDIAN fill, not the mean: one 60 L holiday fill must not
  /// redefine a driver who tops up 20 L at a time.
  final double? typicalQuantity;

  final double? medianDistanceBetweenFillsKm;
  final Duration? medianTimeBetweenFills;

  bool get hasEvidence => fillCount > 0;
}

/// One vehicle's figure measured against the reference vehicle's.
@immutable
final class ComparisonDelta {
  const ComparisonDelta({
    required this.figure,
    required this.absolute,
    required this.percent,
    required this.qualifications,
  });

  final ComparisonFigure figure;

  /// subject − reference, in the figure's own unit.
  final double absolute;

  /// The same as a share of the reference, or null when the reference
  /// is zero (a percentage of nothing is not a number).
  final double? percent;

  /// The union of both sides' caveats — a delta is never cleaner than
  /// the dirtier of the two figures it came from.
  final Set<ComparisonQualification> qualifications;
}
