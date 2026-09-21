// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:meta/meta.dart';

import '../../../../core/domain/consumption_estimate.dart';
import '../../../../core/domain/data_value.dart';
import 'fuzzy_consumption_input.dart';
import 'fuzzy_variables.dart';

/// What one sample's figure is (#4232, Epic #4222 *Source semantics*).
enum FuzzyOutputKind {
  /// A valid native ECU fuel rate, passed through untouched.
  measured,

  /// The fuzzy estimate over a physics input.
  estimated,

  /// No figure: neither a valid native reading nor a usable physics input.
  unavailable,
}

/// Why a sample has no figure — stated, never a zero.
enum FuzzyUnavailableReason {
  /// No physics estimate (or no basis for it) was supplied.
  noPhysicsInput,

  /// The physics estimate is older than its horizon.
  physicsStale,

  /// The physics estimate is non-finite, negative or implausibly large.
  physicsInvalid,
}

/// A rule that fired, and how strongly.
@immutable
class FuzzyFiredRule {
  const FuzzyFiredRule({
    required this.id,
    required this.strength,
    required this.degraded,
  });

  final String id;

  /// Firing strength in `(0, 1]`.
  final double strength;

  /// Whether this is a degraded substitute for an unavailable input.
  final bool degraded;

  @override
  bool operator ==(Object other) =>
      other is FuzzyFiredRule &&
      other.id == id &&
      other.strength == strength &&
      other.degraded == degraded;

  @override
  int get hashCode => Object.hash(id, strength, degraded);

  @override
  String toString() => 'FuzzyFiredRule($id, $strength${degraded ? ', d' : ''})';
}

/// Everything that went into a figure: which inputs were usable, which
/// rules fired, and how the native reading compared.
@immutable
class FuzzyEvidence {
  const FuzzyEvidence({
    required this.inputs,
    required this.physicsStatus,
    required this.nativeStatus,
    required this.coverage,
    required this.firedRules,
    required this.unevaluableRuleIds,
    required this.defaultRuleStrength,
    required this.multiplier,
    required this.residualLPerHour,
    this.nativeAgreementRatio,
  });

  /// Status of every context variable, in [FuzzyVariable] order.
  final Map<FuzzyVariable, FuzzyInputStatus> inputs;
  final FuzzyInputStatus physicsStatus;
  final FuzzyInputStatus nativeStatus;

  /// Mean freshness over the context variables, `[0, 1]` (0 for any that
  /// is not fresh).
  final double coverage;

  /// Rules with non-zero strength, in rule-base order.
  final List<FuzzyFiredRule> firedRules;

  /// Rules that could not be evaluated because an antecedent's input was
  /// unavailable (degraded rules whose gate was closed are not listed).
  final List<String> unevaluableRuleIds;

  /// Strength of the implicit physics-prior rule — `1 − max strength`, so
  /// defuzzification is defined even when nothing else fires.
  final double defaultRuleStrength;

  /// The defuzzified multiplier and residual (before output bounds).
  final double multiplier;
  final double residualLPerHour;

  /// `inferred / native` when both exist and native > 0 — agreement
  /// evidence only; it never changes the measured figure.
  final double? nativeAgreementRatio;

  /// Inputs that were supplied but not usable.
  Iterable<FuzzyVariable> get unusableInputs => inputs.entries
      .where((e) => e.value != FuzzyInputStatus.fresh)
      .map((e) => e.key);
}

/// One sample's inference.
@immutable
class FuzzyInferenceResult {
  const FuzzyInferenceResult({
    required this.kind,
    required this.version,
    required this.evidence,
    this.fuelRateLPerHour,
    this.inferredFuelRateLPerHour,
    this.confidence,
    this.physicsBasis,
    this.nativeSource,
    this.unavailableReason,
    this.speedKmh,
  });

  final FuzzyOutputKind kind;

  /// Model + rule versions the figure was produced under.
  final ConsumptionModelVersion version;
  final FuzzyEvidence evidence;

  /// **The** figure for this sample, L/h: the native reading when
  /// [kind] is measured, the fuzzy estimate when estimated, else null.
  final double? fuelRateLPerHour;

  /// The fuzzy estimate, whenever a usable physics input existed — also on
  /// a measured sample, where it is evidence beside the measurement and
  /// never the figure.
  final double? inferredFuelRateLPerHour;

  /// Input-coverage confidence in `[0, 1]` for an estimate; null for a
  /// measurement (ADR 0022: a measured read is not a probability) and for
  /// an unavailable sample. Not a calibrated probability — see ADR 0023.
  final double? confidence;
  final FuzzyPhysicsBasis? physicsBasis;
  final NativeFuelRateSource? nativeSource;
  final FuzzyUnavailableReason? unavailableReason;

  /// The validated fresh speed the per-distance figure divides by.
  final double? speedKmh;

  /// Below this speed a per-distance figure is undefined (the `standstill`
  /// term's upper edge).
  static const double minSpeedForPerDistanceKmh = 5;

  /// L/100 km, or null at (near) standstill or without a figure. Bounded:
  /// the rate is bounded and the divisor is at least
  /// [minSpeedForPerDistanceKmh].
  double? get litresPer100Km {
    final rate = fuelRateLPerHour;
    final v = speedKmh;
    if (rate == null || v == null || v < minSpeedForPerDistanceKmh) {
      return null;
    }
    return rate / v * 100;
  }

  /// The contract's source class (ADR 0022). A measured sample is
  /// `measured`; an estimate over engine air mass is `estimated`; one over
  /// GPS road-load is `gpsOnly`, matching how the pump-gain rule treats
  /// those classes today. Whether GPS-only figures later take the gain is
  /// #4233's decision, not this engine's.
  ConsumptionSourceClass get sourceClass => switch (kind) {
        FuzzyOutputKind.measured => ConsumptionSourceClass.measured,
        FuzzyOutputKind.unavailable => ConsumptionSourceClass.none,
        FuzzyOutputKind.estimated =>
          physicsBasis == FuzzyPhysicsBasis.gpsRoadLoad
              ? ConsumptionSourceClass.gpsOnly
              : ConsumptionSourceClass.estimated,
      };

  /// The per-sample rate as a [DataValue] carrying its provenance.
  DataValue<double> get fuelRateValue => switch (kind) {
        FuzzyOutputKind.measured => DataValue.measured(fuelRateLPerHour!),
        FuzzyOutputKind.estimated =>
          DataValue.estimated(fuelRateLPerHour!, basis: DataBasis.derived),
        FuzzyOutputKind.unavailable => DataValue.unknown(
            reason: unavailableReason == FuzzyUnavailableReason.physicsInvalid
                ? DataUnknownReason.unreadable
                : DataUnknownReason.notMeasuredYet,
          ),
      };
}
