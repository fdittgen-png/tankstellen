// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:math' as math;

import 'package:flutter/material.dart';
// `intl` also exports a `TextDirection`; hide it so the painter keeps
// using the dart:ui/material one (with `.ltr`).
import 'package:intl/intl.dart' hide TextDirection;

import 'monthly_bar_chart_base.dart' show drawChartText;

/// The monthly LINE + area painter (#4175), sibling of
/// [MonthlyBarChartPainter] and sharing its axis geometry, its label
/// anchoring and its "no external chart library" stance.
///
/// A trend across months is a line; bars are for comparing discrete
/// quantities. The four stacked bar charts this replaces were being
/// read as a trend and drawn as four comparisons.
///
/// ## Why the curve tension is computed, not a constant
///
/// Every "modern chart" recipe says to turn smoothing on and leave it
/// on. With two data points — which is what a user with two months of
/// fill-ups has, and the state the screen was reported in — a bezier
/// through two points is a straight line wearing a costume: it implies
/// a shape between the points that nothing measured. So [_tension]
/// scales with how many points there are and is exactly zero below
/// three. The smoothing appears when there is something to smooth.
///
/// Feature boundary: primitives only — no feature types cross into core.
class MonthlyLineChartPainter extends CustomPainter {
  MonthlyLineChartPainter({
    required this.values,
    required this.months,
    required this.color,
    required this.maxLabel,
    required this.labelColor,
    required this.monthFormat,
    required this.surfaceColor,
    this.progress = 1,
    this.bottomInset = 24,
  });

  /// One value per month, oldest first.
  final List<double> values;

  /// Month timestamps aligned with [values] — drives the X-axis labels.
  final List<DateTime> months;

  /// Line colour; the area beneath fades this out to nothing.
  final Color color;

  /// Prebuilt max-value label shown top-right (e.g. `'42 L'`).
  final String maxLabel;

  /// Axis/label text colour (typically `onSurface`).
  final Color labelColor;

  /// What the chart is drawn ON. The data dots are rings — a disc in
  /// [color] with this colour cored out — and a painter cannot guess
  /// the card surface behind it. Passing it keeps the ring correct in
  /// light, dark and the eco theme instead of hard-coding white.
  final Color surfaceColor;

  /// Locale-aware short-month formatter for the X-axis labels (#2971).
  final DateFormat monthFormat;

  /// 0 → 1 reveal, so switching metric animates rather than cutting.
  /// Drives the vertical position only: the axis and the month labels
  /// stay put, because a chart whose axis moves is a chart the eye has
  /// to re-read on every frame.
  final double progress;

  /// Space reserved below the line for the month labels.
  final double bottomInset;

  /// Catmull-Rom tension, and zero when there is nothing to smooth.
  double get _tension => values.length < 3 ? 0 : 0.16;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    const leftInset = 8.0;
    const rightInset = 8.0;
    const topInset = 18.0;

    final chartWidth = size.width - leftInset - rightInset;
    final chartHeight = size.height - topInset - bottomInset;
    final baseline = topInset + chartHeight;

    final maxValue = values.reduce(math.max);
    final effectiveMax = maxValue > 0 ? maxValue : 1.0;

    // A single month has no slot to centre in; put it in the middle
    // rather than at the left edge, where it would read as the start of
    // a line that simply has not been drawn yet.
    final count = values.length;
    final points = <Offset>[
      for (var i = 0; i < count; i++)
        Offset(
          count == 1
              ? leftInset + chartWidth / 2
              : leftInset + chartWidth * (i / (count - 1)),
          baseline - (values[i] / effectiveMax) * chartHeight * progress,
        ),
    ];

    // Max reference line, matching the bar chart's so the two read as
    // one family when they appear on the same screen.
    canvas.drawLine(
      const Offset(leftInset, topInset),
      Offset(size.width - rightInset, topInset),
      Paint()
        ..color = color.withAlpha(50)
        ..strokeWidth = 1,
    );
    drawChartText(
      canvas,
      maxLabel,
      Offset(size.width - rightInset, 2),
      anchorRight: true,
      color: labelColor.withAlpha(160),
      fontSize: 10,
    );

    final line = _linePath(points);

    // The area first, so the stroke sits on top of its own fill.
    final area = Path.from(line)
      ..lineTo(points.last.dx, baseline)
      ..lineTo(points.first.dx, baseline)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withAlpha(64), color.withAlpha(0)],
        ).createShader(Rect.fromLTWH(0, topInset, size.width, chartHeight)),
    );

    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // A dot per month: with two points especially, the dots are what
    // say "these are measurements" rather than "this is a shape".
    for (final p in points) {
      canvas.drawCircle(p, 4.5, Paint()..color = color);
      canvas.drawCircle(p, 2, Paint()..color = surfaceColor);
    }

    for (var i = 0; i < count; i++) {
      drawChartText(
        canvas,
        monthFormat.format(months[i]),
        Offset(points[i].dx, baseline + 4),
        anchorCenter: true,
        color: labelColor.withAlpha(160),
        fontSize: 10,
      );
    }
  }

  /// A Catmull-Rom path through [points], degenerating to straight
  /// segments when [_tension] is zero. See the class doc for why that
  /// is a property of the data and not a style choice.
  Path _linePath(List<Offset> points) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    if (points.length == 1) return path;
    final t = _tension;
    if (t == 0) {
      for (final p in points.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      return path;
    }
    for (var i = 0; i < points.length - 1; i++) {
      final p0 = i == 0 ? points[i] : points[i - 1];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = i + 2 < points.length ? points[i + 2] : p2;
      path.cubicTo(
        p1.dx + (p2.dx - p0.dx) * t,
        p1.dy + (p2.dy - p0.dy) * t,
        p2.dx - (p3.dx - p1.dx) * t,
        p2.dy - (p3.dy - p1.dy) * t,
        p2.dx,
        p2.dy,
      );
    }
    return path;
  }

  @override
  bool shouldRepaint(covariant MonthlyLineChartPainter old) =>
      old.values != values ||
      old.months != months ||
      old.color != color ||
      old.maxLabel != maxLabel ||
      old.progress != progress ||
      old.surfaceColor != surfaceColor ||
      old.monthFormat.locale != monthFormat.locale;
}
