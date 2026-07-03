// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Per-event fuel-cost attribution over a trip's samples
/// (#3432, epic #3416 task 7).
///
/// Pure transform in the `obd2_trip_features` style: no I/O, sorts
/// defensively, O(n). Turns the signals the recorder already polls into
/// TYPED waste/saving events + a per-class litre breakdown — the "where
/// your fuel went" data the trip analysis and the eco lessons render.
///
/// ## Counterfactual model (coaching-grade, not telematics-grade —
/// same philosophy/constants as `driving_insights_analyzer.dart`)
/// * **Idle** — engine on, stationary ≥ [kIdleEventMinSeconds]; 100 %
///   of the burn is attributable (counterfactual: engine off);
///   unmeasured rate falls back to [kIdleFuelRateAssumptionLPerHour].
/// * **Harsh accel** — pedal (throttle fallback) spikes from below
///   [kAccelPedalBaselinePercent] to ≥ [kAccelPedalSpikePercent];
///   excess = `Σ max(0, rate − baseline) × dt` vs the mean measured
///   rate over [kAccelBaselineWindow] before the spike; without a
///   measured rate the analyzer's 0.05 L/event constant is used.
/// * **High-RPM cruise** — RPM ≥ [kHighRpmCruiseRpm] at STEADY speed
///   ≥ [kCruiseMinSpeedKmh], sustained, throttle below the intentional-
///   acceleration cap. Saving heuristic: an upshift at constant speed
///   drops the rate ~[kUpshiftRateSavingRatio] (pumping/friction scale
///   with RPM at fixed power). Narrower than the "time over 3000 RPM"
///   insight — only steady cruising, where an upshift is available.
/// * **Coasting / fuel cut** — measured rate ≤ [kFuelCutRateLPerHour]
///   while moving ≥ [kCoastingMinSpeedKmh], sustained. POSITIVE class:
///   litres "saved" = the injected-idle counterfactual
///   ([kIdleFuelRateAssumptionLPerHour] × duration). Requires a
///   measured rate — a fuel cut is unrecognisable without the signal.
library;

import 'dart:math' as math;

import 'trip_sample.dart';

/// Event classes the attribution detects. [coasting] is the one
/// positive class (litres SAVED, not wasted).
enum FuelEventType { idle, harshAccel, highRpmCruise, coasting }

/// Stationary duration before an idle phase becomes an idle EVENT.
const double kIdleEventMinSeconds = 30.0;

/// Warm petrol idle burn assumption (L/h) when no rate is measured —
/// canonical with `driving_insights_analyzer.dart`.
const double kIdleFuelRateAssumptionLPerHour = 0.6;

/// Pedal/throttle level at/above which a sample is a spike.
const double kAccelPedalSpikePercent = 85.0;

/// Pedal/throttle level the driver must have been BELOW before the
/// spike (distinguishes a stab from sustained full throttle).
const double kAccelPedalBaselinePercent = 60.0;

/// Pre-event window the baseline fuel rate is averaged over.
const Duration kAccelBaselineWindow = Duration(seconds: 5);

/// Cap on a single harsh-accel event's attribution window.
const double kAccelEventMaxSeconds = 8.0;

/// Fallback waste per harsh-accel event when no rate is measured —
/// canonical with the analyzer's `_wastedLitersPerHardAccelEvent`.
const double kAccelFallbackLitersPerEvent = 0.05;

/// RPM at/above which steady cruising suggests an available upshift.
const double kHighRpmCruiseRpm = 2800.0;

/// Minimum sustained duration of a high-RPM cruise event.
const double kHighRpmCruiseMinSeconds = 5.0;

/// Minimum speed for "cruise" (below this, high RPM is pull-away).
const double kCruiseMinSpeedKmh = 30.0;

/// |dv/dt| bound (km/h per second) for "steady speed".
const double kCruiseSteadyAccelKmhPerS = 2.0;

/// Throttle above this means the high RPM is intentional (overtake) —
/// mirrors `DrivingCoachingThresholds.shiftUpMaxThrottlePercent`.
const double kCruiseMaxThrottlePercent = 50.0;

/// Estimated share of the cruise fuel rate an earlier upshift saves.
const double kUpshiftRateSavingRatio = 0.25;

/// Fallback cruise fuel rate (L/h) when unmeasured — the analyzer's
/// synthetic high-RPM baseline.
const double kCruiseFallbackRateLPerHour = 6.0;

/// Coasting event bounds: injector-cut rate ceiling, minimum speed
/// (a rolling stop isn't coaching) and minimum sustained duration.
const double kFuelCutRateLPerHour = 0.5;
const double kCoastingMinSpeedKmh = 20.0;
const double kCoastingMinSeconds = 3.0;

/// One detected event: type, bounds, and its attributed litres (wasted
/// for the negative classes, SAVED for [FuelEventType.coasting]).
class FuelEvent {
  final FuelEventType type;
  final DateTime start;
  final DateTime end;
  final double liters;

  const FuelEvent({
    required this.type,
    required this.start,
    required this.end,
    required this.liters,
  });

  double get seconds =>
      end.difference(start).inMicroseconds / Duration.microsecondsPerSecond;

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
        'seconds': _round(seconds, 1),
        'liters': _round(liters, 3),
      };
}

/// The per-trip attribution result: typed [events] + per-class totals —
/// the "where your fuel went" breakdown.
class FuelAttribution {
  final List<FuelEvent> events;

  /// Trip duration in seconds (first→last sample), for percent-of-trip.
  final double totalSeconds;

  const FuelAttribution({required this.events, required this.totalSeconds});

  static const FuelAttribution empty =
      FuelAttribution(events: [], totalSeconds: 0);

  Iterable<FuelEvent> eventsOf(FuelEventType type) =>
      events.where((e) => e.type == type);

  double litersOf(FuelEventType type) =>
      eventsOf(type).fold(0.0, (sum, e) => sum + e.liters);

  double secondsOf(FuelEventType type) =>
      eventsOf(type).fold(0.0, (sum, e) => sum + e.seconds);

  double get idleLiters => litersOf(FuelEventType.idle);
  double get harshAccelLiters => litersOf(FuelEventType.harshAccel);
  double get highRpmCruiseLiters => litersOf(FuelEventType.highRpmCruise);

  /// Litres SAVED by fuel-cut coasting (positive class).
  double get coastingSavedLiters => litersOf(FuelEventType.coasting);

  /// Percent (0–100) of trip time spent in [type] events.
  double percentOfTrip(FuelEventType type) =>
      totalSeconds <= 0 ? 0.0 : secondsOf(type) / totalSeconds * 100.0;

  Map<String, dynamic> toJson() => {
        'totalSeconds': _round(totalSeconds, 1),
        'idleLiters': _round(idleLiters, 3),
        'harshAccelLiters': _round(harshAccelLiters, 3),
        'highRpmCruiseLiters': _round(highRpmCruiseLiters, 3),
        'coastingSavedLiters': _round(coastingSavedLiters, 3),
        'events': [for (final e in events) e.toJson()],
      };

  /// Detect all event classes over [samples]. Returns [empty] for
  /// trips too short to attribute anything (< 2 samples).
  static FuelAttribution fromSamples(List<TripSample> samples) {
    if (samples.length < 2) return empty;
    final sorted = [...samples]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final totalSeconds = sorted.last.timestamp
            .difference(sorted.first.timestamp)
            .inMicroseconds /
        Duration.microsecondsPerSecond;
    if (totalSeconds <= 0) return empty;

    final events = <FuelEvent>[
      ..._detectIdle(sorted),
      ..._detectHarshAccel(sorted),
      ..._detectHighRpmCruise(sorted),
      ..._detectCoasting(sorted),
    ]..sort((a, b) => a.start.compareTo(b.start));
    return FuelAttribution(events: events, totalSeconds: totalSeconds);
  }
}

/// Interval-runs helper: attributes each interval to its START sample
/// (the analyzer/histogram convention), opens a run while [inState]
/// holds, and emits via [build] once a run closes ≥ [minSeconds].
List<FuelEvent> _runs(
  List<TripSample> sorted, {
  required bool Function(TripSample prev, TripSample cur) inState,
  required double minSeconds,
  required FuelEvent? Function(int startIdx, int endIdx, double seconds) build,
}) {
  final events = <FuelEvent>[];
  int? runStart;
  double runSeconds = 0;

  void close(int endIdx) {
    final start = runStart;
    runStart = null;
    if (start == null || runSeconds < minSeconds) return;
    final e = build(start, endIdx, runSeconds);
    if (e != null) events.add(e);
  }

  for (var i = 1; i < sorted.length; i++) {
    final prev = sorted[i - 1];
    final cur = sorted[i];
    final dt = cur.timestamp.difference(prev.timestamp).inMicroseconds /
        Duration.microsecondsPerSecond;
    if (dt <= 0) continue;
    if (inState(prev, cur)) {
      if (runStart == null) {
        runStart = i - 1;
        runSeconds = 0;
      }
      runSeconds += dt;
    } else {
      close(i - 1);
    }
  }
  close(sorted.length - 1);
  return events;
}

/// Integrated litres over [startIdx, endIdx) at the measured rate,
/// falling back to [fallbackRateLPerHour] on unmeasured intervals.
double _integrateLiters(
  List<TripSample> sorted,
  int startIdx,
  int endIdx,
  double fallbackRateLPerHour, {
  double Function(double rate)? rateTransform,
}) {
  var liters = 0.0;
  for (var i = startIdx; i < endIdx; i++) {
    final dt = sorted[i + 1]
            .timestamp
            .difference(sorted[i].timestamp)
            .inMicroseconds /
        Duration.microsecondsPerSecond;
    if (dt <= 0) continue;
    final measured = sorted[i].fuelRateLPerHour;
    var rate =
        (measured != null && measured > 0) ? measured : fallbackRateLPerHour;
    if (rateTransform != null) rate = rateTransform(rate);
    liters += rate * dt / 3600.0;
  }
  return liters;
}

List<FuelEvent> _detectIdle(List<TripSample> sorted) => _runs(
      sorted,
      // #2692 C4-G — null RPM is "no engine signal", never a running
      // engine: a GPS-only standstill is not an idle event.
      inState: (prev, _) => prev.speedKmh <= 0.5 && (prev.rpm ?? 0) > 0,
      minSeconds: kIdleEventMinSeconds,
      build: (startIdx, endIdx, seconds) => FuelEvent(
        type: FuelEventType.idle,
        start: sorted[startIdx].timestamp,
        end: sorted[endIdx].timestamp,
        liters: _integrateLiters(
            sorted, startIdx, endIdx, kIdleFuelRateAssumptionLPerHour),
      ),
    );

List<FuelEvent> _detectHarshAccel(List<TripSample> sorted) {
  final events = <FuelEvent>[];
  var i = 1;
  while (i < sorted.length) {
    final prevPedal =
        sorted[i - 1].pedalPercent ?? sorted[i - 1].throttlePercent;
    final curPedal = sorted[i].pedalPercent ?? sorted[i].throttlePercent;
    final isSpike = prevPedal != null &&
        curPedal != null &&
        prevPedal < kAccelPedalBaselinePercent &&
        curPedal >= kAccelPedalSpikePercent;
    if (!isSpike) {
      i++;
      continue;
    }

    // Pre-event baseline: mean measured rate over the window before
    // the spike; null when nothing in the window carried a rate.
    final windowStart = sorted[i].timestamp.subtract(kAccelBaselineWindow);
    var baselineSum = 0.0;
    var baselineCount = 0;
    for (var j = i - 1; j >= 0; j--) {
      if (sorted[j].timestamp.isBefore(windowStart)) break;
      final r = sorted[j].fuelRateLPerHour;
      if (r != null && r > 0) {
        baselineSum += r;
        baselineCount++;
      }
    }
    final baseline = baselineCount > 0 ? baselineSum / baselineCount : null;

    // Event window: while the pedal stays at/above the spike level,
    // capped at kAccelEventMaxSeconds.
    var end = i;
    while (end + 1 < sorted.length) {
      final p =
          sorted[end + 1].pedalPercent ?? sorted[end + 1].throttlePercent;
      if (p == null || p < kAccelPedalSpikePercent) break;
      final span = sorted[end + 1]
              .timestamp
              .difference(sorted[i].timestamp)
              .inMicroseconds /
          Duration.microsecondsPerSecond;
      if (span > kAccelEventMaxSeconds) break;
      end++;
    }

    final double liters;
    if (baseline != null) {
      var excess = 0.0;
      for (var j = i; j < end; j++) {
        final dt = sorted[j + 1]
                .timestamp
                .difference(sorted[j].timestamp)
                .inMicroseconds /
            Duration.microsecondsPerSecond;
        if (dt <= 0) continue;
        final r = sorted[j].fuelRateLPerHour;
        if (r == null || r <= baseline) continue;
        excess += (r - baseline) * dt / 3600.0;
      }
      liters = excess;
    } else {
      liters = kAccelFallbackLitersPerEvent;
    }

    events.add(FuelEvent(
      type: FuelEventType.harshAccel,
      start: sorted[i].timestamp,
      end: sorted[end].timestamp,
      liters: liters,
    ));
    i = end + 1;
  }
  return events;
}

List<FuelEvent> _detectHighRpmCruise(List<TripSample> sorted) => _runs(
      sorted,
      inState: (prev, cur) {
        if ((prev.rpm ?? 0) < kHighRpmCruiseRpm) return false;
        if (prev.speedKmh < kCruiseMinSpeedKmh) return false;
        final throttle = prev.pedalPercent ?? prev.throttlePercent;
        if (throttle != null && throttle >= kCruiseMaxThrottlePercent) {
          return false; // intentional acceleration, no upshift coaching
        }
        final dt = cur.timestamp.difference(prev.timestamp).inMicroseconds /
            Duration.microsecondsPerSecond;
        if (dt <= 0) return false;
        final accel = (cur.speedKmh - prev.speedKmh).abs() / dt;
        return accel <= kCruiseSteadyAccelKmhPerS;
      },
      minSeconds: kHighRpmCruiseMinSeconds,
      build: (startIdx, endIdx, seconds) => FuelEvent(
        type: FuelEventType.highRpmCruise,
        start: sorted[startIdx].timestamp,
        end: sorted[endIdx].timestamp,
        // Rate-delta heuristic: the upshift saving is a fixed share of
        // the cruise burn (see the library doc).
        liters: _integrateLiters(
          sorted,
          startIdx,
          endIdx,
          kCruiseFallbackRateLPerHour,
          rateTransform: (rate) => rate * kUpshiftRateSavingRatio,
        ),
      ),
    );

List<FuelEvent> _detectCoasting(List<TripSample> sorted) => _runs(
      sorted,
      inState: (prev, _) {
        // A fuel CUT requires a measured rate — an absent signal must
        // never be praised as coasting.
        final rate = prev.fuelRateLPerHour;
        return rate != null &&
            rate <= kFuelCutRateLPerHour &&
            prev.speedKmh >= kCoastingMinSpeedKmh;
      },
      minSeconds: kCoastingMinSeconds,
      build: (startIdx, endIdx, seconds) => FuelEvent(
        type: FuelEventType.coasting,
        start: sorted[startIdx].timestamp,
        end: sorted[endIdx].timestamp,
        // Saved vs the injected-idle counterfactual.
        liters: kIdleFuelRateAssumptionLPerHour * seconds / 3600.0,
      ),
    );

double _round(double v, int places) {
  final f = math.pow(10, places).toDouble();
  return (v * f).round() / f;
}
