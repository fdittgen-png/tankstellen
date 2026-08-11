// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import 'package:flutter/material.dart';
// `intl` also exports a `TextDirection`; hide it so the painter keeps using
// the dart:ui/material one (with `.ltr`).
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../l10n/app_localizations.dart';
import '../../domain/monthly_summary.dart';

/// A minimal bar chart rendered via [CustomPainter].
///
/// Consistent with the rest of the project: no external chart library,
/// pure paint operations, cheap to rebuild. One bar per month, label
/// at the bottom, max value reference line at the top.
/// One coloured slice of a stacked bar (#3691) — e.g. the E85 share of
/// a month's litres. Segments stack bottom-up in list order.
class BarSegment {
  final double value;
  final Color color;

  const BarSegment({required this.value, required this.color});
}

class MonthlyBarChart extends StatelessWidget {
  /// The summaries to render, oldest first.
  final List<MonthlySummary> summaries;

  /// How to extract the numeric value from a summary (e.g. cost, co2).
  final double Function(MonthlySummary) valueOf;

  /// Bar fill color.
  final Color color;

  /// Unit suffix shown on the max-value label (e.g. "€", "kg").
  final String unitLabel;

  /// Optional per-bar stacked segments (#3691), aligned with
  /// [summaries]. When provided, bar i renders its segments bottom-up
  /// instead of one solid [color] — the additive per-fuel breakdown.
  /// [valueOf] still scales the axis, so segments should sum to it.
  final List<List<BarSegment>>? stacks;

  const MonthlyBarChart({
    super.key,
    required this.summaries,
    required this.valueOf,
    required this.color,
    required this.unitLabel,
    this.stacks,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    if (summaries.isEmpty) {
      final l = AppLocalizations.of(context);
      return SizedBox(
        height: 180,
        child: Center(child: Text(l.noDataAvailable)),
      );
    }
    // Month-axis labels are locale DATA, not a translatable string: resolve
    // the active locale's short-month names via intl (matches price_chart.dart's
    // `DateFormat.Md(locale)` pattern). #2971.
    final locale = Localizations.localeOf(context).toString();
    return SizedBox(
      height: 180,
      child: CustomPaint(
        painter: _BarChartPainter(
          summaries: summaries,
          valueOf: valueOf,
          color: color,
          unitLabel: unitLabel,
          labelColor: onSurface,
          monthFormat: DateFormat.MMM(locale),
          stacks: stacks,
        ),
        size: Size.infinite,
      ),
    );
  }
}

/// Rounded top corners of every bar / stack-top segment — one shared
/// const so the inline-radius ratchet (#lint) counts a single site.
const Radius _barCorner = Radius.circular(3);

class _BarChartPainter extends CustomPainter {
  final List<MonthlySummary> summaries;
  final double Function(MonthlySummary) valueOf;
  final Color color;
  final String unitLabel;
  final Color labelColor;

  /// Locale-aware short-month formatter for the X-axis labels (#2971).
  final DateFormat monthFormat;

  /// Per-bar stacked segments (#3691); null = solid bars.
  final List<List<BarSegment>>? stacks;

  _BarChartPainter({
    required this.summaries,
    required this.valueOf,
    required this.color,
    required this.unitLabel,
    required this.labelColor,
    required this.monthFormat,
    this.stacks,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (summaries.isEmpty) return;

    const leftInset = 8.0;
    const rightInset = 8.0;
    const topInset = 18.0;
    const bottomInset = 24.0;

    final chartWidth = size.width - leftInset - rightInset;
    final chartHeight = size.height - topInset - bottomInset;

    final values = summaries.map(valueOf).toList();
    final maxValue = values.reduce(math.max);
    final effectiveMax = maxValue > 0 ? maxValue : 1.0;

    final barCount = summaries.length;
    final slot = chartWidth / barCount;
    final barWidth = math.max(4.0, slot * 0.6);

    final barPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final refPaint = Paint()
      ..color = color.withAlpha(50)
      ..strokeWidth = 1;
    canvas.drawLine(
      const Offset(leftInset, topInset),
      Offset(size.width - rightInset, topInset),
      refPaint,
    );

    // Max label at top-right.
    _drawText(
      canvas,
      '${maxValue.toStringAsFixed(0)} $unitLabel',
      Offset(size.width - rightInset, 2),
      anchorRight: true,
      color: labelColor.withAlpha(160),
      fontSize: 10,
    );

    for (int i = 0; i < barCount; i++) {
      final v = values[i];
      final barHeight = effectiveMax > 0
          ? (v / effectiveMax) * chartHeight
          : 0.0;
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
          final segHeight = effectiveMax > 0
              ? (seg.value / effectiveMax) * chartHeight
              : 0.0;
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
      final m = summaries[i].month;
      _drawText(
        canvas,
        monthFormat.format(m),
        Offset(cx, topInset + chartHeight + 4),
        anchorCenter: true,
        color: labelColor.withAlpha(160),
        fontSize: 10,
      );
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset, {
    bool anchorRight = false,
    bool anchorCenter = false,
    Color color = const Color(0xFF000000),
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
  bool shouldRepaint(_BarChartPainter oldDelegate) {
    return oldDelegate.summaries != summaries ||
        oldDelegate.color != color ||
        oldDelegate.unitLabel != unitLabel ||
        oldDelegate.stacks != stacks ||
        oldDelegate.monthFormat.locale != monthFormat.locale;
  }
}
