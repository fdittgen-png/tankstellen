import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/core/storage/stores/alerts_hive_store.dart';

void main() {
  late AlertsHiveStore store;
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('alerts_store_test_');
    Hive.init(tempDir.path);
    await HiveStorage.initForTest();
    store = AlertsHiveStore();
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('AlertsHiveStore', () {
    test('empty box returns an empty list', () {
      expect(store.getAlerts(), isEmpty);
      expect(store.alertCount, 0);
    });

    test('saves and re-reads a single alert map', () async {
      final alert = {
        'id': 'alert-1',
        'stationId': 'station-1',
        'fuelType': 'diesel',
        'targetPrice': 1.5,
        'isActive': true,
      };
      await store.saveAlerts([alert]);

      final round = store.getAlerts();
      expect(round, hasLength(1));
      expect(round.first['id'], 'alert-1');
      expect(round.first['stationId'], 'station-1');
      expect(round.first['targetPrice'], 1.5);
      expect(store.alertCount, 1);
    });

    test('saves and re-reads multiple alerts in order', () async {
      await store.saveAlerts([
        {'id': 'a', 'targetPrice': 1.5},
        {'id': 'b', 'targetPrice': 1.6},
        {'id': 'c', 'targetPrice': 1.7},
      ]);
      final round = store.getAlerts();
      expect(round.map((a) => a['id']).toList(), ['a', 'b', 'c']);
      expect(store.alertCount, 3);
    });

    test('saveAlerts replaces the existing list (not append)', () async {
      await store.saveAlerts([
        {'id': 'old-1', 'targetPrice': 1.0},
        {'id': 'old-2', 'targetPrice': 1.1},
      ]);
      await store.saveAlerts([
        {'id': 'new-1', 'targetPrice': 1.5},
      ]);

      final round = store.getAlerts();
      expect(round.map((a) => a['id']).toList(), ['new-1']);
    });

    test('clearAlerts empties the box', () async {
      await store.saveAlerts([
        {'id': 'a', 'targetPrice': 1.5},
      ]);
      await store.clearAlerts();
      expect(store.getAlerts(), isEmpty);
      expect(store.alertCount, 0);
    });

    test('saveAlerts with an empty list persists emptiness', () async {
      await store.saveAlerts([
        {'id': 'a', 'targetPrice': 1.5},
      ]);
      await store.saveAlerts([]);
      expect(store.getAlerts(), isEmpty);
    });
  });
}
