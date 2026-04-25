/// Pure analyzer that turns a stream of [TripSample]s into "cost
/// lines" for the trip Insights tab (#1041 phase 1).
///
/// Phase 1 covers three behaviour-driven categories — high RPM,
/// hard acceleration, and idling. Each yields a [DrivingInsight] when
/// it accumulates at least [_noiseFloorLiters] of estimated waste.
/// Results are sorted by `litersWasted` descending and capped at
/// [_topN] entries so the UI shows a focused list.
///
/// The counterfactual model is documented in
/// `docs/guides/driving-insights.md`. Numbers here are intentionally
/// rough — the goal is *coaching*, not telematics-grade accounting.
/// Future phases (cards C/D/E in #1041) will refine the model with
/// throttle, coolant temp, and elevation data.
library;

import '../domain/driving_insight.dart';
import '../domain/trip_recorder.dart';

/// RPM above which a sample counts as "high RPM".
const double _highRpmThreshold = 3000;

/// Acceleration (m/s²) above which an interval counts as "hard accel".
const double _hardAccelThresholdMps2 = 3.0;

/// Liters wasted per hard-accel event. Documented constant — see
/// `docs/guides/driving-insights.md`. Order-of-magnitude estimate
/// from "punching the throttle costs ~50 mL extra over a smooth
/// counterfactual" telematics literature.
const double _wastedLitersPerHardAccelEvent = 0.05;

/// Counterfactual fuel rate for high-RPM segments expressed as a
/// fraction of the measured rate. 0.6 ≈ "the same trip at moderate
/// RPM would have burned ~60% of the fuel you actually burned during
/// those high-RPM windows".
const double _highRpmCounterfactualRatio = 0.6;

/// Default fuel rate (L/h) assumed for idling when no measured
/// fuel-rate samples are available. 0.6 L/h is a common figure for
/// petrol passenger cars at warm idle (~700-900 RPM).
const double _idleFuelRateAssumptionLPerHour = 0.6;

/// Categories below this many liters are dropped — they're indistinguishable
/// from sensor noise.
const double _noiseFloorLiters = 0.05;

/// Maximum cost lines returned by [analyzeTrip].
const int _topN = 3;

/// Analyze a trip's samples and return the top-3 cost lines, sorted by
/// estimated litres wasted (descending). Empty input → empty list.
///
/// The function is pure and synchronous — safe to call from a UI
/// thread for trip durations the app realistically records (a 60-min
/// trip at 1 Hz is 3 600 samples; the loop is O(n)).
List<DrivingInsight> analyzeTrip(List<TripSample> samples) {
  if (samples.length < 2) return const [];

  // Sort by timestamp so out-of-order persistence (#1040 race
  // conditions) doesn't blow up the integration. Copy first so we
  // don't mutate the caller's list.
  final sorted = [...samples]
    ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

  // Total trip duration — used to compute percentages.
  final totalDt = sorted.last.timestamp
          .difference(sorted.first.timestamp)
          .inMicroseconds /
      Duration.microsecondsPerSecond;
  if (totalDt <= 0) return const [];

  // Accumulators.
  double highRpmSeconds = 0;
  double highRpmWastedLiters = 0;
  bool sawFuelRateInHighRpm = false;

  int hardAccelEvents = 0;
  double hardAccelTotalDt = 0;

  double idleSeconds = 0;
  double idleWastedLiters = 0;

  for (var i = 1; i < sorted.length; i++) {
    final prev = sorted[i - 1];
    final cur = sorted[i];
    final dt =
        cur.timestamp.difference(prev.timestamp).inMicroseconds /
            Duration.microsecondsPerSecond;
    if (dt <= 0) continue;

    // High-RPM cost: time fraction above the threshold weighted by
    // measured-vs-counterfactual fuel rate. Mirrors TripRecorder's
    // convention of attributing the whole interval to the start
    // sample's RPM (the ~1 Hz cadence is short relative to gear
    // shifts).
    if (prev.rpm > _highRpmThreshold) {
      highRpmSeconds += dt;
      final measuredRate = prev.fuelRateLPerHour;
      if (measuredRate != null && measuredRate > 0) {
        sawFuelRateInHighRpm = true;
        // Counterfactual = same speed at lower RPM ≈
        // _highRpmCounterfactualRatio × measured. Wasted = (measured −
        // counterfactual) × dt.
        final counterfactualRate = measuredRate * _highRpmCounterfactualRatio;
        final wastedLPerHour = measuredRate - counterfactualRate;
        highRpmWastedLiters += wastedLPerHour * dt / 3600.0;
      }
    }

    // Hard-acceleration: derivative of speed across the interval.
    // Convert km/h → m/s by / 3.6.
    final dvMps = (cur.speedKmh - prev.speedKmh) / 3.6;
    final accelMps2 = dvMps / dt;
    if (accelMps2 >= _hardAccelThresholdMps2) {
      hardAccelEvents++;
      hardAccelTotalDt += dt;
    }

    // Idling: engine on (rpm > 0), car stationary (speed == 0) for
    // the whole interval. Use a small tolerance on speed to absorb
    // the OBD2 noise floor.
    if (prev.speedKmh <= 0.5 && prev.rpm > 0) {
      idleSeconds += dt;
      final measuredRate = prev.fuelRateLPerHour;
      // Idle wastes 100% of the fuel — there's no counterfactual,
      // every drop is avoidable (turn the engine off).
      final rate = (measuredRate != null && measuredRate > 0)
          ? measuredRate
          : _idleFuelRateAssumptionLPerHour;
      idleWastedLiters += rate * dt / 3600.0;
    }
  }

  final candidates = <DrivingInsight>[];

  // High-RPM cost line.
  if (highRpmSeconds > 0) {
    // If no fuel-rate samples were available we can't quantify the
    // waste — fall back to "60% of the measured rate" using a
    // synthetic 6 L/h baseline so the cost line still surfaces.
    // Documented in docs/guides/driving-insights.md.
    final liters = sawFuelRateInHighRpm
        ? highRpmWastedLiters
        : _fallbackHighRpmWaste(highRpmSeconds);
    final pctTime = highRpmSeconds / totalDt * 100.0;
    if (liters >= _noiseFloorLiters) {
      candidates.add(DrivingInsight(
        labelKey: 'insightHighRpm',
        litersWasted: liters,
        percentOfTrip: pctTime,
        metadata: {
          'aboveRpm': _highRpmThreshold,
          'highRpmSeconds': highRpmSeconds,
          'pctTime': pctTime,
        },
      ));
    }
  }

  // Hard-acceleration cost line.
  if (hardAccelEvents > 0) {
    final liters = hardAccelEvents * _wastedLitersPerHardAccelEvent;
    final pctTime = hardAccelTotalDt / totalDt * 100.0;
    if (liters >= _noiseFloorLiters) {
      candidates.add(DrivingInsight(
        labelKey: 'insightHardAccel',
        litersWasted: liters,
        percentOfTrip: pctTime,
        metadata: {
          'eventCount': hardAccelEvents,
          'thresholdMps2': _hardAccelThresholdMps2,
          'pctTime': pctTime,
        },
      ));
    }
  }

  // Idling cost line.
  if (idleSeconds > 0 && idleWastedLiters >= _noiseFloorLiters) {
    final pctTime = idleSeconds / totalDt * 100.0;
    candidates.add(DrivingInsight(
      labelKey: 'insightIdling',
      litersWasted: idleWastedLiters,
      percentOfTrip: pctTime,
      metadata: {
        'idleSeconds': idleSeconds,
        'pctTime': pctTime,
      },
    ));
  }

  // Sort by wasted litres descending and cap at [_topN].
  candidates.sort((a, b) => b.litersWasted.compareTo(a.litersWasted));
  if (candidates.length <= _topN) return candidates;
  return candidates.sublist(0, _topN);
}

/// Fallback when no fuel-rate samples are available during the
/// high-RPM window. Assumes a 6 L/h synthetic baseline at high RPM
/// and applies the same counterfactual ratio. Documented in
/// `docs/guides/driving-insights.md`.
double _fallbackHighRpmWaste(double highRpmSeconds) {
  const syntheticRateLPerHour = 6.0;
  const wastedLPerHour =
      syntheticRateLPerHour * (1 - _highRpmCounterfactualRatio);
  return wastedLPerHour * highRpmSeconds / 3600.0;
}
