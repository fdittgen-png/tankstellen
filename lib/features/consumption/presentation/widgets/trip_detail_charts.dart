// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
// `intl` re-exports its own `TextDirection`, which would shadow the
// `dart:ui` one the painter's `TextPainter` needs — so `dart:ui` is imported
// `as ui` and `TextDirection.ltr` is qualified `ui.TextDirection.ltr` (same
// disambiguation the price chart uses, #2384).
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/trip_recorder.dart';

// #2431 — the CustomPainter + its point model live in a part file so this
// widget file stays under the 400-line guard after the estimated-series
// fallback + badge landed. They stay library-private (`_`-prefixed) — the
// part shares this file's library scope.
part 'trip_detail_line_painter.dart';

// #2461 — the throttle/pedal + coolant + altitude + λ charts live in a part
// file so this widget file stays under the 400-line guard. They share this
// library's scope (the private `_TripDetailLineChart` painter wrapper).
part 'trip_detail_signal_charts.dart';

// #2977 — the scrub-to-read crosshair (nearest-point hit-test, the crosshair
// overlay painter, and the value/time readout callout) lives in a part file so
// this widget file stays under the 400-line guard. Mirrors the price-chart
// tap-to-nearest pattern (#2384). Shares this library's `_ChartPoint`.
part 'trip_chart_crosshair.dart';

/// One sample of the trip recording profile (#890).
///
/// Mirrors the fields of `TripSample` in the domain layer but lives in
/// the presentation layer so the detail screen stays decoupled from
/// the recorder — #890 displays samples when the caller provides them
/// and shows the empty-state caption when it doesn't. Future PRs will
/// persist these samples alongside [TripHistoryEntry] so the screen
/// can render charts for any historical trip; until then this class
/// is the test-only injection point and keeps the contract ready.
@immutable
class TripDetailSample {
  /// Timestamp of the sample. Samples are ordered chronologically by
  /// the chart painters — unsorted input is sorted before plotting.
  final DateTime timestamp;

  /// Vehicle speed in km/h. Non-null for every sample — the recorder
  /// only emits a [TripDetailSample] once speed has been read.
  final double speedKmh;

  /// Engine RPM. May be null when the car's PID cache reports RPM as
  /// unsupported; the [TripDetailRpmChart] hides itself when every
  /// sample carries a null RPM.
  final double? rpm;

  /// Fuel rate in L/h. May be null when neither PID 5E nor the MAF /
  /// speed-density fallback chain from #874 yields a reading; the
  /// fuel-rate chart renders its empty caption when every sample is
  /// null.
  final double? fuelRateLPerHour;

  /// GPS-physics **estimated** fuel rate in L/h (#2431). Populated only
  /// for OBD2/hybrid trips whose adapter+ECU supported no fuel PID, so
  /// [fuelRateLPerHour] is null on every sample. When the measured series
  /// is all-null but this one isn't, [TripDetailFuelRateChart] renders
  /// THIS series with a "geschätzt" (estimated) badge instead of the
  /// empty caption. Null for measured trips and at a standstill.
  final double? estimatedFuelRateLPerHour;

  /// Throttle position % (PID 0x11). Null when the car's PID cache
  /// flagged 0x11 as unsupported, or when persisted by a build before
  /// #1261 (legacy trips). Drives the throttle axis of the throttle /
  /// RPM histogram on the trip-detail screen.
  final double? throttlePercent;

  /// Calculated engine load % (PID 0x04). Null when the car's PID
  /// cache flagged 0x04 as unsupported, or when persisted by a build
  /// before #1262 (legacy trips). Surfaced by the load-aware coaching
  /// chart in phase 3 of #1262 — distinguishes "uphill at 60 km/h"
  /// (high load) from "flat at 60 km/h" (low load).
  final double? engineLoadPercent;

  /// Engine coolant temperature in °C (PID 0x05). Null when the car
  /// doesn't surface the PID, or when persisted by a build before
  /// #1262 (legacy trips). Drives the cold-start surcharge chip in
  /// phase 3 of #1262.
  final double? coolantTempC;

  /// GPS latitude in degrees (#1374 phase 2). Null when the
  /// `Feature.gpsTripPath` flag was disabled at recording time, when
  /// no fix had landed yet, when location permission was revoked, or
  /// when the trip was persisted by a build before #1374 phase 1.
  /// Mirrors `TripSample.latitude` in the domain layer; the
  /// trip-detail GPS-path overlay reads non-null pairs to draw the
  /// recorded route.
  final double? latitude;

  /// GPS longitude in degrees (#1374 phase 2). Same null-semantics as
  /// [latitude]; the two fields are always written and read together.
  final double? longitude;

  /// Accelerator-pedal position % (PIDs 0x49-0x4B, #2461). Driver
  /// intent. Null when the car exposes no pedal PID or for trips
  /// persisted before #2459. Drives the Throttle/Pedal chart together
  /// with [throttlePercent] (pedal preferred when present).
  final double? pedalPercent;

  /// Commanded equivalence ratio / λ (PID 0x44, #2461). Null when the
  /// car doesn't expose PID 0x44 or for legacy trips. Drives the
  /// optional λ chart and the λ-enrichment eco-insight.
  final double? lambda;

  /// GPS altitude in metres (#2461 / #1935). Null when GPS path was
  /// off, before the first fix, or for legacy trips. Drives the
  /// optional altitude chart.
  final double? altitudeM;

  /// Short-term fuel trim bank 1 in percent (PID 0x06, #2931). Null on
  /// cars that don't expose the PID, for legacy trips, and on trips
  /// recorded without diagnostic capture (the trim is read for the
  /// fuel-rate correction but only persisted onto samples under the
  /// diagnostic-capture flag). Carried through so the combustion-health
  /// heuristic (`CombustionHealthRule`) can read the sustained mixture
  /// trim when it IS present.
  final double? stft;

  /// Long-term fuel trim bank 1 in percent (PID 0x07, #2931). Same
  /// null-semantics as [stft]; the two are read together by the
  /// combustion-health heuristic (total trim = STFT + LTFT).
  final double? ltft;

  /// Reported horizontal GPS accuracy in metres (#2963). Carried through
  /// from `TripSample.hAccuracyM` so the canonical accel-event gate's
  /// bad-fix guard (`countAccelEvents`, kAccelEventAccuracyGateM) can fire
  /// on the saved-trip score path. Both converters used to drop it, so the
  /// gate — which treats a null accuracy as "accept" — never rejected a
  /// jittery GPS-derived accel sample once a trip was persisted and
  /// reopened. Null on legacy trips, on non-GPS trips, and before the first
  /// fix (same semantics as [latitude]).
  final double? hAccuracyM;

  /// The originating domain [TripSample] when this instance was produced
  /// by `toDetailSample` (#3594). The reverse converter returns it
  /// VERBATIM, making the persisted-trip round-trip lossless by
  /// construction — no more field-by-field carrying (this pair dropped
  /// fields five separate times: #2460, #2790, #2931, #2963, #3594).
  /// Null only for hand-built instances (tests); those fall back to the
  /// explicit field copy in `tripDetailToTripSample`.
  final TripSample? domain;

  const TripDetailSample({
    required this.timestamp,
    required this.speedKmh,
    this.rpm,
    this.fuelRateLPerHour,
    this.estimatedFuelRateLPerHour,
    this.throttlePercent,
    this.engineLoadPercent,
    this.coolantTempC,
    this.latitude,
    this.longitude,
    this.pedalPercent,
    this.lambda,
    this.altitudeM,
    this.stft,
    this.ltft,
    this.hAccuracyM,
    this.domain,
  });
}

/// Speed-over-time line chart on the Trip detail screen (#890).
///
/// Always renders when the screen has at least one sample — speed is
/// the one reading the recorder always captures, so the chart is
/// never hidden (unlike [TripDetailRpmChart]). An empty samples list
/// falls back to the shared empty-state caption for consistency.
class TripDetailSpeedChart extends StatelessWidget {
  final List<TripDetailSample> samples;
  final Color? color;

  const TripDetailSpeedChart({
    super.key,
    required this.samples,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return _TripDetailLineChart(
      samples: samples,
      color: color,
      valueOf: (s) => s.speedKmh,
      unit: 'km/h',
      emptyWhenAllNull: false,
    );
  }
}

/// Fuel-rate-over-time line chart on the Trip detail screen (#890).
///
/// Plots the MEASURED `fuelRateLPerHour` series. When every measured
/// sample is null (cars without PID 5E and without MAF) but the
/// GPS-physics fallback stamped an `estimatedFuelRateLPerHour` series
/// (#2431), it falls back to plotting the ESTIMATED series with a
/// "geschätzt" badge instead of the empty caption — so a Peugeot +
/// generic ELM327 trip shows its consumption shape, clearly marked as an
/// estimate rather than presented as a measurement. Only when BOTH
/// series are all-null does it render the empty caption.
class TripDetailFuelRateChart extends StatelessWidget {
  final List<TripDetailSample> samples;
  final Color? color;

  const TripDetailFuelRateChart({
    super.key,
    required this.samples,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final hasMeasured =
        samples.any((s) => s.fuelRateLPerHour != null);
    final hasEstimate =
        !hasMeasured && samples.any((s) => s.estimatedFuelRateLPerHour != null);
    return _TripDetailLineChart(
      samples: samples,
      color: color,
      valueOf: hasEstimate
          ? (s) => s.estimatedFuelRateLPerHour
          : (s) => s.fuelRateLPerHour,
      unit: 'L/h',
      emptyWhenAllNull: true,
      estimated: hasEstimate,
      // #3502 — a 1 Hz fuel-rate series (especially the GPS-physics
      // estimate) is unreadable spikes: plot the rolling median with the
      // raw series faint behind, and cap the axis at p99 so one outlier
      // can't squash the whole readable band.
      smoothWindow: 9,
      capPercentile: 0.99,
    );
  }
}

/// RPM-over-time line chart on the Trip detail screen (#890).
///
/// Hidden by the screen when every sample carries a null RPM (the
/// recorder's PID cache flagged RPM as unsupported). Kept here as a
/// widget rather than the screen's inline logic so tests can drive
/// the empty-state caption directly.
class TripDetailRpmChart extends StatelessWidget {
  final List<TripDetailSample> samples;
  final Color? color;

  const TripDetailRpmChart({
    super.key,
    required this.samples,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return _TripDetailLineChart(
      samples: samples,
      color: color,
      valueOf: (s) => s.rpm,
      unit: 'rpm',
      emptyWhenAllNull: true,
    );
  }
}

/// Engine-load-over-time sparkline on the Trip detail screen
/// (#1262 phase 3).
///
/// Plots `sample.engineLoadPercent` (PID 0x04) on a 0..100 axis. The
/// PARENT screen gates rendering on "any non-null engineLoad sample"
/// — cars without PID 0x04 carry null on every sample, and the screen
/// silently skips the section header rather than rendering an empty
/// card. This widget itself still falls back to the shared empty-state
/// caption when every sample is null, so direct tests of the chart
/// stay symmetrical with the RPM / fuel-rate variants.
class TripDetailEngineLoadChart extends StatelessWidget {
  final List<TripDetailSample> samples;
  final Color? color;

  const TripDetailEngineLoadChart({
    super.key,
    required this.samples,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return _TripDetailLineChart(
      samples: samples,
      color: color,
      valueOf: (s) => s.engineLoadPercent,
      unit: '%',
      emptyWhenAllNull: true,
    );
  }
}

// Shared implementation — the rolling-window line chart `_TripDetailLineChart`
// (stateful: a tap/drag scrub selects the nearest sample and overlays the
// crosshair + readout) lives in the `trip_chart_crosshair.dart` part file
// alongside its scrub geometry, keeping this file under the 400-line guard.

