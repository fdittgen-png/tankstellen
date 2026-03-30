/// Average price for a specific hour of day (0-23).
class HourlyAverage {
  final int hour; // 0-23
  final double avgPrice;
  final int sampleCount;

  const HourlyAverage({
    required this.hour,
    required this.avgPrice,
    required this.sampleCount,
  });
}

/// Average price for a specific day of week (1=Monday, 7=Sunday).
class DayOfWeekAverage {
  final int dayOfWeek; // 1=Monday, 7=Sunday
  final double avgPrice;
  final int sampleCount;

  const DayOfWeekAverage({
    required this.dayOfWeek,
    required this.avgPrice,
    required this.sampleCount,
  });
}

/// Prediction result computed from local price history data.
class PricePrediction {
  /// Human-readable recommendation, e.g. "Prices typically drop Tuesday evenings"
  final String recommendation;

  /// Estimated saving in EUR/liter between worst and best average times.
  final double? potentialSaving;

  /// Cheapest hour of day (0-23).
  final int bestHour;

  /// Cheapest day of week (1=Monday, 7=Sunday).
  final int bestDayOfWeek;

  /// Average price per hour of day.
  final List<HourlyAverage> hourlyAverages;

  /// Average price per day of week.
  final List<DayOfWeekAverage> dailyAverages;

  const PricePrediction({
    required this.recommendation,
    this.potentialSaving,
    required this.bestHour,
    required this.bestDayOfWeek,
    required this.hourlyAverages,
    required this.dailyAverages,
  });
}
