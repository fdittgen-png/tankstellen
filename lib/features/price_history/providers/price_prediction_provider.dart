import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../search/domain/entities/fuel_type.dart';
import '../data/models/price_prediction.dart';
import '../data/models/price_record.dart';
import 'price_history_provider.dart';

part 'price_prediction_provider.g.dart';

/// Day-of-week names used for recommendation text.
const _dayNames = {
  1: 'Monday',
  2: 'Tuesday',
  3: 'Wednesday',
  4: 'Thursday',
  5: 'Friday',
  6: 'Saturday',
  7: 'Sunday',
};

/// Computes "best time to fill" predictions from locally stored price history.
///
/// Returns `null` when fewer than 10 data points are available — not enough
/// data to produce meaningful predictions.
@riverpod
PricePrediction? pricePrediction(
  Ref ref,
  String stationId,
  FuelType fuelType,
) {
  final repo = ref.watch(priceHistoryRepositoryProvider);
  final history = repo.getHistory(stationId, days: 30);

  if (history.length < 10) return null;

  // Extract price/time pairs, filtering out records without a price for this
  // fuel type.
  final pairs = <_PriceTime>[];
  for (final record in history) {
    final price = _priceForFuelType(record, fuelType);
    if (price != null) {
      pairs.add(_PriceTime(price: price, time: record.recordedAt));
    }
  }

  if (pairs.length < 10) return null;

  // --- Group by hour of day ---
  final hourBuckets = <int, List<double>>{};
  for (final p in pairs) {
    hourBuckets.putIfAbsent(p.time.hour, () => []).add(p.price);
  }
  final hourlyAverages = hourBuckets.entries.map((e) {
    final avg = e.value.reduce((a, b) => a + b) / e.value.length;
    return HourlyAverage(
      hour: e.key,
      avgPrice: double.parse(avg.toStringAsFixed(4)),
      sampleCount: e.value.length,
    );
  }).toList()
    ..sort((a, b) => a.hour.compareTo(b.hour));

  // --- Group by day of week ---
  final dayBuckets = <int, List<double>>{};
  for (final p in pairs) {
    dayBuckets.putIfAbsent(p.time.weekday, () => []).add(p.price);
  }
  final dailyAverages = dayBuckets.entries.map((e) {
    final avg = e.value.reduce((a, b) => a + b) / e.value.length;
    return DayOfWeekAverage(
      dayOfWeek: e.key,
      avgPrice: double.parse(avg.toStringAsFixed(4)),
      sampleCount: e.value.length,
    );
  }).toList()
    ..sort((a, b) => a.dayOfWeek.compareTo(b.dayOfWeek));

  if (hourlyAverages.isEmpty || dailyAverages.isEmpty) return null;

  // --- Find cheapest / most expensive ---
  final cheapestHour = hourlyAverages.reduce(
    (a, b) => a.avgPrice <= b.avgPrice ? a : b,
  );
  final mostExpensiveHour = hourlyAverages.reduce(
    (a, b) => a.avgPrice >= b.avgPrice ? a : b,
  );
  final cheapestDay = dailyAverages.reduce(
    (a, b) => a.avgPrice <= b.avgPrice ? a : b,
  );

  // --- Potential saving across hours ---
  final hourlySaving = mostExpensiveHour.avgPrice - cheapestHour.avgPrice;
  final potentialSaving =
      hourlySaving > 0.001 ? double.parse(hourlySaving.toStringAsFixed(3)) : null;

  // --- Recommendation text ---
  final dayName = _dayNames[cheapestDay.dayOfWeek] ?? 'Unknown';
  final hourLabel = _formatHourRange(cheapestHour.hour);
  final recommendation = 'Prices typically drop $dayName $hourLabel';

  return PricePrediction(
    recommendation: recommendation,
    potentialSaving: potentialSaving,
    bestHour: cheapestHour.hour,
    bestDayOfWeek: cheapestDay.dayOfWeek,
    hourlyAverages: hourlyAverages,
    dailyAverages: dailyAverages,
  );
}

/// Formats an hour (0-23) as a human-readable time range, e.g. "6-8 PM".
String _formatHourRange(int hour) {
  final startLabel = _formatHour(hour);
  final endLabel = _formatHour((hour + 2) % 24);
  return '$startLabel-$endLabel';
}

String _formatHour(int hour) {
  if (hour == 0) return '12 AM';
  if (hour < 12) return '$hour AM';
  if (hour == 12) return '12 PM';
  return '${hour - 12} PM';
}

double? _priceForFuelType(PriceRecord record, FuelType fuelType) {
  switch (fuelType) {
    case FuelType.e5:
      return record.e5;
    case FuelType.e10:
      return record.e10;
    case FuelType.e98:
      return record.e98;
    case FuelType.diesel:
      return record.diesel;
    case FuelType.dieselPremium:
      return record.dieselPremium;
    case FuelType.e85:
      return record.e85;
    case FuelType.lpg:
      return record.lpg;
    case FuelType.cng:
      return record.cng;
    case FuelType.hydrogen:
    case FuelType.electric:
    case FuelType.all:
      return null;
  }
}

class _PriceTime {
  final double price;
  final DateTime time;
  const _PriceTime({required this.price, required this.time});
}
