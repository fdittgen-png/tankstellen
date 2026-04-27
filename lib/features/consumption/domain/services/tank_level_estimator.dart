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
/// and the trips logged since the most recent fill-up (#1195).
///
/// Inputs:
/// * [vehicle] — the [VehicleProfile] this tank belongs to. Drives the
///   `tankCapacityL` cap and the L/100 km fallback for the distance
///   path. Once #1191 lands the overall avg from
///   `tripLengthAggregates` will replace the hard-coded 7.0.
/// * [fillUps] — every fill-up logged for the vehicle, newest first.
///   Only the head entry is consulted; older fills don't change the
///   answer because the tank was reset at the most recent fill.
/// * [trips] — every trip recorded since the most recent fill-up. The
///   caller is responsible for the filtering (provider does this); the
///   estimator additionally drops trips with `startedAt == null` or
///   `startedAt < lastFillUp.date` as a defensive belt-and-braces
///   guard so the function stays correct in unit tests that pass a
///   broader list.
///
/// Returns [TankLevelEstimate.unknown] when [fillUps] is empty.
///
/// v1: assumes every fill-up tops the tank up to capacity (the common
/// "plein" pattern). The freshly-added [FillUp.isFullTank] flag is
/// captured but not yet honoured here — once partial-fill UI lands the
/// branch flips to `previous_level + liters_added` for `isFullTank ==
/// false`. Today the data is recorded so the estimator can become
/// flag-aware without a migration.
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
  // Initial tank level. Capacity wins when known; otherwise we fall
  // back to "tank held at least the litres the user just pumped in",
  // which is honest for a partial-fill case where capacity isn't set.
  final startLevelL = capacityL ?? lastFillUp.liters;

  // TODO(#1191): replace with vehicle.tripLengthAggregates
  //   ?.overallAvgLPer100Km once the carbon-dashboard aggregates land.
  const avgLPer100Km = _defaultAvgLPer100Km;

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
  final upperBound = capacityL ?? double.infinity;
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
