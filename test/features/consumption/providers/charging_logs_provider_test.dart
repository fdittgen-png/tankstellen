import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/features/consumption/data/charging_log_store.dart';
import 'package:tankstellen/features/consumption/providers/charging_logs_provider.dart';
import 'package:tankstellen/features/ev/domain/entities/charging_log.dart';

void main() {
  late Directory tempDir;

  ChargingLog makeLog({
    String id = 'c1',
    String vehicleId = 'v1',
    double kWh = 45.0,
    double costEur = 18.0,
    DateTime? date,
  }) {
    return ChargingLog(
      id: id,
      vehicleId: vehicleId,
      date: date ?? DateTime.utc(2026, 4, 1, 10),
      kWh: kWh,
      costEur: costEur,
      chargeTimeMin: 32,
      odometerKm: 32000,
    );
  }

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_charging_prov_');
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

  group('chargingLogsProvider', () {
    test('build() returns an empty list when nothing is persisted', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = await container.read(chargingLogsProvider.future);
      expect(result, isEmpty);
    });

    test('add() persists the log and pushes it to state', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Prime the provider so state transitions from loading → data.
      await container.read(chargingLogsProvider.future);

      final log = makeLog(id: 'added');
      await container.read(chargingLogsProvider.notifier).add(log);

      final state = container.read(chargingLogsProvider).value;
      expect(state, isNotNull);
      expect(state!, hasLength(1));
      expect(state.first.id, 'added');
    });

    test('build() loads previously persisted logs', () async {
      // Write directly via the store, then spin up the provider.
      final store = ChargingLogStore();
      await store.upsert(makeLog(id: 'preloaded'));

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = await container.read(chargingLogsProvider.future);
      expect(result, hasLength(1));
      expect(result.first.id, 'preloaded');
    });

    test('edit() replaces the log with the same id', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(chargingLogsProvider.future);

      final notifier = container.read(chargingLogsProvider.notifier);
      await notifier.add(makeLog(id: 'c1', costEur: 18.0));

      final updated = makeLog(id: 'c1', costEur: 22.0);
      await notifier.edit(updated);

      final state = container.read(chargingLogsProvider).value!;
      expect(state, hasLength(1));
      expect(state.first.costEur, 22.0);
    });

    test('remove() drops the log and keeps the rest', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(chargingLogsProvider.future);

      final notifier = container.read(chargingLogsProvider.notifier);
      await notifier.add(makeLog(id: 'keep', date: DateTime.utc(2026, 4, 1)));
      await notifier.add(makeLog(id: 'drop', date: DateTime.utc(2026, 4, 2)));

      await notifier.remove('drop');

      final state = container.read(chargingLogsProvider).value!;
      expect(state.map((l) => l.id), ['keep']);
    });

    test('remove() with an unknown id is a silent no-op', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(chargingLogsProvider.future);

      final notifier = container.read(chargingLogsProvider.notifier);
      await notifier.add(makeLog(id: 'a1'));

      await notifier.remove('not-there');

      final state = container.read(chargingLogsProvider).value!;
      expect(state, hasLength(1));
      expect(state.first.id, 'a1');
    });

    test('chargingLogsForVehicle filters to the matching vehicle', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(chargingLogsProvider.future);

      final notifier = container.read(chargingLogsProvider.notifier);
      await notifier.add(makeLog(id: 'a', vehicleId: 'ev-1'));
      await notifier.add(
        makeLog(
          id: 'b',
          vehicleId: 'ev-2',
          date: DateTime.utc(2026, 4, 2),
        ),
      );

      final ev1 =
          await container.read(chargingLogsForVehicleProvider('ev-1').future);
      expect(ev1.map((l) => l.id), ['a']);

      final ev2 =
          await container.read(chargingLogsForVehicleProvider('ev-2').future);
      expect(ev2.map((l) => l.id), ['b']);
    });
  });
}
