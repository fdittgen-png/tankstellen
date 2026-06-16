// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

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

import '../domain/accel_event_gate.dart';
import '../domain/climb_restart_detector.dart';
import '../domain/driving_insight.dart';
import '../domain/engine_power_factor.dart';
import '../domain/trip_recorder.dart';

/// RPM above which a sample counts as "high RPM".
const double _highRpmThreshold = 3000;

// Hard-accel detection now routes through the ONE shared accel-event gate
// (#2667): `kHardAccelThresholdMps2` (3.0) sustained ≥ 1 s with the
// accuracy + min-speed gate, so the insight count agrees with the harsh
// detector, the driving score, and the GPS features. The old raw
// per-interval `_hardAccelThresholdMps2` constant is gone.

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

/// Pedal / throttle percent at/above which a sample is "full throttle"
/// (#2461). Canonical with `driving_score_calculator.dart`.
const double _fullThrottlePercent = 90.0;

/// Counterfactual fuel rate for full-throttle segments as a fraction of
/// the measured rate (#2461). 0.7 ≈ "easing onto the throttle would have
/// burned ~70 % of what flooring it did over those windows".
const double _fullThrottleCounterfactualRatio = 0.7;

/// Fallback fuel rate (L/h) assumed at full throttle when no measured
/// fuel-rate samples are available (#2461). High because WOT pulls a lot
/// of fuel; the counterfactual ratio above is then applied.
const double _fullThrottleFallbackLPerHour = 14.0;

/// Counterfactual fuel rate for λ-enrichment segments as a fraction of
/// the measured rate (#2461). An enriched mixture (λ < 1) dumps extra
/// fuel; running stoichiometric would have burned ~85 % of it.
const double _lambdaEnrichmentCounterfactualRatio = 0.85;

/// Fallback fuel rate (L/h) at λ-enrichment when no measured rate is
/// available (#2461) — enrichment shows up under load, so assume a
/// moderately high rate.
const double _lambdaEnrichmentFallbackLPerHour = 10.0;

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
///
/// [enginePowerKw] (Epic #3015) weights the hard-accel wasted-litres by
/// [enginePowerAccelFactor]; `null` leaves it unchanged (factor 1.0).
List<DrivingInsight> analyzeTrip(
  List<TripSample> samples, {
  int? enginePowerKw,
  bool suppressSpeedHarsh = false,
}) {
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

  // Hard-accel EPISODES via the ONE shared gate (#2667) — same count the
  // harsh detector, the score, and the GPS features report.
  // #3368 — suppress harsh-event derivation for a `virtual` dead-reckoning
  // trip (its quantised speed manufactures phantom events), matching the score
  // + the recorder's HarshEventDetector so the lesson agrees.
  final accelCounts = countAccelEvents([
    for (final s in sorted)
      AccelSamplePoint(
        timestamp: s.timestamp,
        speedKmh: s.speedKmh,
        hAccuracyM: s.hAccuracyM,
      ),
  ], suppress: suppressSpeedHarsh);
  final hardAccelEvents = accelCounts.accelEvents;
  final hardAccelTotalDt = accelCounts.accelSeconds;

  // Accumulators.
  double highRpmSeconds = 0;
  double highRpmWastedLiters = 0;
  bool sawFuelRateInHighRpm = false;

  double idleSeconds = 0;
  double idleWastedLiters = 0;

  // #2461 — full-throttle (pedal else throttle ≥ 90 %) and λ-enrichment
  // (commanded mixture richer than stoich) cost lines.
  double fullThrottleSeconds = 0;
  double fullThrottleWastedLiters = 0;
  bool sawFuelRateInFullThrottle = false;

  double lambdaEnrichSeconds = 0;
  double lambdaEnrichWastedLiters = 0;
  bool sawFuelRateInLambda = false;

  for (var i = 1; i < sorted.length; i++) {
    final prev = sorted[i - 1];
    final cur = sorted[i];
    final dt =
        cur.timestamp.difference(prev.timestamp).inMicroseconds /
            Duration.microsecondsPerSecond;
    if (dt <= 0) continue;

    // Full-throttle cost: pedal (PID 0x49-0x4B, driver intent) preferred,
    // else throttle (PID 0x11). Counterfactual = easing on ≈ 70 % of the
    // measured rate; falls back to a synthetic WOT rate when unmeasured.
    final pedal = prev.pedalPercent ?? prev.throttlePercent;
    if (pedal != null && pedal >= _fullThrottlePercent) {
      fullThrottleSeconds += dt;
      final measuredRate = prev.fuelRateLPerHour;
      if (measuredRate != null && measuredRate > 0) {
        sawFuelRateInFullThrottle = true;
        fullThrottleWastedLiters +=
            measuredRate * (1 - _fullThrottleCounterfactualRatio) * dt / 3600.0;
      }
    }

    // λ-enrichment cost: commanded mixture richer than stoichiometric
    // (λ < 1). The extra fuel over a stoich counterfactual is the waste.
    final lambda = prev.lambda;
    if (lambda != null && lambda > 0 && lambda < 1.0) {
      lambdaEnrichSeconds += dt;
      final measuredRate = prev.fuelRateLPerHour;
      if (measuredRate != null && measuredRate > 0) {
        sawFuelRateInLambda = true;
        lambdaEnrichWastedLiters += measuredRate *
            (1 - _lambdaEnrichmentCounterfactualRatio) *
            dt /
            3600.0;
      }
    }

    // High-RPM cost: time fraction above the threshold weighted by
    // measured-vs-counterfactual fuel rate. Mirrors TripRecorder's
    // convention of attributing the whole interval to the start
    // sample's RPM (the ~1 Hz cadence is short relative to gear
    // shifts).
    if ((prev.rpm ?? 0) > _highRpmThreshold) {
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

    // Hard-acceleration is counted ABOVE via the shared gate (#2667), not
    // per-interval here.

    // Idling: engine on (rpm > 0), car stationary (speed == 0) for
    // the whole interval. Use a small tolerance on speed to absorb
    // the OBD2 noise floor.
    // #2692 C4-G — `(prev.rpm ?? 0)`: a GPS-only sample (rpm null, no
    // engine signal) is never counted as an idling engine.
    if (prev.speedKmh <= 0.5 && (prev.rpm ?? 0) > 0) {
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

  // Hard-acceleration cost line. Epic #3015 — scale the per-event waste
  // inversely with engine power (factor 1.0 when power is unknown).
  if (hardAccelEvents > 0) {
    final liters = hardAccelEvents *
        _wastedLitersPerHardAccelEvent *
        enginePowerAccelFactor(enginePowerKw);
    final pctTime = hardAccelTotalDt / totalDt * 100.0;
    // #2963 — strictly `>` (not `>=`): one event's 0.05 L exactly equals the
    // floor, clears `>=`, then renders "0.1 L" (a 2× overstatement).
    if (liters > _noiseFloorLiters) {
      candidates.add(DrivingInsight(
        labelKey: 'insightHardAccel',
        litersWasted: liters,
        percentOfTrip: pctTime,
        metadata: {
          'eventCount': hardAccelEvents,
          'thresholdMps2': kHardAccelThresholdMps2,
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

  // Full-throttle cost line (#2461).
  if (fullThrottleSeconds > 0) {
    final liters = sawFuelRateInFullThrottle
        ? fullThrottleWastedLiters
        : _fullThrottleFallbackLPerHour *
            (1 - _fullThrottleCounterfactualRatio) *
            fullThrottleSeconds /
            3600.0;
    final pctTime = fullThrottleSeconds / totalDt * 100.0;
    if (liters >= _noiseFloorLiters) {
      candidates.add(DrivingInsight(
        labelKey: 'insightFullThrottle',
        litersWasted: liters,
        percentOfTrip: pctTime,
        metadata: {
          'fullThrottleSeconds': fullThrottleSeconds,
          'pctTime': pctTime,
        },
      ));
    }
  }

  // λ-enrichment cost line (#2461).
  if (lambdaEnrichSeconds > 0) {
    final liters = sawFuelRateInLambda
        ? lambdaEnrichWastedLiters
        : _lambdaEnrichmentFallbackLPerHour *
            (1 - _lambdaEnrichmentCounterfactualRatio) *
            lambdaEnrichSeconds /
            3600.0;
    final pctTime = lambdaEnrichSeconds / totalDt * 100.0;
    if (liters >= _noiseFloorLiters) {
      candidates.add(DrivingInsight(
        labelKey: 'insightLambdaEnrichment',
        litersWasted: liters,
        percentOfTrip: pctTime,
        metadata: {
          'lambdaEnrichSeconds': lambdaEnrichSeconds,
          'pctTime': pctTime,
        },
      ));
    }
  }

  // Climbing-fuel cost line (#2693 C6). Recomputes confident road grade
  // inline (same RoadGradeCalculator config the live folder uses) and
  // attributes the extra litres burned over a flat-road counterfactual.
  final climb = detectClimbCost(sorted);
  if (climb.climbingLiters >= _noiseFloorLiters) {
    final pctTime = climb.climbSeconds / totalDt * 100.0;
    candidates.add(DrivingInsight(
      labelKey: 'insightClimbingCost',
      litersWasted: climb.climbingLiters,
      percentOfTrip: pctTime,
      metadata: {
        'gradePercent': climb.peakGradePercent,
        'climbSeconds': climb.climbSeconds,
        'pctTime': pctTime,
      },
    ));
  }

  // Stop-and-go restart cost line (#2694 C8). Counts genuine
  // stop→accelerate restarts (distinguished from a rolling start) and
  // attributes the extra litres of accelerating a stopped car from rest.
  final restart = detectRestartCost(sorted);
  if (restart.restartLiters >= _noiseFloorLiters) {
    candidates.add(DrivingInsight(
      labelKey: 'insightRestartCost',
      litersWasted: restart.restartLiters,
      // percentOfTrip is not meaningful for a count-based category; the
      // metadata carries the restart count for the subtitle.
      percentOfTrip: 0,
      metadata: {
        'restartCount': restart.restartCount,
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
