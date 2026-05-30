// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:math' as math;
import 'dart:ui';

/// One plottable point of the price-history chart: its source index
/// (oldest→newest ordinal), the price for the selected fuel, and the
/// timestamp it was recorded.
class ChartPoint {
  final int index;
  final double price;
  final DateTime date;

  const ChartPoint({
    required this.index,
    required this.price,
    required this.date,
  });
}

/// Pure layout maths for [PriceChart] — kept out of the painter so the
/// painter file stays small and the projection / tick / hit-test logic
/// is unit-testable without a canvas.
class PriceChartLayout {
  /// Inset reserved on the left for the €-axis labels.
  static const double leftInset = 44.0;
  static const double rightInset = 8.0;
  static const double topInset = 10.0;

  /// Inset reserved at the bottom for the date labels.
  static const double bottomInset = 16.0;

  final double minPrice;
  final double maxPrice;
  final double yMin;
  final double yMax;
  final double left;
  final double right;
  final double top;
  final double bottom;
  final double chartWidth;
  final double chartHeight;
  final int firstIndex;
  final int lastIndex;

  /// Prices to label on the Y axis (min / mid / max).
  final List<double> priceTicks;

  /// Data-point ordinals to label on the X axis.
  final List<int> dateTicks;

  const PriceChartLayout({
    required this.minPrice,
    required this.maxPrice,
    required this.yMin,
    required this.yMax,
    required this.left,
    required this.right,
    required this.top,
    required this.bottom,
    required this.chartWidth,
    required this.chartHeight,
    required this.firstIndex,
    required this.lastIndex,
    required this.priceTicks,
    required this.dateTicks,
  });

  double xForIndex(int idx) {
    final span = lastIndex - firstIndex;
    if (span == 0) return left + chartWidth / 2;
    return left + ((idx - firstIndex) / span) * chartWidth;
  }

  double yForPrice(double price) {
    final span = yMax - yMin;
    if (span == 0) return top + chartHeight / 2;
    return top + chartHeight - ((price - yMin) / span) * chartHeight;
  }
}

/// Static façade for chart geometry: layout, tick selection and
/// nearest-point hit-testing.
class PriceChartAxes {
  PriceChartAxes._();

  static PriceChartLayout layout(Size size, List<ChartPoint> points) {
    final prices = points.map((p) => p.price).toList();
    final minPrice = prices.reduce(math.min);
    final maxPrice = prices.reduce(math.max);

    final range = maxPrice - minPrice;
    final padding = range > 0 ? range * 0.1 : 0.01;
    final yMin = minPrice - padding;
    final yMax = maxPrice + padding;

    const left = PriceChartLayout.leftInset;
    final right = size.width - PriceChartLayout.rightInset;
    const top = PriceChartLayout.topInset;
    final bottom = size.height - PriceChartLayout.bottomInset;
    final chartWidth = math.max(0.0, right - left);
    final chartHeight = math.max(0.0, bottom - top);

    // Price ticks: min, mid, max — but collapse to a single value when the
    // series is flat so we never print three identical labels.
    final List<double> priceTicks;
    if (range > 0) {
      priceTicks = [minPrice, (minPrice + maxPrice) / 2, maxPrice];
    } else {
      priceTicks = [minPrice];
    }

    return PriceChartLayout(
      minPrice: minPrice,
      maxPrice: maxPrice,
      yMin: yMin,
      yMax: yMax,
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      chartWidth: chartWidth,
      chartHeight: chartHeight,
      firstIndex: points.first.index,
      lastIndex: points.last.index,
      priceTicks: priceTicks,
      dateTicks: _dateTicks(points, chartWidth),
    );
  }

  /// Choose which data points get a date label. Always the first and last;
  /// a middle tick is added when there is room (>~150 logical px) so labels
  /// (~36 px wide for `dd.MM`) never overlap.
  static List<int> _dateTicks(List<ChartPoint> points, double chartWidth) {
    if (points.length < 2) return [0];
    final ticks = <int>{0, points.length - 1};
    if (chartWidth > 150 && points.length >= 3) {
      ticks.add(points.length ~/ 2);
    }
    final list = ticks.toList()..sort();
    return list;
  }

  /// Index into [points] of the point whose plotted x is nearest [localPos].
  static int nearestPointIndex(
    Offset localPos,
    Size size,
    List<ChartPoint> points,
  ) {
    final l = layout(size, points);
    int best = 0;
    double bestDist = double.infinity;
    for (int i = 0; i < points.length; i++) {
      final dx = (l.xForIndex(points[i].index) - localPos.dx).abs();
      if (dx < bestDist) {
        bestDist = dx;
        best = i;
      }
    }
    return best;
  }
}
