import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/price_prediction.dart';

/// A vertical bar chart showing average price by hour of day (0-23).
///
/// Uses [CustomPainter] following the same pattern as [PriceChart].
/// The cheapest hour bar is drawn in green, the most expensive in red,
/// and the rest use the theme primary colour.
class HourlyPriceChart extends StatelessWidget {
  final List<HourlyAverage> hourlyAverages;

  const HourlyPriceChart({super.key, required this.hourlyAverages});

  @override
  Widget build(BuildContext context) {
    if (hourlyAverages.isEmpty) {
      final l = AppLocalizations.of(context);
      return SizedBox(
        height: 140,
        child: Center(child: Text(l?.noHourlyData ?? 'No hourly data')),
      );
    }
    return SizedBox(
      height: 140,
      child: CustomPaint(
        painter: _HourlyPriceChartPainter(
          hourlyAverages: hourlyAverages,
          primaryColor: Theme.of(context).colorScheme.primary,
          textColor: Theme.of(context).colorScheme.onSurface,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _HourlyPriceChartPainter extends CustomPainter {
  final List<HourlyAverage> hourlyAverages;
  final Color primaryColor;
  final Color textColor;

  _HourlyPriceChartPainter({
    required this.hourlyAverages,
    required this.primaryColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (hourlyAverages.isEmpty) return;

    final prices = hourlyAverages.map((h) => h.avgPrice).toList();
    final minPrice = prices.reduce(math.min);
    final maxPrice = prices.reduce(math.max);

    // Padding around the chart area to make room for labels.
    const topInset = 8.0;
    const bottomInset = 20.0;
    const leftInset = 4.0;
    const rightInset = 4.0;

    final chartWidth = size.width - leftInset - rightInset;
    final chartHeight = size.height - topInset - bottomInset;

    // Each bar gets equal width with a small gap.
    final barCount = hourlyAverages.length;
    final totalBarWidth = chartWidth / barCount;
    final gap = totalBarWidth * 0.2;
    final barWidth = totalBarWidth - gap;

    // Y-axis scaling — handle flat prices gracefully.
    final range = maxPrice - minPrice;
    final effectiveRange = range > 0 ? range : 0.01;
    // Bars should fill at least 20% height even at the minimum.
    const minBarFraction = 0.2;

    for (int i = 0; i < hourlyAverages.length; i++) {
      final h = hourlyAverages[i];
      final normalised = range > 0
          ? (h.avgPrice - minPrice) / effectiveRange
          : 0.5;
      final barHeight =
          (minBarFraction + normalised * (1.0 - minBarFraction)) * chartHeight;

      final x = leftInset + i * totalBarWidth + gap / 2;
      final y = topInset + chartHeight - barHeight;

      // Colour: green for cheapest, red for most expensive, primary otherwise.
      Color barColor;
      if (h.avgPrice == minPrice && range > 0) {
        barColor = Colors.green;
      } else if (h.avgPrice == maxPrice && range > 0) {
        barColor = Colors.red.shade400;
      } else {
        barColor = primaryColor.withAlpha(160);
      }

      final barPaint = Paint()
        ..color = barColor
        ..style = PaintingStyle.fill;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        const Radius.circular(3),
      );
      canvas.drawRRect(rect, barPaint);

      // Draw hour label below bar (only every 3 hours to avoid crowding).
      if (h.hour % 3 == 0) {
        final textSpan = TextSpan(
          text: '${h.hour}',
          style: TextStyle(color: textColor.withAlpha(160), fontSize: 9),
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        )..layout();
        textPainter.paint(
          canvas,
          Offset(
            x + barWidth / 2 - textPainter.width / 2,
            topInset + chartHeight + 4,
          ),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_HourlyPriceChartPainter oldDelegate) {
    return oldDelegate.hourlyAverages != hourlyAverages ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.textColor != textColor;
  }
}
