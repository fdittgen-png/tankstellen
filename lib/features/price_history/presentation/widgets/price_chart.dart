import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../core/theme/fuel_colors.dart';
import '../../../search/domain/entities/fuel_type.dart';
import '../../data/models/price_record.dart';

/// A simple line chart that renders price history using [CustomPainter].
///
/// No external chart library required. Draws a line from oldest (left)
/// to newest (right) with dashed min/max reference lines.
class PriceChart extends StatelessWidget {
  final List<PriceRecord> records;
  final FuelType fuelType;

  const PriceChart({super.key, required this.records, required this.fuelType});

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const SizedBox(
        height: 120,
        child: Center(child: Text('No price history yet')),
      );
    }
    return SizedBox(
      height: 120,
      child: CustomPaint(
        painter: _PriceChartPainter(
          records: records,
          fuelType: fuelType,
          color: FuelColors.forType(fuelType),
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _PriceChartPainter extends CustomPainter {
  final List<PriceRecord> records;
  final FuelType fuelType;
  final Color color;

  _PriceChartPainter({
    required this.records,
    required this.fuelType,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Extract prices for the given fuel type, paired with their index
    // Records are newest-first from the repository, so we reverse for
    // left = oldest, right = newest.
    final reversed = records.reversed.toList();
    final dataPoints = <_DataPoint>[];

    for (int i = 0; i < reversed.length; i++) {
      final price = _priceForFuelType(reversed[i], fuelType);
      if (price != null) {
        dataPoints.add(_DataPoint(index: i, price: price));
      }
    }

    if (dataPoints.isEmpty) return;
    if (dataPoints.length == 1) {
      // Single point: draw a dot in the center
      final dotPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        4,
        dotPaint,
      );
      return;
    }

    // Determine Y axis bounds with a small padding
    final prices = dataPoints.map((d) => d.price).toList();
    final minPrice = prices.reduce(math.min);
    final maxPrice = prices.reduce(math.max);

    // Add 5% padding top and bottom, handle case where min == max
    final range = maxPrice - minPrice;
    final padding = range > 0 ? range * 0.1 : 0.01;
    final yMin = minPrice - padding;
    final yMax = maxPrice + padding;

    // Chart area with insets for labels
    const leftInset = 8.0;
    const rightInset = 8.0;
    const topInset = 8.0;
    const bottomInset = 8.0;

    final chartWidth = size.width - leftInset - rightInset;
    final chartHeight = size.height - topInset - bottomInset;

    double xForIndex(int idx) {
      if (dataPoints.length == 1) return leftInset + chartWidth / 2;
      final first = dataPoints.first.index;
      final last = dataPoints.last.index;
      final totalSpan = last - first;
      if (totalSpan == 0) return leftInset + chartWidth / 2;
      return leftInset + ((idx - first) / totalSpan) * chartWidth;
    }

    double yForPrice(double price) {
      return topInset + chartHeight - ((price - yMin) / (yMax - yMin)) * chartHeight;
    }

    // Draw dashed horizontal lines for min and max
    _drawDashedLine(
      canvas,
      Offset(leftInset, yForPrice(minPrice)),
      Offset(size.width - rightInset, yForPrice(minPrice)),
      Paint()
        ..color = color.withAlpha(60)
        ..strokeWidth = 1,
    );
    _drawDashedLine(
      canvas,
      Offset(leftInset, yForPrice(maxPrice)),
      Offset(size.width - rightInset, yForPrice(maxPrice)),
      Paint()
        ..color = color.withAlpha(60)
        ..strokeWidth = 1,
    );

    // Draw the price line
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(
      xForIndex(dataPoints.first.index),
      yForPrice(dataPoints.first.price),
    );
    for (int i = 1; i < dataPoints.length; i++) {
      path.lineTo(
        xForIndex(dataPoints[i].index),
        yForPrice(dataPoints[i].price),
      );
    }
    canvas.drawPath(path, linePaint);

    // Draw gradient fill under the line
    final fillPath = Path.from(path);
    fillPath.lineTo(xForIndex(dataPoints.last.index), size.height - bottomInset);
    fillPath.lineTo(xForIndex(dataPoints.first.index), size.height - bottomInset);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0, topInset),
        Offset(0, size.height - bottomInset),
        [color.withAlpha(40), color.withAlpha(5)],
      );
    canvas.drawPath(fillPath, fillPaint);

    // Draw dots at each data point
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    for (final dp in dataPoints) {
      canvas.drawCircle(
        Offset(xForIndex(dp.index), yForPrice(dp.price)),
        3,
        dotPaint,
      );
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashLength = 4.0;
    const gapLength = 3.0;
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final totalLength = math.sqrt(dx * dx + dy * dy);
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

  double? _priceForFuelType(PriceRecord record, FuelType fuelType) {
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

  @override
  bool shouldRepaint(_PriceChartPainter oldDelegate) {
    return oldDelegate.records != records ||
        oldDelegate.fuelType != fuelType ||
        oldDelegate.color != color;
  }
}

class _DataPoint {
  final int index;
  final double price;

  const _DataPoint({required this.index, required this.price});
}
