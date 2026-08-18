// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'broken_map_belief.freezed.dart';
part 'broken_map_belief.g.dart';

/// Reason tag set on the most recent strong observation that pushed
/// the broken-MAP posterior up. Useful for the diagnostic overlay
/// (#1395) to surface which signal triggered (idle probe, plein-complet,
/// rev delta).
///
/// Phase 1 establishes the enum surface; phase 2-3 producers (idle
/// probe, reconciler hook) emit these.
enum BrokenMapReason {
  /// Idle vacuum measurement was suspiciously close to atmospheric.
  idleVacuumMissing,

  /// Diesel rev-step measurement showed the MAP barely changing.
  revDeltaMissing,

  /// Plein-complet reconciliation showed estimated L/100km wildly low
  /// vs receipt math.
  pleinCompletDiscrepancy,

  /// VeLearner converged to a η_v above what's physically possible.
  etaImplausible,

  /// Recalled from a prior session via [ObdAdapterBlocklist] — the
  /// adapter was already known to be suspect from earlier observations
  /// (#1423 phase 4). Used by the populator to surface a warning at
  /// the next pair attempt without re-probing.
  priorObservation,

  /// Not yet triggered by a strong observation (default).
  none,
}

/// Persisted Bayesian belief about whether a paired OBD2 adapter's MAP
/// sensor reads correctly (#1424).
///
/// Modeled as a Beta(α, β) posterior over the latent "broken" Bernoulli
/// rate. Defaults `α = 1.0, β = 9.0` give a weak prior centred at
/// `mean = 0.1` (broadly trusts the sensor until observed otherwise).
///
/// One belief per vehicle; persisted in the settings box. The Bayesian
/// shape replaces the EMA scalar from #1423 — see
/// [BrokenMapBeliefUpdater.update] for the update rule and the issue
/// #1424 acceptance tests for calibration evidence.
///
/// ## Confidence semantics
///
/// [pointEstimate] (`α / (α + β)`) is the posterior mean — the
/// drop-in replacement for the legacy `confidence` scalar. UI
/// thresholds (used by the trip-recording screen and the diagnostic
/// overlay) gate on this value:
///
///   - < 0.4 → silent
///   - 0.4–0.7 → "MAP sensor verifying..." chip
///   - 0.7–0.9 → snackbar warning
///   - ≥ 0.9 → hard-disable MAP-derived fuel-rate
///
/// [credibleInterval] (95 %) gives the disclosure interval around
/// [pointEstimate] — surfaced in the diagnostic overlay so a user
/// inspecting the live belief can see how concentrated the posterior
/// is.
///
/// [isVerifiedClean] is the sticky terminal state: once true, the
/// updater short-circuits and the overlay shows a "verified" badge.
///
/// ## Backward-compat JSON migration
///
/// Records persisted by #1423 carry `confidence: double` and
/// `observationCount: int`. [fromJson] derives Beta parameters from
/// those legacy fields when `alpha`/`beta` are absent:
///
///   - `pseudoCount = max(observationCount, 1)`
///   - `α = confidence * pseudoCount + 1.0`
///   - `β = (1 - confidence) * pseudoCount + 9.0`
///
/// The +1 / +9 anchor terms reproduce the default prior so a
/// freshly-migrated record sits at the same weak baseline a
/// never-observed vehicle would.
@freezed
abstract class BrokenMapBelief with _$BrokenMapBelief {
  const BrokenMapBelief._();

  const factory BrokenMapBelief({
    /// Beta-distribution α parameter. Higher α → more "broken" mass.
    /// Defaults to 1.0 (paired with β=9.0 → mean=0.1, weak prior
    /// toward "working").
    @Default(1.0) double alpha,

    /// Beta-distribution β parameter. Higher β → more "working" mass.
    @Default(9.0) double beta,

    /// Number of observations folded into the posterior. Used by
    /// [isVerifiedClean] (auto-clear gate, #1424 deliverable D).
    @Default(0) int observationCount,

    /// Last time the updater was called. Null when the belief was
    /// just constructed and has never been updated.
    DateTime? lastUpdate,

    /// Last reason that contributed a *strong* observation
    /// (`observationScore > 0.5`). Sticky — only overwritten on the
    /// next strong observation.
    @Default(BrokenMapReason.none) BrokenMapReason lastTrigger,
  }) = _BrokenMapBelief;

  /// Migration-aware deserializer. Reads the new `alpha`/`beta` shape
  /// directly when present; falls back to the legacy `confidence`
  /// scalar (#1423 phase 1 entity) when the persisted record pre-dates
  /// #1424 — derives `α = confidence·n + 1` and
  /// `β = (1 - confidence)·n + 9` where `n = max(observationCount, 1)`.
  factory BrokenMapBelief.fromJson(Map<String, dynamic> json) =>
      _$BrokenMapBeliefFromJson(_migrateLegacyJson(json));

  /// In-place legacy-shape detector. When the record carries the
  /// pre-#1424 `confidence: double` field but no `alpha`, derives
  /// Beta(α, β) parameters from the legacy mean and observation
  /// count. Returns the input untouched when the record is already
  /// in the new shape.
  static Map<String, dynamic> _migrateLegacyJson(Map<String, dynamic> json) {
    final hasAlpha = json.containsKey('alpha');
    final hasConfidence = json.containsKey('confidence');
    if (hasAlpha || !hasConfidence) return json;
    final rawConfidence = json['confidence'];
    final rawCount = json['observationCount'];
    final confidence = rawConfidence is num
        ? rawConfidence.toDouble().clamp(0.0, 1.0)
        : 0.0;
    final observationCount = rawCount is num ? rawCount.toInt() : 0;
    final pseudoCount = math.max(observationCount.toDouble(), 1.0);
    final migrated = <String, dynamic>{
      ...json,
      'alpha': confidence * pseudoCount + 1.0,
      'beta': (1.0 - confidence) * pseudoCount + 9.0,
    };
    migrated.remove('confidence');
    return migrated;
  }

  /// Posterior mean — the drop-in replacement for the legacy EMA
  /// `confidence` scalar. In `[0.0, 1.0]`; 0 = certainly working,
  /// 1 = certainly broken.
  double get pointEstimate {
    final n = alpha + beta;
    if (n <= 0) return 0.0;
    return (alpha / n).clamp(0.0, 1.0);
  }

  /// 95 % credible interval around [pointEstimate]. Tuple is `(low,
  /// high)`; the spread is what the diagnostic overlay surfaces as
  /// `± ((high - low) / 2)`.
  ///
  /// Implementation uses two approximations chosen for accuracy and
  /// hand-rolled simplicity (no new pubspec deps, see #1424 § C):
  ///
  ///   - For α, β > 5: a normal approximation via the closed-form
  ///     Beta variance, accurate to ±0.02 for typical posteriors in
  ///     this codebase (α+β in 10–500).
  ///   - For α ≤ 5 OR β ≤ 5: a Wilson score interval over
  ///     `(α / (α + β), α + β)`, which stays well-behaved for the
  ///     low-data branch (initial probes, verifying band) where the
  ///     normal approximation drifts.
  ///
  /// Both branches clamp to `[0, 1]`. Tests
  /// (`broken_map_belief_test.dart`) validate canonical fixtures
  /// (Beta(1, 9) → wide; Beta(50, 50) → ≈ 0.5 ± 0.07).
  (double, double) get credibleInterval {
    final a = alpha;
    final b = beta;
    final n = a + b;
    if (n <= 0) return (0.0, 1.0);
    final mean = a / n;
    if (a > 5 && b > 5) {
      // Normal approximation: variance of Beta(α, β).
      final variance = (a * b) / (n * n * (n + 1));
      final sd = math.sqrt(variance);
      final margin = 1.96 * sd;
      return ((mean - margin).clamp(0.0, 1.0), (mean + margin).clamp(0.0, 1.0));
    }
    // Wilson-score fallback for small α or β. Treats α as "successes"
    // and α + β as the trial count — same shape the binomial Wilson
    // interval uses; behaves sanely when one parameter is near zero.
    const z = 1.96;
    const z2 = z * z;
    final denom = n + z2;
    final centre = (a + z2 / 2) / denom;
    final spread = (z / denom) * math.sqrt(a * b / n + z2 / 4);
    return (
      (centre - spread).clamp(0.0, 1.0),
      (centre + spread).clamp(0.0, 1.0),
    );
  }

  /// Sticky terminal "this sensor is fine" gate (#1424 deliverable D).
  /// Once true, [BrokenMapBeliefUpdater.update] short-circuits — no
  /// further observation moves the belief. The diagnostic overlay
  /// shows a "verified" badge.
  ///
  /// Gate criteria (all must hold):
  ///   - more than 50 observations folded in
  ///   - point estimate below 0.1 (essentially zero broken probability)
  ///   - upper 95 % credible bound below 0.3 (posterior actually
  ///     concentrated, not just a wide band centred low)
  bool get isVerifiedClean {
    if (observationCount <= 50) return false;
    if (pointEstimate >= 0.1) return false;
    return credibleInterval.$2 < 0.3;
  }
}
