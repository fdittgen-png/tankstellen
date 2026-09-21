// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/foundation.dart';

import 'driving_pattern_evidence.dart';

export 'driving_pattern_evidence.dart';

/// #4205 — the independently interpretable behaviour dimensions a trip is
/// described by. The 0–100 [DrivingScore] stays as a presentation
/// compatibility surface; it is never a fuel estimator or a fuel correction.
///
/// Every legacy penalty / credit maps onto one dimension:
///
/// | legacy term                                | dimension                |
/// |--------------------------------------------|--------------------------|
/// | hard accel, full throttle, pedal velocity  | [accelerationDemand]     |
/// | hard brake                                 | [brakingAnticipation]    |
/// | smoothness, speed efficiency (> 110 km/h)  | [speedStability]         |
/// | idling, revs while stationary              | [avoidableIdle]          |
/// | high RPM, lugging, hard shift, λ enrichment| [powertrainOperation]    |
/// | fuel-cut coast credit                      | [coasting]               |
///
/// New context dimensions ([curveApproach], [hillBehaviour],
/// [energyOscillation]) come from the road-load track (#4203), so a climb, a
/// curve or a stop is never a penalty by itself.
enum DrivingDimensionKind {
  accelerationDemand,
  brakingAnticipation,
  speedStability,
  avoidableIdle,
  curveApproach,
  hillBehaviour,
  powertrainOperation,
  energyOscillation,
  coasting,
}

/// How far a dimension's value can be trusted. [none] means the signals it
/// needs were missing — never that the behaviour was absent.
enum DimensionConfidence { none, low, medium, high }

@immutable
class DrivingDimension {
  const DrivingDimension({
    required this.kind,
    required this.value,
    required this.confidence,
    required this.evidenceCount,
    this.context = '',
  });

  const DrivingDimension.unknown(this.kind, {this.context = 'missing signal'})
      : value = null,
        confidence = DimensionConfidence.none,
        evidenceCount = 0;

  final DrivingDimensionKind kind;

  /// 0 (clear opportunity) … 1 (nothing to improve); null when unknown.
  final double? value;
  final DimensionConfidence confidence;

  /// Events or seconds of evidence behind [value] — **whichever the
  /// dimension happened to count**, and for `accelerationDemand` both at
  /// once (`accelEvents + fullThrottleSeconds.round()`).
  ///
  /// It is a within-trip confidence hint, NOT an aggregatable numerator.
  /// Never divide it by a distance and never sum it across trips: use
  /// [DrivingDimensions.totals], whose numerators are typed by what they
  /// count and carry their own eligible exposure (#4366).
  final int evidenceCount;

  /// A short machine-readable note of what the evidence was.
  final String context;

  Map<String, Object?> toJson() => {
        'value': value == null ? null : double.parse(value!.toStringAsFixed(3)),
        'confidence': confidence.name,
        'evidence': evidenceCount,
        if (context.isNotEmpty) 'context': context,
      };
}

@immutable
class DrivingDimensions {
  const DrivingDimensions(this.byKind, {this.rawTotals});

  final Map<DrivingDimensionKind, DrivingDimension> byKind;

  /// The typed evidence as computed, or null when this object was built
  /// without any — read it through [totals].
  final DrivingPatternTotals? rawTotals;

  /// #4366 — the same trip's evidence as TYPED, additive raw numerators
  /// with their eligible exposure, for cross-trip aggregation. Empty on
  /// a [DrivingDimensions] built without it (a hand-made test fixture, a
  /// trip too short to analyse): empty means "no evidence", never
  /// "measured zero", because a measured zero carries exposure.
  DrivingPatternTotals get totals => rawTotals ?? DrivingPatternTotals.empty;

  DrivingDimension operator [](DrivingDimensionKind kind) =>
      byKind[kind] ?? DrivingDimension.unknown(kind);

  /// The top [max] actionable opportunities: known, at least medium
  /// confidence, clearly below par — worst first, evidence as tie-break.
  List<DrivingDimension> topOpportunities({int max = 3}) {
    final candidates = byKind.values
        .where((d) =>
            d.value != null &&
            d.value! < 0.75 &&
            d.confidence.index >= DimensionConfidence.medium.index)
        .toList()
      ..sort((a, b) {
        final byValue = a.value!.compareTo(b.value!);
        return byValue != 0 ? byValue : b.evidenceCount.compareTo(a.evidenceCount);
      });
    return candidates.take(max).toList(growable: false);
  }

  Map<String, Object?> toJson() => {
        for (final d in byKind.values) d.kind.name: d.toJson(),
      };
}
