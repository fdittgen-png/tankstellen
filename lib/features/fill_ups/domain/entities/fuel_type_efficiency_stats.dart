// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/domain/comparison_eligibility.dart';
import '../../../../core/domain/fuel/fuel_quantity_unit.dart';
import '../../../../core/domain/fuel_type.dart';
import '../../../../core/domain/money_tally.dart';

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
    /// bucket. `null` when [attributedIntervalCount] is 0, every such
    /// interval had zero usable distance (odometer reset / open tail only),
    /// or the bucket's fuel is not sold by the litre (#4364 — a kg or kWh
    /// quantity does not become litres by relabelling the suffix).
    double? avgL100km,

    /// Average cost per km over this bucket's intervals, in
    /// [recordedSpend]'s single denomination. `null` under the same
    /// conditions as [avgL100km], and also whenever the bucket's money
    /// spans more than one currency or a contributing fill carried no
    /// price at all (#4364).
    ///
    /// Its valuation basis is [MoneyValuationBasis.modelledConsumedFuel] —
    /// see [intervalCost]. It is an OBSERVED cost, not the vehicle's
    /// intrinsic efficiency and not a total cost of ownership.
    double? avgCostPerKm,

    /// What the fills folded into this bucket ACTUALLY cost at the pump
    /// (#4364) — [MoneyValuationBasis.recordedPurchaseSpend].
    ///
    /// This is the field that answers "how much did the tanks of this
    /// composition cost". It is NOT [intervalCost]: that one values the
    /// fuel the engine burned, which a fuel switch makes a visibly
    /// different number. `null` when the bucket's fills span more than
    /// one denomination — 30 EUR and 225 DKK have no common total.
    double? recordedPurchaseSpend,

    /// [recordedPurchaseSpend] segregated by the currency each fill
    /// recorded, unknown currencies in their own bucket (#4364).
    @Default(MoneyTally.empty) MoneyTally recordedSpend,

    /// Non-correction fills folded into this bucket that carried no
    /// recorded cost (#4364). Non-zero withholds every money figure: a
    /// missing price shrinks a numerator while its distance stays in the
    /// denominator, which manufactures a cheaper fuel.
    @Default(0) int unpricedFillCount,

    /// The unit this bucket's quantities are measured in (#4364).
    /// Litre-based buckets get consumption figures; kg (CNG, hydrogen)
    /// and kWh (electric) buckets keep their native spend and report no
    /// L/100 km at all.
    @Default(FuelQuantityUnit.litre) FuelQuantityUnit quantityUnit,

    /// Count of non-correction fills folded into this bucket's intervals.
    required int fillCount,

    /// Number of closed plein-to-plein intervals classified into this bucket.
    /// 0 ⇒ [avgL100km] / [avgCostPerKm] null.
    required int attributedIntervalCount,

    /// Of [attributedIntervalCount], how many were classified WITHOUT the
    /// carried-over opening tank content — the v2 contributing-fills-only
    /// fallback used when the opening content is unknowable (tank capacity
    /// not set, or the interval opened on a non-plein first fill / a
    /// synthetic correction). 0 ⇒ every interval used the full v3
    /// carried-content composition (#3764, ADR 0015 v3).
    @Default(0) int legacyAttributedIntervalCount,

    /// Σ litres over this bucket's attributed intervals (#3828).
    ///
    /// The aggregator has always summed this to derive [avgL100km] and then
    /// discarded it, which cost the screen its most comparable number: with
    /// litres AND [intervalCost] we can state the **price per litre** each
    /// fuel was actually bought at, instead of leaving the reader to infer
    /// why one fuel costs more per km while burning fewer litres.
    @Default(0) double totalLitres,

    /// Σ distance (km) over this bucket's attributed intervals (#3828).
    /// Says how much driving a row's verdict rests on.
    @Default(0) double totalDistanceKm,

    /// The MODELLED value of the fuel this bucket's intervals burned
    /// ([MoneyValuationBasis.modelledConsumedFuel]) — the burned volume
    /// split over the interval's composition and priced at what each
    /// grade cost (#3846).
    ///
    /// NOT recorded purchase spend (#4364): that is
    /// [recordedPurchaseSpend]. A field named `totalSpent` used to carry
    /// exactly this number, which made a reconstruction read as a bank
    /// statement. Only prices from fills inside the counted closed
    /// windows feed it, so appending a later expensive purchase cannot
    /// retroactively revalue an earlier period.
    ///
    /// `null` when the money is not denominable (mixed currencies, or a
    /// contributing fill with no price).
    double? intervalCost,
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

  /// What a litre of this composition actually cost, averaged over the
  /// attributed intervals (#3828). `null` when no litres were attributed.
  ///
  /// This is the number that drives the whole comparison and was previously
  /// invisible: a fuel can burn FEWER litres per 100 km and still cost more
  /// per km, which reads as a contradiction until the pump price is shown.
  double? get avgPricePerLitre => totalLitres > 0 && intervalCost != null
      ? intervalCost! / totalLitres
      : null;

  /// [avgCostPerKm] in the unit people actually reason in. A per-km figure
  /// like 0.057 is hard to feel; per 100 km is not.
  double? get avgCostPer100km =>
      avgCostPerKm == null ? null : avgCostPerKm! * 100;

  /// Cost of driving 1000 km on this composition — the unit used to express
  /// the gap between two fuels, where a per-km delta rounds to nothing.
  double? get costPer1000km =>
      avgCostPerKm == null ? null : avgCostPerKm! * 1000;

  /// The pump price at which THIS composition would match [other]'s cost per
  /// km, given the two measured consumptions (#3828).
  ///
  ///     costPerKm = (L/100km / 100) * pricePerLitre
  ///     => breakEven = other.costPerKm * 100 / this.L100km
  ///
  /// For an E85 driver this is the single most actionable number on the
  /// screen: below this price, the cheaper-per-litre fuel wins. `null` when
  /// either side lacks a measured consumption — never guessed.
  double? breakEvenPricePerLitreVersus(FuelTypeEfficiencyStats other) {
    final myL100 = avgL100km;
    final theirCostPerKm = other.avgCostPerKm;
    if (myL100 == null || myL100 <= 0 || theirCostPerKm == null) return null;
    return theirCostPerKm * 100 / myL100;
  }

  /// CO2 per km for this composition, given [kgCo2PerLitre] (#3828).
  ///
  /// The factor is passed IN rather than looked up here, so this entity stays
  /// pure and testable without reaching into `core/services`. Callers resolve
  /// it from `Co2Calculator.emissionFactorFor` — and only for PURE buckets,
  /// because a blend's true factor depends on shares this row does not carry.
  /// Guessing one would be worse than omitting the number.
  ///
  /// This is the axis the comparison was missing: a fuel can cost more per km
  /// and still be the better choice on emissions, which for E85 (1.11 kg/L
  /// WtW vs E5's 2.69) is the entire point of running it.
  double? co2PerKmWith(double? kgCo2PerLitre) {
    final l100 = avgL100km;
    if (kgCo2PerLitre == null || l100 == null) return null;
    return (l100 / 100) * kgCo2PerLitre;
  }

  /// [co2PerKmWith] over 1000 km — the unit the cost delta already uses, so
  /// the two sides of the trade-off are directly comparable.
  double? co2Per1000kmWith(double? kgCo2PerLitre) {
    final perKm = co2PerKmWith(kgCo2PerLitre);
    return perKm == null ? null : perKm * 1000;
  }

  /// The valuation [avgCostPerKm] and [intervalCost] rest on. Stated so
  /// a consumer can never present a reconstruction as recorded spend
  /// (#4364).
  MoneyValuationBasis get costValuationBasis =>
      MoneyValuationBasis.modelledConsumedFuel;

  /// True when this row rests on at least two closed full-tank intervals —
  /// the same bar the existing "record at least two full tanks" guard uses
  /// before crowning a winner. One interval is a data point, not a verdict.
  bool get isConfident => attributedIntervalCount >= 2;
}
