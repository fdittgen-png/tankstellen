import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/features/vehicle/data/service_reminder_store.dart';
import 'package:tankstellen/features/vehicle/domain/entities/service_reminder.dart';
import 'package:tankstellen/features/vehicle/providers/service_reminders_provider.dart';

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
    tempDir = await Directory.systemTemp.createTemp('hive_service_rem_prov_');
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

  group('serviceRemindersProvider', () {
    test('build() returns empty list when nothing is persisted', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = await container.read(serviceRemindersProvider.future);
      expect(result, isEmpty);
    });

    test('add() persists the reminder and pushes it to state', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(serviceRemindersProvider.future);

      final r = makeReminder(id: 'added');
      await container.read(serviceRemindersProvider.notifier).add(r);

      final state = container.read(serviceRemindersProvider).value;
      expect(state, isNotNull);
      expect(state!, hasLength(1));
      expect(state.first.id, 'added');
    });

    test('build() loads previously persisted reminders', () async {
      // Write directly via the store, then spin up the provider.
      final store = ServiceReminderStore();
      await store.upsert(makeReminder(id: 'preloaded'));

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = await container.read(serviceRemindersProvider.future);
      expect(result, hasLength(1));
      expect(result.first.id, 'preloaded');
    });

    test('remove() drops the reminder and keeps the rest', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(serviceRemindersProvider.future);

      final notifier = container.read(serviceRemindersProvider.notifier);
      await notifier.add(
        makeReminder(id: 'keep', createdAt: DateTime(2026, 1, 1)),
      );
      await notifier.add(
        makeReminder(id: 'drop', createdAt: DateTime(2026, 1, 2)),
      );

      await notifier.remove('drop');

      final state = container.read(serviceRemindersProvider).value!;
      expect(state.map((r) => r.id), ['keep']);
    });

    test('remove() with an unknown id is a silent no-op', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(serviceRemindersProvider.future);

      final notifier = container.read(serviceRemindersProvider.notifier);
      await notifier.add(makeReminder(id: 'a1'));

      await notifier.remove('not-there');

      final state = container.read(serviceRemindersProvider).value!;
      expect(state, hasLength(1));
      expect(state.first.id, 'a1');
    });

    test('toggle() flips enabled and persists the change', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(serviceRemindersProvider.future);

      final notifier = container.read(serviceRemindersProvider.notifier);
      await notifier.add(makeReminder(id: 't1', enabled: true));

      await notifier.toggle('t1');

      var state = container.read(serviceRemindersProvider).value!;
      expect(state.single.enabled, isFalse);

      await notifier.toggle('t1');
      state = container.read(serviceRemindersProvider).value!;
      expect(state.single.enabled, isTrue);
    });

    test('toggle() with an unknown id leaves state untouched', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(serviceRemindersProvider.future);

      final notifier = container.read(serviceRemindersProvider.notifier);
      await notifier.add(makeReminder(id: 'real', enabled: true));

      await notifier.toggle('ghost');

      final state = container.read(serviceRemindersProvider).value!;
      expect(state, hasLength(1));
      expect(state.single.id, 'real');
      expect(state.single.enabled, isTrue);
    });

    test('markServiced() snaps lastServiceOdometerKm and persists', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(serviceRemindersProvider.future);

      final notifier = container.read(serviceRemindersProvider.notifier);
      await notifier
          .add(makeReminder(id: 'ms1', lastServiceOdometerKm: 42000));

      await notifier.markServiced('ms1', 58000);

      final state = container.read(serviceRemindersProvider).value!;
      expect(state.single.lastServiceOdometerKm, 58000);

      // Round-trip through a fresh container — value should have been
      // written through to the store.
      final container2 = ProviderContainer();
      addTearDown(container2.dispose);
      final reloaded =
          await container2.read(serviceRemindersProvider.future);
      expect(reloaded.single.lastServiceOdometerKm, 58000);
    });

    test('markServiced() with an unknown id is a no-op', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(serviceRemindersProvider.future);

      final notifier = container.read(serviceRemindersProvider.notifier);
      await notifier
          .add(makeReminder(id: 'real', lastServiceOdometerKm: 42000));

      await notifier.markServiced('ghost', 99999);

      final state = container.read(serviceRemindersProvider).value!;
      expect(state, hasLength(1));
      expect(state.single.lastServiceOdometerKm, 42000);
    });
  });
}
