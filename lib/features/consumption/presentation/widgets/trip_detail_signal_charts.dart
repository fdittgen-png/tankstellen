// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// The driving-signal trip-detail charts (#2461): throttle/pedal,
/// coolant, altitude, and commanded-λ.
///
/// Split out of `trip_detail_charts.dart` (a `part of` library) to keep
/// that widget file under the 400-line guard. Each chart is a thin
/// wrapper over the shared private `_TripDetailLineChart`, gated by the
/// parent screen on "any non-null sample" and self-falling-back to the
/// shared empty-state caption otherwise (symmetric with the RPM /
/// engine-load variants).
part of 'trip_detail_charts.dart';

/// Throttle / pedal-position-over-time line chart (#2461).
///
/// Plots accelerator-pedal % (PIDs 0x49-0x4B — driver intent) when the
/// car exposes a pedal PID, falling back per-sample to throttle % (PID
/// 0x11). The PARENT screen gates rendering on "any non-null pedal OR
/// throttle sample"; this widget itself still falls back to the shared
/// empty-state caption when every sample is null, symmetric with the
/// RPM / engine-load variants.
class TripDetailThrottleChart extends StatelessWidget {
  final List<TripDetailSample> samples;
  final Color? color;

  const TripDetailThrottleChart({
    super.key,
    required this.samples,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return _TripDetailLineChart(
      samples: samples,
      color: color,
      // Pedal is the truer "how hard is the driver pushing" signal; fall
      // back to throttle % per-sample so cars with only PID 0x11 still
      // render (#2461). Mirrors the score's `pedal ?? throttle` rule.
      valueOf: (s) => s.pedalPercent ?? s.throttlePercent,
      unit: '%',
      emptyWhenAllNull: true,
    );
  }
}

/// Coolant-temperature-over-time line chart (#2461). Plots
/// `sample.coolantTempC` (PID 0x05) in °C. Parent gates on any non-null
/// sample; self-falls-back to the empty caption otherwise.
class TripDetailCoolantChart extends StatelessWidget {
  final List<TripDetailSample> samples;
  final Color? color;

  const TripDetailCoolantChart({
    super.key,
    required this.samples,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return _TripDetailLineChart(
      samples: samples,
      color: color,
      valueOf: (s) => s.coolantTempC,
      unit: '°C',
      emptyWhenAllNull: true,
    );
  }
}

/// Altitude-over-time line chart (#2461, reworked #3502). Plots the GPS
/// altitude RELATIVE to the trip start, lightly median-smoothed.
///
/// Raw GPS altitude is the WGS84 *ellipsoid* height on Android (no geoid
/// correction), so absolute values routinely read below sea level near a
/// coast — the field screenshot that motivated #3502 showed "−3.7 m".
/// The relative profile keeps exactly the information a driver reads from
/// this chart (climbs and descents, which also feed climbEnergyPerKm)
/// while sidestepping the meaningless absolute datum and the
/// Android-vs-iOS (ellipsoid-vs-MSL) inconsistency.
class TripDetailAltitudeChart extends StatelessWidget {
  final List<TripDetailSample> samples;
  final Color? color;

  const TripDetailAltitudeChart({
    super.key,
    required this.samples,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    // Baseline = median of the first few non-null fixes, so one noisy
    // first fix can't offset the whole profile.
    final first = <double>[];
    for (final s in samples) {
      final a = s.altitudeM;
      if (a == null) continue;
      first.add(a);
      if (first.length == 5) break;
    }
    double? base;
    if (first.isNotEmpty) {
      final sorted = [...first]..sort();
      base = sorted[sorted.length ~/ 2];
    }
    final baseline = base;
    return _TripDetailLineChart(
      samples: samples,
      color: color,
      valueOf: baseline == null
          ? (s) => null
          : (s) {
              final a = s.altitudeM;
              return a == null ? null : a - baseline;
            },
      unit: 'm',
      emptyWhenAllNull: true,
      smoothWindow: 5, // #3502 — kill per-fix altitude jitter
    );
  }
}

/// Commanded-λ-over-time line chart (#2461). Plots `sample.lambda` (PID
/// 0x44, dimensionless — < 1 is enrichment). Parent gates on any
/// non-null sample; self-falls-back to the empty caption otherwise.
class TripDetailLambdaChart extends StatelessWidget {
  final List<TripDetailSample> samples;
  final Color? color;

  const TripDetailLambdaChart({
    super.key,
    required this.samples,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return _TripDetailLineChart(
      samples: samples,
      color: color,
      valueOf: (s) => s.lambda,
      unit: 'λ',
      emptyWhenAllNull: true,
    );
  }
}
