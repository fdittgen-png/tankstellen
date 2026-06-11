// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../vehicle/domain/entities/reference_vehicle.dart';
import 'broken_map_belief.dart';

/// Membership functions + Bayesian updater for [BrokenMapBelief]
/// (#1424). Pure math — no I/O, no Riverpod, no Hive.
///
/// All four membership functions
/// ([vacuumMissingScore], [revDeltaMissingScore],
/// [discrepancySeverityScore], [etaImplausibilityScore]) are unchanged
/// from #1423 phase 1. They produce the per-observation `score` ∈
/// `[0.0, 1.0]` that [update] folds into the Beta posterior — the
/// migration replaces the EMA scalar with a Beta(α, β) shape, but the
/// upstream signal generators stay put.
///
/// Returns values are clamped to `[0.0, 1.0]` where 1.0 is strong
/// evidence of a broken MAP sensor.
class BrokenMapBeliefUpdater {
  /// Threshold above which an observation is "strong" enough to set
  /// [BrokenMapBelief.lastTrigger]. Below this the belief still
  /// accumulates but the trigger tag isn't overwritten.
  static const double _strongThreshold = 0.5;

  /// Posterior memory factor (`γ`). Each step multiplies the prior
  /// (α, β) by `γ` before adding the new observation's contribution —
  /// caps the effective sample size so a strong-but-stale belief can
  /// recover when later observations contradict it (issue #1424
  /// acceptance test: 5×0.9 then 20×0.05 → posterior < 0.4).
  static const double _decayFactor = 0.5;

  /// Weight on the broken-evidence ("α-side") increment. Combined with
  /// [_decayFactor] picks the steady-state mean for sustained input
  /// `s`: `mean_ss = αW·s / (αW·s + βW·(1-s))`. The 8 / 1 split
  /// makes 5 borderline-0.4 observations push the posterior past 0.8
  /// (issue #1424 acceptance test).
  static const double _alphaWeight = 8.0;

  /// Weight on the working-evidence ("β-side") increment. See
  /// [_alphaWeight]. Together with the decay, sustained `s = 0.05`
  /// observations decay the posterior back toward `~0.3` (broken-MAP
  /// scoring is fuzzy — even a healthy sensor scores `> 0` against
  /// the strict membership functions, so 0 is the wrong asymptote).
  static const double _betaWeight = 1.0;

  /// Numeric stability nudge in the Bayes-factor denominator. Avoids a
  /// pure division-by-zero when the score is 1.0 and lets the BF stay
  /// finite (no NaN, no infinity) so downstream consumers can read
  /// the diagnostic overlay even on a perfectly broken-looking
  /// observation.
  static const double _bayesFactorEpsilon = 0.01;

  /// Sea-level reference barometric pressure (kPa). The membership-
  /// function kPa windows were originally calibrated here; away from
  /// sea level the windows scale relative to this baseline (#1623).
  static const double _seaLevelBaroKpa = 101.325;

  /// Resolve the `(low, high)` kPa anchors of a membership function,
  /// scaled for ambient barometric pressure and induction class
  /// (#1623). The stock anchors ([lowKpa], [highKpa]) were calibrated
  /// for a sea-level naturally-aspirated engine.
  ///
  /// Two independent corrections:
  ///
  ///  - **Barometric** — manifold-pressure deltas scale ~linearly with
  ///    ambient pressure, so at altitude (lower baro) the window
  ///    shrinks proportionally. Without this a healthy high-altitude
  ///    engine reads as "low vacuum / small rev swing" and
  ///    false-positives. The factor is clamped to `[0.6, 1.1]` so a
  ///    malformed baro reading cannot invert or explode the window. A
  ///    null [baroKpa] (signal unavailable) leaves the window stock.
  ///
  ///  - **Induction** — forced-induction (turbo / VNT / supercharged)
  ///    engines have MAP excursions the NA calibration models loosely.
  ///    Their transition band is widened symmetrically around its
  ///    midpoint, so a borderline reading scores nearer 0.5 (neutral)
  ///    and the Bayesian updater needs corroborating observations
  ///    before the belief moves. Widening never produces a *confident*
  ///    false reading — it only adds tolerance.
  static (double, double) scaledMembershipAnchors(
    double lowKpa,
    double highKpa, {
    required double? baroKpa,
    required InductionType? inductionType,
  }) {
    final baroFactor = baroKpa == null
        ? 1.0
        : (baroKpa / _seaLevelBaroKpa).clamp(0.6, 1.1);
    var lo = lowKpa * baroFactor;
    var hi = highKpa * baroFactor;
    final widen = _inductionBandWiden(inductionType);
    if (widen != 1.0) {
      final mid = (lo + hi) / 2.0;
      lo = mid - (mid - lo) * widen;
      hi = mid + (hi - mid) * widen;
    }
    return (lo, hi);
  }

  /// Transition-band widening factor by induction class (#1623). `>1`
  /// widens the neutral band; `1.0` leaves it stock. Forced-induction
  /// engines all share the same widen — the NA calibration is equally
  /// loose for any boosted intake.
  static double _inductionBandWiden(InductionType? type) {
    switch (type) {
      case InductionType.turbocharged:
      case InductionType.supercharged:
      case InductionType.vnt:
        return 1.3;
      case InductionType.naturallyAspirated:
      case null:
        return 1.0;
    }
  }

  /// Idle-vacuum-missing membership. On a healthy NA petrol engine,
  /// `baro - map` at idle is a strong vacuum; a broken MAP that
  /// returns atmospheric collapses the delta.
  ///   - Returns 0.0 at/above the healthy anchor (45 kPa at sea level).
  ///   - Returns 1.0 at/below the suspicious anchor (15 kPa at sea
  ///     level).
  ///   - Linear interp in between.
  ///
  /// Both anchors are scaled by [scaledMembershipAnchors] for ambient
  /// barometric pressure and [inductionType] (#1623).
  static double vacuumMissingScore({
    required double baroKpa,
    required double mapKpa,
    InductionType? inductionType,
  }) {
    final delta = baroKpa - mapKpa;
    final (lo, hi) = scaledMembershipAnchors(
      15.0,
      45.0,
      baroKpa: baroKpa,
      inductionType: inductionType,
    );
    return (1.0 - ((delta - lo) / (hi - lo))).clamp(0.0, 1.0);
  }

  /// Diesel-rev-delta membership. Diesels run unthrottled so idle MAP
  /// is near baro; the discriminator is how much MAP *changes* under
  /// a brief rev. Healthy: large swing. Broken: small swing.
  ///   - Returns 0.0 at/above the healthy anchor (30 kPa at sea level).
  ///   - Returns 1.0 at/below the suspicious anchor (8 kPa at sea
  ///     level).
  ///
  /// Both anchors are scaled by [scaledMembershipAnchors] for ambient
  /// barometric pressure and [inductionType] (#1623). [baroKpa] is
  /// optional — the diesel probe reads it best-effort; a null leaves
  /// the window at its sea-level width.
  static double revDeltaMissingScore({
    required double mapIdleKpa,
    required double mapRevvedKpa,
    double? baroKpa,
    InductionType? inductionType,
  }) {
    final delta = (mapRevvedKpa - mapIdleKpa).abs();
    final (lo, hi) = scaledMembershipAnchors(
      8.0,
      30.0,
      baroKpa: baroKpa,
      inductionType: inductionType,
    );
    return (1.0 - ((delta - lo) / (hi - lo))).clamp(0.0, 1.0);
  }

  /// Plein-complet ratio severity. Reconciler computes
  /// `actualLPer100km / estimatedLPer100km`. Ratios > 1.3 are
  /// suspicious (estimated is undercounting); > 2.2 is conclusive.
  ///   - Returns 0.0 when ratio ≤ 1.3 (clean).
  ///   - Returns 1.0 when ratio ≥ 2.2.
  static double discrepancySeverityScore({required double ratio}) {
    return ((ratio - 1.3) / 0.9).clamp(0.0, 1.0);
  }

  /// VeLearner-proposed-η_v implausibility. η_v above 0.97 is
  /// physically suspicious for a typical engine; > 1.22 is
  /// definitely impossible (the learner is compensating for a fuel
  /// undercount that's actually MAP-derived).
  ///   - Returns 0.0 when proposedEta ≤ 0.97.
  ///   - Returns 1.0 when proposedEta ≥ 1.22.
  static double etaImplausibilityScore({required double proposedEta}) {
    return ((proposedEta - 0.97) / 0.25).clamp(0.0, 1.0);
  }

  /// Vehicle-class Bayes-factor multiplier (#1424 deliverable E).
  ///
  /// Returns a scalar applied to the per-observation Bayes factor:
  ///
  ///   - Atkinson-cycle engines (Toyota HSD, Mazda Skyactiv-X) → 0.3.
  ///     These run a delayed-intake-valve cycle that legitimately
  ///     produces unusual MAP readings — we down-weight broken-MAP
  ///     evidence so the legitimate physiology doesn't trip the
  ///     blocklist.
  ///   - Turbocharged or VNT-diesel induction → 1.5. Forced-induction
  ///     engines have a flatter MAP curve at idle than NA engines, so
  ///     a "MAP near baro" reading is *more* informative when the
  ///     vehicle has a turbo (we expect spool-related swings under
  ///     load that healthy turbos always produce).
  ///   - Otherwise (NA petrol/diesel, supercharged petrol) → 1.0
  ///     (neutral).
  ///
  /// `null` vehicle (no profile bound to the active fill) returns
  /// 1.0 — neutral — so observations from un-resolved vehicles still
  /// fold cleanly without a class boost.
  static double bayesFactorAdjustment(ReferenceVehicle? v) {
    if (v == null) return 1.0;
    if (v.atkinsonCycle) return 0.3;
    if (v.inductionType == InductionType.turbocharged ||
        v.inductionType == InductionType.vnt) {
      return 1.5;
    }
    return 1.0;
  }

  /// Bayes factor for a single observation (#1424). Exposed for tests
  /// and for the diagnostic overlay's "why did the belief move?" copy.
  ///
  /// Computed as `(s / (1 - s + ε)) × vehicleAdjustment`:
  ///   - `s / (1 - s + ε)` is the per-observation likelihood ratio
  ///     of "broken" vs "working" given a fuzzy score (1 at s=0.5,
  ///     >1 above, <1 below).
  ///   - `vehicleAdjustment` is the engine-class multiplier from
  ///     [bayesFactorAdjustment].
  ///   - `ε = 0.01` guards the s=1.0 corner from a hard divide-by-zero
  ///     (see [_bayesFactorEpsilon]).
  static double bayesFactor(double observationScore, ReferenceVehicle? v) {
    final s = observationScore.clamp(0.0, 1.0);
    final base = s / (1 - s + _bayesFactorEpsilon);
    return base * bayesFactorAdjustment(v);
  }

  /// Folds [observationScore] (already-combined, in `[0.0, 1.0]`) into
  /// [prev] via a tempered Bayesian update.
  ///
  /// The update is:
  ///
  /// ```
  ///   v   = bayesFactorAdjustment(vehicle)   // 0.3, 1.0, or 1.5
  ///   α'  = γ · α + αW · s · v
  ///   β'  = γ · β + βW · (1 - s)
  /// ```
  ///
  /// where `γ = 0.5`, `αW = 8`, `βW = 1` (see [_decayFactor],
  /// [_alphaWeight], [_betaWeight]) — calibrated against the issue
  /// #1424 acceptance tests:
  ///
  ///   - 5 observations of `s = 0.4` push posterior `pointEstimate`
  ///     above 0.8 (Bayes compounds where EMA didn't).
  ///   - 5 observations of `s = 0.9` then 20 of `s = 0.05` decay
  ///     the posterior back below 0.4 (bounded effective sample size
  ///     means contradicting evidence eventually wins).
  ///
  /// `γ < 1` is the deliberate departure from a textbook Beta
  /// posterior. Without it, a sticky high posterior couldn't recover
  /// from later contradicting observations — and the broken-MAP
  /// path needs that recovery (a user can swap a flaky adapter for
  /// a working one without losing the original belief, which is
  /// what the second acceptance test guards against).
  ///
  /// `now` is injected for deterministic tests; production callers
  /// pass `DateTime.now()`. `vehicle` is the active vehicle's
  /// reference catalog entry (`null` ⇒ no class boost — observations
  /// fold neutrally).
  ///
  /// **Sticky terminal state**: once [BrokenMapBelief.isVerifiedClean]
  /// flips true (50+ observations, mean < 0.1, upper-CI < 0.3), the
  /// updater returns `prev` unchanged — the belief locks. This mirrors
  /// the issue's "verified" semantics: the user has earned the
  /// terminal trust state and a single noisy probe shouldn't undo it.
  static BrokenMapBelief update(
    BrokenMapBelief prev,
    double observationScore, {
    required DateTime now,
    required ReferenceVehicle? vehicle,
    BrokenMapReason? reason,
  }) {
    if (prev.isVerifiedClean) return prev;

    final clampedScore = observationScore.clamp(0.0, 1.0);
    final v = bayesFactorAdjustment(vehicle);
    final newAlpha = _decayFactor * prev.alpha + _alphaWeight * clampedScore * v;
    final newBeta = _decayFactor * prev.beta + _betaWeight * (1.0 - clampedScore);
    final isStrong = clampedScore > _strongThreshold;
    return prev.copyWith(
      alpha: newAlpha,
      beta: newBeta,
      observationCount: prev.observationCount + 1,
      lastUpdate: now,
      lastTrigger: isStrong && reason != null ? reason : prev.lastTrigger,
    );
  }
}
