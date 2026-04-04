import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/features/price_history/data/models/price_record.dart';
import 'package:tankstellen/features/price_history/data/repositories/price_history_repository.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

/// Tests for PriceHistoryRepository (the core logic behind the provider).
///
/// We test the repository directly with a fake storage layer because the
/// provider itself is a thin wrapper that delegates to the repository.
void main() {
  group('PriceHistoryRepository', () {
    late _FakePriceHistoryStorage storage;
    late PriceHistoryRepository repo;

    setUp(() {
      storage = _FakePriceHistoryStorage();
      repo = PriceHistoryRepository(storage);
    });

    // -----------------------------------------------------------------------
    // getHistory
    // -----------------------------------------------------------------------
    group('getHistory', () {
      test('returns records for a station within the time window', () async {
        final now = DateTime.now();
        await _seedRecords(repo, 'station-1', [
          PriceRecord(
            stationId: 'station-1',
            recordedAt: now.subtract(const Duration(days: 1)),
            e5: 1.50,
            diesel: 1.30,
          ),
          PriceRecord(
            stationId: 'station-1',
            recordedAt: now.subtract(const Duration(hours: 2)),
            e5: 1.55,
            diesel: 1.35,
          ),
        ]);

        final history = repo.getHistory('station-1', days: 30);
        expect(history, hasLength(2));
        // Newest first
        expect(history.first.e5, 1.55);
        expect(history.last.e5, 1.50);
      });

      test('returns empty list for unknown station', () {
        final history = repo.getHistory('unknown-station', days: 30);
        expect(history, isEmpty);
      });

      test('filters out records older than the window', () async {
        final now = DateTime.now();
        await _seedRecords(repo, 's1', [
          PriceRecord(
            stationId: 's1',
            recordedAt: now.subtract(const Duration(days: 2)),
            e5: 1.50,
          ),
          PriceRecord(
            stationId: 's1',
            recordedAt: now.subtract(const Duration(days: 10)),
            e5: 1.40,
          ),
        ]);

        // Only 3-day window
        final history = repo.getHistory('s1', days: 3);
        expect(history, hasLength(1));
        expect(history.first.e5, 1.50);
      });

      test('returns empty for station with only expired records', () async {
        final now = DateTime.now();
        await _seedRecords(repo, 's1', [
          PriceRecord(
            stationId: 's1',
            recordedAt: now.subtract(const Duration(days: 60)),
            e5: 1.50,
          ),
        ]);

        final history = repo.getHistory('s1', days: 30);
        expect(history, isEmpty);
      });
    });

    // -----------------------------------------------------------------------
    // recordPrice (deduplication)
    // -----------------------------------------------------------------------
    group('recordPrice', () {
      test('records a price snapshot', () async {
        final record = PriceRecord(
          stationId: 's1',
          recordedAt: DateTime.now(),
          e5: 1.55,
          diesel: 1.35,
        );

        await repo.recordPrice(record);

        final history = repo.getHistory('s1');
        expect(history, hasLength(1));
        expect(history.first.e5, 1.55);
      });

      test('deduplicates within 1 hour', () async {
        final now = DateTime.now();
        await repo.recordPrice(PriceRecord(
          stationId: 's1',
          recordedAt: now,
          e5: 1.55,
        ));
        await repo.recordPrice(PriceRecord(
          stationId: 's1',
          recordedAt: now.add(const Duration(minutes: 30)),
          e5: 1.56,
        ));

        final history = repo.getHistory('s1');
        // Second record should be dropped (within 60 minutes).
        expect(history, hasLength(1));
        expect(history.first.e5, 1.55);
      });

      test('records after 1-hour gap', () async {
        final now = DateTime.now();
        await repo.recordPrice(PriceRecord(
          stationId: 's1',
          recordedAt: now.subtract(const Duration(hours: 2)),
          e5: 1.55,
        ));
        await repo.recordPrice(PriceRecord(
          stationId: 's1',
          recordedAt: now,
          e5: 1.60,
        ));

        final history = repo.getHistory('s1');
        expect(history, hasLength(2));
      });
    });

    // -----------------------------------------------------------------------
    // getStats
    // -----------------------------------------------------------------------
    group('getStats', () {
      test('computes min, max, avg for E5 prices', () async {
        final now = DateTime.now();
        await _seedRecords(repo, 's1', [
          PriceRecord(
            stationId: 's1',
            recordedAt: now.subtract(const Duration(days: 3)),
            e5: 1.40,
          ),
          PriceRecord(
            stationId: 's1',
            recordedAt: now.subtract(const Duration(days: 2)),
            e5: 1.50,
          ),
          PriceRecord(
            stationId: 's1',
            recordedAt: now.subtract(const Duration(days: 1)),
            e5: 1.60,
          ),
        ]);

        final stats = repo.getStats('s1', FuelType.e5);
        expect(stats.min, 1.40);
        expect(stats.max, 1.60);
        expect(stats.avg, closeTo(1.50, 0.001));
        expect(stats.current, 1.60); // newest
      });

      test('returns empty PriceStats for unknown station', () {
        final stats = repo.getStats('unknown', FuelType.e5);
        expect(stats.min, isNull);
        expect(stats.max, isNull);
        expect(stats.avg, isNull);
        expect(stats.current, isNull);
        expect(stats.trend, PriceTrend.stable);
      });

      test('returns empty PriceStats when station has no prices for fuel type',
          () async {
        final now = DateTime.now();
        await _seedRecords(repo, 's1', [
          PriceRecord(
            stationId: 's1',
            recordedAt: now.subtract(const Duration(days: 1)),
            diesel: 1.30,
          ),
        ]);

        // Ask for E5 but only diesel is recorded.
        final stats = repo.getStats('s1', FuelType.e5);
        expect(stats.min, isNull);
        expect(stats.max, isNull);
      });

      test('detects upward trend', () async {
        final now = DateTime.now();
        await _seedRecords(repo, 's1', [
          PriceRecord(
            stationId: 's1',
            recordedAt: now.subtract(const Duration(days: 3)),
            e5: 1.40,
          ),
          PriceRecord(
            stationId: 's1',
            recordedAt: now.subtract(const Duration(days: 1)),
            e5: 1.50,
          ),
        ]);

        final stats = repo.getStats('s1', FuelType.e5);
        expect(stats.trend, PriceTrend.up);
      });

      test('detects downward trend', () async {
        final now = DateTime.now();
        await _seedRecords(repo, 's1', [
          PriceRecord(
            stationId: 's1',
            recordedAt: now.subtract(const Duration(days: 3)),
            e5: 1.60,
          ),
          PriceRecord(
            stationId: 's1',
            recordedAt: now.subtract(const Duration(days: 1)),
            e5: 1.40,
          ),
        ]);

        final stats = repo.getStats('s1', FuelType.e5);
        expect(stats.trend, PriceTrend.down);
      });

      test('detects stable trend for small differences', () async {
        final now = DateTime.now();
        await _seedRecords(repo, 's1', [
          PriceRecord(
            stationId: 's1',
            recordedAt: now.subtract(const Duration(days: 3)),
            e5: 1.500,
          ),
          PriceRecord(
            stationId: 's1',
            recordedAt: now.subtract(const Duration(days: 1)),
            e5: 1.504, // diff < 0.005
          ),
        ]);

        final stats = repo.getStats('s1', FuelType.e5);
        expect(stats.trend, PriceTrend.stable);
      });

      test('single record yields stable trend', () async {
        final now = DateTime.now();
        await _seedRecords(repo, 's1', [
          PriceRecord(
            stationId: 's1',
            recordedAt: now.subtract(const Duration(days: 1)),
            e5: 1.50,
          ),
        ]);

        final stats = repo.getStats('s1', FuelType.e5);
        expect(stats.trend, PriceTrend.stable);
        expect(stats.current, 1.50);
        expect(stats.min, 1.50);
        expect(stats.max, 1.50);
      });

      test('computes stats for diesel fuel type', () async {
        final now = DateTime.now();
        await _seedRecords(repo, 's1', [
          PriceRecord(
            stationId: 's1',
            recordedAt: now.subtract(const Duration(days: 2)),
            diesel: 1.30,
          ),
          PriceRecord(
            stationId: 's1',
            recordedAt: now.subtract(const Duration(days: 1)),
            diesel: 1.35,
          ),
        ]);

        final stats = repo.getStats('s1', FuelType.diesel);
        expect(stats.min, 1.30);
        expect(stats.max, 1.35);
        expect(stats.current, 1.35);
      });
    });

    // -----------------------------------------------------------------------
    // evictOldRecords
    // -----------------------------------------------------------------------
    group('evictOldRecords', () {
      test('removes records older than specified days', () async {
        final now = DateTime.now();
        await _seedRecords(repo, 's1', [
          PriceRecord(
            stationId: 's1',
            recordedAt: now.subtract(const Duration(days: 60)),
            e5: 1.40,
          ),
          PriceRecord(
            stationId: 's1',
            recordedAt: now.subtract(const Duration(days: 1)),
            e5: 1.50,
          ),
        ]);

        final removed = await repo.evictOldRecords(days: 30);
        expect(removed, 1);

        final remaining = repo.getHistory('s1', days: 365);
        expect(remaining, hasLength(1));
        expect(remaining.first.e5, 1.50);
      });

      test('returns 0 when nothing to evict', () async {
        final removed = await repo.evictOldRecords(days: 30);
        expect(removed, 0);
      });
    });
  });
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Seed records directly, bypassing the 1-hour dedup by using well-spaced
/// timestamps. We insert via storage to avoid dedup logic.
Future<void> _seedRecords(
  PriceHistoryRepository repo,
  String stationId,
  List<PriceRecord> records,
) async {
  for (final r in records) {
    // Use a direct storage write to bypass dedup.
    // We add records individually with enough time gap.
    await repo.recordPrice(r);
  }
}

/// Fake storage that keeps data in memory.
class _FakePriceHistoryStorage implements PriceHistoryStorage {
  final Map<String, List<Map<String, dynamic>>> _store = {};

  @override
  Future<void> savePriceRecords(
      String stationId, List<Map<String, dynamic>> records) async {
    _store[stationId] = records;
  }

  @override
  List<Map<String, dynamic>> getPriceRecords(String stationId) {
    return _store[stationId] ?? [];
  }

  @override
  List<String> getPriceHistoryKeys() {
    return _store.keys.toList();
  }

  @override
  Future<void> clearPriceHistoryForStation(String stationId) async {
    _store.remove(stationId);
  }

  @override
  Future<void> clearPriceHistory() async {
    _store.clear();
  }

  @override
  int get priceHistoryEntryCount =>
      _store.values.fold(0, (sum, list) => sum + list.length);
}
