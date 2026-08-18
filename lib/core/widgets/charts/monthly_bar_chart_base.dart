// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import 'package:flutter/material.dart';
// `intl` also exports a `TextDirection`; hide it so the painter keeps using
// the dart:ui/material one (with `.ltr`).
import 'package:intl/intl.dart' hide TextDirection;

/// One coloured slice of a stacked bar (#3691) — e.g. the E85 share of
/// a month's litres. Segments stack bottom-up in list order.
class BarSegment {
  final double value;
  final Color color;

  const BarSegment({required this.value, required this.color});
}

/// Rounded top corners of every bar / stack-top segment — one shared
/// const so the inline-radius ratchet (#lint) counts a single site.
const Radius _barCorner = Radius.circular(3);

/// Shared text painting for the hand-rolled monthly charts (carbon
/// monthly bars, charging cost bars, charging efficiency line). One
/// implementation of the anchor math instead of three private copies.
void drawChartText(
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

/// The ONE minimal monthly bar-chart painter, promoted to core from
/// the carbon / charging twins. Consistent with the rest of the
/// project: no external chart library, pure paint operations, cheap to
/// rebuild. One bar per month, locale-aware short month label at the
/// bottom (#2971), max-value reference line + label at the top.
///
/// Feature charts subclass this with their own domain-facing
/// constructor (and painter type name — widget tests match on it) and
/// hand the extracted primitives to this base: [values], [months], the
/// prebuilt [maxLabel] string, and optional [stacks].
///
/// Feature boundary: primitives only — no feature types cross into
/// core.
class MonthlyBarChartPainter extends CustomPainter {
  /// One value per month, oldest first.
  final List<double> values;

  /// Month timestamps aligned with [values] — drives the X-axis labels.
  final List<DateTime> months;

  /// Bar fill color.
  final Color color;

  /// Prebuilt max-value label shown top-right (e.g. `'42 kg'`, `'€42'`).
  final String maxLabel;

  /// Axis/label text color (typically `onSurface`).
  final Color labelColor;

  /// Locale-aware short-month formatter for the X-axis labels (#2971).
  final DateFormat monthFormat;

  /// Per-bar stacked segments (#3691); null = solid bars.
  final List<List<BarSegment>>? stacks;

  /// Bar width as a fraction of the per-month slot (carbon 0.6,
  /// charging 0.55).
  final double barWidthFactor;

  /// Space reserved below the bars for the month labels.
  final double bottomInset;

  MonthlyBarChartPainter({
    required this.values,
    required this.months,
    required this.color,
    required this.maxLabel,
    required this.labelColor,
    required this.monthFormat,
    this.stacks,
    this.barWidthFactor = 0.6,
    this.bottomInset = 24,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    const leftInset = 8.0;
    const rightInset = 8.0;
    const topInset = 18.0;

    final chartWidth = size.width - leftInset - rightInset;
    final chartHeight = size.height - topInset - bottomInset;

    final maxValue = values.reduce(math.max);
    final effectiveMax = maxValue > 0 ? maxValue : 1.0;

    final barCount = values.length;
    final slot = chartWidth / barCount;
    final barWidth = math.max(4.0, slot * barWidthFactor);

    final barPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Max reference line.
    final refPaint = Paint()
      ..color = color.withAlpha(50)
      ..strokeWidth = 1;
    canvas.drawLine(
      const Offset(leftInset, topInset),
      Offset(size.width - rightInset, topInset),
      refPaint,
    );

    // Max label at top-right.
    drawChartText(
      canvas,
      maxLabel,
      Offset(size.width - rightInset, 2),
      anchorRight: true,
      color: labelColor.withAlpha(160),
      fontSize: 10,
    );

    for (int i = 0; i < barCount; i++) {
      final v = values[i];
      final barHeight = (v / effectiveMax) * chartHeight;
      final cx = leftInset + slot * i + slot / 2;
      final left = cx - barWidth / 2;
      final top = topInset + chartHeight - barHeight;
      final segments = stacks != null && i < stacks!.length
          ? stacks![i]
          : null;
      if (segments == null || segments.isEmpty) {
        final rect = RRect.fromRectAndCorners(
          Rect.fromLTWH(left, top, barWidth, barHeight),
          topLeft: _barCorner,
          topRight: _barCorner,
        );
        canvas.drawRRect(rect, barPaint);
      } else {
        // Stacked bottom-up (#3691): each fuel's share as its own
        // colour, the topmost segment keeping the rounded corners.
        var bottom = topInset + chartHeight;
        for (var si = 0; si < segments.length; si++) {
          final seg = segments[si];
          final segHeight = (seg.value / effectiveMax) * chartHeight;
          if (segHeight <= 0) continue;
          final segTop = bottom - segHeight;
          final isTop = si == segments.length - 1;
          final segPaint = Paint()
            ..color = seg.color
            ..style = PaintingStyle.fill;
          canvas.drawRRect(
            RRect.fromRectAndCorners(
              Rect.fromLTWH(left, segTop, barWidth, segHeight),
              topLeft: isTop ? _barCorner : Radius.zero,
              topRight: isTop ? _barCorner : Radius.zero,
            ),
            segPaint,
          );
          bottom = segTop;
        }
      }

      // Month label below the bar.
      drawChartText(
        canvas,
        monthFormat.format(months[i]),
        Offset(cx, topInset + chartHeight + 4),
        anchorCenter: true,
        color: labelColor.withAlpha(160),
        fontSize: 10,
      );
    }
  }

  @override
  bool shouldRepaint(covariant MonthlyBarChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.months != months ||
        oldDelegate.color != color ||
        oldDelegate.maxLabel != maxLabel ||
        oldDelegate.stacks != stacks ||
        oldDelegate.monthFormat.locale != monthFormat.locale;
  }
}
