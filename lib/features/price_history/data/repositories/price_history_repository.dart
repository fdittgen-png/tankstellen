import 'package:flutter/foundation.dart';
import '../../../search/domain/entities/fuel_type.dart';
import '../../../../core/storage/hive_storage.dart';
import '../models/price_record.dart';

/// Trend direction for a fuel price over a time window.
enum PriceTrend { up, down, stable }

/// Aggregate statistics for a single fuel type at a station.
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

/// Persists price snapshots per station via [HiveStorage] and provides
/// query/aggregation methods for price history analysis.
class PriceHistoryRepository {
  final HiveStorage _storage;

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
