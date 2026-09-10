// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:math' as math;
import 'dart:ui';

/// One plotted sample of a trip line chart: the timestamp it was read at
/// and the value read. Shared by the painter, the geometry and the
/// scrub gesture so all three agree on what a point is.
class ChartPoint {
  final DateTime timestamp;
  final double value;

  const ChartPoint(this.timestamp, this.value);
}

/// Pure projection maths for a trip line chart — kept out of the painter so
/// the painter and the gesture's nearest-point hit-test share ONE definition
/// of where a sample lands, and the drawn marker always sits on the read
/// value. Insets/padding match the previous inline `_LineChartPainter` maths.
class TripChartGeometry {
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

  const TripChartGeometry._({
    required this.minV,
    required this.maxV,
    required this._yMin,
    required this._ySpan,
    required this._firstTs,
    required this._tSpan,
    required this._chartWidth,
    required this._chartHeight,
  });

  factory TripChartGeometry.forSize(
    Size size,
    List<ChartPoint> points, {
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

    return TripChartGeometry._(
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
    List<ChartPoint> points,
  ) {
    final geo = TripChartGeometry.forSize(size, points);
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
