// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

// Part of `trip_detail_charts.dart` (#2977) — the scrub-to-read crosshair:
// the shared time/value projection geometry, the nearest-point hit-test, and
// the value/time readout callout. Split into a part file so the widget host
// file stays under the 400-line guard (#1680). Mirrors the price-chart
// tap-to-nearest pattern (#2384) so the two charts feel identical.
part of 'trip_detail_charts.dart';

/// Shared implementation — every Trip-detail chart is the same
/// rolling-window line plot over [timestamp], differing only in which
/// sample field they extract. Keeping the widget private avoids exposing a
/// stable but internal widget API to the rest of the app.
///
/// #2977 — stateful so a tap/drag (scrub) selects the nearest sample and
/// overlays a vertical crosshair + a value/time readout, mirroring the
/// price-chart tap-to-nearest pattern (#2384). The crosshair geometry +
/// readout callout live below in this same part file.
class _TripDetailLineChart extends StatefulWidget {
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

  const _TripDetailLineChart({
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
  State<_TripDetailLineChart> createState() => _TripDetailLineChartState();
}

class _TripDetailLineChartState extends State<_TripDetailLineChart> {
  /// Index into the plotted (non-null, time-sorted) points of the sample the
  /// scrub crosshair is reading, or null when the user has not scrubbed yet.
  int? _selected;

  @override
  void didUpdateWidget(_TripDetailLineChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A new series invalidates the selected ordinal.
    if (!identical(oldWidget.samples, widget.samples) ||
        oldWidget.valueOf != widget.valueOf) {
      _selected = null;
    }
  }

  void _scrub(Offset localPos, Size size, List<_ChartPoint> points) {
    if (points.length < 2) return;
    final nearest = _TripChartGeometry.nearestPointIndex(
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
  static List<_ChartPoint> _rollingMedian(List<_ChartPoint> pts, int window) {
    final half = window ~/ 2;
    final out = <_ChartPoint>[];
    for (var i = 0; i < pts.length; i++) {
      final from = math.max(0, i - half);
      final to = math.min(pts.length, i + half + 1);
      final vals = [for (var j = from; j < to; j++) pts[j].value]..sort();
      final mid = vals.length ~/ 2;
      final median = vals.length.isOdd
          ? vals[mid]
          : (vals[mid - 1] + vals[mid]) / 2;
      out.add(_ChartPoint(pts[i].timestamp, median));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final effective = widget.color ?? theme.colorScheme.primary;

    // Keep only samples whose value is non-null; we still need the
    // original timestamps so the chart's X axis reflects real time.
    final points = <_ChartPoint>[];
    for (final s in widget.samples) {
      final v = widget.valueOf(s);
      if (v == null) continue;
      points.add(_ChartPoint(s.timestamp, v));
    }
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
    points.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // #3502 — readable series: rolling-median smoothing (raw kept faint
    // behind) + a percentile-capped y-axis. Both off by default.
    var plotted = points;
    List<_ChartPoint>? rawBehind;
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
                    painter: _LineChartPainter(
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

/// Pure projection maths for a trip line chart — kept out of the painter so
/// the painter and the gesture's nearest-point hit-test share ONE definition
/// of where a sample lands, and the drawn marker always sits on the read
/// value. Insets/padding match the previous inline `_LineChartPainter` maths.
class _TripChartGeometry {
  /// Insets reserved around the plot (must match the painter's drawn area).
  static const double leftInset = 8.0;
  static const double rightInset = 8.0;
  static const double topInset = 18.0;
  static const double bottomInset = 22.0;

  final double minV;
  final double maxV;
  final double _yMin;
  final double _ySpan;
  final int _firstTs;
  final int _tSpan;
  final double _chartWidth;
  final double _chartHeight;

  const _TripChartGeometry._({
    required this.minV,
    required this.maxV,
    required double yMin,
    required double ySpan,
    required int firstTs,
    required int tSpan,
    required double chartWidth,
    required double chartHeight,
  }) : _yMin = yMin,
       _ySpan = ySpan,
       _firstTs = firstTs,
       _tSpan = tSpan,
       _chartWidth = chartWidth,
       _chartHeight = chartHeight;

  factory _TripChartGeometry.forSize(
    Size size,
    List<_ChartPoint> points, {
    double? yCap,
  }) {
    final chartWidth = size.width - leftInset - rightInset;
    final chartHeight = size.height - topInset - bottomInset;

    final values = points.map((p) => p.value).toList(growable: false);
    final minV = values.reduce(math.min);
    // #3502 — a percentile cap bounds the axis so one spike can't squash
    // the readable band; values above it project clamped at the top edge
    // (yFor clamps).
    var maxV = values.reduce(math.max);
    if (yCap != null && yCap > minV && yCap < maxV) maxV = yCap;
    final range = (maxV - minV).abs();
    final padding = range > 0 ? range * 0.1 : 1.0;
    final yMin = minV - padding;
    final yMax = maxV + padding;
    final ySpan = (yMax - yMin) == 0 ? 1.0 : (yMax - yMin);

    final firstTs = points.first.timestamp.millisecondsSinceEpoch;
    final lastTs = points.last.timestamp.millisecondsSinceEpoch;
    final tSpan = (lastTs - firstTs) == 0 ? 1 : (lastTs - firstTs);

    return _TripChartGeometry._(
      minV: minV,
      maxV: maxV,
      yMin: yMin,
      ySpan: ySpan,
      firstTs: firstTs,
      tSpan: tSpan,
      chartWidth: chartWidth,
      chartHeight: chartHeight,
    );
  }

  double xFor(DateTime t) {
    final rel = (t.millisecondsSinceEpoch - _firstTs) / _tSpan;
    return leftInset + rel * _chartWidth;
  }

  double yFor(double v) {
    // #3502 — clamp into the (possibly capped) axis range so above-cap
    // spikes draw flat at the top edge instead of escaping the plot.
    final vv = v.clamp(_yMin, _yMin + _ySpan).toDouble();
    return topInset + _chartHeight - ((vv - _yMin) / _ySpan) * _chartHeight;
  }

  /// Index into [points] of the point whose plotted x is nearest [localPos].
  /// Mirrors `PriceChartAxes.nearestPointIndex` (#2384).
  static int nearestPointIndex(
    Offset localPos,
    Size size,
    List<_ChartPoint> points,
  ) {
    final geo = _TripChartGeometry.forSize(size, points);
    int best = 0;
    double bestDist = double.infinity;
    for (int i = 0; i < points.length; i++) {
      final dx = (geo.xFor(points[i].timestamp) - localPos.dx).abs();
      if (dx < bestDist) {
        bestDist = dx;
        best = i;
      }
    }
    return best;
  }
}

/// A small callout showing the scrubbed point's value + unit and time, e.g.
/// "42.0 km/h · 10:00:05". Rendered as a real widget (not painted) so it is
/// legible at any scale and testable via `find.textContaining`. Mirrors the
/// price-chart `_PriceTooltip` (#2384).
class _TripChartReadout extends StatelessWidget {
  final _ChartPoint point;
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
        '${point.value.toStringAsFixed(1)} $unit · ${timeFormat.format(point.timestamp)}';
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
