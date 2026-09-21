// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:meta/meta.dart';

import '../consumption_estimate.dart';
import '../data_value.dart';
import 'fuel_grade.dart';

// The evidence a vehicle's fuel behaviour is learned from (#4276), and
// nothing else: canonical consumption figures and full-to-full fill
// windows. There is deliberately no telemetry here — this layer never
// computes a litre, it only aggregates figures the consumption pipeline
// (Epic #4222) already produced and stamped.

/// Where one piece of evidence sits in the #4276 hierarchy, strongest
/// first.
enum EvidenceTier {
  /// A valid native ECU fuel reading ([ConsumptionSourceClass.measured]).
  measured,

  /// A valid full-to-full fill window — aggregate pump truth.
  reference,

  /// The canonical estimate (MAF / speed-density / GPS-only).
  estimated,

  /// No usable figure. Counted, never averaged.
  unknown,
}

/// A driving condition that confounds consumption (#4276). Recorded per
/// trip so a profile can say how comparable two contexts' evidence is;
/// the correction itself is the residual against
/// [TripFuelEvidence.expectedLPer100Km], never a factor per condition.
enum DrivingCondition { hilly, coldStart, stopAndGo }

/// One recorded drive as behaviour evidence.
@immutable
final class TripFuelEvidence {
  TripFuelEvidence({
    required this.id,
    required this.at,
    required this.distanceKm,
    required this.litresPer100Km,
    required this.sourceClass,
    this.version,
    this.expectedLPer100Km,
    this.calibrationGrade,
    Set<DrivingCondition> conditions = const {},
    Set<DrivingCondition> observedConditions = const {...DrivingCondition.values},
  })  : conditions = Set.unmodifiable(conditions),
        observedConditions = Set.unmodifiable(observedConditions) {
    if (id.isEmpty) throw ArgumentError.value(id, 'id');
    if (!distanceKm.isFinite || distanceKm < 0) {
      throw ArgumentError.value(distanceKm, 'distanceKm');
    }
    final e = expectedLPer100Km;
    if (e != null && (!e.isFinite || e <= 0)) {
      throw ArgumentError.value(e, 'expectedLPer100Km');
    }
  }

  /// The evidence carried by a canonical [ConsumptionEstimate] (#4230).
  factory TripFuelEvidence.fromEstimate(
    ConsumptionEstimate estimate, {
    required String id,
    required DateTime at,
    required double distanceKm,
    double? expectedLPer100Km,
    FuelGrade? calibrationGrade,
    Set<DrivingCondition> conditions = const {},
    Set<DrivingCondition> observedConditions =
        const {...DrivingCondition.values},
  }) =>
      TripFuelEvidence(
        id: id,
        at: at,
        distanceKm: distanceKm,
        litresPer100Km: estimate.litresPer100Km,
        sourceClass: estimate.sourceClass,
        version: estimate.version,
        expectedLPer100Km: expectedLPer100Km,
        calibrationGrade: calibrationGrade,
        conditions: conditions,
        observedConditions: observedConditions,
      );

  /// Stable identity (the trip id).
  final String id;

  /// When the drive started — the instant its blend is read at.
  final DateTime at;
  final double distanceKm;

  /// The canonical figure, carrying its own trust (#4160).
  final DataValue<double> litresPer100Km;

  /// Which production path produced [litresPer100Km].
  final ConsumptionSourceClass sourceClass;

  /// The versions the figure was produced under, or null for a figure
  /// recorded before versions existed — never a fabricated `model: 1`
  /// (ADR 0022 §4).
  final ConsumptionModelVersion? version;

  /// What the consumption pipeline expects THIS vehicle to burn under this
  /// drive's conditions (speed, grade, stops, temperature) on a reference
  /// fuel — the "expected" of #4206's `residual = observed − expected`.
  ///
  /// Must not depend on the tank's blend: a fuel-aware expectation would
  /// cancel exactly the effect being learned. Null when the pipeline
  /// produced none; the trip then still counts toward raw L/100 km but
  /// cannot control confounders.
  final double? expectedLPer100Km;

  /// The grade whose pump gain calibrated an estimated figure (#4220), or
  /// null. An estimate calibrated under another grade's gain is excluded
  /// from a pure context — that is how E10 learning would leak into E85.
  final FuelGrade? calibrationGrade;

  /// The conditions that were TRUE of this drive, among those the
  /// producer evaluated.
  final Set<DrivingCondition> conditions;

  /// The conditions the producer actually EVALUATED (#4364).
  ///
  /// Not the same question as [conditions]: "no hills were recorded" and
  /// "hills were never looked at" produce the same empty set, and only
  /// one of them supports a condition-adjusted claim. Production today
  /// evaluates cold starts alone — no grade, no stop-and-go — so a
  /// profile built from it may report an observation and must not report
  /// an *adjusted* efficiency.
  ///
  /// Defaults to the full set for a caller that constructs complete
  /// evidence (tests, a future full-context pipeline); a producer that
  /// knows less must say so.
  final Set<DrivingCondition> observedConditions;

  /// True when every confounding condition was evaluated for this drive.
  bool get hasFullConditionContext =>
      observedConditions.length == DrivingCondition.values.length;

  /// The evidence tier of [litresPer100Km].
  EvidenceTier get tier {
    final value = litresPer100Km.valueOrNull;
    if (value == null || !value.isFinite || value <= 0 || distanceKm <= 0) {
      return EvidenceTier.unknown;
    }
    return switch (sourceClass) {
      ConsumptionSourceClass.measured => EvidenceTier.measured,
      ConsumptionSourceClass.estimated ||
      ConsumptionSourceClass.gpsOnly =>
        EvidenceTier.estimated,
      ConsumptionSourceClass.none => EvidenceTier.unknown,
    };
  }

  /// observed ÷ expected, or null without both.
  double? get residualRatio {
    final expected = expectedLPer100Km;
    final value = litresPer100Km.valueOrNull;
    if (expected == null || value == null || tier == EvidenceTier.unknown) {
      return null;
    }
    return value / expected;
  }
}

/// One closed, valid full-to-full fill window as behaviour evidence.
@immutable
final class FillWindowEvidence {
  FillWindowEvidence({
    required this.id,
    required this.openedAt,
    required this.closedAt,
    required this.litres,
    required this.distanceKm,
    this.pumpedCost,
    this.costCurrency,
  }) {
    if (id.isEmpty) throw ArgumentError.value(id, 'id');
    if (!closedAt.isAfter(openedAt)) {
      throw ArgumentError.value(closedAt, 'closedAt', 'must follow openedAt');
    }
    if (!litres.isFinite || litres <= 0) {
      throw ArgumentError.value(litres, 'litres');
    }
    if (!distanceKm.isFinite || distanceKm <= 0) {
      throw ArgumentError.value(distanceKm, 'distanceKm');
    }
    final cost = pumpedCost;
    if (cost != null && (!cost.isFinite || cost < 0)) {
      throw ArgumentError.value(cost, 'pumpedCost');
    }
  }

  /// Stable identity (the closing fill's id).
  final String id;
  final DateTime openedAt;
  final DateTime closedAt;

  /// Litres pumped after the opening fill up to and including the closing
  /// fill (the #1362 walker).
  final double litres;

  /// Odometer delta.
  final double distanceKm;

  /// What was actually paid for [litres], or null when a price is
  /// missing — or, since #4364, when the window's fills spanned more
  /// than one currency and no single amount is true of it.
  final double? pumpedCost;

  /// The denomination [pumpedCost] is in: an ISO code, or
  /// `kUnknownCurrency` when the fills recorded none (#4364). Null
  /// exactly when [pumpedCost] is. Never inferred from today's country.
  final String? costCurrency;

  double get lPer100Km => litres / distanceKm * 100;
}

/// A CO2e emission factor with the provenance #4219 requires of any
/// environmental figure: a named source, a version and the boundary.
///
/// A figure computed without one of these is not calculated — the lookup
/// returns null and every CO2e metric stays null. No default factor exists
/// anywhere in this layer.
@immutable
final class Co2eFactor {
  Co2eFactor({
    required this.kgCo2ePerLitre,
    required this.source,
    required this.version,
    required this.boundary,
  }) {
    if (!kgCo2ePerLitre.isFinite || kgCo2ePerLitre < 0) {
      throw ArgumentError.value(kgCo2ePerLitre, 'kgCo2ePerLitre');
    }
    if (source.isEmpty) throw ArgumentError.value(source, 'source');
    if (version.isEmpty) throw ArgumentError.value(version, 'version');
  }

  final double kgCo2ePerLitre;
  final String source;
  final String version;
  final Co2eBoundary boundary;

  Map<String, Object?> toJson() => {
        'kgCo2ePerLitre': kgCo2ePerLitre,
        'source': source,
        'version': version,
        'boundary': boundary.name,
      };
}

/// Which emissions a [Co2eFactor] counts.
enum Co2eBoundary { wellToWheel, tankToWheel }

/// Resolves the factor for one pure grade, or null when none is on record.
/// Mixed and unknown contexts never get a factor: their shares vary
/// window to window, and a blended factor would be invented precision.
typedef Co2eFactorLookup = Co2eFactor? Function(FuelGrade grade);

/// The lookup that knows no factor — the honest default.
Co2eFactor? noCo2eFactor(FuelGrade grade) => null;
