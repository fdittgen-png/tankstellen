import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/core/storage/stores/price_history_hive_store.dart';

void main() {
  late PriceHistoryHiveStore store;
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('price_history_test_');
    Hive.init(tempDir.path);
    await HiveStorage.initForTest();
    store = PriceHistoryHiveStore();
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  final recordA = {
    'timestamp': '2026-04-01T10:00:00Z',
    'e10': 1.799,
    'diesel': 1.659,
  };
  final recordB = {
    'timestamp': '2026-04-02T10:00:00Z',
    'e10': 1.819,
    'diesel': 1.679,
  };

  group('PriceHistoryHiveStore', () {
    test('empty box returns empty list and zero count', () {
      expect(store.getPriceRecords('st-1'), isEmpty);
      expect(store.getPriceHistoryKeys(), isEmpty);
      expect(store.priceHistoryEntryCount, 0);
    });

    test('saves and re-reads per-station records', () async {
      await store.savePriceRecords('st-1', [recordA, recordB]);
      final round = store.getPriceRecords('st-1');
      expect(round, hasLength(2));
      expect(round[0]['e10'], 1.799);
      expect(round[1]['e10'], 1.819);
    });

    test('isolates records by station id', () async {
      await store.savePriceRecords('st-1', [recordA]);
      await store.savePriceRecords('st-2', [recordB]);

      expect(store.getPriceRecords('st-1').first['diesel'], 1.659);
      expect(store.getPriceRecords('st-2').first['diesel'], 1.679);
      expect(store.priceHistoryEntryCount, 2);
    });

    test('getPriceHistoryKeys returns all station ids with data',
        () async {
      await store.savePriceRecords('st-1', [recordA]);
      await store.savePriceRecords('st-2', [recordB]);

      final keys = store.getPriceHistoryKeys();
      expect(keys.toSet(), {'st-1', 'st-2'});
    });

    test('savePriceRecords overwrites the station''s prior list',
        () async {
      await store.savePriceRecords('st-1', [recordA, recordB]);
      await store.savePriceRecords('st-1', [recordA]);
      expect(store.getPriceRecords('st-1'), hasLength(1));
    });

    test('clearPriceHistoryForStation removes only that station',
        () async {
      await store.savePriceRecords('st-1', [recordA]);
      await store.savePriceRecords('st-2', [recordB]);
      await store.clearPriceHistoryForStation('st-1');

      expect(store.getPriceRecords('st-1'), isEmpty);
      expect(store.getPriceRecords('st-2'), hasLength(1));
      expect(store.getPriceHistoryKeys(), ['st-2']);
    });

    test('clearPriceHistory wipes the whole box', () async {
      await store.savePriceRecords('st-1', [recordA]);
      await store.savePriceRecords('st-2', [recordB]);
      await store.clearPriceHistory();

      expect(store.getPriceHistoryKeys(), isEmpty);
      expect(store.priceHistoryEntryCount, 0);
    });

    test('missing station id returns empty list, not null', () {
      // The getter returns `[]` for an unseen id so callers can
      // iterate without null-guarding every read. Pin that.
      expect(store.getPriceRecords('never-seen'), isEmpty);
    });
  });
}
