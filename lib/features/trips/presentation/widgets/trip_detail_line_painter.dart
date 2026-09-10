// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../core/utils/unit_formatter.dart';
import 'trip_chart_geometry.dart';

/// The shared rolling-window line-chart painter behind every trip-detail
/// chart (#2431). It draws the polyline, the min/max labels, the time
/// axis and — when the gesture supplies one — the scrub crosshair, all
/// projected through [TripChartGeometry] so the drawn marker always sits
/// on the value the readout names.

class LineChartPainter extends CustomPainter {
  final List<ChartPoint> points;
  final Color color;
  final Color labelColor;
  final String unit;

  /// #3502 — the un-smoothed series, drawn as a faint background polyline
  /// behind [points] when smoothing is on. Null keeps the classic
  /// single-line plot.
  final List<ChartPoint>? rawPoints;

  /// #3502 — percentile axis cap forwarded into the geometry (see
  /// [TripChartGeometry.forSize]); above-cap values draw clamped.
  final double? yCap;

  /// #2977 — index of the scrubbed sample whose crosshair + marker is drawn,
  /// or null when the user has not scrubbed. Projected with the same
  /// [TripChartGeometry] the nearest-point hit-test uses, so the marker
  /// lands exactly on the read value.
  final int? selectedIndex;

  LineChartPainter({
    required this.points,
    required this.color,
    required this.labelColor,
    required this.unit,
    this.rawPoints,
    this.yCap,
    this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final geo = TripChartGeometry.forSize(size, points, yCap: yCap);

    // #3502 — the raw series first (behind), faint + thin, values clamped
    // into the capped axis by yFor. Nothing is hidden by the smoothing —
    // the eye reads the median line, the spikes stay visible as texture.
    final raw = rawPoints;
    if (raw != null && raw.isNotEmpty) {
      final rawPaint = Paint()
        ..color = color.withAlpha(70)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      final rawPath = Path();
      for (int i = 0; i < raw.length; i++) {
        final pt = Offset(geo.xFor(raw[i].timestamp), geo.yFor(raw[i].value));
        if (i == 0) {
          rawPath.moveTo(pt.dx, pt.dy);
        } else {
          rawPath.lineTo(pt.dx, pt.dy);
        }
      }
      canvas.drawPath(rawPath, rawPaint);
    }

    // Max / min labels at the corners — gives the user a quick read
    // on the range without cluttering the plot with grid lines.
    _drawText(
      canvas,
      '${UnitFormatter.formatDecimal(geo.maxV)} $unit',
      Offset(size.width - TripChartGeometry.rightInset, 2),
      anchorRight: true,
      color: labelColor.withAlpha(160),
      fontSize: 10,
    );
    _drawText(
      canvas,
      UnitFormatter.formatDecimal(geo.minV),
      Offset(TripChartGeometry.leftInset,
          size.height - TripChartGeometry.bottomInset + 4),
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
      final pt = Offset(geo.xFor(p.timestamp), geo.yFor(p.value));
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    canvas.drawPath(path, linePaint);

    // #2977 — scrub crosshair: a faint vertical guide at the selected x plus
    // a filled marker + ring on the data point. Mirrors the price-chart
    // selected-point highlight (#2384) so the two charts feel identical.
    if (selectedIndex != null && selectedIndex! < points.length) {
      final sel = points[selectedIndex!];
      final cx = geo.xFor(sel.timestamp);
      final cy = geo.yFor(sel.value);
      canvas.drawLine(
        Offset(cx, TripChartGeometry.topInset),
        Offset(cx, size.height - TripChartGeometry.bottomInset),
        Paint()
          ..color = color.withAlpha(120)
          ..strokeWidth = 1,
      );
      final dotPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(cx, cy), 4, dotPaint);
      canvas.drawCircle(
        Offset(cx, cy),
        6,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
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
      textDirection: ui.TextDirection.ltr,
    )..layout();
    var dx = offset.dx;
    if (anchorRight) dx -= tp.width;
    if (anchorCenter) dx -= tp.width / 2;
    tp.paint(canvas, Offset(dx, offset.dy));
  }

  @override
  bool shouldRepaint(LineChartPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.rawPoints != rawPoints ||
      oldDelegate.yCap != yCap ||
      oldDelegate.color != color ||
      oldDelegate.unit != unit ||
      oldDelegate.selectedIndex != selectedIndex;
}
