// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:meta/meta.dart';

import 'fuzzy_variables.dart';

/// The rule base of the fuzzy consumption engine (#4232): which driving
/// situations it recognises, what each one does to the physics estimate,
/// and which degraded variants stand in when an input is unavailable.
///
/// ## Consequents are neutral priors — nothing here is fitted
///
/// Every consequent in [FuzzyRuleBase.neutral] is **multiplier 1.0,
/// residual 0.0 L/h**. With no real trace in #4231's corpus there is no
/// evidence that the physics over- or under-reads in any situation, and
/// inventing one would be precisely the "fitted number" the epic's
/// validation gate exists to refuse. So the neutral rule base defuzzifies
/// to the physics estimate unchanged, for every input.
///
/// What it does carry is the **structure** fitting needs: the situations,
/// their antecedents, the degraded variants, and a stable id per rule so a
/// fitted rule base can replace a consequent without renumbering anything.
/// Fitting awaits #4231's native-fuel-rate traces (per-second targets); a
/// fitted rule base ships with a bumped [FuzzyRuleBase.rulesVersion].
@immutable
class FuzzyAntecedent {
  const FuzzyAntecedent(this.variable, this.term, {this.negated = false});

  final FuzzyVariable variable;
  final FuzzyTerm term;

  /// `NOT term` — membership `1 − μ`.
  final bool negated;
}

/// What a rule does to the physics estimate: `rate · multiplier + residual`.
@immutable
class FuzzyConsequent {
  const FuzzyConsequent({this.multiplier = 1, this.residualLPerHour = 0});

  /// The neutral prior: leave the physics estimate unchanged.
  static const FuzzyConsequent neutral = FuzzyConsequent();

  final double multiplier;
  final double residualLPerHour;
}

/// One rule: `IF all antecedents THEN consequent`, AND as `min`.
@immutable
class FuzzyRule {
  const FuzzyRule({
    required this.id,
    required this.antecedents,
    this.consequent = FuzzyConsequent.neutral,
    this.onlyWhenUnavailable = const [],
  });

  /// Stable identifier — a fitted rule base keeps the ids.
  final String id;
  final List<FuzzyAntecedent> antecedents;
  final FuzzyConsequent consequent;

  /// A **degraded** rule: it may fire only while every variable listed here
  /// is unavailable (missing, stale or invalid). This is how an input gap
  /// selects a documented substitute instead of a silent zero — e.g. idle
  /// recognised from speed alone when there is no RPM.
  final List<FuzzyVariable> onlyWhenUnavailable;

  bool get isDegraded => onlyWhenUnavailable.isNotEmpty;
}

/// An ordered, versioned rule base.
@immutable
class FuzzyRuleBase {
  const FuzzyRuleBase({required this.rulesVersion, required this.rules})
      : assert(rulesVersion >= 1, 'rule version starts at 1');

  /// Stamped as `ConsumptionModelVersion.rules`. Bump on ANY change to a
  /// rule, a consequent or a membership breakpoint.
  final int rulesVersion;

  /// Evaluated in this order; the evidence lists fired rules in it too.
  final List<FuzzyRule> rules;

  /// The shipped rule base: every consequent neutral (see the file doc).
  static const FuzzyRuleBase neutral =
      FuzzyRuleBase(rulesVersion: 1, rules: _neutralRules);
}

const _speed = FuzzyVariable.speed;
const _accel = FuzzyVariable.accel;
const _grade = FuzzyVariable.grade;
const _curve = FuzzyVariable.curvature;
const _stops = FuzzyVariable.stops;
const _rpm = FuzzyVariable.rpm;
const _load = FuzzyVariable.load;
const _throttle = FuzzyVariable.throttle;
const _coolant = FuzzyVariable.coolantTemp;
const _oil = FuzzyVariable.oilTemp;
const _mass = FuzzyVariable.vehicleMass;

/// The situations, in evaluation order. `d` suffix = degraded variant.
const List<FuzzyRule> _neutralRules = [
  // Idle: standing with the engine loafing.
  FuzzyRule(id: 'idle', antecedents: [
    FuzzyAntecedent(_speed, FuzzyTerm.standstill),
    FuzzyAntecedent(_rpm, FuzzyTerm.low),
  ]),
  FuzzyRule(
    id: 'idle-d',
    antecedents: [FuzzyAntecedent(_speed, FuzzyTerm.standstill)],
    onlyWhenUnavailable: [_rpm],
  ),
  // Urban: flowing at town speed, or the stop-and-go that dominates it.
  FuzzyRule(id: 'urban-cruise', antecedents: [
    FuzzyAntecedent(_speed, FuzzyTerm.urban),
    FuzzyAntecedent(_accel, FuzzyTerm.steady),
    FuzzyAntecedent(_stops, FuzzyTerm.flowing),
  ]),
  FuzzyRule(id: 'stop-and-go', antecedents: [
    FuzzyAntecedent(_speed, FuzzyTerm.urban),
    FuzzyAntecedent(_stops, FuzzyTerm.stopAndGo),
  ]),
  // Steady cruise on the flat — rolling-resistance vs aero dominated.
  FuzzyRule(id: 'rural-cruise', antecedents: [
    FuzzyAntecedent(_speed, FuzzyTerm.rural),
    FuzzyAntecedent(_accel, FuzzyTerm.steady),
    FuzzyAntecedent(_grade, FuzzyTerm.flat),
  ]),
  FuzzyRule(id: 'highway-cruise', antecedents: [
    FuzzyAntecedent(_speed, FuzzyTerm.highway),
    FuzzyAntecedent(_accel, FuzzyTerm.steady),
    FuzzyAntecedent(_grade, FuzzyTerm.flat),
  ]),
  FuzzyRule(id: 'highway-high-rpm', antecedents: [
    FuzzyAntecedent(_speed, FuzzyTerm.highway),
    FuzzyAntecedent(_rpm, FuzzyTerm.high),
  ]),
  // Acceleration under load; degraded to throttle, then to kinematics.
  FuzzyRule(id: 'accel-loaded', antecedents: [
    FuzzyAntecedent(_accel, FuzzyTerm.accelerating),
    FuzzyAntecedent(_load, FuzzyTerm.heavy),
  ]),
  FuzzyRule(
    id: 'accel-throttle-d',
    antecedents: [
      FuzzyAntecedent(_accel, FuzzyTerm.accelerating),
      FuzzyAntecedent(_throttle, FuzzyTerm.open),
    ],
    onlyWhenUnavailable: [_load],
  ),
  FuzzyRule(
    id: 'accel-kinematic-d',
    antecedents: [FuzzyAntecedent(_accel, FuzzyTerm.accelerating)],
    onlyWhenUnavailable: [_load, _throttle],
  ),
  FuzzyRule(id: 'accel-heavy-vehicle', antecedents: [
    FuzzyAntecedent(_accel, FuzzyTerm.accelerating),
    FuzzyAntecedent(_mass, FuzzyTerm.heavy),
  ]),
  // Climbing; degraded to grade alone.
  FuzzyRule(id: 'climb-loaded', antecedents: [
    FuzzyAntecedent(_grade, FuzzyTerm.uphill),
    FuzzyAntecedent(_load, FuzzyTerm.heavy),
  ]),
  FuzzyRule(
    id: 'climb-d',
    antecedents: [FuzzyAntecedent(_grade, FuzzyTerm.uphill)],
    onlyWhenUnavailable: [_load],
  ),
  FuzzyRule(id: 'climb-heavy-vehicle', antecedents: [
    FuzzyAntecedent(_grade, FuzzyTerm.uphill),
    FuzzyAntecedent(_mass, FuzzyTerm.heavy),
  ]),
  // Overrun: closed throttle while the engine is spun by the wheels —
  // the fuel-cut situation `FuzzyClassifier` recognises (#894).
  FuzzyRule(id: 'descent-overrun', antecedents: [
    FuzzyAntecedent(_grade, FuzzyTerm.downhill),
    FuzzyAntecedent(_throttle, FuzzyTerm.closed),
  ]),
  FuzzyRule(id: 'overrun', antecedents: [
    FuzzyAntecedent(_throttle, FuzzyTerm.closed),
    FuzzyAntecedent(_rpm, FuzzyTerm.low, negated: true),
    FuzzyAntecedent(_speed, FuzzyTerm.standstill, negated: true),
  ]),
  FuzzyRule(
    id: 'braking-d',
    antecedents: [FuzzyAntecedent(_accel, FuzzyTerm.braking)],
    onlyWhenUnavailable: [_throttle, _rpm],
  ),
  // A curve taken with a speed change (#4203 curve episodes).
  FuzzyRule(id: 'curve-transient', antecedents: [
    FuzzyAntecedent(_curve, FuzzyTerm.curving),
    FuzzyAntecedent(_accel, FuzzyTerm.steady, negated: true),
  ]),
  // Warm-up enrichment; degraded to oil temperature (#2515 precedence).
  FuzzyRule(id: 'cold-engine', antecedents: [
    FuzzyAntecedent(_coolant, FuzzyTerm.cold),
  ]),
  FuzzyRule(
    id: 'cold-engine-oil-d',
    antecedents: [FuzzyAntecedent(_oil, FuzzyTerm.cold)],
    onlyWhenUnavailable: [_coolant],
  ),
];
