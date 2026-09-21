// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// Metric-level eligibility for a comparison (#4364, Epic #4358 work
/// package I) — the contract #4365 (observed comparison), #4366 (driving
/// patterns) and #4367 (same-trip comparison) consume, and the one
/// #4214's fleet comparison adopts.
///
/// ## Why per METRIC and not per comparison
///
/// A vehicle comparison is not one verdict. Consumption may be
/// comparable while cost is not (two currencies), cost may be comparable
/// while the ranking is not (one vehicle has four windows and the other
/// has one), and a driving-pattern observation stays useful even when no
/// combined winner can be named. A single `isComparable` flag over the
/// whole result throws all of that away, so eligibility lives on each
/// [ComparableMetric]:
///
///  * [MetricEligibility.comparable] — say it plainly;
///  * [MetricEligibility.qualified] — say it WITH the stated
///    [ComparisonQualification]s, never bare;
///  * [MetricEligibility.unavailable] — say why, and show nothing else.
///
/// ## Two rules the type enforces by shape
///
/// 1. **An absent metric is never zero.** An unavailable metric has no
///    value at all; there is no `?? 0` to reach for, because
///    [ComparableMetric.valueOrNull] is the only accessor and it is null.
/// 2. **A qualification cannot be dropped on the way to a widget.** A
///    qualified metric carries a non-empty [qualifications] set — the
///    constructor rejects an empty one — so a renderer that forgets it
///    has nothing to render.
///
/// ## What it deliberately does NOT add
///
/// No new confidence scale. Trust comes from [DataValue] (#4160,
/// measured / estimated / stale / unknown); statistical spread comes from
/// `BehaviourMetric` (#4276); the consumption provenance comes from
/// [ConsumptionSourceClass] / `ConsumptionModelVersion` (#4230). This
/// type composes them and adds only the *eligibility* axis nothing owned.
///
/// Two claims this contract refuses to let a consumer make:
///
///  * a **sampling interval is not a sensor-accuracy percentage** — the
///    95 % interval on a `BehaviourMetric` describes spread between
///    drives, not how right the pipeline is (only the #4231 corpus can
///    say that);
///  * **observed cost is not intrinsic vehicle efficiency**, and neither
///    is it total ownership cost — see [MoneyValuationBasis].
library;

import 'package:meta/meta.dart';

import 'comparison_coverage.dart';
import 'data_value.dart';

export 'comparison_coverage.dart';

/// Whether one metric may be compared across the selected subjects.
enum MetricEligibility {
  /// Directly comparable as it stands.
  comparable,

  /// Comparable only with a stated qualification. The value is real and
  /// worth showing; the caveat travels with it.
  qualified,

  /// Not comparable. There is no value — not a zero, not a fallback.
  unavailable,
}

/// A caveat that keeps a metric usable but must be stated with it.
enum ComparisonQualification {
  /// No blend-independent expected-consumption input, so conditions are
  /// not controlled: a hilly winter reads as a worse vehicle.
  uncontrolledConditions,

  /// Only some of the confounding conditions were evaluated at all
  /// (production records cold starts, not grade or stop-and-go).
  partialConditionCoverage,

  /// The compared subjects rest on markedly different sample sizes.
  unequalSampleSizes,

  /// The figure is modelled, not observed.
  estimatedBasis,

  /// The figure was measured but is too old to present as current.
  staleBasis,

  /// Measured and estimated evidence both exist; they are reported side
  /// by side and never pooled as one observation.
  mixedProvenance,

  /// A currency conversion under a named, dated rate produced this
  /// figure — it is a report-time valuation, not the amount paid.
  convertedCurrency,

  /// Records were left out of the total; the count is in
  /// [ComparisonCoverage.exclusions].
  excludedRecords,

  /// The in-progress fill window after the last full tank is excluded.
  openWindowExcluded,

  /// Part of the tank's composition is not attributable to any grade.
  unknownBlendShare,

  /// The money is a reconstructed consumed-fuel valuation, not recorded
  /// purchase spend ([MoneyValuationBasis.modelledConsumedFuel]).
  reconstructedValuation,
}

/// Why a metric is not comparable at all.
enum ComparisonUnavailableReason {
  /// Nothing on record for this metric.
  noEvidence,

  /// Fewer samples than the metric's stated minimum.
  tooFewSamples,

  /// No matched distance to divide by.
  noMatchedDistance,

  /// Amounts in more than one currency; no conversion was selected.
  mixedCurrencies,

  /// Amounts whose currency was never recorded cannot be denominated.
  unknownCurrency,

  /// A conversion was asked for and no rate relates the currencies.
  exchangeRateUnavailable,

  /// A rate exists but is too old to decide a comparison.
  exchangeRateStale,

  /// Quantities in incompatible units (litres against kg or kWh).
  incompatibleUnits,

  /// The metric is only defined for litre-based fuels; this subject is
  /// sold by kg or kWh.
  unsupportedUnit,

  /// Records could not be attributed to exactly one subject.
  ambiguousAttribution,

  /// Some records in the matched window carry no price, so a total would
  /// be a partial sum masquerading as a cheap subject.
  missingPrices,

  /// No blend-independent expected-consumption input exists, so no
  /// condition-adjusted claim can be made.
  noExpectedConsumption,

  /// Not every confounding condition was evaluated, so "adjusted"
  /// would overstate what is known.
  incompleteConditionCoverage,
}

/// Which of the three distinct money quantities a figure is.
///
/// #4364 defect 2: `FuelTypeEfficiencyStats` surfaced a *reconstructed
/// consumed-fuel valuation* in a field called `totalSpent`. They are not
/// the same number, they do not move together, and only one of them is
/// what left the driver's bank account.
enum MoneyValuationBasis {
  /// Σ of what was actually paid at the pump for the counted fills. The
  /// only basis that is a fact about money.
  recordedPurchaseSpend,

  /// The purchase cost of the fills that CLOSED the matched windows,
  /// over the matched distance — the classic "€/km over full tanks".
  /// Reproducible from the window alone; blind to what the tank already
  /// held.
  closingWindowPurchaseCost,

  /// Burned volume valued at what each grade cost — a MODEL of the fuel
  /// consumed, not a purchase. Prices from purchases outside the counted
  /// windows may never enter it, or a later expensive fill would
  /// retroactively rewrite an earlier period.
  modelledConsumedFuel,
}

/// One metric of one subject, with its eligibility for comparison.
///
/// The value travels as a [DataValue] so measured / estimated / stale /
/// unknown is not re-invented here (#4160). An
/// [MetricEligibility.unavailable] metric has no [DataValue] at all — not
/// an `Unknown`, not a zero — because "we have no comparable figure" and
/// "the figure is zero" must never render alike.
@immutable
final class ComparableMetric<T extends Object> {
  ComparableMetric._(
    this.figure,
    this.eligibility,
    Set<ComparisonQualification> qualifications,
    this.reason,
    ComparisonCoverage? coverage,
  )   : qualifications = Set.unmodifiable(qualifications),
        coverage = coverage ?? ComparisonCoverage.none;

  /// Directly comparable. [figure] must carry a value.
  factory ComparableMetric.comparable(
    DataValue<T> figure, {
    ComparisonCoverage? coverage,
  }) {
    if (!figure.isKnown) {
      throw ArgumentError.value(
          figure, 'figure', 'a comparable metric must carry a value');
    }
    return ComparableMetric._(
        figure, MetricEligibility.comparable, const {}, null, coverage);
  }

  /// Comparable with stated caveats. [qualifications] may not be empty —
  /// an unqualified "qualified" is how a caveat goes missing.
  factory ComparableMetric.qualified(
    DataValue<T> figure, {
    required Set<ComparisonQualification> qualifications,
    ComparisonCoverage? coverage,
  }) {
    if (!figure.isKnown) {
      throw ArgumentError.value(
          figure, 'figure', 'a qualified metric must carry a value');
    }
    if (qualifications.isEmpty) {
      throw ArgumentError.value(qualifications, 'qualifications',
          'state the qualification or use ComparableMetric.comparable');
    }
    return ComparableMetric._(figure, MetricEligibility.qualified,
        qualifications, null, coverage);
  }

  /// Not comparable, and why. Carries no value.
  factory ComparableMetric.unavailable(
    ComparisonUnavailableReason reason, {
    ComparisonCoverage? coverage,
    Set<ComparisonQualification> qualifications = const {},
  }) =>
      ComparableMetric._(null, MetricEligibility.unavailable, qualifications,
          reason, coverage);

  /// The value with its trust, or null when unavailable.
  final DataValue<T>? figure;

  final MetricEligibility eligibility;

  /// Non-empty exactly when [eligibility] is
  /// [MetricEligibility.qualified]; may also decorate an unavailable
  /// metric with context.
  final Set<ComparisonQualification> qualifications;

  /// Set exactly when [eligibility] is [MetricEligibility.unavailable].
  final ComparisonUnavailableReason? reason;

  final ComparisonCoverage coverage;

  /// May this metric take part in a ranking at all?
  bool get isComparable => eligibility != MetricEligibility.unavailable;

  /// The number, or null. Never 0 as a stand-in for "we do not know".
  T? get valueOrNull => figure?.valueOrNull;

  /// The same metric with [extra] added to its qualifications — a
  /// comparable metric becomes qualified, an unavailable one stays
  /// unavailable.
  ComparableMetric<T> qualifiedBy(Set<ComparisonQualification> extra) {
    if (extra.isEmpty) return this;
    final merged = {...qualifications, ...extra};
    return ComparableMetric._(
      figure,
      eligibility == MetricEligibility.unavailable
          ? MetricEligibility.unavailable
          : MetricEligibility.qualified,
      merged,
      reason,
      coverage,
    );
  }

  Map<String, Object?> toJson() => {
        'eligibility': eligibility.name,
        'value': valueOrNull,
        'qualifications': [for (final q in qualifications) q.name],
        'reason': reason?.name,
        'coverage': coverage.toJson(),
      };

  @override
  String toString() => eligibility == MetricEligibility.unavailable
      ? 'ComparableMetric.unavailable(${reason!.name})'
      : 'ComparableMetric($valueOrNull, ${eligibility.name},'
          ' ${[for (final q in qualifications) q.name]})';
}
