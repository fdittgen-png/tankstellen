import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/features/vehicle/data/repositories/service_reminder_repository.dart';
import 'package:tankstellen/features/vehicle/domain/entities/service_reminder.dart';
import 'package:tankstellen/features/vehicle/providers/service_reminder_providers.dart';

void main() {
  late Directory tempDir;
  late Box<String> box;
  late ProviderContainer container;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('reminder_provider_');
    Hive.init(tempDir.path);
    box = await Hive.openBox<String>(HiveBoxes.serviceReminders);
    await box.clear();
    container = ProviderContainer(
      overrides: [
        serviceReminderRepositoryProvider
            .overrideWithValue(ServiceReminderRepository(box)),
      ],
    );
    addTearDown(container.dispose);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('ServiceReminderList provider (#584)', () {
    test('starts empty', () {
      expect(container.read(serviceReminderListProvider), isEmpty);
    });

    test('save then read returns the reminder', () async {
      const reminder = ServiceReminder(
        id: 'r-1',
        vehicleId: 'v-1',
        label: 'Oil change',
        intervalKm: 15000,
      );
      await container
          .read(serviceReminderListProvider.notifier)
          .save(reminder);
      final list = container.read(serviceReminderListProvider);
      expect(list, hasLength(1));
      expect(list.first.id, 'r-1');
    });

    test('remove deletes and updates state', () async {
      const reminder = ServiceReminder(
        id: 'r-1',
        vehicleId: 'v-1',
        label: 'Oil change',
        intervalKm: 15000,
      );
      final notifier = container.read(serviceReminderListProvider.notifier);
      await notifier.save(reminder);
      await notifier.remove('r-1');
      expect(container.read(serviceReminderListProvider), isEmpty);
    });

    test('markDone rebases lastService and clears the pending flag', () async {
      const reminder = ServiceReminder(
        id: 'r-1',
        vehicleId: 'v-1',
        label: 'Oil change',
        intervalKm: 15000,
        pendingAcknowledgment: true,
      );
      final notifier = container.read(serviceReminderListProvider.notifier);
      await notifier.save(reminder);
      await notifier.markDone('r-1', 15200);

      final list = container.read(serviceReminderListProvider);
      expect(list.first.lastServiceOdometerKm, 15200);
      expect(list.first.pendingAcknowledgment, isFalse);
    });

    test('serviceRemindersForVehicle filters by vehicleId', () async {
      final notifier = container.read(serviceReminderListProvider.notifier);
      await notifier.save(const ServiceReminder(
        id: 'r-1',
        vehicleId: 'v-1',
        label: 'Oil',
        intervalKm: 15000,
      ));
      await notifier.save(const ServiceReminder(
        id: 'r-2',
        vehicleId: 'v-2',
        label: 'Oil',
        intervalKm: 15000,
      ));

      final v1 =
          container.read(serviceRemindersForVehicleProvider('v-1'));
      expect(v1, hasLength(1));
      expect(v1.first.id, 'r-1');
    });

    test('removeAllForVehicle cascades reminders for a deleted vehicle',
        () async {
      final notifier = container.read(serviceReminderListProvider.notifier);
      await notifier.save(const ServiceReminder(
        id: 'r-1',
        vehicleId: 'v-1',
        label: 'Oil',
        intervalKm: 15000,
      ));
      await notifier.save(const ServiceReminder(
        id: 'r-2',
        vehicleId: 'v-1',
        label: 'Tires',
        intervalKm: 20000,
      ));
      await notifier.save(const ServiceReminder(
        id: 'r-3',
        vehicleId: 'v-2',
        label: 'Oil',
        intervalKm: 15000,
      ));

      await notifier.removeAllForVehicle('v-1');

      final remaining = container.read(serviceReminderListProvider);
      expect(remaining, hasLength(1));
      expect(remaining.first.vehicleId, 'v-2');
    });
  });
}
