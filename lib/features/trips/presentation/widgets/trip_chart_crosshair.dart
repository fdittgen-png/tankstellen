// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

// Part of `trip_detail_charts.dart` (#2977) — the scrub-to-read crosshair:
// the shared time/value projection geometry, the nearest-point hit-test, and
// the value/time readout callout. Split into a part file so the widget host
// file stays under the 400-line guard (#1680). Mirrors the price-chart
// tap-to-nearest pattern (#2384) so the two charts feel identical.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/unit_formatter.dart';
import '../../../../l10n/app_localizations.dart';
import 'trip_chart_geometry.dart';
import 'trip_detail_line_painter.dart';
import 'trip_detail_sample.dart';

/// Shared implementation — every Trip-detail chart is the same
/// rolling-window line plot over [timestamp], differing only in which
/// sample field they extract. Keeping the widget private avoids exposing a
/// stable but internal widget API to the rest of the app.
///
/// #2977 — stateful so a tap/drag (scrub) selects the nearest sample and
/// overlays a vertical crosshair + a value/time readout, mirroring the
/// price-chart tap-to-nearest pattern (#2384). The crosshair geometry +
/// readout callout live below in this same part file.
class TripDetailLineChart extends StatefulWidget {
  final List<TripDetailSample> samples;
  final Color? color;
  final double? Function(TripDetailSample) valueOf;
  final String unit;
  final bool emptyWhenAllNull;

  /// #2431 — when true the plotted series is a GPS-physics ESTIMATE, not
  /// a measurement: a "~ geschätzt" badge is overlaid so the user is
  /// never misled into reading it as measured data.
  final bool estimated;

  /// #3502 — centered rolling-median window applied to the plotted series
  /// (≤1 = off). When on, the RAW series is kept as a faint background
  /// polyline so nothing is hidden — the smoothed line is what the eye
  /// reads, the raw one is what the scrub still exposes point-by-point.
  final int smoothWindow;

  /// #3502 — cap the y-axis at this percentile (0..1) of the RAW values
  /// (null = classic full-range axis). A 1 Hz estimate series whose single
  /// spike is 3× the p99 otherwise squashes the whole readable band into
  /// the bottom of the plot; capped values draw clamped at the top edge.
  final double? capPercentile;

  const TripDetailLineChart({
    super.key,
    required this.samples,
    required this.color,
    required this.valueOf,
    required this.unit,
    required this.emptyWhenAllNull,
    this.estimated = false,
    this.smoothWindow = 1,
    this.capPercentile,
  });

  @override
  State<TripDetailLineChart> createState() => TripDetailLineChartState();
}

class TripDetailLineChartState extends State<TripDetailLineChart> {
  /// Index into the plotted (non-null, time-sorted) points of the sample the
  /// scrub crosshair is reading, or null when the user has not scrubbed yet.
  int? _selected;

  @override
  void didUpdateWidget(TripDetailLineChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A new series invalidates the selected ordinal.
    if (!identical(oldWidget.samples, widget.samples) ||
        oldWidget.valueOf != widget.valueOf) {
      _selected = null;
    }
  }

  void _scrub(Offset localPos, Size size, List<ChartPoint> points) {
    if (points.length < 2) return;
    final nearest = TripChartGeometry.nearestPointIndex(
      localPos,
      size,
      points,
    );
    if (nearest != _selected) {
      setState(() => _selected = nearest);
    }
  }

  /// #3502 — centered rolling median over [window] values (odd windows
  /// centre exactly; even ones lean left by half a slot). Timestamps are
  /// preserved so the x-axis stays truthful; the median (not a mean) keeps
  /// step edges crisp while killing single-sample spikes.
  static List<ChartPoint> _rollingMedian(List<ChartPoint> pts, int window) {
    final half = window ~/ 2;
    final out = <ChartPoint>[];
    for (var i = 0; i < pts.length; i++) {
      final from = math.max(0, i - half);
      final to = math.min(pts.length, i + half + 1);
      final vals = [for (var j = from; j < to; j++) pts[j].value]..sort();
      final mid = vals.length ~/ 2;
      final median = vals.length.isOdd
          ? vals[mid]
          : (vals[mid - 1] + vals[mid]) / 2;
      out.add(ChartPoint(pts[i].timestamp, median));
    }
    return out;
  }

  // #4072 — memoised derivations keyed on the samples list identity and
  // the two knobs; a scrub only moves `_selected`.
  Object? _memoSamples;
  List<ChartPoint>? _memoPoints;
  int? _memoWindow;
  double? _memoCap;
  ({List<ChartPoint> plotted, List<ChartPoint>? rawBehind, double? yCap})?
      _memoSeries;

  List<ChartPoint> _derivedPoints() {
    final cached = _memoPoints;
    if (identical(widget.samples, _memoSamples) && cached != null) {
      return cached;
    }
    final points = <ChartPoint>[];
    for (final s in widget.samples) {
      final v = widget.valueOf(s);
      if (v == null) continue;
      points.add(ChartPoint(s.timestamp, v));
    }
    points.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    _memoSamples = widget.samples;
    _memoPoints = points;
    _memoSeries = null;
    return points;
  }

  ({List<ChartPoint> plotted, List<ChartPoint>? rawBehind, double? yCap})
      _derivedSeries(List<ChartPoint> points) {
    final cached = _memoSeries;
    if (cached != null &&
        _memoWindow == widget.smoothWindow &&
        _memoCap == widget.capPercentile) {
      return cached;
    }
    var plotted = points;
    List<ChartPoint>? rawBehind;
    if (widget.smoothWindow > 1 && points.length > widget.smoothWindow) {
      rawBehind = points;
      plotted = _rollingMedian(points, widget.smoothWindow);
    }
    double? yCap;
    final capAt = widget.capPercentile;
    if (capAt != null && points.length > 10) {
      final sortedVals = points.map((p) => p.value).toList(growable: false)
        ..sort();
      yCap = sortedVals[((sortedVals.length - 1) * capAt).round()];
    }
    _memoWindow = widget.smoothWindow;
    _memoCap = widget.capPercentile;
    return _memoSeries = (plotted: plotted, rawBehind: rawBehind, yCap: yCap);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final effective = widget.color ?? theme.colorScheme.primary;

    // Keep only samples whose value is non-null; we still need the
    // original timestamps so the chart's X axis reflects real time.
    // #4072 — derived once per samples list, not once per scrub frame:
    // every crosshair move rebuilt, re-sorted and re-smoothed the series.
    final points = _derivedPoints();
    final showEmpty =
        widget.samples.isEmpty || (widget.emptyWhenAllNull && points.isEmpty);
    if (showEmpty) {
      return SizedBox(
        height: 140,
        child: Center(
          child: Text(
            l.trajetDetailChartEmpty,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
    // #3502 — readable series: rolling-median smoothing (raw kept faint
    // behind) + a percentile-capped y-axis. Both off by default.
    final derived = _derivedSeries(points);
    final plotted = derived.plotted;
    final rawBehind = derived.rawBehind;
    final yCap = derived.yCap;

    final selected = (_selected != null && _selected! < plotted.length)
        ? _selected
        : null;
    final locale = Localizations.localeOf(context);

    final chart = SizedBox(
      height: 160,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) => _scrub(d.localPosition, size, plotted),
            onHorizontalDragStart: (d) =>
                _scrub(d.localPosition, size, plotted),
            onHorizontalDragUpdate: (d) =>
                _scrub(d.localPosition, size, plotted),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: LineChartPainter(
                      points: plotted,
                      rawPoints: rawBehind,
                      yCap: yCap,
                      color: effective,
                      labelColor: theme.colorScheme.onSurface,
                      unit: widget.unit,
                      selectedIndex: selected,
                    ),
                    size: Size.infinite,
                  ),
                ),
                if (selected != null)
                  _TripChartReadout(
                    point: plotted[selected],
                    unit: widget.unit,
                    locale: locale,
                  ),
              ],
            ),
          );
        },
      ),
    );
    if (!widget.estimated) return chart;
    // #2431 — overlay a clearly-marked estimate badge on the GPS-physics
    // fallback series so it is never read as a measurement.
    return Stack(
      children: [
        chart,
        Positioned(
          top: 0,
          left: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '~ ${l.trajetDetailChartEstimatedBadge}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A small callout showing the scrubbed point's value + unit and time, e.g.
/// "42.0 km/h · 10:00:05". Rendered as a real widget (not painted) so it is
/// legible at any scale and testable via `find.textContaining`. Mirrors the
/// price-chart `_PriceTooltip` (#2384).
class _TripChartReadout extends StatelessWidget {
  final ChartPoint point;
  final String unit;
  final Locale locale;

  const _TripChartReadout({
    required this.point,
    required this.unit,
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Reuse the existing per-chart unit suffix + the existing `toStringAsFixed`
    // value formatting (same as the corner min/max labels). The time uses the
    // locale's medium time format — no new user-facing string.
    final timeFormat = DateFormat.Hms(locale.toString());
    final label =
        '${UnitFormatter.formatDecimal(point.value)} $unit · ${timeFormat.format(point.timestamp)}';
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.inverseSurface,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onInverseSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
