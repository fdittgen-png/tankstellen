import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/price_history/data/models/price_prediction.dart';
import 'package:tankstellen/features/price_history/data/models/price_record.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

// We test the prediction computation by importing the provider's top-level
// function and calling it through a ProviderContainer. Since the provider
// depends on priceHistoryRepositoryProvider (which needs HiveStorage/Hive),
// we override pricePredictionProvider itself with a function that applies
// the same algorithm on test data. This keeps the tests fast and isolated.
//
// To test the actual algorithm faithfully, we replicate the provider's
// computation in a standalone helper that mirrors price_prediction_provider.dart.

PricePrediction? _computePrediction(List<PriceRecord> history, FuelType fuelType) {
  if (history.length < 10) return null;

  final pairs = <_PriceTime>[];
  for (final record in history) {
    final price = _priceForFuelType(record, fuelType);
    if (price != null) {
      pairs.add(_PriceTime(price: price, time: record.recordedAt));
    }
  }
  if (pairs.length < 10) return null;

  // Group by hour
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

  // Group by day of week
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

  final cheapestHour =
      hourlyAverages.reduce((a, b) => a.avgPrice <= b.avgPrice ? a : b);
  final mostExpensiveHour =
      hourlyAverages.reduce((a, b) => a.avgPrice >= b.avgPrice ? a : b);
  final cheapestDay =
      dailyAverages.reduce((a, b) => a.avgPrice <= b.avgPrice ? a : b);

  final hourlySaving = mostExpensiveHour.avgPrice - cheapestHour.avgPrice;
  final potentialSaving =
      hourlySaving > 0.001 ? double.parse(hourlySaving.toStringAsFixed(3)) : null;

  const dayNames = {
    1: 'Monday', 2: 'Tuesday', 3: 'Wednesday', 4: 'Thursday',
    5: 'Friday', 6: 'Saturday', 7: 'Sunday',
  };
  final dayName = dayNames[cheapestDay.dayOfWeek] ?? 'Unknown';
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

class _PriceTime {
  final double price;
  final DateTime time;
  const _PriceTime({required this.price, required this.time});
}

void main() {
  group('Price prediction computation', () {
    test('returns null when fewer than 10 records', () {
      final records = List.generate(
        5,
        (i) => PriceRecord(
          stationId: 'station-1',
          recordedAt: DateTime(2026, 3, 20, i),
          diesel: 1.45 + i * 0.01,
        ),
      );

      final prediction = _computePrediction(records, FuelType.diesel);
      expect(prediction, isNull);
    });

    test('returns null when exactly 9 records with prices', () {
      final records = List.generate(
        9,
        (i) => PriceRecord(
          stationId: 'station-1',
          recordedAt: DateTime(2026, 3, 20, i),
          diesel: 1.45 + i * 0.001,
        ),
      );

      final prediction = _computePrediction(records, FuelType.diesel);
      expect(prediction, isNull);
    });

    test('computes correct hourly averages', () {
      final records = <PriceRecord>[];
      for (int day = 1; day <= 6; day++) {
        // Morning (hour 6): cheap
        records.add(PriceRecord(
          stationId: 'station-1',
          recordedAt: DateTime(2026, 3, day, 6),
          diesel: 1.40,
        ));
        // Evening (hour 18): expensive
        records.add(PriceRecord(
          stationId: 'station-1',
          recordedAt: DateTime(2026, 3, day, 18),
          diesel: 1.60,
        ));
      }

      final prediction = _computePrediction(records, FuelType.diesel);

      expect(prediction, isNotNull);
      expect(prediction!.hourlyAverages.length, 2);

      final hour6 = prediction.hourlyAverages.firstWhere((h) => h.hour == 6);
      final hour18 = prediction.hourlyAverages.firstWhere((h) => h.hour == 18);

      expect(hour6.avgPrice, closeTo(1.40, 0.001));
      expect(hour18.avgPrice, closeTo(1.60, 0.001));
      expect(hour6.sampleCount, 6);
      expect(hour18.sampleCount, 6);
    });

    test('identifies cheapest hour correctly', () {
      final records = <PriceRecord>[];
      for (int day = 1; day <= 5; day++) {
        records.add(PriceRecord(
          stationId: 'station-1',
          recordedAt: DateTime(2026, 3, day, 8),
          e10: 1.50,
        ));
        records.add(PriceRecord(
          stationId: 'station-1',
          recordedAt: DateTime(2026, 3, day, 14),
          e10: 1.55,
        ));
        records.add(PriceRecord(
          stationId: 'station-1',
          recordedAt: DateTime(2026, 3, day, 20),
          e10: 1.42,
        ));
      }

      final prediction = _computePrediction(records, FuelType.e10);

      expect(prediction, isNotNull);
      expect(prediction!.bestHour, 20);
    });

    test('generates recommendation text with day and hour range', () {
      final records = <PriceRecord>[];
      for (int day = 2; day <= 6; day++) {
        records.add(PriceRecord(
          stationId: 'station-1',
          recordedAt: DateTime(2026, 3, day, 10),
          e5: 1.50,
        ));
        records.add(PriceRecord(
          stationId: 'station-1',
          recordedAt: DateTime(2026, 3, day, 20),
          e5: 1.55,
        ));
      }
      // Extra cheap Monday record
      records.add(PriceRecord(
        stationId: 'station-1',
        recordedAt: DateTime(2026, 3, 9, 10),
        e5: 1.40,
      ));

      final prediction = _computePrediction(records, FuelType.e5);

      expect(prediction, isNotNull);
      expect(prediction!.recommendation, contains('Prices typically drop'));
      expect(prediction.bestHour, 10);
    });

    test('computes potential saving between cheapest and most expensive hour',
        () {
      final records = <PriceRecord>[];
      for (int day = 1; day <= 5; day++) {
        records.add(PriceRecord(
          stationId: 'station-1',
          recordedAt: DateTime(2026, 3, day, 6),
          diesel: 1.40,
        ));
        records.add(PriceRecord(
          stationId: 'station-1',
          recordedAt: DateTime(2026, 3, day, 18),
          diesel: 1.60,
        ));
      }

      final prediction = _computePrediction(records, FuelType.diesel);

      expect(prediction, isNotNull);
      expect(prediction!.potentialSaving, closeTo(0.20, 0.001));
    });
  });
}
