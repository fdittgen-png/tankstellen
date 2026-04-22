import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/features/vehicle/data/repositories/service_reminder_repository.dart';
import 'package:tankstellen/features/vehicle/domain/entities/service_reminder.dart';

void main() {
  late Directory tempDir;
  late Box<String> box;
  late ServiceReminderRepository repo;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('service_reminder_test_');
    Hive.init(tempDir.path);
    box = await Hive.openBox<String>(HiveBoxes.serviceReminders);
    await box.clear();
    repo = ServiceReminderRepository(box);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  const oilChange = ServiceReminder(
    id: 'r-oil',
    vehicleId: 'v-1',
    label: 'Oil change',
    intervalKm: 15000,
    lastServiceOdometerKm: 0,
  );

  const tiresV1 = ServiceReminder(
    id: 'r-tires-v1',
    vehicleId: 'v-1',
    label: 'Tires',
    intervalKm: 40000,
  );

  const oilV2 = ServiceReminder(
    id: 'r-oil-v2',
    vehicleId: 'v-2',
    label: 'Oil change',
    intervalKm: 20000,
  );

  group('ServiceReminderRepository', () {
    test('getAll returns empty on a fresh box', () {
      expect(repo.getAll(), isEmpty);
    });

    test('save then getAll returns the reminder', () async {
      await repo.save(oilChange);
      final all = repo.getAll();
      expect(all, hasLength(1));
      expect(all.first.id, 'r-oil');
      expect(all.first.intervalKm, 15000);
      expect(all.first.isActive, isTrue);
      expect(all.first.pendingAcknowledgment, isFalse);
    });

    test('save updates an existing entry matched by id', () async {
      await repo.save(oilChange);
      await repo.save(oilChange.copyWith(intervalKm: 12000));
      final all = repo.getAll();
      expect(all, hasLength(1));
      expect(all.first.intervalKm, 12000);
    });

    test('getForVehicle filters by vehicleId', () async {
      await repo.save(oilChange);
      await repo.save(tiresV1);
      await repo.save(oilV2);

      final v1 = repo.getForVehicle('v-1');
      expect(v1.map((r) => r.id).toSet(), {'r-oil', 'r-tires-v1'});

      final v2 = repo.getForVehicle('v-2');
      expect(v2, hasLength(1));
      expect(v2.first.id, 'r-oil-v2');
    });

    test('getById returns the stored reminder', () async {
      await repo.save(oilChange);
      final r = repo.getById('r-oil');
      expect(r, isNotNull);
      expect(r!.label, 'Oil change');
    });

    test('getById returns null for missing id', () {
      expect(repo.getById('missing'), isNull);
    });

    test('delete removes the reminder', () async {
      await repo.save(oilChange);
      await repo.save(tiresV1);
      await repo.delete('r-oil');
      final all = repo.getAll();
      expect(all, hasLength(1));
      expect(all.first.id, 'r-tires-v1');
    });

    test('delete is a no-op for unknown ids', () async {
      await repo.save(oilChange);
      await repo.delete('missing');
      expect(repo.getAll(), hasLength(1));
    });

    test('deleteForVehicle cascades reminders of a given vehicle', () async {
      await repo.save(oilChange);
      await repo.save(tiresV1);
      await repo.save(oilV2);

      await repo.deleteForVehicle('v-1');
      final all = repo.getAll();
      expect(all, hasLength(1));
      expect(all.first.vehicleId, 'v-2');
    });

    test('markDone rebases lastService and clears pending flag', () async {
      await repo.save(oilChange.copyWith(pendingAcknowledgment: true));
      final updated = await repo.markDone('r-oil', 15200);
      expect(updated, isNotNull);
      expect(updated!.lastServiceOdometerKm, 15200);
      expect(updated.pendingAcknowledgment, isFalse);

      final reloaded = repo.getById('r-oil');
      expect(reloaded!.lastServiceOdometerKm, 15200);
      expect(reloaded.pendingAcknowledgment, isFalse);
    });

    test('markDone returns null for unknown id', () async {
      final updated = await repo.markDone('missing', 123);
      expect(updated, isNull);
    });

    test('clear empties the box', () async {
      await repo.save(oilChange);
      await repo.save(tiresV1);
      await repo.clear();
      expect(repo.getAll(), isEmpty);
    });

    test('malformed entries are skipped without crashing', () async {
      await repo.save(oilChange);
      await box.put('garbage', 'not valid json');
      // A syntactically valid JSON that is missing required fields.
      await box.put('half-valid', '{"id":"x"}');

      final all = repo.getAll();
      expect(all, hasLength(1));
      expect(all.first.id, 'r-oil');
    });
  });
}
