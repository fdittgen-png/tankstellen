// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:meta/meta.dart';

import '../../../../core/domain/fuel/fuel_composition.dart';
import '../../../../core/domain/fuel/fuel_grade.dart';
import '../../../../core/domain/fuel/grade_composition_bounds.dart';
import '../../../../core/domain/fuel/tank_blend_snapshot.dart';

/// One grade's whole-percent share of a tank, ready to format (#4278).
@immutable
final class MixShareView {
  const MixShareView(this.grade, this.percent);
  final FuelGrade grade;
  final int percent;

  @override
  bool operator ==(Object other) =>
      other is MixShareView && other.grade == grade && other.percent == percent;

  @override
  int get hashCode => Object.hash(grade, percent);

  @override
  String toString() => 'MixShareView(${grade.key}, $percent)';
}

/// A [TankBlendSnapshot] reduced to what a driver reads (#4278): whole
/// percentages that never overstate the evidence.
///
/// While any share is unattributed the grade shares are guaranteed
/// MINIMUMS, so they are rounded DOWN — "≥ 62 %" must still be true — and
/// the unknown share is whatever the floored figures leave. With complete
/// evidence the shares are exact and rounded to the nearest percent.
@immutable
final class TankMixView {
  const TankMixView._({
    required this.shares,
    required this.unknownPercent,
    required this.isExact,
    required this.minLitres,
    required this.maxLitres,
    required this.exactLitres,
    required this.capacityLitres,
    required this.plausibleMaxEthanolShare,
  });

  /// [ethanolEvidence] — the grades this vehicle was filled with or is
  /// approved for — bounds [plausibleMaxEthanolShare]'s unknown share.
  factory TankMixView.of(TankBlendSnapshot snapshot,
      {Iterable<FuelGrade> ethanolEvidence = const []}) {
    final exact = snapshot.unknownShare <= 1e-9;
    final grades = [
      for (final g in FuelGrade.values)
        if (g != FuelGrade.unknown && snapshot.minimumShare(g) > 0) g,
    ];
    final percents = exact
        ? _largestRemainder([for (final g in grades) snapshot.minimumShare(g)])
        : [
            for (final g in grades)
              (snapshot.minimumShare(g) * 100 + 1e-9).floor(),
          ];
    final shares = <MixShareView>[
      for (var i = 0; i < grades.length; i++)
        if (percents[i] > 0) MixShareView(grades[i], percents[i]),
    ]..sort((a, b) {
        final byShare = b.percent.compareTo(a.percent);
        return byShare != 0 ? byShare : a.grade.index.compareTo(b.grade.index);
      });
    final attributed = shares.fold(0, (sum, s) => sum + s.percent);
    return TankMixView._(
      shares: List.unmodifiable(shares),
      unknownPercent: exact ? 0 : (100 - attributed).clamp(0, 100),
      isExact: exact,
      minLitres: snapshot.minLitres,
      maxLitres: snapshot.maxLitres,
      exactLitres: snapshot.totalLitres,
      capacityLitres: snapshot.tankCapacityLitres,
      plausibleMaxEthanolShare:
          _plausibleMaxEthanolShare(snapshot, ethanolEvidence),
    );
  }

  /// The most ethanol each grade may legally hold (EN 15293 / EN 228
  /// upper limits): E85 85 %, E10 10 %, E5 and E98 5 %, everything else 0.
  static double _maxEthanolContent(FuelGrade grade) => switch (grade) {
        FuelGrade.e85 => 0.85,
        FuelGrade.e10 => 0.10,
        FuelGrade.e5 || FuelGrade.e98 => 0.05,
        _ => 0.0,
      };

  static double? _plausibleMaxEthanolShare(
      TankBlendSnapshot snapshot, Iterable<FuelGrade> evidence) {
    final known = [
      for (final e in snapshot.gradeShares.entries)
        if (e.key != FuelGrade.unknown && e.value > 0) e,
    ];
    final grades = {...evidence, for (final e in known) e.key};
    if (grades.isEmpty) return null;
    var share = 0.0;
    for (final e in known) {
      share += e.value * _maxEthanolContent(e.key);
    }
    final unknownCeiling =
        grades.map(_maxEthanolContent).reduce((a, b) => a > b ? a : b);
    return (share + snapshot.unknownShare * unknownCeiling).clamp(0.0, 1.0);
  }

  /// Whole percentages of exact shares that still sum to 100: floor each,
  /// then hand the missing points to the largest remainders.
  static List<int> _largestRemainder(List<double> shares) {
    final raw = [for (final s in shares) s * 100];
    final floors = [for (final r in raw) (r + 1e-9).floor()];
    var missing = 100 - floors.fold(0, (a, b) => a + b);
    final order = List.generate(raw.length, (i) => i)
      ..sort((a, b) => (raw[b] - floors[b]).compareTo(raw[a] - floors[a]));
    for (final i in order) {
      if (missing <= 0) break;
      floors[i]++;
      missing--;
    }
    return floors;
  }

  /// Grades with at least one whole percent, largest first.
  final List<MixShareView> shares;

  /// The share no grade can be credited with, in whole percent.
  final int unknownPercent;

  /// True when every share is established (no unknown slack at all).
  final bool isExact;
  final double minLitres;
  final double? maxLitres;

  /// The litres in the tank when the volume interval has collapsed.
  final double? exactLitres;
  final double? capacityLitres;

  /// The MOST ethanol (0..1) this tank can plausibly hold (#4322): each
  /// attributed grade at its standard's upper limit (E85 0.85), and the
  /// unknown share at the highest limit among the grades this vehicle has
  /// actually been filled with or is approved for — never E85 for a car
  /// with no E85 in either. Null when there is no such evidence at all.
  ///
  /// An UPPER bound on purpose, and only for excusing a symptom: the
  /// combustion-health lesson (#3701) asks "could the fuel explain these
  /// lean trims?", and answering with the guaranteed minimum re-fires the
  /// "lean +25 %" false alarm on every E85 trip. Claims — the mix shown,
  /// pricing, `tankFuelKey` — keep reading the guaranteed minimums.
  final double? plausibleMaxEthanolShare;

  /// Nothing about the tank's content can be attributed.
  bool get isUnknown => shares.isEmpty;

  /// The share the display leads with, or null when [isUnknown].
  MixShareView? get leading => shares.isEmpty ? null : shares.first;
}

/// What a commercial grade's fuel standard GUARANTEES, in whole percent
/// (#4278) — the general technical fact, never a claim about this car.
/// Read from [guaranteedCompositionOf], so the surface cannot drift from
/// the blend model's own bounds.
@immutable
final class GradeFactView {
  const GradeFactView._({
    required this.grade,
    required this.petrolPercent,
    required this.ethanolPercent,
    required this.dieselPercent,
    required this.openPercent,
  });

  factory GradeFactView.of(FuelGrade grade) {
    final c = guaranteedCompositionOf(grade);
    int pct(FuelComponent k) => ((c.fractions[k] ?? 0) * 100).round();
    return GradeFactView._(
      grade: grade,
      petrolPercent: pct(FuelComponent.petrol),
      ethanolPercent: pct(FuelComponent.ethanol),
      dieselPercent: pct(FuelComponent.diesel),
      openPercent: pct(FuelComponent.unknown),
    );
  }

  final FuelGrade grade;
  final int petrolPercent;
  final int ethanolPercent;
  final int dieselPercent;

  /// The band the standard leaves open.
  final int openPercent;
}
