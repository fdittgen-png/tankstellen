// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/fuel_colors.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/domain/fuel_type.dart';
import '../../domain/entities/price_record.dart';
import 'price_chart_axes.dart';

/// A simple line chart that renders price history using [CustomPainter].
///
/// No external chart library required. Draws a line from oldest (left)
/// to newest (right) with dashed min/max reference lines, a price (€)
/// Y-axis scale, date X-axis labels, and a tap/long-press tooltip that
/// reveals the price + date of the nearest data point (#2384).
class PriceChart extends StatefulWidget {
  final List<PriceRecord> records;
  final FuelType fuelType;

  const PriceChart({super.key, required this.records, required this.fuelType});

  @override
  State<PriceChart> createState() => _PriceChartState();

  /// Builds the ordered, oldest→newest list of plottable points for
  /// [records] / [fuelType]. Exposed for testing the axis/label maths.
  @visibleForTesting
  static List<ChartPoint> pointsFor(
    List<PriceRecord> records,
    FuelType fuelType,
  ) {
    final reversed = records.reversed.toList();
    final points = <ChartPoint>[];
    for (int i = 0; i < reversed.length; i++) {
      final price = priceForFuelType(reversed[i], fuelType);
      if (price != null) {
        points.add(
          ChartPoint(index: i, price: price, date: reversed[i].recordedAt),
        );
      }
    }
    return points;
  }
}

class _PriceChartState extends State<PriceChart> {
  /// Data-point index of the currently highlighted point (tap/long-press),
  /// or null when nothing is selected.
  int? _selected;

  static const double _chartHeight = 132;

  @override
  void didUpdateWidget(PriceChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.records != widget.records ||
        oldWidget.fuelType != widget.fuelType) {
      _selected = null;
    }
  }

  void _handlePointer(Offset localPos, Size size, List<ChartPoint> points) {
    if (points.length < 2) return;
    final nearest = PriceChartAxes.nearestPointIndex(localPos, size, points);
    if (nearest != _selected) {
      setState(() => _selected = nearest);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.records.isEmpty) {
      final l = AppLocalizations.of(context);
      return SizedBox(
        height: _chartHeight,
        child: Center(child: Text(l.noPriceHistory)),
      );
    }

    final theme = Theme.of(context);
    final color = FuelColors.forType(widget.fuelType);
    final points = PriceChart.pointsFor(widget.records, widget.fuelType);
    final locale = Localizations.localeOf(context).toString();
    final dateFormat = DateFormat.Md(locale);

    final selected = (_selected != null && _selected! < points.length)
        ? _selected
        : null;

    return SizedBox(
      height: _chartHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) => _handlePointer(d.localPosition, size, points),
            onLongPressStart: (d) =>
                _handlePointer(d.localPosition, size, points),
            onLongPressMoveUpdate: (d) =>
                _handlePointer(d.localPosition, size, points),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _PriceChartPainter(
                      points: points,
                      color: color,
                      axisColor: theme.colorScheme.onSurfaceVariant,
                      dateFormat: dateFormat,
                      selectedIndex: selected,
                    ),
                  ),
                ),
                if (selected != null)
                  _PriceTooltip(
                    point: points[selected],
                    dateFormat: dateFormat,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// A small callout showing the selected point's price + date, e.g.
/// "2,069 € · 23.05". Rendered as a real widget so it is legible at any
/// scale and testable via `find.textContaining`.
class _PriceTooltip extends StatelessWidget {
  final ChartPoint point;
  final DateFormat dateFormat;

  const _PriceTooltip({required this.point, required this.dateFormat});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label =
        '${PriceFormatter.formatPrice(point.price)} · ${dateFormat.format(point.date)}';
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.inverseSurface,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onInverseSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _PriceChartPainter extends CustomPainter {
  final List<ChartPoint> points;
  final Color color;
  final Color axisColor;
  final DateFormat dateFormat;
  final int? selectedIndex;

  _PriceChartPainter({
    required this.points,
    required this.color,
    required this.axisColor,
    required this.dateFormat,
    required this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    if (points.length == 1) {
      final dotPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(size.width / 2, size.height / 2), 4, dotPaint);
      return;
    }

    final layout = PriceChartAxes.layout(size, points);

    // Y-axis price gridlines (min / mid / max) with €-labels.
    for (final tick in layout.priceTicks) {
      final y = layout.yForPrice(tick);
      _drawLabel(
        canvas,
        PriceFormatter.formatPrice(tick),
        Offset(0, y),
        anchorMiddle: true,
      );
    }

    // Dashed horizontal guides for the observed min and max prices.
    final guidePaint = Paint()
      ..color = color.withAlpha(60)
      ..strokeWidth = 1;
    _drawDashedLine(
      canvas,
      Offset(layout.left, layout.yForPrice(layout.minPrice)),
      Offset(layout.right, layout.yForPrice(layout.minPrice)),
      guidePaint,
    );
    _drawDashedLine(
      canvas,
      Offset(layout.left, layout.yForPrice(layout.maxPrice)),
      Offset(layout.right, layout.yForPrice(layout.maxPrice)),
      guidePaint,
    );

    // The price line.
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(
      layout.xForIndex(points.first.index),
      layout.yForPrice(points.first.price),
    );
    for (int i = 1; i < points.length; i++) {
      path.lineTo(
        layout.xForIndex(points[i].index),
        layout.yForPrice(points[i].price),
      );
    }
    canvas.drawPath(path, linePaint);

    // Gradient fill under the line.
    final fillPath = Path.from(path)
      ..lineTo(layout.xForIndex(points.last.index), layout.bottom)
      ..lineTo(layout.xForIndex(points.first.index), layout.bottom)
      ..close();
    final fillPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, layout.top),
        Offset(0, layout.bottom),
        [color.withAlpha(40), color.withAlpha(5)],
      );
    canvas.drawPath(fillPath, fillPaint);

    // Data-point dots.
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    for (final p in points) {
      canvas.drawCircle(
        Offset(layout.xForIndex(p.index), layout.yForPrice(p.price)),
        3,
        dotPaint,
      );
    }

    // Highlight the selected point with a ring.
    if (selectedIndex != null && selectedIndex! < points.length) {
      final sel = points[selectedIndex!];
      final center = Offset(
        layout.xForIndex(sel.index),
        layout.yForPrice(sel.price),
      );
      canvas.drawCircle(center, 5, dotPaint);
      canvas.drawCircle(
        center,
        7,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    // X-axis date labels (first + last, plus middle ticks if they fit).
    for (final tick in layout.dateTicks) {
      final p = points[tick];
      _drawLabel(
        canvas,
        dateFormat.format(p.date),
        Offset(layout.xForIndex(p.index), size.height),
        centerHorizontally: true,
        clampX: size.width,
      );
    }
  }

  void _drawLabel(
    Canvas canvas,
    String text,
    Offset anchor, {
    bool anchorMiddle = false,
    bool centerHorizontally = false,
    double? clampX,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: axisColor, fontSize: 9),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();

    double dx = anchor.dx;
    if (centerHorizontally) {
      dx = anchor.dx - tp.width / 2;
    }
    if (clampX != null) {
      dx = dx.clamp(0.0, math.max(0.0, clampX - tp.width));
    }

    double dy = anchor.dy;
    if (anchorMiddle) {
      dy = anchor.dy - tp.height / 2;
    } else {
      // Bottom-axis labels: sit just below the chart baseline.
      dy = anchor.dy - tp.height;
    }
    tp.paint(canvas, Offset(dx, dy));
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashLength = 4.0;
    const gapLength = 3.0;
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final totalLength = math.sqrt(dx * dx + dy * dy);
    if (totalLength == 0) return;
    final unitDx = dx / totalLength;
    final unitDy = dy / totalLength;

    double distance = 0;
    while (distance < totalLength) {
      final dashEnd = math.min(distance + dashLength, totalLength);
      canvas.drawLine(
        Offset(start.dx + unitDx * distance, start.dy + unitDy * distance),
        Offset(start.dx + unitDx * dashEnd, start.dy + unitDy * dashEnd),
        paint,
      );
      distance += dashLength + gapLength;
    }
  }

  @override
  bool shouldRepaint(_PriceChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.color != color ||
        oldDelegate.axisColor != axisColor ||
        oldDelegate.selectedIndex != selectedIndex;
  }
}

/// Resolve the price for [fuelType] from a [PriceRecord]. Exposed for
/// the chart point builder and its tests.
@visibleForTesting
double? priceForFuelType(PriceRecord record, FuelType fuelType) {
  return switch (fuelType) {
    FuelTypeE5() => record.e5,
    FuelTypeE10() => record.e10,
    FuelTypeE98() => record.e98,
    FuelTypeDiesel() => record.diesel,
    FuelTypeDieselPremium() => record.dieselPremium,
    FuelTypeE85() => record.e85,
    FuelTypeLpg() => record.lpg,
    FuelTypeCng() => record.cng,
    FuelTypeHydrogen() || FuelTypeElectric() || FuelTypeAll() => null,
  };
}
