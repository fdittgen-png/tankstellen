// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// The one shape a consumption figure reaches a consumer in (#4230,
/// Epic #4222). See `docs/decisions/0022-canonical-consumption-estimate.md`
/// for the producer → contract → consumer map this type sits in the
/// middle of.
///
/// ## Why this is a composition, not a fifth provenance type
///
/// #4230's merged-in #4207 content is explicit: *"do not add a fifth type
/// beside `TripFuelSourceKind`, `FuelConsumptionFigure` + `DataValue`,
/// `PumpGainResolution` or `CalibratedTripFigures`."* Each of those
/// already owns one axis, and they are genuinely different axes:
///
///  * [TripFuelSourceKind] — which branch produced the litres
///    (measured / estimated / gps / none);
///  * [DataValue] — how much a number may be trusted, app-wide (#4160);
///  * [PumpGainResolution] — which calibration was applied, and from
///    where;
///  * [CalibratedTripFigures] — the re-expression at today's gain.
///
/// So this type adds no new vocabulary. It *composes* those four into the
/// single object the epic's technical-lead contract requires a consumer to
/// receive: "value, source/provenance, confidence, model/rule version,
/// calibration version, time/recording identity, and whether the value is
/// measured or estimated".
///
/// What it adds that did not exist: **versions**. Nothing in
/// `lib/features/trips`, `lib/core/domain` or `lib/features/fill_ups`
/// carried a model, rule or calibration version — `GpsCalibrationMatrix`
/// tracks maturity through `fillUpReconciliationCount` /
/// `residualVariance` / `lastReconciledAt` instead.
/// `consumption_source_class_gates_test.dart` records that gap and assigns
/// it here.
///
/// ## The boundary this type IS
///
/// A consumer cannot select an estimator through it. There is no
/// `estimator` parameter, no strategy enum, no `useFuzzy` flag — the
/// producer decides, stamps what it did, and the consumer reads. That is
/// #4230's acceptance criterion "no consumer can choose rule/GPS/physics/
/// fuzzy as an estimator", enforced by the shape of the type rather than
/// by reviewers noticing.
library;

import 'package:meta/meta.dart';

import 'data_value.dart';

/// Which production path produced a figure.
///
/// Deliberately NOT a new provenance vocabulary — it is the *same* four
/// cases as `TripFuelSourceKind`, restated here because
/// `feature_boundary_test` pins **core → feature at zero** (#3129), so
/// this file cannot import `features/trips/domain/trip_fuel_source.dart`.
///
/// The translation therefore lives on the feature side, in
/// `features/trips/domain/trip_consumption_source_class.dart`
/// (`TripFuelSourceKindMapping.asConsumptionSourceClass`). Its `switch` is
/// exhaustive, so a fifth trip kind is a compile error there rather than a
/// silent mis-mapping, and `trip_consumption_source_class_test.dart` pins
/// the two enums together so they cannot drift.
enum ConsumptionSourceClass {
  /// A valid native ECU fuel reading (PID 9D / A2 / 5E).
  ///
  /// Binding, per Epic #4222's *Source semantics*: reported as measured,
  /// **never** scaled by the pump gain, and never replaced by the
  /// estimated path. It is also the per-second training target the
  /// rulebase is fitted against.
  measured,

  /// MAF / speed-density — engine data, but a modelled litre.
  ///
  /// The per-fuel pump gain applies here, **exactly once**.
  estimated,

  /// GPS-physics only: no engine data at all.
  ///
  /// Also a modelled litre, but from a different input set, and never
  /// pump-gain rescaled (the gain anchors an engine-derived estimate; a
  /// GPS figure was never multiplied by it).
  gpsOnly,

  /// No per-distance fuel figure exists.
  none,
}

/// Whether a source class may carry a pump gain at all.
///
/// One predicate, so the rule lives in the domain rather than in each
/// call site's `if`. `consumption_source_class_gates_test.dart` asserts
/// the same three facts against the trip layer; this is the contract side
/// of them.
extension ConsumptionSourceClassRules on ConsumptionSourceClass {
  /// True only for [ConsumptionSourceClass.measured].
  bool get isMeasured => this == ConsumptionSourceClass.measured;

  /// Whether the per-fuel pump gain applies to this class.
  ///
  /// Only [ConsumptionSourceClass.estimated]. Measured fuel was never
  /// multiplied by a gain, so rescaling it would corrupt a measurement;
  /// GPS-only figures come from the road-load model, which the gain does
  /// not calibrate.
  bool get pumpGainApplies => this == ConsumptionSourceClass.estimated;
}

/// The model, rule and calibration versions a figure was produced under
/// (#4230 acceptance: "model and calibration versions are first-class").
///
/// Three separate numbers because they move independently: the inference
/// model can be replaced without touching the rulebase, the rulebase can
/// be retuned without a new model, and a vehicle's calibration advances
/// every time a full-to-full fill re-anchors it.
///
/// Why this is not one opaque string: a stored figure has to be
/// *comparable* to what the current build would produce, and "is this
/// older than mine" is a question a version number answers and a hash
/// does not. #4234's acceptance ("historical persisted values remain
/// reproducible through version metadata") needs exactly that ordering.
@immutable
class ConsumptionModelVersion {
  const ConsumptionModelVersion({
    required this.model,
    required this.rules,
    this.calibration,
  })  : assert(model >= 1, 'model version starts at 1'),
        assert(rules >= 1, 'rule version starts at 1');

  /// The inference model's version. Bumped when the architecture of the
  /// estimate changes — a new input set, a different defuzzification.
  final int model;

  /// The rulebase / membership-function version. Bumped when the rules
  /// are retuned against the replay corpus.
  final int rules;

  /// The vehicle's calibration generation, or null when the figure is not
  /// attributable to a fill-anchored generation.
  ///
  /// Null is meaningfully different from 0: "not attributable" is not
  /// "calibrated at generation zero". ADR 0024 §5 widened null from
  /// "never calibrated" to "not attributable". It covers an uncalibrated
  /// vehicle, a figure that carries no pump gain (GPS road-load), and a gain
  /// that moved after the figure was integrated.
  final int? calibration;

  /// Whether this figure was produced by an older build than [other].
  ///
  /// The comparison a replay or a re-expression needs: a stored estimate
  /// from an older model must be recomputed rather than trusted, and that
  /// decision is the consumer's, not this type's.
  bool isOlderThan(ConsumptionModelVersion other) =>
      model < other.model || (model == other.model && rules < other.rules);

  Map<String, Object?> toJson() => {
        'model': model,
        'rules': rules,
        if (calibration != null) 'calibration': calibration,
      };

  /// Decodes a persisted version.
  ///
  /// A record written before versions existed has no such object at all;
  /// its absence is the caller's to handle (null in, null out) rather
  /// than something this type invents a default for. Inventing `model: 1`
  /// for an unversioned figure would claim provenance it does not have —
  /// the same reasoning `TankBlendState` uses for its own `modelVersion`.
  static ConsumptionModelVersion? tryDecode(Object? json) {
    if (json is! Map) return null;
    final map = json.cast<String, Object?>();
    final model = map['model'];
    final rules = map['rules'];
    if (model is! int || rules is! int || model < 1 || rules < 1) return null;
    final calibration = map['calibration'];
    return ConsumptionModelVersion(
      model: model,
      rules: rules,
      calibration: calibration is int ? calibration : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ConsumptionModelVersion &&
      other.model == model &&
      other.rules == rules &&
      other.calibration == calibration;

  @override
  int get hashCode => Object.hash(model, rules, calibration);

  @override
  String toString() =>
      'ConsumptionModelVersion(m$model r$rules c${calibration ?? '-'})';
}

/// One consumption figure, with everything a consumer needs to render it
/// honestly and nothing it needs to choose how it was made.
@immutable
class ConsumptionEstimate {
  const ConsumptionEstimate({
    required this.litresPer100Km,
    required this.sourceClass,
    this.version,
    this.confidence,
    this.pumpGain,
    this.recordedAt,
    this.recordingId,
  }) : assert(
          confidence == null || (confidence >= 0 && confidence <= 1),
          'confidence is a [0,1] fraction',
        );

  /// The figure, carrying its own trust (#4160).
  ///
  /// A [DataValue] rather than a bare `double` so a rendering path cannot
  /// drop the `≈`: `Unknown` carries *why* it is absent, and `map` cannot
  /// launder an unknown into a present value.
  final DataValue<double> litresPer100Km;

  /// Which production path produced it.
  final ConsumptionSourceClass sourceClass;

  /// The versions it was produced under, or null when the producing path
  /// stamped none — a legacy trip, the batch GPS estimator, a figure
  /// finalised before #4233's stamp reached its path. Absence is stated,
  /// never defaulted to `model: 1` (ADR 0022 §4, ADR 0024 §6).
  final ConsumptionModelVersion? version;

  /// How much the producer trusts it, in `[0, 1]`, or null when the
  /// producer has no calibrated notion of confidence.
  ///
  /// Null rather than 1.0 for a measurement: "no confidence figure" and
  /// "perfectly confident" are different claims, and a measured ECU read
  /// is not a probability.
  final double? confidence;

  /// The pump gain applied, or null when none was.
  ///
  /// Invariant, asserted by [isConsistent] and by the contract tests: a
  /// non-null gain is only legal on [ConsumptionSourceClass.estimated].
  final double? pumpGain;

  /// When the figure was recorded, and which recording it belongs to —
  /// the "time/recording identity" the epic's contract requires so a
  /// figure can be traced back to the drive that produced it.
  final DateTime? recordedAt;
  final String? recordingId;

  /// Whether this figure is a measurement rather than a model.
  ///
  /// Reads the source class, not the [DataValue] case: a measured ECU
  /// figure that has gone stale is still *measured* provenance, and the
  /// staleness is the `DataValue`'s business.
  bool get isMeasured => sourceClass.isMeasured;

  /// Whether the pump-gain rule holds for this figure.
  ///
  /// The one invariant worth checking at a boundary: measured and
  /// GPS-only figures must carry no gain. False here means a producer
  /// scaled something it must not have, which is the corruption
  /// `consumption_source_class_gates_test.dart` exists to catch.
  bool get isConsistent =>
      pumpGain == null || sourceClass.pumpGainApplies;

  /// A figure that does not exist, with the reason stated.
  ///
  /// Trust rule 1: a missing input is *stated*, never defaulted. The
  /// source class is [ConsumptionSourceClass.none] because "there is no
  /// figure" is itself the classification.
  factory ConsumptionEstimate.unavailable({
    required DataUnknownReason reason,
    ConsumptionModelVersion? version,
    DateTime? recordedAt,
    String? recordingId,
  }) =>
      ConsumptionEstimate(
        litresPer100Km: DataValue<double>.unknown(reason: reason),
        sourceClass: ConsumptionSourceClass.none,
        version: version,
        recordedAt: recordedAt,
        recordingId: recordingId,
      );

  @override
  String toString() => 'ConsumptionEstimate(${sourceClass.name}, '
      '$litresPer100Km, $version)';
}
