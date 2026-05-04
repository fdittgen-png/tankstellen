import 'broken_map_belief.dart';

/// Membership functions + EMA updater for [BrokenMapBelief] (#1423).
/// Pure math — no I/O, no Riverpod, no Hive. Phase 1 ships these so
/// downstream phases (idle probe, reconciler hook, blocklist) can
/// build on a stable contract.
///
/// All membership functions return values in [0.0, 1.0] where 1.0 is
/// strong evidence of a broken MAP sensor. Each is paired with a
/// realistic boundary range derived from the issue spec (§ E).
class BrokenMapBeliefUpdater {
  /// Exponential smoothing factor (`α`). 0.4 weights the new
  /// observation noticeably without making the belief jump on a
  /// single noisy sample. Tuned in spec § E.
  static const double _alpha = 0.4;

  /// Threshold above which an observation is "strong" enough to set
  /// [BrokenMapBelief.lastTrigger]. Below this the belief still
  /// accumulates but the trigger tag isn't overwritten.
  static const double _strongThreshold = 0.5;

  /// Idle-vacuum-missing membership. On a healthy NA petrol engine,
  /// `baro - map` at idle is typically 30-45 kPa (strong vacuum).
  /// On a broken MAP that returns atmospheric, the delta is ≤ 5 kPa.
  ///   - Returns 0.0 when delta ≥ 45 kPa (healthy vacuum).
  ///   - Returns 1.0 when delta ≤ 15 kPa (no vacuum — likely broken).
  ///   - Linear interp in between.
  static double vacuumMissingScore({
    required double baroKpa,
    required double mapKpa,
  }) {
    final delta = baroKpa - mapKpa;
    return (1.0 - ((delta - 15.0) / 30.0)).clamp(0.0, 1.0);
  }

  /// Diesel-rev-delta membership. Diesels run unthrottled so idle MAP
  /// is near baro; the discriminator is how much MAP *changes* under
  /// a brief rev. Healthy: ≥ 30 kPa swing. Broken: ≤ 8 kPa swing.
  ///   - Returns 0.0 when |rev - idle| ≥ 30 kPa.
  ///   - Returns 1.0 when |rev - idle| ≤ 8 kPa.
  static double revDeltaMissingScore({
    required double mapIdleKpa,
    required double mapRevvedKpa,
  }) {
    final delta = (mapRevvedKpa - mapIdleKpa).abs();
    return (1.0 - ((delta - 8.0) / 22.0)).clamp(0.0, 1.0);
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

  /// Folds [observationScore] (already-combined, in [0.0, 1.0]) into
  /// [prev] via EMA. Updates the trigger only when the score crosses
  /// the strong threshold.
  ///
  /// `now` is injected for deterministic tests; production callers pass
  /// `DateTime.now()`.
  static BrokenMapBelief update(
    BrokenMapBelief prev,
    double observationScore, {
    required DateTime now,
    BrokenMapReason? reason,
  }) {
    final clampedScore = observationScore.clamp(0.0, 1.0);
    final newConfidence =
        (_alpha * clampedScore + (1.0 - _alpha) * prev.confidence)
            .clamp(0.0, 1.0);
    final isStrong = clampedScore > _strongThreshold;
    return prev.copyWith(
      confidence: newConfidence,
      observationCount: prev.observationCount + 1,
      lastUpdate: now,
      lastTrigger: isStrong && reason != null ? reason : prev.lastTrigger,
    );
  }
}
