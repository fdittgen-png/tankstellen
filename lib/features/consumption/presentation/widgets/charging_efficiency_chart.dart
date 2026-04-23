import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Monthly kWh/100 km line chart (#582 phase 3).
///
/// Companion to [ChargingCostTrendChart] on the Charging tab — same
/// 6-month window, same colour, but plots efficiency as a connected
/// line with dot markers instead of bars. Months with no data
/// (`null`) are skipped: the line bridges the gap so the trend stays
/// readable, and dots only render for months with actual numbers.
///
/// Empty-state: when every month is null, renders a centred caption
/// instead of a lonely dot.
class ChargingEfficiencyChart extends StatelessWidget {
  /// Month-start → kWh/100 km for that month, or `null` for months
  /// with insufficient data.
  final Map<DateTime, double?> monthlyEfficiency;

  /// Line colour. Defaults to [ColorScheme.primary].
  final Color? color;

  const ChargingEfficiencyChart({
    super.key,
    required this.monthlyEfficiency,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final effective = color ?? theme.colorScheme.primary;
    final entries = monthlyEfficiency.entries.toList(growable: false)
      ..sort((a, b) => a.key.compareTo(b.key));
    final points = entries.where((e) => e.value != null).toList(growable: false);
    if (entries.isEmpty || points.isEmpty) {
      return SizedBox(
        height: 140,
        child: Center(
          child: Text(
            l?.chargingChartsEmpty ?? 'Not enough data yet',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
    return SizedBox(
      height: 160,
      child: CustomPaint(
        painter: _EfficiencyPainter(
          entries: entries,
          color: effective,
          labelColor: theme.colorScheme.onSurface,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _EfficiencyPainter extends CustomPainter {
  final List<MapEntry<DateTime, double?>> entries;
  final Color color;
  final Color labelColor;

  _EfficiencyPainter({
    required this.entries,
    required this.color,
    required this.labelColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.isEmpty) return;
    final values = entries
        .where((e) => e.value != null)
        .map((e) => e.value!)
        .toList(growable: false);
    if (values.isEmpty) return;

    const leftInset = 8.0;
    const rightInset = 8.0;
    const topInset = 18.0;
    const bottomInset = 22.0;

    final chartWidth = size.width - leftInset - rightInset;
    final chartHeight = size.height - topInset - bottomInset;

    final minV = values.reduce(math.min);
    final maxV = values.reduce(math.max);
    final range = (maxV - minV).abs();
    final padding = range > 0 ? range * 0.1 : 1.0;
    final yMin = (minV - padding).clamp(0.0, double.infinity);
    final yMax = maxV + padding;

    double xForIndex(int i) =>
        leftInset + (entries.length == 1
            ? chartWidth / 2
            : (i / (entries.length - 1)) * chartWidth);
    double yForValue(double v) =>
        topInset +
        chartHeight -
        ((v - yMin) / (yMax - yMin == 0 ? 1 : (yMax - yMin))) * chartHeight;

    // Max label top-right
    _drawText(
      canvas,
      '${maxV.toStringAsFixed(1)} kWh',
      Offset(size.width - rightInset, 2),
      anchorRight: true,
      color: labelColor.withAlpha(160),
      fontSize: 10,
    );

    // Month labels along the bottom axis.
    for (int i = 0; i < entries.length; i++) {
      _drawText(
        canvas,
        _shortMonth(entries[i].key),
        Offset(xForIndex(i), topInset + chartHeight + 4),
        anchorCenter: true,
        color: labelColor.withAlpha(160),
        fontSize: 10,
      );
    }

    // Connect the dots (skipping null months by bridging).
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path();
    var started = false;
    for (int i = 0; i < entries.length; i++) {
      final v = entries[i].value;
      if (v == null) continue;
      final p = Offset(xForIndex(i), yForValue(v));
      if (!started) {
        path.moveTo(p.dx, p.dy);
        started = true;
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(path, linePaint);

    // Data dots
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    for (int i = 0; i < entries.length; i++) {
      final v = entries[i].value;
      if (v == null) continue;
      canvas.drawCircle(
        Offset(xForIndex(i), yForValue(v)),
        3,
        dotPaint,
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
  bool shouldRepaint(_EfficiencyPainter oldDelegate) =>
      oldDelegate.entries != entries || oldDelegate.color != color;
}
