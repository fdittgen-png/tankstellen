import 'package:flutter/foundation.dart';

import '../../../vehicle/domain/entities/vehicle_profile.dart';
import '../../data/trip_history_repository.dart';
import '../entities/fill_up.dart';

/// How a [TankLevelEstimate] was derived (#1195).
///
/// * [obd2] — every trip considered carried a measured
///   `fuelLitersConsumed` value from the OBD2 fuel-rate samples.
/// * [distanceFallback] — every trip relied on the distance × avg
///   L/100 km fallback because no OBD2 fuel measurement was available.
/// * [mixed] — at least one trip used OBD2 and at least one trip used
///   the distance fallback. Surfaced to the user as "mixed measurement"
///   so the estimate's data quality is honest.
enum TankLevelEstimationMethod {
  obd2,
  distanceFallback,
  mixed,
}

/// Default L/100 km used when a vehicle has no learned average yet.
///
/// 7 L/100 km is a defensive midpoint for European fleet averages —
/// honest enough for the distance-based fallback to give a usable range
/// estimate without overstating accuracy. Will be replaced by
/// `vehicle.tripLengthAggregates.overallAvgLPer100Km` once #1191 lands.
const double _defaultAvgLPer100Km = 7.0;

/// Result of the tank-level computation (#1195).
///
/// All values are honest: `levelL` is clamped to `[0, capacityL]` so the
/// UI never shows negative fuel or "more than full" readings, and
/// `rangeKm` is null whenever the underlying average is unavailable.
@immutable
class TankLevelEstimate {
  /// Estimated litres currently in the tank, clamped to
  /// `[0, capacityL ?? infinity]`.
  final double levelL;

  /// Vehicle tank capacity in litres, when known. Null when the
  /// vehicle profile has no `tankCapacityL` set — the UI then renders
  /// the level number without a percentage bar or range estimate.
  final double? capacityL;

  /// Date of the most recent fill-up considered. The UI shows this in
  /// the caption ("Last fill-up: 27 Apr · 1 trip since · …"). Null on
  /// the [unknown] sentinel.
  final DateTime? lastFillUpDate;

  /// How the consumption since the last fill-up was measured.
  final TankLevelEstimationMethod method;

  /// Estimated remaining range, in kilometres. Null when no average
  /// L/100 km is available (e.g. vehicle without history and the
  /// hard-coded fallback was suppressed) — surface as "no range
  /// estimate" rather than fabricating a number.
  final double? rangeKm;

  /// Number of trips actually folded into the consumption calculation
  /// (i.e. trips with `startedAt` after the last fill-up). Used by the
  /// UI to render the "N trip(s) since" caption without re-walking the
  /// trip list.
  final int tripsSince;

  const TankLevelEstimate({
    required this.levelL,
    required this.capacityL,
    required this.lastFillUpDate,
    required this.method,
    required this.rangeKm,
    required this.tripsSince,
  });

  /// Sentinel returned when no fill-ups exist for the vehicle. Callers
  /// render the "Log a fill-up to see your tank level" empty state.
  const TankLevelEstimate.unknown()
      : levelL = 0,
        capacityL = null,
        lastFillUpDate = null,
        method = TankLevelEstimationMethod.obd2,
        rangeKm = null,
        tripsSince = 0;

  /// True when the estimator returned the [unknown] sentinel because
  /// no fill-up history is available yet.
  bool get hasFillUp => lastFillUpDate != null;
}

/// Compute the current tank level for a vehicle from its fill-up history
/// and the trips logged since the most recent fill-up (#1195, #1360).
///
/// Inputs:
/// * [vehicle] — the [VehicleProfile] this tank belongs to. Drives the
///   `tankCapacityL` cap and the L/100 km fallback for the distance
///   path. Once #1191 lands the overall avg from
///   `tripLengthAggregates` will replace the hard-coded 7.0.
/// * [fillUps] — every fill-up logged for the vehicle, newest first.
///   When the most recent fill is a full "plein" the older entries
///   don't change the answer (the tank was reset at the most recent
///   fill). When the most recent fill is partial (#1360) the estimator
///   walks earlier fills + trips between them to derive the level just
///   before the partial top-up.
/// * [trips] — trip history for the vehicle. The caller (provider)
///   filters by vehicle and drops null `startedAt`; this function adds
///   defensive guards. Trips after the most recent fill subtract from
///   the level; trips between earlier fills are used to compute the
///   level just before a partial-fill anchor.
///
/// Returns [TankLevelEstimate.unknown] when [fillUps] is empty.
///
/// Partial-fill branch (#1360):
/// * `lastFillUp.isFullTank == true` → starting level resets to
///   `vehicle.tankCapacityL` (or `lastFillUp.liters` when no capacity
///   is configured) — historical behaviour.
/// * `lastFillUp.isFullTank == false` → starting level is
///   `previous_level + lastFillUp.liters`, clamped into
///   `[0, capacityL]`. The "previous level" is computed by walking
///   earlier fill-ups oldest→newest and subtracting trip consumption
///   between them, anchored by the most recent prior full fill (or 0
///   when no full anchor exists, the honest fallback for a tank with
///   partials only).
///
/// `tripsSince`, `method`, and `rangeKm` are derived solely from trips
/// AFTER the most recent fill-up — partial or full. The "trips since
/// last fill-up" caption stays meaningful regardless of the toggle.
TankLevelEstimate estimateTankLevel({
  required VehicleProfile vehicle,
  required List<FillUp> fillUps,
  required List<TripHistoryEntry> trips,
}) {
  if (fillUps.isEmpty) {
    return const TankLevelEstimate.unknown();
  }

  final lastFillUp = fillUps.first;
  final capacityL = vehicle.tankCapacityL;
  final upperBound = capacityL ?? double.infinity;

  // TODO(#1191): replace with vehicle.tripLengthAggregates
  //   ?.overallAvgLPer100Km once the carbon-dashboard aggregates land.
  const avgLPer100Km = _defaultAvgLPer100Km;

  // Compute the starting level right after [lastFillUp] (#1360 partial-
  // fill branch). For full fills this is just capacity; for partials
  // we walk back through earlier history.
  final startLevelL = _initialLevelAfterFill(
    fillUps: fillUps,
    trips: trips,
    capacityL: capacityL,
    avgLPer100Km: avgLPer100Km,
  );

  var consumed = 0.0;
  var consideredTrips = 0;
  var sawObd2 = false;
  var sawFallback = false;

  for (final t in trips) {
    final startedAt = t.summary.startedAt;
    if (startedAt == null) continue;
    if (startedAt.isBefore(lastFillUp.date)) continue;
    consideredTrips++;
    final measured = t.summary.fuelLitersConsumed;
    if (measured != null) {
      consumed += measured;
      sawObd2 = true;
    } else {
      consumed += t.summary.distanceKm * avgLPer100Km / 100.0;
      sawFallback = true;
    }
  }

  // Clamp into [0, capacity] so we never advertise more fuel than the
  // tank holds (defensive against a rare negative-consumption write
  // race) or a negative level (consumed > capacity, e.g. user logged
  // a full week of trips without a fill-up).
  final levelL = (startLevelL - consumed).clamp(0.0, upperBound);

  final TankLevelEstimationMethod method;
  if (sawObd2 && sawFallback) {
    method = TankLevelEstimationMethod.mixed;
  } else if (sawFallback) {
    method = TankLevelEstimationMethod.distanceFallback;
  } else {
    // No trips at all OR every considered trip carried OBD2 data —
    // both branches are honest as `obd2`: the empty-trips case is
    // vacuously a measured estimate (no consumption to attribute to
    // the fallback).
    method = TankLevelEstimationMethod.obd2;
  }

  // Range estimate: how far the remaining litres take you at the
  // vehicle's average. avgLPer100Km is non-zero today (hard-coded
  // 7.0); guard against a future zero so the division stays honest.
  final rangeKm = avgLPer100Km > 0 ? (levelL / avgLPer100Km) * 100.0 : null;

  return TankLevelEstimate(
    levelL: levelL,
    capacityL: capacityL,
    lastFillUpDate: lastFillUp.date,
    method: method,
    rangeKm: rangeKm,
    tripsSince: consideredTrips,
  );
}

/// Compute the level right after the most recent fill (#1360).
///
/// `fillUps` is the same input the estimator received: newest first,
/// for one vehicle. `trips` includes both pre- and post-fill trips —
/// the post-fill ones are subtracted by the caller, so this helper
/// only consults trips strictly between earlier fills.
///
/// Algorithm:
///  1. If the most recent fill is full, return `capacityL ?? lastFill.liters`
///     (no need to walk history — the tank just got reset).
///  2. Else, find the most recent prior FULL fill, anchor the level at
///     capacity there, then walk forward applying intermediate partial
///     fills and trip consumption between them. The result is the level
///     just before the most recent (partial) fill; add its litres,
///     clamp into `[0, capacity]`, and return.
///  3. If no prior full anchor exists, start from 0 — honest worst-
///     case for a tank whose history is partials only (the user's
///     starting state is unknown). The clamp keeps the answer within
///     `[0, capacity]`.
double _initialLevelAfterFill({
  required List<FillUp> fillUps,
  required List<TripHistoryEntry> trips,
  required double? capacityL,
  required double avgLPer100Km,
}) {
  final upper = capacityL ?? double.infinity;
  final lastFill = fillUps.first;

  if (lastFill.isFullTank) {
    // Capacity wins when known; otherwise fall back to "tank held at
    // least the litres the user just pumped in", which is honest when
    // capacity isn't configured.
    return capacityL ?? lastFill.liters;
  }

  // Build a chronological (oldest→newest) view of every prior fill.
  final priorFills = fillUps.skip(1).toList(growable: false).reversed.toList();

  // Find the most recent full fill before lastFill — the anchor.
  int anchorIdx = -1;
  for (var i = priorFills.length - 1; i >= 0; i--) {
    if (priorFills[i].isFullTank) {
      anchorIdx = i;
      break;
    }
  }

  // No anchor → honest fallback: start from 0 and let the partials
  // accumulate (clamp keeps the answer within capacity). When capacity
  // is unknown we still return `lastFill.liters` clamped — same shape
  // as the no-capacity branch above for the full-tank path.
  double level;
  int startIdx;
  if (anchorIdx < 0) {
    level = 0;
    startIdx = 0;
  } else {
    level = capacityL ?? priorFills[anchorIdx].liters;
    startIdx = anchorIdx + 1;
  }

  // Walk forward: for each prior fill from startIdx to the end, apply
  // trip consumption between the previous boundary and this fill, then
  // apply the partial top-up.
  var prevBoundary = anchorIdx >= 0 ? priorFills[anchorIdx].date : null;
  for (var i = startIdx; i < priorFills.length; i++) {
    final f = priorFills[i];
    final consumed = _consumedBetween(
      trips: trips,
      from: prevBoundary,
      to: f.date,
      avgLPer100Km: avgLPer100Km,
    );
    level = (level - consumed).clamp(0.0, upper);
    // Each partial in the chain adds its litres. (Full fills before
    // lastFill are also clamped — anchorIdx already pointed at the
    // most recent one, so any later "full" entries don't appear here
    // by construction.)
    level = (level + f.liters).clamp(0.0, upper);
    prevBoundary = f.date;
  }

  // Finally, consume between the last prior boundary and lastFill,
  // then add lastFill.liters (the partial top-up).
  final consumedToLast = _consumedBetween(
    trips: trips,
    from: prevBoundary,
    to: lastFill.date,
    avgLPer100Km: avgLPer100Km,
  );
  level = (level - consumedToLast).clamp(0.0, upper);
  level = (level + lastFill.liters).clamp(0.0, upper);
  return level;
}

/// Sum trip consumption strictly between [from] (exclusive) and [to]
/// (exclusive). Null `from` means "since the beginning of time".
///
/// Trips with `startedAt == null` are skipped (defensive — the provider
/// already drops these). OBD2 measurements win when present; otherwise
/// the distance × avg L/100 km fallback applies.
double _consumedBetween({
  required List<TripHistoryEntry> trips,
  required DateTime? from,
  required DateTime to,
  required double avgLPer100Km,
}) {
  var total = 0.0;
  for (final t in trips) {
    final startedAt = t.summary.startedAt;
    if (startedAt == null) continue;
    if (from != null && !startedAt.isAfter(from)) continue;
    if (!startedAt.isBefore(to)) continue;
    final measured = t.summary.fuelLitersConsumed;
    if (measured != null) {
      total += measured;
    } else {
      total += t.summary.distanceKm * avgLPer100Km / 100.0;
    }
  }
  return total;
}
