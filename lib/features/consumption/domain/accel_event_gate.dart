// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// The ONE canonical accel-event gate (#2667, Epic #2647 C3 / Fix D).
///
/// Three independent detectors used to disagree on the count for the same
/// physical event:
///   * [HarshEventDetector] (3.0/3.5 m/s², a ~0.9 s resample, and — since
///     #2653 — a sustained-window + accuracy + min-speed + source gate),
///   * `GpsDrivingFeatures.from` (a *2.0 m/s²* threshold with a ≥ 1 s
///     window but NO accuracy / min-speed gate),
///   * `driving_insights_analyzer.dart` (a *raw* `dvMps/dt` at 3.0 m/s²
///     with NO sustained window at all).
///
/// `driving_score_calculator.dart` already canonicalised
/// [kHardAccelThresholdMps2] / [kHardBrakeThresholdMps2] but the others
/// did not import them, so a single physical event yielded up to four
/// different counts.
///
/// This file is the single source of truth: the canonical thresholds and
/// the shared gate constants live here, plus one pure [countAccelEvents]
/// episode counter that every consumer routes through. The score
/// calculator re-exports the threshold constants from here, the harsh
/// detector keys its defaults off them, and the GPS-features / insights
/// list paths call [countAccelEvents] directly — so a given physical
/// event yields ONE count across the score, the insights, and the GPS
/// features.
///
/// ## Count semantics — one event per *episode*
///
/// An "event" is one sustained threshold-crossing *episode*, not one per
/// qualifying sample interval. A 4-second hard brake is ONE brake, not
/// four. The detector arms when the speed derivative first holds at or
/// beyond the threshold for at least [kAccelEventMinSustainedSec], counts
/// once, then re-arms only after the derivative drops back below the
/// threshold. This matches the physical intuition of "how many times did
/// the driver brake/accelerate hard", and is the semantics the GPS
/// features already used — it is the harsh detector's old
/// once-per-resample-interval count that was the outlier.
library;

/// Acceleration (m/s²) at/above which an interval is a hard-accel event.
/// Canonical — re-exported by `driving_score_calculator.dart`.
const double kHardAccelThresholdMps2 = 3.0;

/// Deceleration (m/s², positive) at/below whose negation an interval is a
/// hard-brake event. Canonical 3.5 (brake harder to trip than accel — the
/// telematics convention).
const double kHardBrakeThresholdMps2 = 3.5;

/// Minimum window length (seconds) the derivative must span before a
/// crossing counts (#2653) — rejects the single sub-1 s phasing spike a
/// coarse speed staircase produces. Matches the "sustained ≥ 1 s"
/// convention shared with the GPS features.
const double kAccelEventMinSustainedSec = 1.0;

/// Minimum mean interval speed (km/h) below which an interval is not
/// scored (#2653). Dead-reckoning noise at a near-standstill manufactures
/// phantom events; genuine harsh manoeuvres happen above a walking pace.
const double kAccelEventMinSpeedKmh = 5.0;

/// Reported horizontal GPS accuracy (metres) above which a sample is
/// dropped *and* the episode anchor reset, so the derivative is never
/// taken across a bad fix (#2653) — "a bad fix is worse than no fix". A
/// null / non-finite accuracy is treated as "unknown, accept" so
/// OBD-speed-only samples (no GPS) still flow.
const double kAccelEventAccuracyGateM = 10.0;

/// Upper Δt (seconds) between two samples still treated as a measurement
/// interval. A longer gap is a dropout/pause, not a window — counting a
/// derivative across it would fabricate an event.
const double kAccelEventMaxGapSec = 60.0;

/// One sample fed to [countAccelEvents]. Decoupled from any concrete
/// sample type so both `TripSample` (with `hAccuracyM`) and the leaner
/// `TripDetailSample` (no accuracy) can map onto it.
class AccelSamplePoint {
  const AccelSamplePoint({
    required this.timestamp,
    required this.speedKmh,
    this.hAccuracyM,
  });

  final DateTime timestamp;
  final double speedKmh;

  /// Reported horizontal GPS accuracy (m); null/non-finite = unknown.
  final double? hAccuracyM;
}

/// Accel / brake episode counts plus the indices (into the
/// timestamp-sorted input) at which each accel episode *began* — the
/// markers the trip-detail map renders (#1458).
class AccelEventCounts {
  const AccelEventCounts({
    required this.accelEvents,
    required this.brakeEvents,
    required this.accelSeconds,
    required this.accelStartIndices,
  });

  final int accelEvents;
  final int brakeEvents;

  /// Total seconds spent inside hard-accel episodes (the sum of the
  /// qualifying intervals' Δt). Used by the insights analyzer for the
  /// hard-accel cost line's `percentOfTrip`.
  final double accelSeconds;

  /// Post-sort indices where an accel episode is first *confirmed* — the
  /// end index of the interval at which the sustained-window floor
  /// ([kAccelEventMinSustainedSec]) is reached. One index per episode; the
  /// trip-detail map drops one marker there (#1458).
  final List<int> accelStartIndices;
}

/// Count hard-accel / hard-brake *episodes* over [points] using the
/// canonical thresholds + the shared sustained-window + accuracy +
/// min-speed gate (#2667).
///
/// Pure and synchronous. The input is copied and sorted by timestamp
/// (so out-of-order persistence cannot fabricate or drop an event); the
/// caller's list is never mutated. Intervals with `dt <= 0` (duplicate
/// timestamps) or `dt > kAccelEventMaxGapSec` (a dropout) are skipped and
/// break the running episode so the derivative is never taken across the
/// gap.
///
/// [suppress] — when true the whole series is unfit for differentiation
/// (the `virtual` dead-reckoning odometer); counts are zero. Mirrors the
/// harsh detector's source-aware suppression so the GPS-only / virtual
/// paths agree on "no events" rather than counting phasing artefacts.
AccelEventCounts countAccelEvents(
  List<AccelSamplePoint> points, {
  bool suppress = false,
}) {
  if (suppress || points.length < 2) {
    return const AccelEventCounts(
      accelEvents: 0,
      brakeEvents: 0,
      accelSeconds: 0,
      accelStartIndices: <int>[],
    );
  }

  final sorted = [...points]
    ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

  var accelEvents = 0, brakeEvents = 0;
  var accelSeconds = 0.0;
  final accelStartIndices = <int>[];

  // Episode state: accumulate the sustained duration above each threshold;
  // arm once it first reaches the sustained-window floor; re-arm only when
  // the derivative drops back below the threshold.
  var accelDur = 0.0, brakeDur = 0.0;
  var inAccel = false, inBrake = false;

  void breakEpisodes() {
    accelDur = 0;
    brakeDur = 0;
    inAccel = false;
    inBrake = false;
  }

  for (var i = 1; i < sorted.length; i++) {
    final prev = sorted[i - 1];
    final cur = sorted[i];
    final dt = cur.timestamp.difference(prev.timestamp).inMicroseconds /
        Duration.microsecondsPerSecond;
    if (dt <= 0 || dt > kAccelEventMaxGapSec) {
      breakEpisodes();
      continue;
    }

    // Accuracy gate: a bad fix is worse than no fix — drop it and break
    // the running episode so no derivative spans it.
    final pAcc = prev.hAccuracyM, cAcc = cur.hAccuracyM;
    final badFix = (pAcc != null && pAcc.isFinite && pAcc > kAccelEventAccuracyGateM) ||
        (cAcc != null && cAcc.isFinite && cAcc > kAccelEventAccuracyGateM);
    if (badFix) {
      breakEpisodes();
      continue;
    }

    // Min-speed floor: a near-standstill wobble is not a real manoeuvre.
    final meanSpeedKmh = (prev.speedKmh + cur.speedKmh) / 2.0;
    if (meanSpeedKmh < kAccelEventMinSpeedKmh) {
      breakEpisodes();
      continue;
    }

    // Δspeed km/h → m/s by / 3.6, then / Δt for m/s².
    final accelMps2 = ((cur.speedKmh - prev.speedKmh) / 3.6) / dt;

    if (accelMps2 >= kHardAccelThresholdMps2) {
      accelDur += dt;
      accelSeconds += dt;
      if (!inAccel && accelDur >= kAccelEventMinSustainedSec) {
        accelEvents++;
        // Confirm at the END index of the interval that crossed the
        // sustained floor — where the hard accel is first certain, the
        // marker position the trip-detail map has always used (#1458).
        accelStartIndices.add(i);
        inAccel = true;
      }
    } else {
      accelDur = 0;
      inAccel = false;
    }

    if (accelMps2 <= -kHardBrakeThresholdMps2) {
      brakeDur += dt;
      if (!inBrake && brakeDur >= kAccelEventMinSustainedSec) {
        brakeEvents++;
        inBrake = true;
      }
    } else {
      brakeDur = 0;
      inBrake = false;
    }
  }

  return AccelEventCounts(
    accelEvents: accelEvents,
    brakeEvents: brakeEvents,
    accelSeconds: accelSeconds,
    accelStartIndices: accelStartIndices,
  );
}
