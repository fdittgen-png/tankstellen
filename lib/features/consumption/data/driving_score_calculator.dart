/// Pure calculator that turns a stream of [TripSample]s into a
/// [DrivingScore] composite for the trip Insights tab (#1041 phase 5a
/// — Card A).
///
/// ## Score model
///
/// Start at 100 and subtract penalty contributions per category. The
/// final score is floored at 0 and capped at 100. Weights are
/// intentionally coarse — the goal is *coaching*, not telematics-grade
/// scoring. Future phases may calibrate against the per-vehicle
/// baseline store; until then the same constants used by the cost-line
/// analyzer (`driving_insights_analyzer.dart`) are reused so the two
/// surfaces stay consistent.
///
/// ## Weights (sum of caps = 85; remaining 15 of headroom keeps the
/// floor reachable only on truly catastrophic trips)
///
///   * Idling: linear in idle-time fraction of trip duration. 100% of
///     the trip idling = -25. (50 % idling = -12.5.)
///   * Hard accelerations (≥ 3.0 m/s²): -3 per event, capped at -15
///     (so 5+ events saturates).
///   * Hard brakes (≤ -3.0 m/s²): -3 per event, capped at -15.
///   * High-RPM time (> 3000 RPM): linear in fraction of trip
///     duration, full saturation at -20 when the entire trip was
///     above threshold.
///   * Full-throttle time: linear in fraction of trip duration, full
///     saturation at -10. Persisted [TripSample]s do not currently
///     carry throttle %, so this contribution is 0 for legacy trips —
///     the calculator still exposes the field so the UI does not need
///     a schema change when throttle persistence lands. The
///     [TripSample] schema may grow a `throttlePercent` field in a
///     follow-up; until then the throttle penalty stays a documented
///     no-op.
///
/// ## Sub-text follow-up
///
/// The issue body describes a "Better than X% of past trips" sub-text
/// that consumes the existing baseline store. That store
/// (`baseline_store.dart`) tracks per-vehicle per-situation
/// *steady-state baselines*, not per-trip scores, so a trip-history
/// percentile is its own piece of work. This calculator therefore
/// returns a single [DrivingScore] without any percentile context;
/// surfacing percentile / "better than X%" is intentionally deferred
/// to a follow-up phase.
library;

import '../domain/driving_score.dart';
import '../domain/trip_recorder.dart';

/// RPM above which a sample counts as "high RPM". Mirrors the constant
/// in `driving_insights_analyzer.dart` so the two coaching surfaces
/// agree on what "above threshold" means.
const double _highRpmThreshold = 3000;

/// Acceleration (m/s²) above which an interval counts as a hard
/// acceleration event. Same threshold the analyzer uses.
const double _hardAccelThresholdMps2 = 3.0;

/// Negative acceleration (m/s²) below which an interval counts as a
/// hard brake event. Stored as a positive number; comparison uses the
/// negated form.
const double _hardBrakeThresholdMps2 = 3.0;

/// Speed (km/h) at or below which the recorder treats the car as
/// "stationary" for idle accounting. Matches the analyzer's tolerance.
const double _idleSpeedToleranceKmh = 0.5;

/// Penalty caps per category. Documented in the leading comment.
const double _idlingPenaltyCap = 25.0;
const double _hardAccelPenaltyCap = 15.0;
const double _hardBrakePenaltyCap = 15.0;
const double _highRpmPenaltyCap = 20.0;
const double _fullThrottlePenaltyCap = 10.0;

/// Per-event score deductions.
const double _hardAccelPenaltyPerEvent = 3.0;
const double _hardBrakePenaltyPerEvent = 3.0;

/// Compute a composite driving score for the given trip samples.
/// Empty / single-sample trips return [DrivingScore.perfect] — there is
/// no Δt to integrate, so we cannot fairly attribute any penalty.
///
/// The function is pure and synchronous — safe to call from a UI
/// thread for trip durations the app realistically records (a 60-min
/// trip at 1 Hz is 3 600 samples; the loop is O(n)).
DrivingScore computeDrivingScore(List<TripSample> samples) {
  if (samples.length < 2) return DrivingScore.perfect;

  // Sort by timestamp so out-of-order persistence (#1040 race
  // conditions) doesn't blow up the integration. Copy first so we
  // don't mutate the caller's list.
  final sorted = [...samples]
    ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

  // Total trip duration — used to compute time-fraction penalties.
  final totalDt = sorted.last.timestamp
          .difference(sorted.first.timestamp)
          .inMicroseconds /
      Duration.microsecondsPerSecond;
  if (totalDt <= 0) return DrivingScore.perfect;

  // Accumulators.
  double idleSeconds = 0;
  double highRpmSeconds = 0;
  // Full-throttle accounting is left at zero by design — see the
  // module-level docstring for why.
  const double fullThrottleSeconds = 0;
  int hardAccelEvents = 0;
  int hardBrakeEvents = 0;

  for (var i = 1; i < sorted.length; i++) {
    final prev = sorted[i - 1];
    final cur = sorted[i];
    final dt =
        cur.timestamp.difference(prev.timestamp).inMicroseconds /
            Duration.microsecondsPerSecond;
    if (dt <= 0) continue;

    // Idle accounting: engine on, car stationary across the whole
    // interval. Mirrors the analyzer's tolerance to absorb OBD2 noise.
    if (prev.speedKmh <= _idleSpeedToleranceKmh && prev.rpm > 0) {
      idleSeconds += dt;
    }

    // High-RPM accounting: attribute the whole interval to the START
    // sample's RPM (the ~1 Hz polling cadence is short relative to gear
    // shifts; matches the analyzer's convention).
    if (prev.rpm > _highRpmThreshold) {
      highRpmSeconds += dt;
    }

    // Hard accel / brake events: derivative of speed across the
    // interval. Convert km/h → m/s by / 3.6. Threshold is inclusive
    // for accel and inclusive (negated) for brake — matches the
    // analyzer.
    final dvMps = (cur.speedKmh - prev.speedKmh) / 3.6;
    final accelMps2 = dvMps / dt;
    if (accelMps2 >= _hardAccelThresholdMps2) {
      hardAccelEvents++;
    } else if (accelMps2 <= -_hardBrakeThresholdMps2) {
      hardBrakeEvents++;
    }
  }

  // Per-category penalties.
  final idlingPenalty =
      _clamp(idleSeconds / totalDt * _idlingPenaltyCap, 0, _idlingPenaltyCap);
  final highRpmPenalty = _clamp(
    highRpmSeconds / totalDt * _highRpmPenaltyCap,
    0,
    _highRpmPenaltyCap,
  );
  final hardAccelPenalty = _clamp(
    hardAccelEvents * _hardAccelPenaltyPerEvent,
    0,
    _hardAccelPenaltyCap,
  );
  final hardBrakePenalty = _clamp(
    hardBrakeEvents * _hardBrakePenaltyPerEvent,
    0,
    _hardBrakePenaltyCap,
  );
  final fullThrottlePenalty = _clamp(
    fullThrottleSeconds / totalDt * _fullThrottlePenaltyCap,
    0,
    _fullThrottlePenaltyCap,
  );

  final raw = 100.0 -
      idlingPenalty -
      highRpmPenalty -
      hardAccelPenalty -
      hardBrakePenalty -
      fullThrottlePenalty;
  // Floor at 0, cap at 100, then round to the nearest integer.
  final clamped = _clamp(raw, 0, 100);
  final scoreInt = clamped.round();

  return DrivingScore(
    score: scoreInt,
    idlingPenalty: idlingPenalty,
    hardAccelPenalty: hardAccelPenalty,
    hardBrakePenalty: hardBrakePenalty,
    highRpmPenalty: highRpmPenalty,
    fullThrottlePenalty: fullThrottlePenalty,
  );
}

double _clamp(double value, double low, double high) {
  if (value < low) return low;
  if (value > high) return high;
  return value;
}
