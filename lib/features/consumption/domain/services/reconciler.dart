import 'package:flutter/foundation.dart';

import '../../data/trip_history_repository.dart';
import '../entities/fill_up.dart';
import '../trip_recorder.dart';

/// Outcome bucket for [Reconciler.reconcile] (#1361). Lets the caller
/// distinguish "no correction needed because the gap was tiny" from
/// "no correction needed because no trips fell in the window" — both
/// produce a null [ReconciliationResult.correction] but mean different
/// things to the breadcrumb log and the user.
enum ReconciliationAction {
  /// A correction fill-up was synthesised. [ReconciliationResult.correction]
  /// is non-null and ready to be persisted alongside the closing plein.
  created,

  /// `gap` was within the relative + absolute thresholds. No correction
  /// is produced — the OBD integrator already matched the pump within
  /// noise, so adding an entry would clutter the list.
  skippedBelowThreshold,

  /// `gap` was negative, meaning the OBD integrator over-estimated
  /// fuel use vs. what the pump actually delivered. We don't synthesize
  /// a "negative correction" entry; that's noise / instrumentation
  /// drift, not a missed fill-up. Logged so a future η_v audit can
  /// spot vehicles whose integrator runs hot.
  clampedNegative,

  /// No trips were found in the window. Without trip data there's no
  /// reconciliation to perform — every pumped litre maps trivially to
  /// itself. This is the typical first-fill-after-install case.
  skippedNoTrips,
}

/// Result of reconciling a closed plein-to-plein window (#1361).
///
/// All numeric fields are populated even when [correction] is null so
/// the caller can log a useful breadcrumb regardless of outcome.
@immutable
class ReconciliationResult {
  /// Sum of `liters` across every fill-up in the window (including
  /// the closing plein).
  final double pumped;

  /// Sum of `summary.fuelLitersConsumed` across every trip in the
  /// window. Trips with `fuelLitersConsumed == null` contribute zero.
  final double consumed;

  /// `pumped - consumed`. Positive means the pump delivered more than
  /// the OBD integrator accounted for — the user likely drove without
  /// recording (adapter unplugged, off-app drives) and the gap should
  /// be backfilled as a correction entry.
  final double gap;

  /// The synthesised correction [FillUp] when [action] is
  /// [ReconciliationAction.created]; null otherwise.
  final FillUp? correction;

  /// Bucket explaining why [correction] is or isn't populated.
  final ReconciliationAction action;

  const ReconciliationResult({
    required this.pumped,
    required this.consumed,
    required this.gap,
    required this.correction,
    required this.action,
  });
}

/// Pure-logic reconciliation helper for the trip-vs-pump correction
/// system (#1361). Takes a closing plein, the full fill-up list for
/// the vehicle, and the full trip list for the vehicle, and either
/// emits a synthetic correction [FillUp] or a "no correction needed"
/// outcome. No Riverpod, no Hive — fully unit-testable.
///
/// The window semantics are `(previousPlein.date, closingPlein.date]`
/// when a previous plein exists, and `[firstFill.date, closingPlein.date]`
/// (closed lower bound) when the closing plein is the first plein in
/// the data set. `windowFills` always includes the closing plein.
class Reconciler {
  /// Don't synthesise a correction unless the absolute gap is at
  /// least this many litres. Sub-half-litre gaps are within typical
  /// pump rounding + integrator noise.
  static const double absoluteThresholdLiters = 0.5;

  /// Don't synthesise a correction unless the relative gap exceeds
  /// 5 % of pumped volume. Picks up a 1.5 L miss on a 30 L tank, but
  /// ignores a 0.4 L drift on the same tank.
  static const double relativeThreshold = 0.05;

  const Reconciler();

  /// Compute the reconciliation outcome for the window CLOSED by
  /// [closingPlein]. Returns null if [closingPlein.isFullTank] is
  /// false — windows only close on a full-tank fill, partials extend
  /// the open window.
  ReconciliationResult? reconcile({
    required FillUp closingPlein,
    required List<FillUp> allFillUpsForVehicle,
    required List<TripSummary> tripsForVehicle,
  }) {
    if (!closingPlein.isFullTank) {
      return null;
    }

    final vehicleId = closingPlein.vehicleId;

    // Same-vehicle fills only. Skip already-existing correction
    // entries — re-running reconciliation must NOT include the
    // previous correction in the next window's `pumped`.
    final sameVehicleFills = allFillUpsForVehicle
        .where(
          (f) =>
              f.vehicleId == vehicleId &&
              !f.isCorrection &&
              f.id != closingPlein.id,
        )
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    // Find the most recent prior plein. Anything strictly older than
    // [closingPlein] qualifies — we don't care if there are partial
    // top-ups between the two pleins (those will be folded into the
    // window via [windowFills]).
    FillUp? previousPlein;
    for (final f in sameVehicleFills) {
      if (!f.date.isBefore(closingPlein.date)) continue;
      if (!f.isFullTank) continue;
      if (previousPlein == null || f.date.isAfter(previousPlein.date)) {
        previousPlein = f;
      }
    }

    DateTime windowStart;
    bool inclusiveLower;
    if (previousPlein != null) {
      windowStart = previousPlein.date;
      inclusiveLower = false;
    } else {
      // No prior plein — window starts at the first fill-up. If even
      // that's missing (closingPlein is the first ever fill-up), the
      // window is just the closing plein itself.
      if (sameVehicleFills.isEmpty) {
        windowStart = closingPlein.date;
      } else {
        windowStart = sameVehicleFills.first.date;
      }
      inclusiveLower = true;
    }

    bool inWindow(DateTime when) {
      final afterStart = inclusiveLower
          ? !when.isBefore(windowStart)
          : when.isAfter(windowStart);
      final beforeEnd = !when.isAfter(closingPlein.date);
      return afterStart && beforeEnd;
    }

    // windowFills = same-vehicle fills in the window + the closing
    // plein. Exclude correction entries so re-running reconciliation
    // doesn't double-count last cycle's gap.
    final windowFills = <FillUp>[
      ...sameVehicleFills.where((f) => inWindow(f.date)),
      closingPlein,
    ]..sort((a, b) => a.date.compareTo(b.date));

    final pumped = windowFills.fold<double>(
      0,
      (sum, f) => sum + f.liters,
    );

    final windowTrips = tripsForVehicle.where((t) {
      final when = t.startedAt;
      if (when == null) return false;
      return inWindow(when);
    }).toList();

    if (windowTrips.isEmpty) {
      debugPrint(
        '[reconcile] vehicle=$vehicleId window=${windowStart.toIso8601String()}'
        '..${closingPlein.date.toIso8601String()} pumped=$pumped consumed=0 '
        'gap=$pumped action=skippedNoTrips',
      );
      return ReconciliationResult(
        pumped: pumped,
        consumed: 0,
        gap: pumped,
        correction: null,
        action: ReconciliationAction.skippedNoTrips,
      );
    }

    final consumed = windowTrips.fold<double>(
      0,
      (sum, t) => sum + (t.fuelLitersConsumed ?? 0),
    );
    final gap = pumped - consumed;

    if (gap < 0) {
      debugPrint(
        '[reconcile] vehicle=$vehicleId window=${windowStart.toIso8601String()}'
        '..${closingPlein.date.toIso8601String()} pumped=$pumped '
        'consumed=$consumed gap=$gap action=clampedNegative',
      );
      return ReconciliationResult(
        pumped: pumped,
        consumed: consumed,
        gap: gap,
        correction: null,
        action: ReconciliationAction.clampedNegative,
      );
    }

    if (gap < absoluteThresholdLiters || gap < pumped * relativeThreshold) {
      debugPrint(
        '[reconcile] vehicle=$vehicleId window=${windowStart.toIso8601String()}'
        '..${closingPlein.date.toIso8601String()} pumped=$pumped '
        'consumed=$consumed gap=$gap action=skippedBelowThreshold',
      );
      return ReconciliationResult(
        pumped: pumped,
        consumed: consumed,
        gap: gap,
        correction: null,
        action: ReconciliationAction.skippedBelowThreshold,
      );
    }

    // Build a synthetic FillUp at the window midpoint. Date and
    // odometer midpoints are computed from the window's first fill
    // (which may be the previous plein, a partial top-up, or the
    // closing plein itself in degenerate one-fill windows).
    final firstFill = windowFills.first;
    final midDateMs = (firstFill.date.millisecondsSinceEpoch +
            closingPlein.date.millisecondsSinceEpoch) ~/
        2;
    final midDate = DateTime.fromMillisecondsSinceEpoch(midDateMs);
    final midOdo =
        (firstFill.odometerKm + closingPlein.odometerKm) / 2.0;

    final correction = FillUp(
      id: 'correction_${closingPlein.id}',
      date: midDate,
      liters: gap,
      totalCost: 0,
      odometerKm: midOdo,
      fuelType: closingPlein.fuelType,
      vehicleId: vehicleId,
      isFullTank: false,
      isCorrection: true,
    );

    debugPrint(
      '[reconcile] vehicle=$vehicleId window=${windowStart.toIso8601String()}'
      '..${closingPlein.date.toIso8601String()} pumped=$pumped '
      'consumed=$consumed gap=$gap action=created',
    );
    return ReconciliationResult(
      pumped: pumped,
      consumed: consumed,
      gap: gap,
      correction: correction,
      action: ReconciliationAction.created,
    );
  }
}

/// Convenience adapter for callers that hold a list of
/// [TripHistoryEntry] (the on-disk shape) rather than the raw
/// [TripSummary]s the [Reconciler] consumes. Keeps the reconciler
/// repository-agnostic while letting production wiring pass through
/// the trip history list directly.
List<TripSummary> tripSummariesForVehicle({
  required String? vehicleId,
  required List<TripHistoryEntry> history,
}) {
  return history
      .where((e) => e.vehicleId == vehicleId)
      .map((e) => e.summary)
      .toList(growable: false);
}
