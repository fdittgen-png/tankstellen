import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/features/consumption/data/charging_log_store.dart';
import 'package:tankstellen/features/ev/domain/entities/charging_log.dart';

void main() {
  late Directory tempDir;

  ChargingLog makeLog({
    String id = 'c1',
    String vehicleId = 'v1',
    double kWh = 45.0,
    double costEur = 18.0,
    int chargeTimeMin = 32,
    int odometerKm = 32000,
    DateTime? date,
    String? stationName,
    String? chargingStationId,
  }) {
    return ChargingLog(
      id: id,
      vehicleId: vehicleId,
      date: date ?? DateTime.utc(2026, 4, 1, 10),
      kWh: kWh,
      costEur: costEur,
      chargeTimeMin: chargeTimeMin,
      odometerKm: odometerKm,
      stationName: stationName,
      chargingStationId: chargingStationId,
    );
  }

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_charging_log_');
    Hive.init(tempDir.path);
  });

  setUp(() async {
    // Fresh settings box per test — mirrors the RadiusAlertStore test.
    if (Hive.isBoxOpen(HiveBoxes.settings)) {
      await Hive.box(HiveBoxes.settings).close();
    }
    await Hive.openBox(HiveBoxes.settings);
    await Hive.box(HiveBoxes.settings).clear();
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('ChargingLogStore', () {
    test('list returns empty when the settings box has no charging logs',
        () async {
      final store = ChargingLogStore();
      expect(await store.list(), isEmpty);
    });

    test('upsert persists a log retrievable via list', () async {
      final store = ChargingLogStore();
      await store.upsert(makeLog(id: 'c1'));

      final all = await store.list();
      expect(all, hasLength(1));
      expect(all.single.id, 'c1');
      expect(all.single.kWh, 45.0);
    });

    test('upsert overwrites an existing log with the same id', () async {
      final store = ChargingLogStore();
      await store.upsert(makeLog(id: 'c1', costEur: 18.0));
      await store.upsert(makeLog(id: 'c1', costEur: 22.0));

      final all = await store.list();
      expect(all, hasLength(1));
      expect(all.single.costEur, 22.0);
    });

    test('remove deletes only the targeted log', () async {
      final store = ChargingLogStore();
      await store.upsert(makeLog(id: 'a'));
      await store.upsert(
        makeLog(id: 'b', date: DateTime.utc(2026, 4, 2)),
      );

      await store.remove('a');

      final all = await store.list();
      expect(all, hasLength(1));
      expect(all.single.id, 'b');
    });

    test('remove is a no-op when the id is unknown', () async {
      final store = ChargingLogStore();
      await store.upsert(makeLog(id: 'c1'));

      await store.remove('does-not-exist');

      final all = await store.list();
      expect(all, hasLength(1));
      expect(all.single.id, 'c1');
    });

    test('listForVehicle filters by vehicleId', () async {
      final store = ChargingLogStore();
      await store.upsert(makeLog(id: 'a', vehicleId: 'ev-1'));
      await store.upsert(
        makeLog(id: 'b', vehicleId: 'ev-1', date: DateTime.utc(2026, 4, 2)),
      );
      await store.upsert(
        makeLog(id: 'c', vehicleId: 'ev-2', date: DateTime.utc(2026, 4, 3)),
      );

      final ev1Logs = await store.listForVehicle('ev-1');
      expect(ev1Logs.map((l) => l.id).toList(), ['a', 'b']);

      final ev2Logs = await store.listForVehicle('ev-2');
      expect(ev2Logs.map((l) => l.id), ['c']);

      final ghost = await store.listForVehicle('never-existed');
      expect(ghost, isEmpty);
    });

    test('list ignores non-charging-log keys in the shared settings box',
        () async {
      // The settings box carries lots of unrelated payloads — user
      // prefs, last filter, etc. list() must filter by key prefix.
      final box = Hive.box(HiveBoxes.settings);
      await box.put('theme', 'dark');
      await box.put('user_locale', 'fr');

      final store = ChargingLogStore();
      await store.upsert(makeLog(id: 'real'));

      final all = await store.list();
      expect(all, hasLength(1));
      expect(all.single.id, 'real');
    });

    test('list returns logs oldest-first by date', () async {
      final store = ChargingLogStore();
      await store.upsert(
        makeLog(id: 'newer', date: DateTime.utc(2026, 3, 15)),
      );
      await store.upsert(
        makeLog(id: 'oldest', date: DateTime.utc(2025, 12, 20)),
      );
      await store.upsert(
        makeLog(id: 'middle', date: DateTime.utc(2026, 1, 10)),
      );

      final all = await store.list();
      expect(all.map((l) => l.id).toList(), ['oldest', 'middle', 'newer']);
    });

    test('list returns empty when the settings box is closed', () async {
      await Hive.box(HiveBoxes.settings).close();

      final store = ChargingLogStore();
      expect(await store.list(), isEmpty);
      // Restore for teardown
      await Hive.openBox(HiveBoxes.settings);
    });
  });
}
