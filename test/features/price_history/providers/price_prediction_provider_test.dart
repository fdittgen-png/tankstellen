import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/features/price_history/data/models/price_record.dart';
import 'package:tankstellen/features/price_history/data/repositories/price_history_repository.dart';
import 'package:tankstellen/features/price_history/providers/price_history_provider.dart';
import 'package:tankstellen/features/price_history/providers/price_prediction_provider.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

/// Tests for the [pricePredictionProvider].
///
/// Drives the real provider via [ProviderContainer] with an overridden
/// [priceHistoryRepositoryProvider] that returns predetermined price
/// records. Covers all branches of the "best time to fill" computation.
void main() {
  ProviderContainer makeContainer(List<PriceRecord> records) {
    final repo = _FakePriceHistoryRepository(records);
    final c = ProviderContainer(overrides: [
      priceHistoryRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  group('pricePrediction — null cases', () {
    test('returns null when history has fewer than 10 records', () {
      final records = List.generate(
        9,
        (i) => PriceRecord(
          stationId: 's1',
          recordedAt: DateTime(2026, 3, 1, i),
          e10: 1.50 + i * 0.001,
        ),
      );

      final container = makeContainer(records);
      final result = container.read(pricePredictionProvider('s1', FuelType.e10));

      expect(result, isNull);
    });

    test('returns null when fewer than 10 records have a price for the requested fuel', () {
      // 12 records but only 9 have e10 set.
      final records = <PriceRecord>[
        for (int i = 0; i < 9; i++)
          PriceRecord(
            stationId: 's1',
            recordedAt: DateTime(2026, 3, 1, i),
            e10: 1.50 + i * 0.001,
          ),
        for (int i = 0; i < 3; i++)
          PriceRecord(
            stationId: 's1',
            recordedAt: DateTime(2026, 3, 2, i),
            diesel: 1.40, // no e10 set
          ),
      ];

      final container = makeContainer(records);
      final result = container.read(pricePredictionProvider('s1', FuelType.e10));

      expect(result, isNull);
    });

    test('returns null for FuelType.hydrogen even when 10+ records exist', () {
      final records = List.generate(
        12,
        (i) => PriceRecord(
          stationId: 's1',
          recordedAt: DateTime(2026, 3, 1, i),
          e10: 1.50,
          e5: 1.55,
          diesel: 1.40,
        ),
      );

      final container = makeContainer(records);
      final result = container.read(pricePredictionProvider('s1', FuelType.hydrogen));

      expect(result, isNull);
    });

    test('returns null for FuelType.electric even when 10+ records exist', () {
      final records = List.generate(
        12,
        (i) => PriceRecord(
          stationId: 's1',
          recordedAt: DateTime(2026, 3, 1, i),
          e10: 1.50,
        ),
      );

      final container = makeContainer(records);
      final result = container.read(pricePredictionProvider('s1', FuelType.electric));

      expect(result, isNull);
    });

    test('returns null for FuelType.all even when 10+ records exist', () {
      final records = List.generate(
        12,
        (i) => PriceRecord(
          stationId: 's1',
          recordedAt: DateTime(2026, 3, 1, i),
          e10: 1.50,
        ),
      );

      final container = makeContainer(records);
      final result = container.read(pricePredictionProvider('s1', FuelType.all));

      expect(result, isNull);
    });
  });

  group('pricePrediction — successful computation', () {
    test('returns a non-null PricePrediction with populated averages', () {
      // 5 days × 2 hours = 10 records spread across hours and weekdays.
      final records = <PriceRecord>[];
      for (int day = 2; day <= 6; day++) {
        records.add(PriceRecord(
          stationId: 's1',
          recordedAt: DateTime(2026, 3, day, 8),
          e10: 1.50,
        ));
        records.add(PriceRecord(
          stationId: 's1',
          recordedAt: DateTime(2026, 3, day, 18),
          e10: 1.60,
        ));
      }

      final container = makeContainer(records);
      final result = container.read(pricePredictionProvider('s1', FuelType.e10));

      expect(result, isNotNull);
      expect(result!.hourlyAverages, isNotEmpty);
      expect(result.dailyAverages, isNotEmpty);
      expect(result.recommendation, startsWith('Prices typically drop'));
    });

    test('groups same-hour samples into one HourlyAverage with mean price', () {
      // 12 records all at hour 14 with two distinct prices alternating.
      final records = <PriceRecord>[];
      for (int i = 0; i < 12; i++) {
        records.add(PriceRecord(
          stationId: 's1',
          recordedAt: DateTime(2026, 3, 1 + i, 14),
          e10: i.isEven ? 1.40 : 1.50,
        ));
      }

      final container = makeContainer(records);
      final result = container.read(pricePredictionProvider('s1', FuelType.e10));

      expect(result, isNotNull);
      expect(result!.hourlyAverages, hasLength(1));
      final h = result.hourlyAverages.single;
      expect(h.hour, 14);
      expect(h.sampleCount, 12);
      // Mean of six 1.40s and six 1.50s = 1.45, rounded to 4 decimals.
      expect(h.avgPrice, closeTo(1.45, 0.0001));
    });

    test('groups same-weekday samples into one DayOfWeekAverage', () {
      // 12 records all on Mondays (DateTime(2026, 3, 2) is a Monday).
      final records = <PriceRecord>[];
      for (int week = 0; week < 6; week++) {
        for (int hour = 8; hour < 10; hour++) {
          records.add(PriceRecord(
            stationId: 's1',
            recordedAt: DateTime(2026, 3, 2 + week * 7, hour),
            e10: 1.50,
          ));
        }
      }

      // Sanity: ensure weekday is Monday (==1).
      expect(records.first.recordedAt.weekday, 1);

      final container = makeContainer(records);
      final result = container.read(pricePredictionProvider('s1', FuelType.e10));

      expect(result, isNotNull);
      expect(result!.dailyAverages, hasLength(1));
      expect(result.dailyAverages.single.dayOfWeek, 1);
      expect(result.dailyAverages.single.sampleCount, 12);
    });

    test('selects the cheapest hour as bestHour', () {
      // Three hours, 4 records each. Hour 20 is cheapest.
      final records = <PriceRecord>[];
      for (int day = 1; day <= 4; day++) {
        records.add(PriceRecord(
          stationId: 's1',
          recordedAt: DateTime(2026, 3, day, 8),
          e10: 1.55,
        ));
        records.add(PriceRecord(
          stationId: 's1',
          recordedAt: DateTime(2026, 3, day, 14),
          e10: 1.60,
        ));
        records.add(PriceRecord(
          stationId: 's1',
          recordedAt: DateTime(2026, 3, day, 20),
          e10: 1.40,
        ));
      }

      final container = makeContainer(records);
      final result = container.read(pricePredictionProvider('s1', FuelType.e10));

      expect(result, isNotNull);
      expect(result!.bestHour, 20);
    });

    test('selects the cheapest weekday as bestDayOfWeek', () {
      // Make Wednesday clearly cheapest. DateTime(2026, 3, 4) is a Wednesday.
      final records = <PriceRecord>[];
      // 5 expensive Mondays.
      for (int w = 0; w < 5; w++) {
        records.add(PriceRecord(
          stationId: 's1',
          recordedAt: DateTime(2026, 3, 2 + w * 7, 10),
          e10: 1.60,
        ));
      }
      // 5 cheap Wednesdays.
      for (int w = 0; w < 5; w++) {
        records.add(PriceRecord(
          stationId: 's1',
          recordedAt: DateTime(2026, 3, 4 + w * 7, 10),
          e10: 1.30,
        ));
      }

      // Sanity check.
      expect(DateTime(2026, 3, 2).weekday, 1); // Monday
      expect(DateTime(2026, 3, 4).weekday, 3); // Wednesday

      final container = makeContainer(records);
      final result = container.read(pricePredictionProvider('s1', FuelType.e10));

      expect(result, isNotNull);
      expect(result!.bestDayOfWeek, 3);
      expect(result.recommendation, contains('Wednesday'));
    });

    test('potentialSaving equals max-min hourly avg rounded to 3 decimals', () {
      final records = <PriceRecord>[];
      for (int day = 1; day <= 5; day++) {
        records.add(PriceRecord(
          stationId: 's1',
          recordedAt: DateTime(2026, 3, day, 6),
          diesel: 1.40,
        ));
        records.add(PriceRecord(
          stationId: 's1',
          recordedAt: DateTime(2026, 3, day, 18),
          diesel: 1.60,
        ));
      }

      final container = makeContainer(records);
      final result = container.read(pricePredictionProvider('s1', FuelType.diesel));

      expect(result, isNotNull);
      // Range is exactly 0.20.
      expect(result!.potentialSaving, closeTo(0.20, 0.0001));
    });

    test('potentialSaving is null when hourly range is <= 0.001', () {
      // All hourly averages effectively identical -> diff <= 0.001.
      final records = <PriceRecord>[];
      for (int day = 1; day <= 6; day++) {
        records.add(PriceRecord(
          stationId: 's1',
          recordedAt: DateTime(2026, 3, day, 6),
          e10: 1.500,
        ));
        records.add(PriceRecord(
          stationId: 's1',
          recordedAt: DateTime(2026, 3, day, 18),
          e10: 1.500,
        ));
      }

      final container = makeContainer(records);
      final result = container.read(pricePredictionProvider('s1', FuelType.e10));

      expect(result, isNotNull);
      expect(result!.potentialSaving, isNull);
    });

    test('recommendation contains the cheapest day name and hour range', () {
      // Same as above 'cheapest weekday' fixture: cheapest day is Wednesday.
      final records = <PriceRecord>[];
      for (int w = 0; w < 5; w++) {
        records.add(PriceRecord(
          stationId: 's1',
          recordedAt: DateTime(2026, 3, 2 + w * 7, 10),
          e10: 1.60,
        ));
      }
      for (int w = 0; w < 5; w++) {
        records.add(PriceRecord(
          stationId: 's1',
          recordedAt: DateTime(2026, 3, 4 + w * 7, 10),
          e10: 1.30,
        ));
      }

      final container = makeContainer(records);
      final result = container.read(pricePredictionProvider('s1', FuelType.e10));

      expect(result, isNotNull);
      expect(result!.recommendation, contains('Wednesday'));
      // bestHour will be 10 -> "10 AM-12 PM".
      expect(result.recommendation, contains('10 AM-12 PM'));
    });
  });

  group('pricePrediction — hour-range formatting', () {
    test('formats morning hours as "<n> AM-<m> AM" (e.g. 6 AM-8 AM)', () {
      // Make hour 6 cheapest; we expect "6 AM-8 AM" in the recommendation.
      final result = _runWithCheapestHour(makeContainer, hour: 6);
      expect(result.recommendation, contains('6 AM-8 AM'));
    });

    test('formats midnight as "12 AM-2 AM" when bestHour is 0', () {
      final result = _runWithCheapestHour(makeContainer, hour: 0);
      expect(result.recommendation, contains('12 AM-2 AM'));
    });

    test('formats noon as "12 PM-2 PM" when bestHour is 12', () {
      final result = _runWithCheapestHour(makeContainer, hour: 12);
      expect(result.recommendation, contains('12 PM-2 PM'));
    });

    test('wraps PM to AM as "11 PM-1 AM" when bestHour is 23', () {
      final result = _runWithCheapestHour(makeContainer, hour: 23);
      expect(result.recommendation, contains('11 PM-1 AM'));
    });
  });

  group('pricePrediction — covers every supported FuelType', () {
    // For each fuel field, feed 12 records with that field set; assert non-null.
    test('FuelType.e5', () {
      final records = List.generate(
        12,
        (i) => PriceRecord(
          stationId: 's1',
          recordedAt: DateTime(2026, 3, 1 + i, 10 + (i % 3)),
          e5: 1.50 + (i % 3) * 0.05,
        ),
      );
      final container = makeContainer(records);
      final result = container.read(pricePredictionProvider('s1', FuelType.e5));
      expect(result, isNotNull);
    });

    test('FuelType.e10', () {
      final records = List.generate(
        12,
        (i) => PriceRecord(
          stationId: 's1',
          recordedAt: DateTime(2026, 3, 1 + i, 10 + (i % 3)),
          e10: 1.50 + (i % 3) * 0.05,
        ),
      );
      final container = makeContainer(records);
      final result = container.read(pricePredictionProvider('s1', FuelType.e10));
      expect(result, isNotNull);
    });

    test('FuelType.e98', () {
      final records = List.generate(
        12,
        (i) => PriceRecord(
          stationId: 's1',
          recordedAt: DateTime(2026, 3, 1 + i, 10 + (i % 3)),
          e98: 1.70 + (i % 3) * 0.05,
        ),
      );
      final container = makeContainer(records);
      final result = container.read(pricePredictionProvider('s1', FuelType.e98));
      expect(result, isNotNull);
    });

    test('FuelType.diesel', () {
      final records = List.generate(
        12,
        (i) => PriceRecord(
          stationId: 's1',
          recordedAt: DateTime(2026, 3, 1 + i, 10 + (i % 3)),
          diesel: 1.40 + (i % 3) * 0.05,
        ),
      );
      final container = makeContainer(records);
      final result = container.read(pricePredictionProvider('s1', FuelType.diesel));
      expect(result, isNotNull);
    });

    test('FuelType.dieselPremium', () {
      final records = List.generate(
        12,
        (i) => PriceRecord(
          stationId: 's1',
          recordedAt: DateTime(2026, 3, 1 + i, 10 + (i % 3)),
          dieselPremium: 1.55 + (i % 3) * 0.05,
        ),
      );
      final container = makeContainer(records);
      final result = container.read(pricePredictionProvider('s1', FuelType.dieselPremium));
      expect(result, isNotNull);
    });

    test('FuelType.e85', () {
      final records = List.generate(
        12,
        (i) => PriceRecord(
          stationId: 's1',
          recordedAt: DateTime(2026, 3, 1 + i, 10 + (i % 3)),
          e85: 1.00 + (i % 3) * 0.05,
        ),
      );
      final container = makeContainer(records);
      final result = container.read(pricePredictionProvider('s1', FuelType.e85));
      expect(result, isNotNull);
    });

    test('FuelType.lpg', () {
      final records = List.generate(
        12,
        (i) => PriceRecord(
          stationId: 's1',
          recordedAt: DateTime(2026, 3, 1 + i, 10 + (i % 3)),
          lpg: 0.90 + (i % 3) * 0.05,
        ),
      );
      final container = makeContainer(records);
      final result = container.read(pricePredictionProvider('s1', FuelType.lpg));
      expect(result, isNotNull);
    });

    test('FuelType.cng', () {
      final records = List.generate(
        12,
        (i) => PriceRecord(
          stationId: 's1',
          recordedAt: DateTime(2026, 3, 1 + i, 10 + (i % 3)),
          cng: 1.20 + (i % 3) * 0.05,
        ),
      );
      final container = makeContainer(records);
      final result = container.read(pricePredictionProvider('s1', FuelType.cng));
      expect(result, isNotNull);
    });
  });
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Builds 10 records all at [hour] with e10 set, to make `bestHour == hour`.
PricePredictionResult _runWithCheapestHour(
  ProviderContainer Function(List<PriceRecord>) makeContainer, {
  required int hour,
}) {
  final records = <PriceRecord>[
    for (int i = 0; i < 12; i++)
      PriceRecord(
        stationId: 's1',
        recordedAt: DateTime(2026, 3, 1 + i, hour),
        e10: 1.40,
      ),
  ];
  final container = makeContainer(records);
  final result = container.read(pricePredictionProvider('s1', FuelType.e10));
  expect(result, isNotNull, reason: 'Expected prediction for hour $hour');
  expect(result!.bestHour, hour);
  return PricePredictionResult(result.recommendation);
}

/// Tiny wrapper so the helper can return only what we need without leaking
/// the full PricePrediction type to callers (which would force an import in
/// test helpers).
class PricePredictionResult {
  final String recommendation;
  const PricePredictionResult(this.recommendation);
}

/// Fake [PriceHistoryRepository] that returns a predetermined record list
/// from [getHistory] without touching storage.
class _FakePriceHistoryRepository extends PriceHistoryRepository {
  final List<PriceRecord> _records;

  _FakePriceHistoryRepository(this._records) : super(_NullStorage());

  @override
  List<PriceRecord> getHistory(String stationId, {int days = 30}) {
    return List.of(_records);
  }
}

/// Stub [PriceHistoryStorage] used only to satisfy the
/// [PriceHistoryRepository] constructor — never actually invoked because
/// [_FakePriceHistoryRepository.getHistory] is overridden.
class _NullStorage implements PriceHistoryStorage {
  @override
  List<Map<String, dynamic>> getPriceRecords(String stationId) => const [];

  @override
  Future<void> savePriceRecords(
      String stationId, List<Map<String, dynamic>> records) async {}

  @override
  List<String> getPriceHistoryKeys() => const [];

  @override
  Future<void> clearPriceHistoryForStation(String stationId) async {}

  @override
  Future<void> clearPriceHistory() async {}

  @override
  int get priceHistoryEntryCount => 0;
}
