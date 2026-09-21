// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:math' as math;

import 'package:meta/meta.dart';

import '../../../../core/domain/consumption_estimate.dart';
import 'fuzzy_consumption_input.dart';
import 'fuzzy_inference_result.dart';
import 'fuzzy_rule_base.dart';
import 'fuzzy_variables.dart';

export 'fuzzy_consumption_input.dart';
export 'fuzzy_inference_result.dart';
export 'fuzzy_rule_base.dart';
export 'fuzzy_variables.dart';

/// The output guard band of the engine (#4232). Structural bounds, not
/// fitted values — they exist so no input and no rule base can produce a
/// figure outside physical plausibility.
abstract final class FuzzyOutputBounds {
  /// Above any road car at full load (a large petrol engine at wide-open
  /// throttle burns well under this). A fuel-rate **input** above it is
  /// rejected as invalid; an **output** is clamped to it.
  static const double maxFuelRateLPerHour = 100;

  /// Freshness horizon of a fuel-rate input (physics or native), seconds.
  static const double fuelRateStaleAfterSeconds = 3;

  /// The multiplier a rule base may apply, whatever its consequents say.
  static const double minMultiplier = 0.5;
  static const double maxMultiplier = 2;
}

/// How confidence is composed (#4232 "confidence reflects input
/// coverage/freshness"). **Not a calibrated probability**: calibrating it
/// against pump truth needs #4231's corpus. Until then it is an ordinal
/// score that is monotone in coverage and freshness.
abstract final class FuzzyConfidencePriors {
  /// Share of the ceiling a fresh physics input earns with zero context.
  static const double coverageFloor = 0.5;

  /// Ordinal ceiling per physics basis, in the corpus README's accuracy
  /// order (air mass tightest, GPS road-load loosest). Ordinal priors, not
  /// measured accuracies.
  static double ceilingFor(FuzzyPhysicsBasis basis) => switch (basis) {
        FuzzyPhysicsBasis.maf => 1.0,
        FuzzyPhysicsBasis.speedDensity => 0.85,
        FuzzyPhysicsBasis.gpsRoadLoad => 0.7,
      };
}

/// The fuzzy consumption inference engine (#4232, Epic #4222): a
/// zero-order Takagi–Sugeno system over the physics fuel-rate estimate.
///
/// ```
/// strength_i   = min over antecedents μ           (AND = min, NOT = 1 − μ)
/// default      = 1 − max_i strength_i              (the physics-prior rule)
/// multiplier   = (default · 1 + Σ s_i · m_i) / (default + Σ s_i)
/// residual     = (Σ s_i · r_i)               / (default + Σ s_i)
/// estimate     = clamp(physics · clamp(multiplier) + residual, 0, max)
/// ```
///
/// Binding semantics (ADR 0023):
///
///  * **Measured passes through.** A valid, fresh native ECU rate is the
///    sample's figure, untouched; the estimate beside it is evidence only.
///  * **Physics is an input.** The MAF / speed-density arithmetic and the
///    GPS road-load balance are computed by their owners and handed in.
///    This class calls no other estimator — a structural test pins its
///    imports.
///  * **Absence is stated.** Missing / stale / invalid inputs are recorded,
///    close their rules (opening documented degraded ones) and lower
///    confidence. No input ever becomes a zero.
///  * **Deterministic.** No clock, no randomness, no mutable state: the
///    same input and rule base give the same result.
@immutable
class FuzzyConsumptionEngine {
  const FuzzyConsumptionEngine({this.ruleBase = FuzzyRuleBase.neutral});

  /// The inference architecture's version (`ConsumptionModelVersion.model`).
  /// Bump when the inference itself changes — inputs, AND/defuzzification,
  /// bounds or the confidence composition.
  static const int modelVersion = 1;

  final FuzzyRuleBase ruleBase;

  /// The version stamped on every result.
  ConsumptionModelVersion get version => ConsumptionModelVersion(
      model: modelVersion, rules: ruleBase.rulesVersion);

  /// Infer one sample.
  FuzzyInferenceResult infer(FuzzyConsumptionInput input) {
    final statuses = <FuzzyVariable, FuzzyInputStatus>{};
    var freshnessSum = 0.0;
    for (final v in FuzzyVariable.values) {
      final reading = input.readingFor(v);
      final status = classifyReading(reading,
          min: v.min, max: v.max, staleAfterSeconds: v.staleAfterSeconds);
      statuses[v] = status;
      if (status == FuzzyInputStatus.fresh) {
        freshnessSum += freshnessOf(reading!, v.staleAfterSeconds);
      }
    }
    final coverage = freshnessSum / FuzzyVariable.values.length;

    final fired = <FuzzyFiredRule>[];
    final unevaluable = <String>[];
    var weightSum = 0.0;
    var multiplierSum = 0.0;
    var residualSum = 0.0;
    var maxStrength = 0.0;
    for (final rule in ruleBase.rules) {
      final gateOpen = rule.onlyWhenUnavailable
          .every((v) => statuses[v] != FuzzyInputStatus.fresh);
      if (!gateOpen) continue;
      final strength = _strengthOf(rule, input, statuses);
      if (strength == null) {
        unevaluable.add(rule.id);
        continue;
      }
      if (strength <= 0) continue;
      fired.add(FuzzyFiredRule(
          id: rule.id, strength: strength, degraded: rule.isDegraded));
      weightSum += strength;
      multiplierSum += strength * rule.consequent.multiplier;
      residualSum += strength * rule.consequent.residualLPerHour;
      maxStrength = math.max(maxStrength, strength);
    }
    final defaultStrength = 1 - maxStrength;
    weightSum += defaultStrength;
    multiplierSum += defaultStrength;
    // weightSum ≥ 1 by construction (max + (1 − max)), so no divide by 0.
    var multiplier = multiplierSum / weightSum;
    var residual = residualSum / weightSum;
    // A malformed rule base (non-finite consequent) degrades to the
    // physics prior rather than poisoning the figure.
    if (!multiplier.isFinite) multiplier = 1;
    if (!residual.isFinite) residual = 0;

    final physicsStatus = input.physicsBasis == null
        ? FuzzyInputStatus.missing
        : _fuelRateStatus(input.physicsFuelRateLPerHour);
    final nativeStatus = input.nativeSource == null
        ? FuzzyInputStatus.missing
        : _fuelRateStatus(input.nativeFuelRateLPerHour);

    double? inferred;
    if (physicsStatus == FuzzyInputStatus.fresh) {
      final physics = input.physicsFuelRateLPerHour!.value;
      final bounded = multiplier.clamp(
          FuzzyOutputBounds.minMultiplier, FuzzyOutputBounds.maxMultiplier);
      inferred = (physics * bounded + residual)
          .clamp(0.0, FuzzyOutputBounds.maxFuelRateLPerHour);
    }

    final native = nativeStatus == FuzzyInputStatus.fresh
        ? input.nativeFuelRateLPerHour!.value
        : null;
    final evidence = FuzzyEvidence(
      inputs: statuses,
      physicsStatus: physicsStatus,
      nativeStatus: nativeStatus,
      coverage: coverage,
      firedRules: fired,
      unevaluableRuleIds: unevaluable,
      defaultRuleStrength: defaultStrength,
      multiplier: multiplier,
      residualLPerHour: residual,
      nativeAgreementRatio:
          (native != null && native > 0 && inferred != null)
              ? inferred / native
              : null,
    );
    final speed = statuses[FuzzyVariable.speed] == FuzzyInputStatus.fresh
        ? input.speedKmh!.value
        : null;

    if (native != null) {
      return FuzzyInferenceResult(
        kind: FuzzyOutputKind.measured,
        version: version,
        evidence: evidence,
        fuelRateLPerHour: native,
        inferredFuelRateLPerHour: inferred,
        physicsBasis: inferred == null ? null : input.physicsBasis,
        nativeSource: input.nativeSource,
        speedKmh: speed,
      );
    }
    if (inferred != null) {
      final basis = input.physicsBasis!;
      final physicsFreshness = freshnessOf(input.physicsFuelRateLPerHour!,
          FuzzyOutputBounds.fuelRateStaleAfterSeconds);
      final confidence = FuzzyConfidencePriors.ceilingFor(basis) *
          physicsFreshness *
          (FuzzyConfidencePriors.coverageFloor +
              (1 - FuzzyConfidencePriors.coverageFloor) * coverage);
      return FuzzyInferenceResult(
        kind: FuzzyOutputKind.estimated,
        version: version,
        evidence: evidence,
        fuelRateLPerHour: inferred,
        inferredFuelRateLPerHour: inferred,
        confidence: confidence.clamp(0.0, 1.0),
        physicsBasis: basis,
        speedKmh: speed,
      );
    }
    return FuzzyInferenceResult(
      kind: FuzzyOutputKind.unavailable,
      version: version,
      evidence: evidence,
      unavailableReason: switch (physicsStatus) {
        FuzzyInputStatus.stale => FuzzyUnavailableReason.physicsStale,
        FuzzyInputStatus.invalid => FuzzyUnavailableReason.physicsInvalid,
        _ => FuzzyUnavailableReason.noPhysicsInput,
      },
      speedKmh: speed,
    );
  }

  /// A rule's strength, or null when an antecedent's input is unavailable.
  static double? _strengthOf(
    FuzzyRule rule,
    FuzzyConsumptionInput input,
    Map<FuzzyVariable, FuzzyInputStatus> statuses,
  ) {
    var strength = 1.0;
    for (final a in rule.antecedents) {
      if (statuses[a.variable] != FuzzyInputStatus.fresh) return null;
      final mu = a.variable
          .membership(a.term, input.readingFor(a.variable)!.value);
      strength = math.min(strength, a.negated ? 1 - mu : mu);
    }
    return strength;
  }

  static FuzzyInputStatus _fuelRateStatus(FuzzyReading? reading) =>
      classifyReading(reading,
          min: 0,
          max: FuzzyOutputBounds.maxFuelRateLPerHour,
          staleAfterSeconds: FuzzyOutputBounds.fuelRateStaleAfterSeconds);
}
