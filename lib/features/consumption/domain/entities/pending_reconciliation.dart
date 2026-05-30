// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';

import 'fill_up.dart';

/// A reconciliation gap that the detector ([Reconciler.reconcile])
/// flagged as needing a correction, surfaced for a future consumer to
/// act on (Epic #2439 / #2441).
///
/// Today (#1361) the only consumer is the silent auto-save path — the
/// seam still persists [correction] immediately, so this object is
/// purely an *exposed hook* and changes nothing the user sees. The
/// guided reconciliation workflow (#2442) will later read this pending
/// gap, explain it to the user, and decide how to resolve it (correct
/// the fill-ups, add a virtual trajet, or defer) instead of the silent
/// save.
///
/// Immutable value object — no Riverpod, no Hive, fully unit-testable.
/// Mirrors the hand-written `@immutable` style of [ReconciliationResult]
/// so it stays codegen-free.
@immutable
class PendingReconciliation {
  /// The synthetic correction [FillUp] the detector built for this gap.
  /// On the silent-save path this is exactly the entry that is written
  /// today; the workflow (#2442) will instead use it as the *proposed*
  /// correction the user can confirm, edit, or reject.
  final FillUp correction;

  /// Sum of pumped litres across the plein-to-plein window (including
  /// the closing plein). Mirrors `ReconciliationResult.pumped`.
  final double pumped;

  /// Sum of OBD-integrated trip fuel across the window. Mirrors
  /// `ReconciliationResult.consumed`.
  final double consumed;

  /// `pumped - consumed` — the unaccounted litres the correction
  /// backfills. Always positive for a pending gap (the detector only
  /// emits a correction when the gap clears both thresholds).
  final double gap;

  /// Window-midpoint date the correction is dated at (the detector's
  /// own midpoint between the window's first fill and the closing
  /// plein).
  final DateTime windowMidpointDate;

  /// Window-midpoint odometer reading the correction carries.
  final double windowMidpointOdometerKm;

  /// The vehicle this gap belongs to. Null only in degenerate data
  /// (vehicle-less fills never reach the detector's created branch).
  final String? vehicleId;

  const PendingReconciliation({
    required this.correction,
    required this.pumped,
    required this.consumed,
    required this.gap,
    required this.windowMidpointDate,
    required this.windowMidpointOdometerKm,
    required this.vehicleId,
  });

  /// Build a [PendingReconciliation] from a created-action correction
  /// [FillUp] and the window's pumped/consumed/gap figures. The window
  /// midpoint date + odometer are read straight off [correction] (the
  /// detector already placed it at the window midpoint), so this stays
  /// a faithful, lossless projection of the detector's output.
  factory PendingReconciliation.fromCorrection({
    required FillUp correction,
    required double pumped,
    required double consumed,
    required double gap,
  }) {
    return PendingReconciliation(
      correction: correction,
      pumped: pumped,
      consumed: consumed,
      gap: gap,
      windowMidpointDate: correction.date,
      windowMidpointOdometerKm: correction.odometerKm,
      vehicleId: correction.vehicleId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PendingReconciliation &&
          runtimeType == other.runtimeType &&
          correction == other.correction &&
          pumped == other.pumped &&
          consumed == other.consumed &&
          gap == other.gap &&
          windowMidpointDate == other.windowMidpointDate &&
          windowMidpointOdometerKm == other.windowMidpointOdometerKm &&
          vehicleId == other.vehicleId;

  @override
  int get hashCode => Object.hash(
        correction,
        pumped,
        consumed,
        gap,
        windowMidpointDate,
        windowMidpointOdometerKm,
        vehicleId,
      );
}
