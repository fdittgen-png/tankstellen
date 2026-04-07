import 'package:hive_flutter/hive_flutter.dart';

import '../../data/storage_repository.dart';
import '../hive_boxes.dart';

/// Hive-backed implementation of [PriceHistoryStorage].
///
/// Manages 30-day price history records per station for trend analysis
/// and "best time to fill" predictions.
class PriceHistoryHiveStore implements PriceHistoryStorage {
  Box get _priceHistory => Hive.box(HiveBoxes.priceHistory);

  @override
  Future<void> savePriceRecords(
          String stationId, List<Map<String, dynamic>> records) =>
      _priceHistory.put(stationId, records);

  @override
  List<Map<String, dynamic>> getPriceRecords(String stationId) {
    final data = _priceHistory.get(stationId);
    if (data == null) return [];
    return (data as List)
        .map((e) => HiveBoxes.toStringDynamicMap(e))
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  @override
  List<String> getPriceHistoryKeys() =>
      _priceHistory.keys.cast<String>().toList();

  @override
  Future<void> clearPriceHistoryForStation(String stationId) =>
      _priceHistory.delete(stationId);

  @override
  Future<void> clearPriceHistory() => _priceHistory.clear();

  @override
  int get priceHistoryEntryCount => _priceHistory.length;
}
