// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'fuel_grade.dart';
import 'tank_blend_snapshot.dart';

/// Minimum GUARANTEED share of one grade for a tank to count as that pure
/// grade (#4276).
///
/// 0.85 is the line ADR 0015 already draws for fill-up buckets
/// (`kMaxMinorityShareForPure = 0.15`): a 10 % splash-top reads as
/// "basically that grade", a 30 % blend is a different fuel. Reusing it
/// keeps the behaviour profile and the per-fuel comparison agreeing on what
/// "pure E85" means. Because [TankBlendSnapshot.gradeShares] are guaranteed
/// minimums, the classification is sound: no assignment of the unknown
/// slack can take the grade below this line.
const double kPureGradeMinShare = 0.85;

/// The largest unattributable share a tank may carry and still be
/// classified at all (#4276). Above it the context is
/// [FuelContextKind.unknown] — evidence from that trip teaches nothing
/// about any grade.
///
/// Mirrors [kPureGradeMinShare]: if more than 15 % of the tank could be
/// anything, the slack alone could move a blend across the pure/mixed line
/// ADR 0015 tolerates, so the label would be a guess.
const double kMaxUnknownShareForContext = 0.15;

/// Share below which a grade is a trace, not a constituent of a mixed
/// bucket. Same 1 % floor `TankMixEstimate.isBlend` uses.
const double kMinConstituentShare = 0.01;

/// What a tank held, reduced to the unit behaviour is learned per (#4276).
enum FuelContextKind {
  /// One grade holds at least [kPureGradeMinShare].
  pure,

  /// Classified, but no grade reaches [kPureGradeMinShare]. Keyed by the
  /// constituent grades, so an E5/E10 mix never shares a bucket with an
  /// E10/E85 mix.
  mixed,

  /// The unknown share exceeds [kMaxUnknownShareForContext], or nothing
  /// was attributable.
  unknown,
}

/// A behaviour-learning bucket: a pure grade, a mixed set of grades, or
/// unknown (#4276).
///
/// Isolation is a property of this type: evidence is grouped by [key], and
/// no computation ever reads across keys. E10 learning cannot become E85
/// learning because they are different keys, and a mixed E10/E85 tank is
/// a third key rather than a share of either.
final class FuelContext implements Comparable<FuelContext> {
  const FuelContext._(this.kind, this.grades);

  /// A pure-grade context.
  factory FuelContext.pure(FuelGrade grade) {
    if (!grade.isLiquid) throw ArgumentError.value(grade, 'grade');
    return FuelContext._(FuelContextKind.pure, [grade]);
  }

  /// A mixed context over [grades] (at least two liquid grades). Order is
  /// canonicalised, so `{E85, E10}` and `{E10, E85}` are the same bucket.
  factory FuelContext.mixed(Iterable<FuelGrade> grades) {
    final set = grades.toSet();
    if (set.length < 2 || set.any((g) => !g.isLiquid)) {
      throw ArgumentError.value(grades, 'grades');
    }
    return FuelContext._(
        FuelContextKind.mixed, List.unmodifiable(_canonical(set)));
  }

  /// The unknown context.
  static const FuelContext unknown =
      FuelContext._(FuelContextKind.unknown, <FuelGrade>[]);

  final FuelContextKind kind;

  /// The pure grade, or the mixed constituents in [FuelGrade] order.
  final List<FuelGrade> grades;

  /// The pure grade, or null for a mixed/unknown context.
  FuelGrade? get pureGrade =>
      kind == FuelContextKind.pure ? grades.single : null;

  /// Stable identity: `pure:e85`, `mixed:e10+e85`, `unknown`.
  String get key => switch (kind) {
        FuelContextKind.pure => 'pure:${grades.single.key}',
        FuelContextKind.mixed => 'mixed:${grades.map((g) => g.key).join('+')}',
        FuelContextKind.unknown => 'unknown',
      };

  /// Classifies [snapshot] (see the thresholds above).
  ///
  /// A mixed bucket takes the two grades with the largest guaranteed share
  /// (ties by [FuelGrade] order); a third grade's litres still belong to
  /// the bucket, as in ADR 0015. An unordered pair rather than
  /// dominant/secondary: with slack in the tank the dominant grade can be
  /// ambiguous, and the bucket must not flip on it.
  static FuelContext classify(TankBlendSnapshot snapshot) {
    if (snapshot.unknownShare > kMaxUnknownShareForContext) return unknown;
    final known = [
      for (final g in FuelGrade.values)
        if (g != FuelGrade.unknown && snapshot.minimumShare(g) > 0) g,
    ]..sort((a, b) {
        final byShare =
            snapshot.minimumShare(b).compareTo(snapshot.minimumShare(a));
        return byShare != 0 ? byShare : a.index.compareTo(b.index);
      });
    if (known.isEmpty) return unknown;
    final top = known.first;
    if (snapshot.minimumShare(top) >= kPureGradeMinShare) {
      return FuelContext.pure(top);
    }
    final constituents = known
        .where((g) => snapshot.minimumShare(g) >= kMinConstituentShare)
        .take(2)
        .toList();
    if (constituents.length < 2) return unknown;
    return FuelContext.mixed(constituents);
  }

  /// Combines the contexts a tank passed through over one fill window.
  ///
  /// All equal → that context. Any unknown → unknown (part of the window
  /// burned fuel nobody can name). Otherwise the window burned more than
  /// one known context, which is a mixed bucket over the union's grades —
  /// the two most frequent across [contexts], ties by [FuelGrade] order.
  static FuelContext combine(Iterable<FuelContext> contexts) {
    final list = contexts.toList();
    if (list.isEmpty) return unknown;
    if (list.every((c) => c == list.first)) return list.first;
    if (list.any((c) => c.kind == FuelContextKind.unknown)) return unknown;
    final counts = <FuelGrade, int>{};
    for (final c in list) {
      for (final g in c.grades) {
        counts[g] = (counts[g] ?? 0) + 1;
      }
    }
    final ranked = counts.keys.toList()
      ..sort((a, b) {
        final byCount = counts[b]!.compareTo(counts[a]!);
        return byCount != 0 ? byCount : a.index.compareTo(b.index);
      });
    return FuelContext.mixed(ranked.take(2));
  }

  static List<FuelGrade> _canonical(Iterable<FuelGrade> grades) =>
      grades.toList()..sort((a, b) => a.index.compareTo(b.index));

  @override
  int compareTo(FuelContext other) => key.compareTo(other.key);

  @override
  bool operator ==(Object other) => other is FuelContext && other.key == key;

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() => 'FuelContext($key)';
}
