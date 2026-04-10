/// Trend direction for a fuel price over a time window.
enum PriceTrend { up, down, stable }

/// Aggregate statistics for a single fuel type at a station.
///
/// Pure value object with no persistence concerns — safe to import from the
/// presentation layer.
class PriceStats {
  final double? min;
  final double? max;
  final double? avg;
  final double? current;
  final PriceTrend trend;

  const PriceStats({
    this.min,
    this.max,
    this.avg,
    this.current,
    this.trend = PriceTrend.stable,
  });
}
