// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'gps_driving_features.dart';

/// Coarse three-band verdict for a single GPS-efficiency KPI (#2795 C6).
///
/// Mirrors the spirit of [DrivingStyleClass] on the OBD2 driving score:
/// the raw RPA / PKE / VAPOS / coasting numbers mean nothing to a driver,
/// so each is bucketed into a good / moderate / aggressive band that the
/// KPI card colours and labels with a one-line interpretation.
enum GpsKpiVerdict {
  /// Eco-efficient — gentle, energy-light driving.
  good,

  /// Typical mixed driving — neither notably efficient nor wasteful.
  moderate,

  /// Energy-heavy — hard acceleration / aggressive pace (or, for the
  /// inverted coasting KPI, very little coasting).
  aggressive,
}

/// Maps a [GpsDrivingFeatures] aggregate to a per-KPI [GpsKpiVerdict]
/// band (#2795 C6 / Epic #2789).
///
/// ## Threshold grounding
///
/// The #2804 calibration export exists to collect labelled real-trip data
/// for these cutoffs, but no annotated corpus has been gathered yet — so
/// the bands below are **conservative defaults**, deliberately wide so a
/// genuinely calm trip never reads "aggressive" and a genuinely hard one
/// never reads "good". They are anchored on:
///
///   * the eco-driving literature's typical ranges (RPA ≈ 0.10–0.30 m/s²,
///     PKE ≈ 0.2–0.8 m/s², coasting a few % to ~30 % of moving time), and
///   * the one labelled trip in the trace fixtures (RPA 0.224, PKE 0.331,
///     VAPOS 1.42, coast 0.18 — a score-78 "good but mixed" drive), which
///     must land in MODERATE on every axis here so the verdict agrees with
///     the smooth-driving lesson / driving score rather than contradicting
///     them.
///
/// Each cutoff is a single named const so a future calibration pass can
/// retune it in one place. The bands are intentionally NOT derived from
/// the matrix coefficients — those model fuel cost, not subjective
/// aggressiveness.
class GpsKpiVerdicts {
  // RPA — Relative Positive Acceleration (m/s²). Higher = more energy
  // spent accelerating. 0.224 (fixture) sits inside MODERATE.
  static const double rpaGoodMax = 0.15;
  static const double rpaModerateMax = 0.30;

  // PKE — Positive Kinetic Energy (m/s²). Higher = harder accel bursts.
  // 0.331 (fixture) sits inside MODERATE.
  static const double pkeGoodMax = 0.25;
  static const double pkeModerateMax = 0.50;

  // VAPOS — mean positive v·a (m²/s³), the accel power-proxy. 1.42
  // (fixture) sits inside MODERATE.
  static const double vaposGoodMax = 1.0;
  static const double vaposModerateMax = 2.5;

  // Coasting share (0–1) — INVERTED polarity: MORE coasting is better.
  // 0.18 (fixture) sits inside MODERATE; the praise threshold the road-use
  // panel uses (0.25) is the GOOD floor here so the two agree.
  static const double coastGoodMin = 0.25;
  static const double coastModerateMin = 0.10;

  const GpsKpiVerdicts._();

  /// Band an RPA value (lower = better). [bands] defaults to the
  /// conservative literature-anchored cutoffs; the #3503 calibration
  /// derives a personal set from the driver's own verdicts.
  static GpsKpiVerdict rpa(double v,
          {GpsKpiBands bands = GpsKpiBands.defaults}) =>
      _lowerIsBetter(v, bands.rpaGoodMax, bands.rpaModerateMax);

  /// Band a PKE value (lower = better).
  static GpsKpiVerdict pke(double v,
          {GpsKpiBands bands = GpsKpiBands.defaults}) =>
      _lowerIsBetter(v, bands.pkeGoodMax, bands.pkeModerateMax);

  /// Band a VAPOS value (lower = better).
  static GpsKpiVerdict vapos(double v,
          {GpsKpiBands bands = GpsKpiBands.defaults}) =>
      _lowerIsBetter(v, bands.vaposGoodMax, bands.vaposModerateMax);

  /// Band a coasting share (higher = better — inverted polarity).
  static GpsKpiVerdict coast(double v,
      {GpsKpiBands bands = GpsKpiBands.defaults}) {
    if (v >= bands.coastGoodMin) return GpsKpiVerdict.good;
    if (v >= bands.coastModerateMin) return GpsKpiVerdict.moderate;
    return GpsKpiVerdict.aggressive;
  }

  static GpsKpiVerdict _lowerIsBetter(double v, double goodMax, double moderateMax) {
    if (v <= goodMax) return GpsKpiVerdict.good;
    if (v <= moderateMax) return GpsKpiVerdict.moderate;
    return GpsKpiVerdict.aggressive;
  }
}

/// One resolvable set of KPI band cutoffs (#3503, epic #3498).
///
/// [defaults] is byte-identical to the [GpsKpiVerdicts] consts; the
/// verdict-calibration store derives a personal instance from the driver's
/// own smooth/aggressive labels once enough have accumulated — a heavier
/// vehicle or a hilly commute legitimately shifts where "smooth" sits.
class GpsKpiBands {
  final double rpaGoodMax;
  final double rpaModerateMax;
  final double pkeGoodMax;
  final double pkeModerateMax;
  final double vaposGoodMax;
  final double vaposModerateMax;
  final double coastGoodMin;
  final double coastModerateMin;

  const GpsKpiBands({
    required this.rpaGoodMax,
    required this.rpaModerateMax,
    required this.pkeGoodMax,
    required this.pkeModerateMax,
    required this.vaposGoodMax,
    required this.vaposModerateMax,
    required this.coastGoodMin,
    required this.coastModerateMin,
  });

  /// The uncalibrated defaults — the [GpsKpiVerdicts] consts, unchanged.
  static const GpsKpiBands defaults = GpsKpiBands(
    rpaGoodMax: GpsKpiVerdicts.rpaGoodMax,
    rpaModerateMax: GpsKpiVerdicts.rpaModerateMax,
    pkeGoodMax: GpsKpiVerdicts.pkeGoodMax,
    pkeModerateMax: GpsKpiVerdicts.pkeModerateMax,
    vaposGoodMax: GpsKpiVerdicts.vaposGoodMax,
    vaposModerateMax: GpsKpiVerdicts.vaposModerateMax,
    coastGoodMin: GpsKpiVerdicts.coastGoodMin,
    coastModerateMin: GpsKpiVerdicts.coastModerateMin,
  );
}
