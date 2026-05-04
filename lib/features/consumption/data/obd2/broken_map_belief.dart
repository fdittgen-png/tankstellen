import 'package:freezed_annotation/freezed_annotation.dart';

part 'broken_map_belief.freezed.dart';
part 'broken_map_belief.g.dart';

/// Reason tag set on the most recent strong observation that pushed
/// [BrokenMapBelief.confidence] up. Useful for the diagnostic overlay
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

  /// Not yet triggered by a strong observation (default).
  none,
}

/// Persisted fuzzy belief about whether a paired OBD2 adapter's MAP
/// sensor reads correctly (#1423). One belief per vehicle; persisted in
/// the settings box (key wiring deferred to phase 4 — phase 1 only
/// ships the entity + EMA math).
///
/// Confidence semantics:
///   - 0.0 → trusted (no broken-MAP evidence)
///   - 1.0 → certainly broken
///
/// UI thresholds (used by phase 5 consumers, documented here for
/// reference):
///   - < 0.4 → silent
///   - 0.4–0.7 → "MAP sensor verifying..." chip
///   - 0.7–0.9 → snackbar warning
///   - ≥ 0.9 → hard-disable MAP-derived fuel-rate
@freezed
abstract class BrokenMapBelief with _$BrokenMapBelief {
  const BrokenMapBelief._();

  const factory BrokenMapBelief({
    /// EMA-smoothed confidence in [0.0, 1.0]. Updater clamps on every
    /// step.
    @Default(0.0) double confidence,

    /// Number of observations folded into [confidence]. Useful for
    /// "verified" auto-clear (phase 2 of #1424 will gate on this).
    @Default(0) int observationCount,

    /// Last time [BrokenMapBeliefUpdater.update] was called. Null when
    /// the belief was just constructed and has never been updated.
    DateTime? lastUpdate,

    /// Last reason that contributed a *strong* observation
    /// (`observationScore > 0.5`). Sticky — only overwritten on the
    /// next strong observation.
    @Default(BrokenMapReason.none) BrokenMapReason lastTrigger,
  }) = _BrokenMapBelief;

  factory BrokenMapBelief.fromJson(Map<String, dynamic> json) =>
      _$BrokenMapBeliefFromJson(json);
}
