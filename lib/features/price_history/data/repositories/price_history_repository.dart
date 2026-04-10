import 'package:flutter/foundation.dart';
import '../../../search/domain/entities/fuel_type.dart';
import '../../../../core/data/storage_repository.dart';
import '../../domain/entities/price_stats.dart';
import '../models/price_record.dart';

// Re-export PriceStats / PriceTrend so existing `price_history_repository.dart`
// consumers continue to compile. New code should import directly from
// `domain/entities/price_stats.dart`.
export '../../domain/entities/price_stats.dart';

/// Persists price snapshots per station via [PriceHistoryStorage] and provides
/// query/aggregation methods for price history analysis.
class PriceHistoryRepository {
  final PriceHistoryStorage _storage;

  PriceHistoryRepository(this._storage);

  /// Save a price snapshot for a station.
  ///
  /// Deduplicates within 1 hour: if a record for the same station already
  /// exists within the last 60 minutes, the new record is silently dropped.
  Future<void> recordPrice(PriceRecord record) async {
    final existing = _loadRecords(record.stationId);

    // Deduplicate: skip if a record exists within the last hour.
    if (existing.isNotEmpty) {
      final latest = existing.first; // sorted newest-first
      final diff = record.recordedAt.difference(latest.recordedAt).abs();
      if (diff.inMinutes < 60) return;
    }

    existing.insert(0, record);
    await _saveRecords(record.stationId, existing);
  }

  /// Get price history for a station, sorted by date (newest first).
  ///
  /// Returns records from the last [days] days.
  List<PriceRecord> getHistory(String stationId, {int days = 30}) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return _loadRecords(stationId)
        .where((r) => r.recordedAt.isAfter(cutoff))
        .toList();
  }

  /// Evict records older than [days] days across all stations.
  ///
  /// Returns the number of records removed.
  Future<int> evictOldRecords({int days = 30}) async {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    int removed = 0;

    // Iterate all stored station keys
    final allKeys = _storage.getPriceHistoryKeys();
    for (final stationId in allKeys) {
      final records = _loadRecords(stationId);
      final before = records.length;
      records.removeWhere((r) => r.recordedAt.isBefore(cutoff));
      removed += before - records.length;

      if (records.isEmpty) {
        await _storage.clearPriceHistoryForStation(stationId);
      } else if (removed > 0) {
        await _saveRecords(stationId, records);
      }
    }

    return removed;
  }

  /// Get stats: min, max, avg, trend for a station and fuel type.
  ///
  /// Analyses the last [days] days of data.
  PriceStats getStats(String stationId, FuelType fuelType, {int days = 7}) {
    final records = getHistory(stationId, days: days);
    final prices = records
        .map((r) => _priceForFuelType(r, fuelType))
        .whereType<double>()
        .toList();

    if (prices.isEmpty) return const PriceStats();

    final current = prices.first;
    final min = prices.reduce((a, b) => a < b ? a : b);
    final max = prices.reduce((a, b) => a > b ? a : b);
    final avg = prices.reduce((a, b) => a + b) / prices.length;

    // Trend: compare newest vs oldest in window
    final trend = _calculateTrend(prices);

    return PriceStats(
      min: min,
      max: max,
      avg: double.parse(avg.toStringAsFixed(3)),
      current: current,
      trend: trend,
    );
  }

  // --- Private helpers ---

  List<PriceRecord> _loadRecords(String stationId) {
    final raw = _storage.getPriceRecords(stationId);
    final records = raw
        .map((map) {
          try {
            return PriceRecord.fromJson(Map<String, dynamic>.from(map));
          } catch (e) {
            debugPrint('PriceRecord parse failed: $e');
            return null;
          }
        })
        .whereType<PriceRecord>()
        .toList();

    // Ensure newest-first sort
    records.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    return records;
  }

  Future<void> _saveRecords(
      String stationId, List<PriceRecord> records) async {
    final maps = records.map((r) => r.toJson()).toList();
    await _storage.savePriceRecords(stationId, maps);
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

  /// Compare newest price to oldest price in the window.
  /// A difference of less than 0.5 cent is considered stable.
  PriceTrend _calculateTrend(List<double> prices) {
    if (prices.length < 2) return PriceTrend.stable;

    final newest = prices.first;
    final oldest = prices.last;
    final diff = newest - oldest;

    if (diff > 0.005) return PriceTrend.up;
    if (diff < -0.005) return PriceTrend.down;
    return PriceTrend.stable;
  }
}
