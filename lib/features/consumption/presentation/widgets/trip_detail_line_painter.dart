// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

// Part of `trip_detail_charts.dart` (#2431) — the shared rolling-window
// line-chart CustomPainter and its point model, split out so the widget
// file stays under the 400-line guard. Library-private types, shared with
// the host library's `_TripDetailLineChart`.
part of 'trip_detail_charts.dart';

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

  /// #2977 — index of the scrubbed sample whose crosshair + marker is drawn,
  /// or null when the user has not scrubbed. Projected with the same
  /// [_TripChartGeometry] the nearest-point hit-test uses, so the marker
  /// lands exactly on the read value.
  final int? selectedIndex;

  _LineChartPainter({
    required this.points,
    required this.color,
    required this.labelColor,
    required this.unit,
    this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final geo = _TripChartGeometry.forSize(size, points);

    // Max / min labels at the corners — gives the user a quick read
    // on the range without cluttering the plot with grid lines.
    _drawText(
      canvas,
      '${geo.maxV.toStringAsFixed(1)} $unit',
      Offset(size.width - _TripChartGeometry.rightInset, 2),
      anchorRight: true,
      color: labelColor.withAlpha(160),
      fontSize: 10,
    );
    _drawText(
      canvas,
      geo.minV.toStringAsFixed(1),
      Offset(_TripChartGeometry.leftInset,
          size.height - _TripChartGeometry.bottomInset + 4),
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
        Offset(cx, _TripChartGeometry.topInset),
        Offset(cx, size.height - _TripChartGeometry.bottomInset),
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
  bool shouldRepaint(_LineChartPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.color != color ||
      oldDelegate.unit != unit ||
      oldDelegate.selectedIndex != selectedIndex;
}
