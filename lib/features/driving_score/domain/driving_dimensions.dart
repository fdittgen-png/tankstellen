// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';

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

  /// Events or seconds of evidence behind [value].
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
  const DrivingDimensions(this.byKind);

  final Map<DrivingDimensionKind, DrivingDimension> byKind;

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
