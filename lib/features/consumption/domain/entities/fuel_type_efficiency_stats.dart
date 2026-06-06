// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../search/domain/entities/fuel_type.dart';

part 'fuel_type_efficiency_stats.freezed.dart';

/// A composition bucket for the per-fuel efficiency comparison (v2, ADR 0015).
///
/// Replaces ADR 0014's single-`FuelType` grouping key: a closed plein-to-plein
/// interval is now classified by its **fuel composition** rather than collapsed
/// to one dominant fuel. A bucket is EITHER:
///
/// - **PURE** — the interval's minority share is ≤ `kMaxMinorityShareForPure`,
///   so it is treated as the [dominant] fuel alone ([secondary] is `null`,
///   [isMix] is `false`). Display label is the dominant grade code (e.g. `E85`).
/// - **MIX** — the minority share exceeds the threshold, so the bucket is the
///   `dominant/secondary` blend ([secondary] non-null, [isMix] `true`). Display
///   label is the `A/B` mask (e.g. `E85/E10`), dominant first.
///
/// A 3-way blend folds into the two-largest mix label; all its litres still
/// land in that bucket (ADR 0015).
///
/// The [label] / [key] are language-neutral identities (a fuel grade code or a
/// `A/B` mask — see the i18n-ignore comments). Equality + `copyWith` come from
/// [freezed]; no JSON (it is a derived, never-persisted view key).
@freezed
abstract class FuelEfficiencyBucket with _$FuelEfficiencyBucket {
  const FuelEfficiencyBucket._();

  const factory FuelEfficiencyBucket({
    /// The interval's largest-share fuel — the only fuel for a PURE bucket,
    /// the first half of an `A/B` mix label otherwise.
    required FuelType dominant,

    /// The interval's second-largest-share fuel, present only for a MIX
    /// bucket. `null` ⇒ this is a PURE bucket.
    FuelType? secondary,
  }) = _FuelEfficiencyBucket;

  /// `true` when this is a blend ([secondary] non-null), `false` for a pure
  /// single-fuel bucket.
  bool get isMix => secondary != null;

  /// Language-neutral display label — the dominant grade code for a pure
  /// bucket (`E85`), or the `dominant/secondary` mask for a mix (`E85/E10`),
  /// dominant first. The `/` mask + grade codes are language-neutral format,
  /// so this string is exempt from translation (the surrounding prose is not).
  String get label {
    final d = _grade(dominant);
    final s = secondary;
    if (s == null) return d;
    return '$d/${_grade(s)}'; // i18n-ignore: language-neutral A/B mix mask
  }

  /// Stable map/sort key for this bucket — `dominant.apiValue` for a pure
  /// bucket, `dominant.apiValue|secondary.apiValue` for a mix. Deterministic
  /// across runs (used to dedupe + order rows + scope widget keys).
  String get key {
    final s = secondary;
    return s == null ? dominant.apiValue : '${dominant.apiValue}|${s.apiValue}';
  }

  /// Short, language-neutral pump code for [fuel]. Kept local (and tiny) so
  /// the entity has no widget/util dependency; mirrors `shortFuelLabel`.
  static String _grade(FuelType fuel) => switch (fuel) {
        FuelTypeE5() => 'E5', // i18n-ignore: language-neutral fuel grade code
        FuelTypeE10() => 'E10', // i18n-ignore: language-neutral fuel grade code
        FuelTypeE98() => 'E98', // i18n-ignore: language-neutral fuel grade code
        FuelTypeDiesel() =>
          'Diesel', // i18n-ignore: language-neutral fuel grade code
        FuelTypeDieselPremium() =>
          'Diesel+', // i18n-ignore: language-neutral fuel grade code
        FuelTypeE85() => 'E85', // i18n-ignore: language-neutral fuel grade code
        FuelTypeLpg() => 'GPL', // i18n-ignore: language-neutral fuel grade code
        FuelTypeCng() => 'GNV', // i18n-ignore: language-neutral fuel grade code
        FuelTypeHydrogen() =>
          'H2', // i18n-ignore: language-neutral fuel grade code
        FuelTypeElectric() =>
          'EV', // i18n-ignore: language-neutral fuel grade code
        FuelTypeAll() => 'all', // i18n-ignore: language-neutral wildcard code
      };
}

/// Per-composition-bucket efficiency stats for one vehicle (v2, ADR 0015).
///
/// A derived VIEW over a vehicle's fill-ups, produced by
/// `FuelTypeEfficiencyAggregator.byFuelType`. ADR 0015 (which supersedes ADR
/// 0014's dominant-fuel collapse) buckets each closed plein-to-plein interval
/// by its **fuel composition**: a tank ≥ 85 % one fuel is a PURE bucket, a more
/// even blend is a `dominant/secondary` MIX bucket. Pure and mix buckets are
/// directly comparable — a flex-fuel driver can pit pure E85 against an
/// E85/E10 blend.
///
/// This is a read-only projection (never cached, never persisted), so it
/// carries no JSON serialization — only [freezed] for value equality and
/// `copyWith`.
@freezed
abstract class FuelTypeEfficiencyStats with _$FuelTypeEfficiencyStats {
  const FuelTypeEfficiencyStats._();

  const factory FuelTypeEfficiencyStats({
    /// The composition bucket this row aggregates (pure or mix — ADR 0015).
    required FuelEfficiencyBucket bucket,

    /// Average litres / 100 km over the closed intervals classified into this
    /// bucket. `null` when [attributedIntervalCount] is 0 or every such
    /// interval had zero usable distance (odometer reset / open tail only).
    double? avgL100km,

    /// Average cost per km (store currency) over this bucket's intervals.
    /// `null` under the same condition as [avgL100km].
    double? avgCostPerKm,

    /// Σ `totalCost` of every non-correction fill folded into this bucket's
    /// intervals — "how much the tanks of this composition cost in total".
    required double totalSpent,

    /// Count of non-correction fills folded into this bucket's intervals.
    required int fillCount,

    /// Number of closed plein-to-plein intervals classified into this bucket.
    /// 0 ⇒ [avgL100km] / [avgCostPerKm] null.
    required int attributedIntervalCount,
  }) = _FuelTypeEfficiencyStats;

  /// The bucket's dominant fuel (the only fuel for a pure bucket, the
  /// larger share for a mix). Surfaced on every row, including mix rows.
  FuelType get dominant => bucket.dominant;

  /// The bucket's secondary fuel for a mix, `null` for a pure bucket.
  FuelType? get secondary => bucket.secondary;

  /// `true` when this bucket is a blend (ADR 0015 MIX), `false` for pure.
  bool get isMix => bucket.isMix;

  /// Language-neutral display label for this bucket (`E85` or `E85/E10`).
  String get label => bucket.label;
}
