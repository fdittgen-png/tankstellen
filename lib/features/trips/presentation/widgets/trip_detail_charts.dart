// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT


import 'package:flutter/material.dart';


// #4037 (epic #4032) — what used to be four `part` files of this library
// are now libraries of their own: the pure projection maths
// (`trip_chart_geometry.dart`), the painter (`trip_detail_line_painter`),
// the scrub-to-read chart itself (`trip_chart_crosshair`) and the driving-
// signal charts (`trip_detail_signal_charts`). Each has its own imports and
// its own private scope instead of sharing this one. The sample model and
// the signal charts are re-exported so every existing caller keeps its
// single `trip_detail_charts.dart` import.
export 'trip_detail_sample.dart';
export 'trip_detail_signal_charts.dart';

import 'trip_chart_crosshair.dart';
import 'trip_detail_sample.dart';

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
    return TripDetailLineChart(
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
    return TripDetailLineChart(
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
    return TripDetailLineChart(
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
    return TripDetailLineChart(
      samples: samples,
      color: color,
      valueOf: (s) => s.engineLoadPercent,
      unit: '%',
      emptyWhenAllNull: true,
    );
  }
}

// Shared implementation — the rolling-window line chart `TripDetailLineChart`
// (stateful: a tap/drag scrub selects the nearest sample and overlays the
// crosshair + readout) lives in the `trip_chart_crosshair.dart` part file
// alongside its scrub geometry, keeping this file under the 400-line guard.

