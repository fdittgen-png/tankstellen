// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';

import '../../features/price_history/data/models/price_record.dart';
import '../constants/field_names.dart';
import '../storage/hive_storage.dart';
import '../utils/json_extensions.dart';

/// Persists the fresh prices a background scan fetched (#2415). Split out of
/// [BackgroundAlertScanCoordinator] to keep each file reviewable: this owns
/// the two Hive writes the scan does with the batch result —
///   1. append a dedup'd, retention-trimmed price-history point per station,
///   2. patch the cached `station:<id>` blob with the latest prices.
///
/// Assumes Hive is already initialised in this isolate and the
/// HiveIsolateLock is held (the coordinator owns that lifecycle).
class BackgroundPriceHistoryWriter {
  BackgroundPriceHistoryWriter._();

  /// Skip writing a new price-history record if the last one is more recent
  /// than this. Avoids duplicate points when scans run faster than prices
  /// actually change.
  static const dedupWindow = Duration(minutes: 60);

  /// Keep this much price-history per station; older points are trimmed.
  static const retention = Duration(days: 30);

  static Future<void> recordHistory(
    HiveStorage storage,
    Map<String, Map<String, dynamic>> prices,
    DateTime now,
  ) async {
    for (final entry in prices.entries) {
      final stationId = entry.key;
      final p = entry.value;
      if (p[TankerkoenigFields.status] == TankerkoenigFields.statusNoPrices) {
        continue;
      }
      final record = PriceRecord(
        stationId: stationId,
        recordedAt: now,
        e5: p.getDouble(TankerkoenigFields.e5),
        e10: p.getDouble(TankerkoenigFields.e10),
        diesel: p.getDouble(TankerkoenigFields.diesel),
      );
      final existing = storage.getPriceRecords(stationId);
      final lastRecordedAt = existing.isNotEmpty
          ? DateTime.tryParse(existing.last['recordedAt']?.toString() ?? '')
          : null;
      final shouldSave = existing.isEmpty ||
          lastRecordedAt == null ||
          now.difference(lastRecordedAt) > dedupWindow;
      if (!shouldSave) continue;
      final records = [...existing, record.toJson()];
      final cutoff = now.subtract(retention);
      final trimmed = records.where((r) {
        final ts = DateTime.tryParse(r['recordedAt']?.toString() ?? '');
        return ts != null && ts.isAfter(cutoff);
      }).toList();
      await storage.savePriceRecords(
          stationId, trimmed.cast<Map<String, dynamic>>());
    }
    debugPrint('BackgroundPriceHistoryWriter: price history recorded');
  }

  static Future<void> updateCachedStations(
    HiveStorage storage,
    Map<String, Map<String, dynamic>> prices,
  ) async {
    for (final entry in prices.entries) {
      final stationId = entry.key;
      final p = entry.value;
      if (p[TankerkoenigFields.status] == TankerkoenigFields.statusNoPrices) {
        continue;
      }
      final cached = storage.getCachedData('station:$stationId');
      final cachedData = cached?.getMap('data');
      if (cachedData == null) continue;
      final stationData = Map<String, dynamic>.from(cachedData);
      final e5 = p.getDouble(TankerkoenigFields.e5);
      final e10 = p.getDouble(TankerkoenigFields.e10);
      final diesel = p.getDouble(TankerkoenigFields.diesel);
      if (e5 != null) stationData[TankerkoenigFields.e5] = e5;
      if (e10 != null) stationData[TankerkoenigFields.e10] = e10;
      if (diesel != null) stationData[TankerkoenigFields.diesel] = diesel;
      stationData[TankerkoenigFields.isOpen] =
          p[TankerkoenigFields.status] == TankerkoenigFields.statusOpen;
      await storage.cacheData('station:$stationId', stationData);
    }
  }
}
