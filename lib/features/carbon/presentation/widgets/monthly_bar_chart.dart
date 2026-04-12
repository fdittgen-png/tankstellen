import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/monthly_summary.dart';

/// A minimal bar chart rendered via [CustomPainter].
///
/// Consistent with the rest of the project: no external chart library,
/// pure paint operations, cheap to rebuild. One bar per month, label
/// at the bottom, max value reference line at the top.
class MonthlyBarChart extends StatelessWidget {
  /// The summaries to render, oldest first.
  final List<MonthlySummary> summaries;

  /// How to extract the numeric value from a summary (e.g. cost, co2).
  final double Function(MonthlySummary) valueOf;

  /// Bar fill color.
  final Color color;

  /// Unit suffix shown on the max-value label (e.g. "€", "kg").
  final String unitLabel;

  const MonthlyBarChart({
    super.key,
    required this.summaries,
    required this.valueOf,
    required this.color,
    required this.unitLabel,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    if (summaries.isEmpty) {
      final l = AppLocalizations.of(context);
      return SizedBox(
        height: 180,
        child: Center(child: Text(l?.noDataAvailable ?? 'No data')),
      );
    }
    return SizedBox(
      height: 180,
      child: CustomPaint(
        painter: _BarChartPainter(
          summaries: summaries,
          valueOf: valueOf,
          color: color,
          unitLabel: unitLabel,
          labelColor: onSurface,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<MonthlySummary> summaries;
  final double Function(MonthlySummary) valueOf;
  final Color color;
  final String unitLabel;
  final Color labelColor;

  _BarChartPainter({
    required this.summaries,
    required this.valueOf,
    required this.color,
    required this.unitLabel,
    required this.labelColor,
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
      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(left, top, barWidth, barHeight),
        topLeft: const Radius.circular(3),
        topRight: const Radius.circular(3),
      );
      canvas.drawRRect(rect, barPaint);

      // Month label below the bar.
      final m = summaries[i].month;
      _drawText(
        canvas,
        _shortMonth(m),
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

  String _shortMonth(DateTime d) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return names[d.month - 1];
  }

  @override
  bool shouldRepaint(_BarChartPainter oldDelegate) {
    return oldDelegate.summaries != summaries ||
        oldDelegate.color != color ||
        oldDelegate.unitLabel != unitLabel;
  }
}
