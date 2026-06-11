// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/features/price_history/data/models/price_record.dart';
import 'package:tankstellen/features/price_history/data/repositories/price_history_repository.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';

/// In-memory [PriceHistoryStorage] so the repository can be unit-tested
/// without Hive.
class _FakePriceHistoryStorage implements PriceHistoryStorage {
  final Map<String, List<Map<String, dynamic>>> _store = {};

  @override
  List<Map<String, dynamic>> getPriceRecords(String stationId) =>
      _store[stationId] ?? const [];

  @override
  Future<void> savePriceRecords(
      String stationId, List<Map<String, dynamic>> records) async {
    _store[stationId] = records;
  }

  @override
  List<String> getPriceHistoryKeys() => _store.keys.toList();

  @override
  Future<void> clearPriceHistoryForStation(String stationId) async {
    _store.remove(stationId);
  }

  @override
  Future<void> clearPriceHistory() async => _store.clear();

  @override
  int get priceHistoryEntryCount =>
      _store.values.fold(0, (sum, list) => sum + list.length);

  /// Test-only: seed raw record maps directly (used to inject malformed
  /// JSON the parser must recover from).
  void seedRaw(String stationId, List<Map<String, dynamic>> raw) {
    _store[stationId] = raw;
  }
}

/// Unit tests for [PriceHistoryRepository] (epic #1612, child #1629).
void main() {
  late _FakePriceHistoryStorage storage;
  late PriceHistoryRepository repo;

  setUp(() {
    storage = _FakePriceHistoryStorage();
    repo = PriceHistoryRepository(storage);
  });

  PriceRecord record(String stationId, DateTime at, {double? e5}) =>
      PriceRecord(stationId: stationId, recordedAt: at, e5: e5);

  group('recordPrice — 1-hour dedup window', () {
    test('stores the first record for a station', () async {
      await repo.recordPrice(record('s1', DateTime(2026, 5, 15, 12), e5: 1.7));
      expect(repo.getHistory('s1', days: 3650), hasLength(1));
    });

    test('drops a second record logged within 60 minutes', () async {
      await repo.recordPrice(record('s1', DateTime(2026, 5, 15, 12), e5: 1.7));
      await repo.recordPrice(
          record('s1', DateTime(2026, 5, 15, 12, 45), e5: 1.8));
      expect(repo.getHistory('s1', days: 3650), hasLength(1));
    });

    test('keeps a second record logged more than 60 minutes later',
        () async {
      await repo.recordPrice(record('s1', DateTime(2026, 5, 15, 12), e5: 1.7));
      await repo.recordPrice(
          record('s1', DateTime(2026, 5, 15, 13, 30), e5: 1.8));
      expect(repo.getHistory('s1', days: 3650), hasLength(2));
    });
  });

  group('getHistory — windowing and sort', () {
    test('excludes records older than the requested window', () async {
      final now = DateTime.now();
      await repo.recordPrice(record('s1', now, e5: 1.7));
      await repo.recordPrice(
          record('s1', now.subtract(const Duration(days: 40)), e5: 1.5));
      final last30 = repo.getHistory('s1', days: 30);
      expect(last30, hasLength(1));
    });

    test('returns records newest-first', () async {
      final now = DateTime.now();
      await repo.recordPrice(
          record('s1', now.subtract(const Duration(days: 5)), e5: 1.5));
      await repo.recordPrice(record('s1', now, e5: 1.8));
      final history = repo.getHistory('s1', days: 30);
      expect(history.first.recordedAt.isAfter(history.last.recordedAt), isTrue);
    });

    test('unknown station returns an empty list', () {
      expect(repo.getHistory('nope'), isEmpty);
    });
  });

  group('evictOldRecords', () {
    test('removes records older than the cutoff and returns the count',
        () async {
      final now = DateTime.now();
      await repo.recordPrice(record('s1', now, e5: 1.7));
      await repo.recordPrice(
          record('s1', now.subtract(const Duration(days: 50)), e5: 1.5));
      final removed = await repo.evictOldRecords(days: 30);
      expect(removed, 1);
      expect(repo.getHistory('s1', days: 3650), hasLength(1));
    });

    test('clears a station whose every record aged out', () async {
      final now = DateTime.now();
      await repo.recordPrice(
          record('s1', now.subtract(const Duration(days: 99)), e5: 1.5));
      final removed = await repo.evictOldRecords(days: 30);
      expect(removed, 1);
      expect(storage.getPriceHistoryKeys(), isNot(contains('s1')));
    });

    test('returns 0 when nothing is stale', () async {
      await repo.recordPrice(record('s1', DateTime.now(), e5: 1.7));
      expect(await repo.evictOldRecords(days: 30), 0);
    });
  });

  group('getStats', () {
    test('computes min / max / avg / current over the window', () async {
      final now = DateTime.now();
      await repo.recordPrice(
          record('s1', now.subtract(const Duration(days: 3)), e5: 1.50));
      await repo.recordPrice(
          record('s1', now.subtract(const Duration(days: 2)), e5: 1.90));
      await repo.recordPrice(record('s1', now, e5: 1.70));
      final stats = repo.getStats('s1', FuelType.e5, days: 7);
      expect(stats.min, 1.50);
      expect(stats.max, 1.90);
      expect(stats.avg, closeTo(1.70, 0.001));
      expect(stats.current, 1.70); // newest record
    });

    test('reports an upward trend when the newest price is higher',
        () async {
      final now = DateTime.now();
      await repo.recordPrice(
          record('s1', now.subtract(const Duration(days: 5)), e5: 1.50));
      await repo.recordPrice(record('s1', now, e5: 1.85));
      expect(repo.getStats('s1', FuelType.e5).trend, PriceTrend.up);
    });

    test('empty history yields the default PriceStats', () {
      expect(repo.getStats('nope', FuelType.e5), const PriceStats());
    });
  });

  group('malformed-JSON recovery', () {
    test('skips records that fail to parse instead of throwing', () async {
      final good = record('s1', DateTime.now(), e5: 1.7);
      storage.seedRaw('s1', [
        good.toJson(),
        <String, dynamic>{'recordedAt': 'not-a-date'}, // missing stationId
        <String, dynamic>{'garbage': true},
      ]);
      late List<PriceRecord> history;
      expect(() => history = repo.getHistory('s1', days: 3650),
          returnsNormally);
      expect(history, hasLength(1));
      expect(history.single.e5, 1.7);
    });
  });
}
