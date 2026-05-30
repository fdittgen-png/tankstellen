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
