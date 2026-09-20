// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import 'package:meta/meta.dart';

import '../data_value.dart';
import 'fleet_provenance.dart';

/// What a fleet-facing number may be *used for* (#4219, ADR 0025).
///
/// [DataValue] says how far a number may be trusted; [FleetMetricSource]
/// says which branch produced it. A claim class sits above both: it is
/// the answer to "may this figure enter a reimbursement, a CO2
/// disclosure, a coaching screen?" — and the UI must never blur the six.
enum ClaimClass {
  /// 1 — observed by the app or confirmed by the employee: litres and
  /// price from a confirmed fill-up or receipt.
  measuredFact,

  /// 2 — arithmetic over measured facts only: €/km from measured cost
  /// and measured distance.
  calculatedOperational,

  /// 3 — any input was modelled or stale: GPS / MAF consumption, or a
  /// €/km built on one. Always rendered with `≈` and its basis.
  estimate,

  /// 4 — could enter a reimbursement / VAT workflow **after** human and
  /// company confirmation. Never a total labelled "reimbursable".
  accountingCandidate,

  /// 5 — CO2 / CO2e under a **named** factor, version and scope. "Not
  /// calculated" when there is no factor.
  environmentalEstimate,

  /// 6 — derived from an identifiable person's activity: a behaviour
  /// residual, a journey pattern. Own-only; aggregate at manager level.
  personalDataInference,
}

/// The rendering rules ADR 0025 attaches to each class.
extension ClaimClassRules on ClaimClass {
  /// Classes 3 and 5 carry `≈` and a basis / factor label *always*,
  /// whatever the underlying [DataValue] says.
  bool get alwaysQualified =>
      this == ClaimClass.estimate || this == ClaimClass.environmentalEstimate;

  /// Class 4 needs a human and a company before it means anything.
  bool get requiresConfirmation => this == ClaimClass.accountingCandidate;

  /// Class 6 is personal data by construction.
  bool get isPersonalData => this == ClaimClass.personalDataInference;
}

/// A fleet number with everything it takes to state it honestly: the
/// value and its trust ([DataValue]), what it may be used for
/// ([ClaimClass]), how much evidence it rests on ([sampleCount]) and
/// which sources it was built from ([provenance]).
///
/// Two moves are impossible by construction (#4219):
///
///  * **an estimate can never be promoted to measured** — the
///    constructor refuses a [ClaimClass.measuredFact] over a modelled
///    value or an estimating source, [map] keeps the class, and
///    [derive] refuses `measuredFact` as a target while degrading
///    `calculatedOperational` to `estimate` when any input is qualified;
///  * **a missing input can never become a numeric claim** — an
///    [Unknown] input stays `Unknown` with its reason through every
///    derivation, and the compute function never runs.
@immutable
final class ClaimedValue<T> {
  /// The one constructor every factory goes through; validates the
  /// invariants and throws [ArgumentError] when they do not hold.
  ClaimedValue(
    this.value, {
    required this.claim,
    this.sampleCount = 1,
    this.provenance = const [],
  }) {
    if (sampleCount < 0) {
      throw ArgumentError.value(sampleCount, 'sampleCount', 'negative');
    }
    if (value.isKnown && provenance.isEmpty) {
      throw ArgumentError('a known value must name at least one source');
    }
    // An unknown under class 1 is legitimate: the litres *would* be a
    // measured fact, and are not measured yet. The invariants below are
    // about a number that exists.
    if (claim == ClaimClass.measuredFact && value.isKnown) {
      if (value is! Measured<T> && value is! Stale<T>) {
        throw ArgumentError(
            'a measured fact must be an observed value, got $value');
      }
      if (!provenance.any((s) => s.isMeasured)) {
        throw ArgumentError(
            'a measured fact needs an observed source, got $provenance');
      }
      if (provenance.any(
          (s) => s.isEstimate || s == FleetMetricSource.derived)) {
        throw ArgumentError(
            'a measured fact cannot rest on an estimate: $provenance');
      }
    }
  }

  /// Const form for callers whose inputs are literals; the invariants
  /// above are the caller's responsibility here (no runtime check is
  /// possible in a const constructor). Prefer the validating factories.
  const ClaimedValue.unchecked(
    this.value, {
    required this.claim,
    this.sampleCount = 1,
    this.provenance = const [],
  });

  /// Class 1 over an observed value and an observed [source]. Validated.
  factory ClaimedValue.measuredFact(
    T observed, {
    required FleetMetricSource source,
    DateTime? at,
    int sampleCount = 1,
  }) =>
      ClaimedValue(Measured<T>(observed, at: at),
          claim: ClaimClass.measuredFact,
          sampleCount: sampleCount,
          provenance: [source]);

  /// Class 3 over a modelled value. Validated.
  factory ClaimedValue.estimate(
    T modelled, {
    required DataBasis basis,
    required FleetMetricSource source,
    int sampleCount = 1,
  }) =>
      ClaimedValue(Estimated<T>(modelled, basis: basis),
          claim: ClaimClass.estimate,
          sampleCount: sampleCount,
          provenance: [source]);

  /// "Not calculated" — with the reason, under the class the number
  /// *would* have had. No source, no samples.
  factory ClaimedValue.notCalculated({
    required DataUnknownReason reason,
    required ClaimClass claim,
  }) =>
      ClaimedValue(Unknown<T>(reason: reason), claim: claim, sampleCount: 0);

  /// The number and how far it may be trusted.
  final DataValue<T> value;

  /// What it may be used for.
  final ClaimClass claim;

  /// How many observations it rests on (the weakest input's count after
  /// a derivation; 0 for an unknown).
  final int sampleCount;

  /// The sources it was built from, in first-seen order, deduplicated.
  final List<FleetMetricSource> provenance;

  /// The value when there is one, else null — for arithmetic only. A
  /// rendering path switches on [value] and reads [claim].
  T? get valueOrNull => value.valueOrNull;

  /// May be shown as a plain number: only a class-1 fact.
  bool get rendersAsMeasured => claim == ClaimClass.measuredFact;

  /// Needs `≈` / a basis or factor label: the value is modelled or
  /// stale, or the class always is (3 and 5).
  bool get isQualified => value.isQualified || claim.alwaysQualified;

  /// Class 4 gate, for callers that do not want to reach into [claim].
  bool get requiresConfirmation => claim.requiresConfirmation;

  /// Transform the number, keeping class, provenance and evidence count.
  /// Since [DataValue.map] cannot launder an unknown, neither can this.
  ClaimedValue<R> map<R>(R Function(T value) transform) =>
      ClaimedValue<R>.unchecked(value.map(transform),
          claim: claim, sampleCount: sampleCount, provenance: provenance);

  /// Build a metric from other metrics.
  ///
  /// * [claim] is the *requested* class. `measuredFact` is refused — a
  ///   derivation is never an observation. `calculatedOperational` is
  ///   degraded to `estimate` when any input [isQualified]; the other
  ///   classes keep their identity but carry the qualified value.
  /// * Any [Unknown] input short-circuits to an unknown result with
  ///   that input's reason; [compute] is not called.
  /// * The result's trust is [Measured] only when every input is, else
  ///   [Estimated] with [DataBasis.derived].
  /// * [sampleCount] is the minimum over the inputs; [provenance] is the
  ///   ordered union plus [FleetMetricSource.derived].
  static ClaimedValue<R> derive<R>(
    List<ClaimedValue<Object?>> inputs,
    R Function(List<Object?> values) compute, {
    required ClaimClass claim,
  }) {
    if (inputs.isEmpty) {
      throw ArgumentError('derive needs at least one input');
    }
    if (claim == ClaimClass.measuredFact) {
      throw ArgumentError('a derivation is never a measured fact');
    }
    final sources = <FleetMetricSource>[];
    for (final input in inputs) {
      for (final s in input.provenance) {
        if (!sources.contains(s)) sources.add(s);
      }
    }
    if (!sources.contains(FleetMetricSource.derived)) {
      sources.add(FleetMetricSource.derived);
    }
    for (final input in inputs) {
      if (input.value case Unknown<Object?>(:final reason)) {
        return ClaimedValue<R>.unchecked(Unknown<R>(reason: reason),
            claim: claim, sampleCount: 0, provenance: sources);
      }
    }
    final anyQualified = inputs.any((i) => i.isQualified);
    final result = compute([for (final i in inputs) i.valueOrNull]);
    final samples =
        inputs.map((i) => i.sampleCount).reduce(math.min);
    return ClaimedValue<R>.unchecked(
      anyQualified
          ? Estimated<R>(result, basis: DataBasis.derived)
          : Measured<R>(result),
      claim: claim == ClaimClass.calculatedOperational && anyQualified
          ? ClaimClass.estimate
          : claim,
      sampleCount: samples,
      provenance: sources,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ClaimedValue<T> &&
      other.value == value &&
      other.claim == claim &&
      other.sampleCount == sampleCount &&
      _sameList(other.provenance, provenance);

  @override
  int get hashCode =>
      Object.hash(value, claim, sampleCount, Object.hashAll(provenance));

  @override
  String toString() =>
      'ClaimedValue($value, ${claim.name}, n=$sampleCount, '
      '${provenance.map((s) => s.wireName).join('+')})';

  static bool _sameList(
      List<FleetMetricSource> a, List<FleetMetricSource> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
