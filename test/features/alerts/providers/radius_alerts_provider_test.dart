import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/features/alerts/data/radius_alert_store.dart';
import 'package:tankstellen/features/alerts/domain/entities/radius_alert.dart';
import 'package:tankstellen/features/alerts/providers/radius_alerts_provider.dart';

void main() {
  late Directory tempDir;

  RadiusAlert makeAlert({
    String id = 'r1',
    String fuelType = 'diesel',
    double threshold = 1.55,
    bool enabled = true,
    DateTime? createdAt,
  }) {
    return RadiusAlert(
      id: id,
      fuelType: fuelType,
      threshold: threshold,
      centerLat: 48.0,
      centerLng: 2.0,
      radiusKm: 10,
      label: 'Home',
      createdAt: createdAt ?? DateTime(2026, 1, 1, 10, 0),
      enabled: enabled,
    );
  }

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_radius_prov_');
    Hive.init(tempDir.path);
  });

  setUp(() async {
    if (Hive.isBoxOpen(HiveBoxes.alerts)) {
      await Hive.box(HiveBoxes.alerts).close();
    }
    await Hive.openBox(HiveBoxes.alerts);
    await Hive.box(HiveBoxes.alerts).clear();
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('radiusAlertsProvider', () {
    test('build() returns the empty list when no alerts are persisted',
        () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = await container.read(radiusAlertsProvider.future);
      expect(result, isEmpty);
    });

    test('add() persists the alert and pushes it to state', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Prime the provider so state transitions from loading → data.
      await container.read(radiusAlertsProvider.future);

      final alert = makeAlert(id: 'added');
      await container.read(radiusAlertsProvider.notifier).add(alert);

      final state = container.read(radiusAlertsProvider).value;
      expect(state, isNotNull);
      expect(state!, hasLength(1));
      expect(state.first.id, 'added');
    });

    test('build() loads previously persisted alerts', () async {
      // Write directly via the store, then spin up the provider.
      final store = RadiusAlertStore();
      await store.upsert(makeAlert(id: 'preloaded'));

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = await container.read(radiusAlertsProvider.future);
      expect(result, hasLength(1));
      expect(result.first.id, 'preloaded');
    });

    test('remove() drops the alert and keeps the rest', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(radiusAlertsProvider.future);

      final notifier = container.read(radiusAlertsProvider.notifier);
      await notifier.add(makeAlert(id: 'keep', createdAt: DateTime(2026, 1, 1)));
      await notifier.add(makeAlert(id: 'drop', createdAt: DateTime(2026, 1, 2)));

      await notifier.remove('drop');

      final state = container.read(radiusAlertsProvider).value!;
      expect(state.map((a) => a.id), ['keep']);
    });

    test('remove() with an unknown id is a silent no-op', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(radiusAlertsProvider.future);

      final notifier = container.read(radiusAlertsProvider.notifier);
      await notifier.add(makeAlert(id: 'a1'));

      await notifier.remove('not-there');

      final state = container.read(radiusAlertsProvider).value!;
      expect(state, hasLength(1));
      expect(state.first.id, 'a1');
    });

    test('toggle() flips enabled and persists the change', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(radiusAlertsProvider.future);

      final notifier = container.read(radiusAlertsProvider.notifier);
      await notifier.add(makeAlert(id: 't1', enabled: true));

      await notifier.toggle('t1');

      var state = container.read(radiusAlertsProvider).value!;
      expect(state.single.enabled, isFalse);

      await notifier.toggle('t1');
      state = container.read(radiusAlertsProvider).value!;
      expect(state.single.enabled, isTrue);
    });

    test('toggle() with an unknown id leaves state untouched', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(radiusAlertsProvider.future);

      final notifier = container.read(radiusAlertsProvider.notifier);
      await notifier.add(makeAlert(id: 'real', enabled: true));

      await notifier.toggle('ghost');

      final state = container.read(radiusAlertsProvider).value!;
      expect(state, hasLength(1));
      expect(state.single.id, 'real');
      expect(state.single.enabled, isTrue);
    });
  });
}
