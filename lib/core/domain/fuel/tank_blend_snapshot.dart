// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'fuel_composition.dart';
import 'fuel_grade.dart';
import 'grade_composition_bounds.dart';
import 'tank_blend_state.dart';

/// Why a fold step met evidence that contradicted what it had tracked
/// (#4275). Anomalies are recorded, never silently clamped away: each one
/// names the event and says which resolution the engine applied.
enum TankBlendAnomalyKind {
  /// A consumption's minimum exceeded the most the tank could hold. The
  /// volume is widened to `[0, previous max]` — the figure or the fill
  /// history is wrong, and the engine cannot tell which.
  consumptionExceedsVolume,

  /// A single fill pumped more than the known capacity. The tank is
  /// treated as full of that grade.
  fillExceedsCapacity,

  /// The residual the engine believed in (tracked or read) could not fit
  /// beside the pumped litres. Its lower bound is dropped to zero and its
  /// upper bound capped at `capacity − litres`.
  residualExceedsCapacity,

  /// A pinned residual (full-tank arithmetic or a level reading) fell
  /// outside the tracked volume interval. The pin wins — it is evidence
  /// about this instant — and the disagreement is kept for diagnosis.
  observationContradictsTrackedVolume,
}

/// One recorded contradiction, traceable to its event.
final class TankBlendAnomaly {
  const TankBlendAnomaly({required this.eventId, required this.kind});

  final String eventId;
  final TankBlendAnomalyKind kind;

  Map<String, Object?> toJson() => {'eventId': eventId, 'kind': kind.name};

  /// Null for a kind this build does not know — a newer build's anomaly is
  /// dropped rather than crashing the decode of the whole snapshot.
  static TankBlendAnomaly? tryFromJson(Map<String, Object?> json) {
    final kind = TankBlendAnomalyKind.values
        .where((k) => k.name == json['kind'])
        .firstOrNull;
    final id = json['eventId'];
    if (kind == null || id is! String) return null;
    return TankBlendAnomaly(eventId: id, kind: kind);
  }
}

/// The derived tank blend after folding an event log (#4275).
///
/// ## Shares are guaranteed minimums
///
/// [gradeShares] maps each commercial grade to the share of the tank it is
/// GUARANTEED to hold given the evidence; [FuelGrade.unknown] carries the
/// slack nobody can attribute. The shares sum to 1. With complete evidence
/// the slack is 0 and every share is exact; each ambiguity — an unknown
/// grade, an unknown residual volume — moves share into the slack instead
/// of guessing where it belongs. Unknown is not zero: [exactShare] answers
/// null while any slack remains, mirroring [FuelComposition.exactFraction].
///
/// ## Volume is an interval
///
/// `[minLitres, maxLitres]`, with a null [maxLitres] meaning unbounded.
/// [totalLitres] is non-null only when the interval has collapsed.
///
/// ## Versioned and fingerprinted
///
/// [modelVersion], [tankCapacityLitres] and [logFingerprint] let a
/// persisted snapshot be checked against the current build and event log;
/// any mismatch means "recompute", which `TankBlendEngine.resume` does.
final class TankBlendSnapshot {
  TankBlendSnapshot({
    required Map<FuelGrade, double> gradeShares,
    required this.minLitres,
    required this.maxLitres,
    required this.tankCapacityLitres,
    required Iterable<String> appliedEventIds,
    required this.logFingerprint,
    Iterable<TankBlendAnomaly> anomalies = const [],
    this.modelVersion = TankBlendState.currentModelVersion,
  })  : gradeShares = Map.unmodifiable(gradeShares),
        appliedEventIds = List.unmodifiable(appliedEventIds),
        anomalies = List.unmodifiable(anomalies) {
    if (gradeShares.isEmpty ||
        gradeShares.values.any((v) => !v.isFinite || v < 0 || v > 1) ||
        (gradeShares.values.fold(0.0, (a, b) => a + b) - 1).abs() > 1e-6) {
      throw ArgumentError.value(gradeShares, 'gradeShares');
    }
    if (!minLitres.isFinite || minLitres < 0) {
      throw ArgumentError.value(minLitres, 'minLitres');
    }
    final max = maxLitres;
    if (max != null && (!max.isFinite || max < minLitres)) {
      throw ArgumentError.value(max, 'maxLitres');
    }
    final cap = tankCapacityLitres;
    if (cap != null && (!cap.isFinite || cap <= 0)) {
      throw ArgumentError.value(cap, 'tankCapacityLitres');
    }
    if (modelVersion < 1) {
      throw ArgumentError.value(modelVersion, 'modelVersion');
    }
  }

  final Map<FuelGrade, double> gradeShares;
  final double minLitres;
  final double? maxLitres;
  final double? tankCapacityLitres;

  /// Ids folded into this snapshot, in application order.
  final List<String> appliedEventIds;

  /// 32-bit FNV-1a over the applied events' canonical JSON, in order.
  final int logFingerprint;
  final List<TankBlendAnomaly> anomalies;
  final int modelVersion;

  static const _volumeEpsilon = 1e-9;

  /// Share attributable to no grade.
  double get unknownShare => gradeShares[FuelGrade.unknown] ?? 0;

  /// Composition certainty in `[0, 1]`: the share of the tank whose grade
  /// is established. It says nothing about the volume — see [totalLitres].
  double get confidence => (1 - unknownShare).clamp(0.0, 1.0);

  /// The guaranteed minimum share of [grade].
  double minimumShare(FuelGrade grade) => gradeShares[grade] ?? 0;

  /// The grade holding the largest share of the tank however the unknown
  /// share turns out (#4322): its guaranteed minimum exceeds every other
  /// grade's minimum plus ALL of the unknown share. Null when the evidence
  /// leaves the lead open — including a tie, or nothing attributed.
  FuelGrade? get establishedLeadingGrade {
    FuelGrade? lead;
    var first = 0.0;
    var second = 0.0;
    for (final entry in gradeShares.entries) {
      if (entry.key == FuelGrade.unknown) continue;
      if (entry.value > first) {
        second = first;
        first = entry.value;
        lead = entry.key;
      } else if (entry.value > second) {
        second = entry.value;
      }
    }
    return first > second + unknownShare + 1e-9 ? lead : null;
  }

  /// The exact share of [grade], or null while any share is unattributed.
  double? exactShare(FuelGrade grade) =>
      unknownShare > 1e-9 ? null : gradeShares[grade] ?? 0;

  /// Litres in the tank when known exactly, else null (never zero).
  double? get totalLitres {
    final max = maxLitres;
    if (max == null || max - minLitres > _volumeEpsilon) return null;
    return minLitres;
  }

  /// The chemical composition these grade shares guarantee — each grade's
  /// [guaranteedCompositionOf] weighted by its share.
  FuelComposition get composition {
    final fractions = <FuelComponent, double>{};
    for (final entry in gradeShares.entries) {
      if (entry.value == 0) continue;
      final bounds = guaranteedCompositionOf(entry.key);
      for (final part in bounds.fractions.entries) {
        fractions[part.key] =
            (fractions[part.key] ?? 0) + part.value * entry.value;
      }
    }
    // Renormalise away floating-point drift so the #4274 sum check holds.
    final total = fractions.values.fold(0.0, (a, b) => a + b);
    return FuelComposition({
      for (final e in fractions.entries) e.key: (e.value / total).clamp(0, 1),
    });
  }

  /// The #4274 canonical snapshot view. Provenance is the applied event
  /// ids, so every figure traces back to recorded evidence.
  TankBlendState toTankBlendState() => TankBlendState(
        composition: composition,
        totalLitres: totalLitres,
        confidence: confidence,
        provenance: appliedEventIds,
        modelVersion: modelVersion,
      );

  Map<String, Object?> toJson() => {
        'modelVersion': modelVersion,
        'gradeShares': {
          for (final grade in FuelGrade.values)
            if (gradeShares.containsKey(grade)) grade.key: gradeShares[grade],
        },
        'minLitres': minLitres,
        'maxLitres': maxLitres,
        'tankCapacityLitres': tankCapacityLitres,
        'appliedEventIds': appliedEventIds,
        'logFingerprint': logFingerprint,
        'anomalies': [for (final a in anomalies) a.toJson()],
      };

  /// Decodes a persisted snapshot. A grade key this build does not know
  /// folds into [FuelGrade.unknown] (the forward-version rule
  /// [FuelComposition.fromJson] follows), so a newer record still decodes
  /// — and its [modelVersion] tells the consumer to recompute it.
  factory TankBlendSnapshot.fromJson(Map<String, Object?> json) {
    final shares = <FuelGrade, double>{};
    final rawShares = Map<String, Object?>.from(json['gradeShares'] as Map);
    for (final entry in rawShares.entries) {
      final grade = FuelGrade.fromKey(entry.key);
      final key = (grade.isLiquid) ? grade : FuelGrade.unknown;
      shares[key] = (shares[key] ?? 0) + (entry.value as num).toDouble();
    }
    return TankBlendSnapshot(
      gradeShares: shares,
      minLitres: (json['minLitres'] as num).toDouble(),
      maxLitres: (json['maxLitres'] as num?)?.toDouble(),
      tankCapacityLitres: (json['tankCapacityLitres'] as num?)?.toDouble(),
      appliedEventIds:
          (json['appliedEventIds'] as List<Object?>).cast<String>(),
      logFingerprint: json['logFingerprint'] as int,
      anomalies: [
        for (final raw in json['anomalies'] as List<Object?>)
          if (TankBlendAnomaly.tryFromJson(
                  Map<String, Object?>.from(raw as Map))
              case final TankBlendAnomaly a)
            a,
      ],
      modelVersion: json['modelVersion'] as int,
    );
  }
}
