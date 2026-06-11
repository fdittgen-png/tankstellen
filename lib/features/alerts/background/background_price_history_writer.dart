// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';

import '../../price_history/api.dart';
import '../../../core/constants/field_names.dart';
import '../../../core/storage/hive_storage.dart';
import '../../../core/utils/json_extensions.dart';

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

  /// #2864 — every fuel grade the country-agnostic price map can carry
  /// (`background_price_shape.dart`). The writer extracts each one so a non-DE
  /// fuel set (FR E85 / LPG, IT CNG, …) is recorded too. DE stays byte-identical
  /// — e5/e10/diesel are still read from the same keys.
  static const _fuelFields = <String>[
    TankerkoenigFields.e5,
    TankerkoenigFields.e10,
    TankerkoenigFields.e98,
    TankerkoenigFields.diesel,
    TankerkoenigFields.dieselPremium,
    TankerkoenigFields.e85,
    TankerkoenigFields.lpg,
    TankerkoenigFields.cng,
  ];

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
        e98: p.getDouble(TankerkoenigFields.e98),
        diesel: p.getDouble(TankerkoenigFields.diesel),
        dieselPremium: p.getDouble(TankerkoenigFields.dieselPremium),
        e85: p.getDouble(TankerkoenigFields.e85),
        lpg: p.getDouble(TankerkoenigFields.lpg),
        cng: p.getDouble(TankerkoenigFields.cng),
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
      // #2864 — patch every fuel grade present in the fetched prices, not just
      // e5/e10/diesel, so a non-DE station's full fuel set stays fresh in cache.
      for (final field in _fuelFields) {
        final value = p.getDouble(field);
        if (value != null) stationData[field] = value;
      }
      stationData[TankerkoenigFields.isOpen] =
          p[TankerkoenigFields.status] == TankerkoenigFields.statusOpen;
      await storage.cacheData('station:$stationId', stationData);
    }
  }
}
