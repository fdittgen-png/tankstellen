// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:meta/meta.dart';

/// Coarse band a [DrivingScore] falls into (#2460). Surfaced as the
/// headline classification on the Trip detail driving-score card so the
/// driver reads "Very good" before the 0..100 number. The thresholds
/// mirror common eco-coach conventions and the card's colour bands.
enum DrivingStyleClass {
  /// 85..100 — eco-grade driving, little behaviour-driven waste.
  veryGood,

  /// 70..84 — good, a few rough edges.
  good,

  /// 50..69 — average, clear room to improve.
  average,

  /// 0..49 — aggressive / wasteful trip.
  bad;

  /// Classify a 0..100 [score] into its band. Inclusive lower bounds.
  static DrivingStyleClass fromScore(int score) {
    if (score >= 85) return DrivingStyleClass.veryGood;
    if (score >= 70) return DrivingStyleClass.good;
    if (score >= 50) return DrivingStyleClass.average;
    return DrivingStyleClass.bad;
  }
}

/// The ONE canonical composite "driving-style score" for a single trip
/// (#2460 — replaces the two divergent 0..100 implementations that used
/// to live in `driving_score_calculator.dart` and
/// `trip_metrics.drivingScore`).
///
/// The score is a 0..100 integer where 100 is "no behaviour-driven
/// waste detected" and 0 is "every category capped out simultaneously".
/// It is `100 − Σ(weighted penalties) + Σ(eco credits)`, floored at 0
/// and capped at 100, then classified into a [DrivingStyleClass].
///
/// Each public penalty field is the contribution (in score points)
/// subtracted from the starting 100; [ecoCreditCoast] is the single
/// positive contribution (fuel-cut coasting). Fields are exposed so the
/// UI can surface the top contributors as a breakdown chip row without
/// recomputing anything.
///
/// The class is intentionally UI-agnostic — no `BuildContext`, no
/// `AppLocalizations`. The calculator in
/// `driving_score_calculator.dart` produces this from raw
/// [TripSample]s (the canonical path) or from a [TripSummary] (the
/// cheap summary-only path for legacy sample-less trips); the same
/// value-object can be persisted, replayed, or aggregated across trips
/// later without touching UI code.
@immutable
class DrivingScore {
  /// 0..100 composite. Higher is better. Always clamped to the
  /// inclusive [0, 100] range by the calculator.
  final int score;

  // ---- Aggressiveness ----------------------------------------------

  /// Score-points subtracted because of hard-acceleration events
  /// (accelG ≥ 3.0 m/s²), per 100 km.
  final double hardAccelPenalty;

  /// Score-points subtracted because of hard-braking events
  /// (≤ -3.5 m/s²), per 100 km.
  final double hardBrakePenalty;

  /// Score-points subtracted because of time spent at full throttle
  /// (pedal — else throttle — ≥ 90 %). **Now fires** (#2460): the
  /// persisted pedal/throttle drives it. Capped.
  final double fullThrottlePenalty;

  /// Score-points subtracted because the driver stabbed the pedal —
  /// the max d(pedal)/dt over moving samples (#2460 NEW).
  final double pedalVelocityPenalty;

  // ---- Over-rev / shift --------------------------------------------

  /// Score-points subtracted because of time above the high-RPM
  /// threshold (> 3000 RPM).
  final double highRpmPenalty;

  /// Score-points subtracted for labouring below the optimal gear
  /// (lugging — RPM ceiling 2200), derived from
  /// `secondsBelowOptimalGear`.
  final double luggingPenalty;

  /// Score-points subtracted for hard shifts (RPM spike-then-drop)
  /// (#2460 NEW).
  final double hardShiftPenalty;

  // ---- Idle --------------------------------------------------------

  /// Score-points subtracted because of idle time (engine on, speed
  /// near zero).
  final double idlingPenalty;

  /// Score-points subtracted for blipping the throttle while stationary
  /// (rev-while-stationary) (#2460 NEW).
  final double revWhileStationaryPenalty;

  // ---- Smoothness (CONTINUOUS) -------------------------------------

  /// Score-points subtracted for jerky driving — a CONTINUOUS term from
  /// speed std-dev + pedal/throttle variance (#2460; replaces the old
  /// binary smoothness gate).
  final double smoothnessPenalty;

  // ---- Speed efficiency --------------------------------------------

  /// Score-points subtracted for sustained high speed (> 110 km/h)
  /// where aerodynamic drag dominates.
  final double speedEfficiencyPenalty;

  /// Score-points subtracted for λ-enrichment (commanded mixture richer
  /// than stoichiometric, λ < 1) — extra fuel dumped under load
  /// (#2460 NEW, from PID 0x44).
  final double lambdaEnrichmentPenalty;

  // ---- Eco credit (POSITIVE) ---------------------------------------

  /// Score-points ADDED for fuel-cut coasting time-share (fuelRate <
  /// 0.1 while moving > 20 km/h) — the injectors are off, so this is
  /// free distance. Detected before #2460 but never credited; now a
  /// bonus.
  final double ecoCreditCoast;

  const DrivingScore({
    required this.score,
    required this.idlingPenalty,
    required this.hardAccelPenalty,
    required this.hardBrakePenalty,
    required this.highRpmPenalty,
    required this.fullThrottlePenalty,
    this.pedalVelocityPenalty = 0,
    this.luggingPenalty = 0,
    this.hardShiftPenalty = 0,
    this.revWhileStationaryPenalty = 0,
    this.smoothnessPenalty = 0,
    this.speedEfficiencyPenalty = 0,
    this.lambdaEnrichmentPenalty = 0,
    this.ecoCreditCoast = 0,
  });

  /// The coarse classification band for [score] (#2460).
  DrivingStyleClass get styleClass => DrivingStyleClass.fromScore(score);

  /// A "perfect" 100-point score with no penalties — used as a sentinel
  /// in tests and as the natural identity for empty trips (the
  /// calculator returns this for `samples.length < 2`).
  static const DrivingScore perfect = DrivingScore(
    score: 100,
    idlingPenalty: 0,
    hardAccelPenalty: 0,
    hardBrakePenalty: 0,
    highRpmPenalty: 0,
    fullThrottlePenalty: 0,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DrivingScore &&
        other.score == score &&
        other.idlingPenalty == idlingPenalty &&
        other.hardAccelPenalty == hardAccelPenalty &&
        other.hardBrakePenalty == hardBrakePenalty &&
        other.highRpmPenalty == highRpmPenalty &&
        other.fullThrottlePenalty == fullThrottlePenalty &&
        other.pedalVelocityPenalty == pedalVelocityPenalty &&
        other.luggingPenalty == luggingPenalty &&
        other.hardShiftPenalty == hardShiftPenalty &&
        other.revWhileStationaryPenalty == revWhileStationaryPenalty &&
        other.smoothnessPenalty == smoothnessPenalty &&
        other.speedEfficiencyPenalty == speedEfficiencyPenalty &&
        other.lambdaEnrichmentPenalty == lambdaEnrichmentPenalty &&
        other.ecoCreditCoast == ecoCreditCoast;
  }

  @override
  int get hashCode => Object.hashAll([
        score,
        idlingPenalty,
        hardAccelPenalty,
        hardBrakePenalty,
        highRpmPenalty,
        fullThrottlePenalty,
        pedalVelocityPenalty,
        luggingPenalty,
        hardShiftPenalty,
        revWhileStationaryPenalty,
        smoothnessPenalty,
        speedEfficiencyPenalty,
        lambdaEnrichmentPenalty,
        ecoCreditCoast,
      ]);

  @override
  String toString() => 'DrivingScore('
      'score: $score, '
      'class: ${styleClass.name}, '
      'idling: ${idlingPenalty.toStringAsFixed(1)}, '
      'hardAccel: ${hardAccelPenalty.toStringAsFixed(1)}, '
      'hardBrake: ${hardBrakePenalty.toStringAsFixed(1)}, '
      'highRpm: ${highRpmPenalty.toStringAsFixed(1)}, '
      'fullThrottle: ${fullThrottlePenalty.toStringAsFixed(1)}, '
      'pedalVel: ${pedalVelocityPenalty.toStringAsFixed(1)}, '
      'lugging: ${luggingPenalty.toStringAsFixed(1)}, '
      'hardShift: ${hardShiftPenalty.toStringAsFixed(1)}, '
      'revStationary: ${revWhileStationaryPenalty.toStringAsFixed(1)}, '
      'smoothness: ${smoothnessPenalty.toStringAsFixed(1)}, '
      'speedEff: ${speedEfficiencyPenalty.toStringAsFixed(1)}, '
      'lambda: ${lambdaEnrichmentPenalty.toStringAsFixed(1)}, '
      'ecoCredit: +${ecoCreditCoast.toStringAsFixed(1)})';
}
