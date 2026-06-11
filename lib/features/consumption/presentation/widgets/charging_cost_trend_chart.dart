// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import 'package:flutter/material.dart';
// `intl` also exports a `TextDirection`; hide it so the painter keeps using
// the dart:ui/material one (with `.ltr`).
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../l10n/app_localizations.dart';

/// Monthly-total charging-cost bar chart (#582 phase 3).
///
/// Mirrors [MonthlyBarChart] from the carbon feature: one bar per
/// month, short month label below, max-value reference line up top.
/// Uses [CustomPaint] rather than pulling in a chart library so we
/// stay consistent with `price_chart.dart` / `monthly_bar_chart.dart`.
///
/// Empty-state: when every month is 0, renders a centred
/// "Not enough data yet" caption so the section still feels
/// intentional instead of blank.
class ChargingCostTrendChart extends StatelessWidget {
  /// Month-start → total-EUR-for-that-month. Oldest key first; six
  /// entries is the usual case (the provider always pads missing
  /// months with 0.0 for continuity).
  final Map<DateTime, double> monthlyCost;

  /// Bar fill. Defaults to `theme.colorScheme.primary` via
  /// [ColorScheme.primary] — caller can override for tests.
  final Color? color;

  const ChargingCostTrendChart({
    super.key,
    required this.monthlyCost,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final effective = color ?? theme.colorScheme.primary;
    final entries = monthlyCost.entries.toList(growable: false)
      ..sort((a, b) => a.key.compareTo(b.key));
    final hasAnyValue = entries.any((e) => e.value > 0);
    if (entries.isEmpty || !hasAnyValue) {
      return SizedBox(
        height: 140,
        child: Center(
          child: Text(
            l.chargingChartsEmpty,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
    // Month-axis labels are locale DATA, not a translatable string: resolve
    // the active locale's short-month names via intl (matches price_chart.dart's
    // `DateFormat.Md(locale)` pattern). #2971.
    final locale = Localizations.localeOf(context).toString();
    return SizedBox(
      height: 160,
      child: CustomPaint(
        painter: _CostTrendPainter(
          entries: entries,
          color: effective,
          labelColor: theme.colorScheme.onSurface,
          monthFormat: DateFormat.MMM(locale),
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _CostTrendPainter extends CustomPainter {
  final List<MapEntry<DateTime, double>> entries;
  final Color color;
  final Color labelColor;

  /// Locale-aware short-month formatter for the X-axis labels (#2971).
  final DateFormat monthFormat;

  _CostTrendPainter({
    required this.entries,
    required this.color,
    required this.labelColor,
    required this.monthFormat,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.isEmpty) return;

    const leftInset = 8.0;
    const rightInset = 8.0;
    const topInset = 18.0;
    const bottomInset = 22.0;

    final chartWidth = size.width - leftInset - rightInset;
    final chartHeight = size.height - topInset - bottomInset;

    final values = entries.map((e) => e.value).toList(growable: false);
    final maxValue = values.reduce(math.max);
    final effectiveMax = maxValue > 0 ? maxValue : 1.0;

    final barCount = entries.length;
    final slot = chartWidth / barCount;
    final barWidth = math.max(4.0, slot * 0.55);

    final barPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Max reference line
    final refPaint = Paint()
      ..color = color.withAlpha(50)
      ..strokeWidth = 1;
    canvas.drawLine(
      const Offset(leftInset, topInset),
      Offset(size.width - rightInset, topInset),
      refPaint,
    );

    // Max label top-right
    _drawText(
      canvas,
      '€${maxValue.toStringAsFixed(0)}',
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
      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(left, top, barWidth, barHeight),
        topLeft: const Radius.circular(3),
        topRight: const Radius.circular(3),
      );
      canvas.drawRRect(rect, barPaint);
      _drawText(
        canvas,
        monthFormat.format(entries[i].key),
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
  bool shouldRepaint(_CostTrendPainter oldDelegate) =>
      oldDelegate.entries != entries ||
      oldDelegate.color != color ||
      oldDelegate.monthFormat.locale != monthFormat.locale;
}
