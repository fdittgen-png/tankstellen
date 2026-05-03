import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

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

  const TripDetailSample({
    required this.timestamp,
    required this.speedKmh,
    this.rpm,
    this.fuelRateLPerHour,
    this.throttlePercent,
    this.engineLoadPercent,
    this.coolantTempC,
    this.latitude,
    this.longitude,
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
/// Renders the empty-state caption when every sample's
/// `fuelRateLPerHour` is null — cars without PID 5E and without MAF
/// will hit that path; the screen still shows the section header so
/// the user understands the chart exists.
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
    return _TripDetailLineChart(
      samples: samples,
      color: color,
      valueOf: (s) => s.fuelRateLPerHour,
      unit: 'L/h',
      emptyWhenAllNull: true,
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

/// Shared implementation — every Trip-detail chart is the same
/// rolling-window line plot over [timestamp], differing only in which
/// sample field they extract. Keeping the painter private avoids
/// exposing a stable but internal widget API to the rest of the app.
class _TripDetailLineChart extends StatelessWidget {
  final List<TripDetailSample> samples;
  final Color? color;
  final double? Function(TripDetailSample) valueOf;
  final String unit;
  final bool emptyWhenAllNull;

  const _TripDetailLineChart({
    required this.samples,
    required this.color,
    required this.valueOf,
    required this.unit,
    required this.emptyWhenAllNull,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final effective = color ?? theme.colorScheme.primary;

    // Keep only samples whose value is non-null; we still need the
    // original timestamps so the chart's X axis reflects real time.
    final points = <_ChartPoint>[];
    for (final s in samples) {
      final v = valueOf(s);
      if (v == null) continue;
      points.add(_ChartPoint(s.timestamp, v));
    }
    final showEmpty =
        samples.isEmpty || (emptyWhenAllNull && points.isEmpty);
    if (showEmpty) {
      return SizedBox(
        height: 140,
        child: Center(
          child: Text(
            l?.trajetDetailChartEmpty ?? 'No samples recorded',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
    points.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return SizedBox(
      height: 160,
      child: CustomPaint(
        painter: _LineChartPainter(
          points: points,
          color: effective,
          labelColor: theme.colorScheme.onSurface,
          unit: unit,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _ChartPoint {
  final DateTime timestamp;
  final double value;

  const _ChartPoint(this.timestamp, this.value);
}

class _LineChartPainter extends CustomPainter {
  final List<_ChartPoint> points;
  final Color color;
  final Color labelColor;
  final String unit;

  _LineChartPainter({
    required this.points,
    required this.color,
    required this.labelColor,
    required this.unit,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    const leftInset = 8.0;
    const rightInset = 8.0;
    const topInset = 18.0;
    const bottomInset = 22.0;

    final chartWidth = size.width - leftInset - rightInset;
    final chartHeight = size.height - topInset - bottomInset;

    final values = points.map((p) => p.value).toList(growable: false);
    final minV = values.reduce(math.min);
    final maxV = values.reduce(math.max);
    final range = (maxV - minV).abs();
    final padding = range > 0 ? range * 0.1 : 1.0;
    final yMin = (minV - padding).clamp(-double.infinity, double.infinity);
    final yMax = maxV + padding;
    final ySpan = (yMax - yMin) == 0 ? 1.0 : (yMax - yMin);

    final firstTs = points.first.timestamp.millisecondsSinceEpoch;
    final lastTs = points.last.timestamp.millisecondsSinceEpoch;
    final tSpan = (lastTs - firstTs) == 0 ? 1 : (lastTs - firstTs);

    double xFor(DateTime t) {
      final rel = (t.millisecondsSinceEpoch - firstTs) / tSpan;
      return leftInset + rel * chartWidth;
    }

    double yFor(double v) =>
        topInset + chartHeight - ((v - yMin) / ySpan) * chartHeight;

    // Max / min labels at the corners — gives the user a quick read
    // on the range without cluttering the plot with grid lines.
    _drawText(
      canvas,
      '${maxV.toStringAsFixed(1)} $unit',
      Offset(size.width - rightInset, 2),
      anchorRight: true,
      color: labelColor.withAlpha(160),
      fontSize: 10,
    );
    _drawText(
      canvas,
      minV.toStringAsFixed(1),
      Offset(leftInset, size.height - bottomInset + 4),
      color: labelColor.withAlpha(160),
      fontSize: 10,
    );

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path();
    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      final pt = Offset(xFor(p.timestamp), yFor(p.value));
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    canvas.drawPath(path, linePaint);
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset, {
    bool anchorRight = false,
    bool anchorCenter = false,
    required Color color,
    double fontSize = 10,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    var dx = offset.dx;
    if (anchorRight) dx -= tp.width;
    if (anchorCenter) dx -= tp.width / 2;
    tp.paint(canvas, Offset(dx, offset.dy));
  }

  @override
  bool shouldRepaint(_LineChartPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.color != color ||
      oldDelegate.unit != unit;
}
