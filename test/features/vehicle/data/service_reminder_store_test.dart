import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/features/vehicle/data/service_reminder_store.dart';
import 'package:tankstellen/features/vehicle/domain/entities/service_reminder.dart';

void main() {
  late Directory tempDir;

  ServiceReminder makeReminder({
    String id = 'r1',
    String vehicleId = 'v1',
    String label = 'Oil change',
    int intervalKm = 15000,
    int lastServiceOdometerKm = 42000,
    DateTime? createdAt,
    bool enabled = true,
  }) {
    return ServiceReminder(
      id: id,
      vehicleId: vehicleId,
      label: label,
      intervalKm: intervalKm,
      lastServiceOdometerKm: lastServiceOdometerKm,
      createdAt: createdAt ?? DateTime(2026, 1, 1, 9, 0),
      enabled: enabled,
    );
  }

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_service_reminders_');
    Hive.init(tempDir.path);
  });

  setUp(() async {
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

  group('ServiceReminderStore', () {
    test('list returns an empty list when the box is empty', () async {
      final store = ServiceReminderStore();
      expect(await store.list(), isEmpty);
    });

    test('upsert persists a reminder retrievable via list', () async {
      final store = ServiceReminderStore();
      final r = makeReminder(id: 'a1');

      await store.upsert(r);

      final all = await store.list();
      expect(all, hasLength(1));
      expect(all.single.id, 'a1');
      expect(all.single.intervalKm, r.intervalKm);
      expect(all.single.lastServiceOdometerKm, r.lastServiceOdometerKm);
    });

    test('upsert overwrites an existing reminder with the same id', () async {
      final store = ServiceReminderStore();
      await store.upsert(makeReminder(id: 'a1', intervalKm: 15000));
      await store.upsert(makeReminder(id: 'a1', intervalKm: 20000));

      final all = await store.list();
      expect(all, hasLength(1));
      expect(all.single.intervalKm, 20000);
    });

    test('remove deletes only the targeted reminder', () async {
      final store = ServiceReminderStore();
      await store.upsert(makeReminder(id: 'a1'));
      await store.upsert(makeReminder(
        id: 'a2',
        createdAt: DateTime(2026, 1, 2),
      ));

      await store.remove('a1');

      final all = await store.list();
      expect(all, hasLength(1));
      expect(all.single.id, 'a2');
    });

    test('remove is a no-op when the id is unknown', () async {
      final store = ServiceReminderStore();
      await store.upsert(makeReminder(id: 'a1'));

      await store.remove('does-not-exist');

      final all = await store.list();
      expect(all, hasLength(1));
      expect(all.single.id, 'a1');
    });

    test('listForVehicle filters by vehicleId', () async {
      final store = ServiceReminderStore();
      await store.upsert(makeReminder(id: 'a1', vehicleId: 'veh-A'));
      await store.upsert(makeReminder(
        id: 'a2',
        vehicleId: 'veh-A',
        createdAt: DateTime(2026, 1, 2),
      ));
      await store.upsert(makeReminder(
        id: 'a3',
        vehicleId: 'veh-B',
        createdAt: DateTime(2026, 1, 3),
      ));

      final aOnly = await store.listForVehicle('veh-A');
      expect(aOnly.map((r) => r.id), ['a1', 'a2']);

      final bOnly = await store.listForVehicle('veh-B');
      expect(bOnly.map((r) => r.id), ['a3']);
    });

    test('list ignores non-reminder keys sharing the settings box', () async {
      // Settings box is shared with generic app config keys. list()
      // must filter out anything that doesn't carry the reminder
      // prefix so we don't crash on an unrelated payload.
      final box = Hive.box(HiveBoxes.settings);
      await box.put('some_unrelated_setting', 'abc');
      await box.put('other_key', {'x': 1});

      final store = ServiceReminderStore();
      await store.upsert(makeReminder(id: 'mine'));

      final all = await store.list();
      expect(all, hasLength(1));
      expect(all.single.id, 'mine');
    });

    test('list returns reminders oldest-first by createdAt', () async {
      final store = ServiceReminderStore();
      await store.upsert(
        makeReminder(id: 'newer', createdAt: DateTime(2026, 3, 1)),
      );
      await store.upsert(
        makeReminder(id: 'oldest', createdAt: DateTime(2025, 12, 1)),
      );
      await store.upsert(
        makeReminder(id: 'middle', createdAt: DateTime(2026, 1, 15)),
      );

      final all = await store.list();
      expect(all.map((r) => r.id).toList(), ['oldest', 'middle', 'newer']);
    });

    test('list returns empty list when the settings box is closed', () async {
      final box = Hive.box(HiveBoxes.settings);
      await box.close();

      final store = ServiceReminderStore();
      expect(await store.list(), isEmpty);
      // Restore for teardown
      await Hive.openBox(HiveBoxes.settings);
    });
  });
}
