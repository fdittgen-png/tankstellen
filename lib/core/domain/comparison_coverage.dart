// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// What a comparison metric rests on, and what it left out (#4364).
///
/// Split from `comparison_eligibility.dart` (which re-exports it) so
/// both stay inside the #1680 400-line cap; the two are one contract.
library;

import 'package:meta/meta.dart';

import 'fuel/fuel_behaviour_evidence.dart';

/// Why a record was left out of a comparison total.
enum ComparisonExclusion {
  /// A trip or fill with no vehicle recorded. Counted once, never
  /// credited to every selected vehicle.
  unassignedVehicle,

  /// A record whose vehicle cannot be resolved to exactly one subject.
  ambiguousVehicle,

  /// A synthetic/virtual record — never a physical visit or drive.
  virtualRecord,

  /// A bookkeeping correction, not a purchase.
  correction,

  /// Engine-off transport: the vehicle moved, it did not drive.
  engineOffTransport,

  /// A fill in the matched window with no recorded cost.
  missingPrice,

  /// A fill whose currency was never recorded, in a total that has a
  /// named currency.
  unknownCurrencyRecord,

  /// A record in another currency than the total's.
  foreignCurrencyRecord,

  /// A fill or trip whose fuel is not litre-based.
  nonLitreUnit,

  /// Fills after the last full tank — the window has not closed.
  openWindow,

  /// Evidence carrying no usable figure.
  noFigure,
}

/// How much evidence a metric rests on, and what was left out.
///
/// Carried even by an unavailable metric: "no comparable cost, 12 fills
/// excluded for a missing price" is an actionable statement and
/// "unavailable" alone is not.
@immutable
final class ComparisonCoverage {
  ComparisonCoverage({
    this.tripCount = 0,
    this.windowCount = 0,
    this.coveredKm = 0,
    this.coveredTime,
    this.periodStart,
    this.periodEnd,
    this.conditionCoverage = 0,
    Map<ComparisonExclusion, int> exclusions = const {},
    Map<DrivingCondition, double> conditionShares = const {},
    Map<EvidenceTier, int> provenance = const {},
  })  : exclusions = Map.unmodifiable(
            {for (final e in exclusions.entries) if (e.value > 0) e.key: e.value}),
        conditionShares = Map.unmodifiable(conditionShares),
        provenance = Map.unmodifiable(provenance);

  /// Nothing measured and nothing excluded.
  static final ComparisonCoverage none = ComparisonCoverage();

  /// Valid, strictly attributed trips behind the metric.
  final int tripCount;

  /// Valid CLOSED full-to-full fill windows behind the metric.
  final int windowCount;

  /// Distance the metric actually speaks for.
  final double coveredKm;

  /// Recorded driving time the metric speaks for, when known.
  final Duration? coveredTime;

  /// The valid window the metric is true of — never "all history" when
  /// only part of it was counted.
  final DateTime? periodStart;
  final DateTime? periodEnd;

  /// Share of [coveredKm] whose FULL confounding-condition context was
  /// evaluated (0 when only some conditions are ever recorded). Not the
  /// share of distance that HAD a condition — that is
  /// [conditionShares].
  final double conditionCoverage;

  /// Records left out, by reason, zero-valued entries dropped.
  final Map<ComparisonExclusion, int> exclusions;

  /// Share of covered distance driven under each condition.
  final Map<DrivingCondition, double> conditionShares;

  /// How much of the evidence sat in each tier — measured and estimated
  /// counted apart, never pooled.
  final Map<EvidenceTier, int> provenance;

  /// Total records left out for any reason.
  int get excludedCount =>
      exclusions.values.fold(0, (sum, n) => sum + n);

  bool get hasEvidence => tripCount > 0 || windowCount > 0;

  Map<String, Object?> toJson() => {
        'tripCount': tripCount,
        'windowCount': windowCount,
        'coveredKm': coveredKm,
        'coveredSeconds': coveredTime?.inSeconds,
        'periodStart': periodStart?.toIso8601String(),
        'periodEnd': periodEnd?.toIso8601String(),
        'conditionCoverage': conditionCoverage,
        'exclusions': {
          for (final e in exclusions.entries) e.key.name: e.value,
        },
        'conditionShares': {
          for (final e in conditionShares.entries) e.key.name: e.value,
        },
        'provenance': {
          for (final e in provenance.entries) e.key.name: e.value,
        },
      };
}
