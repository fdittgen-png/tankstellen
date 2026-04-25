import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/features/alerts/data/radius_alert_store.dart';
import 'package:tankstellen/features/alerts/domain/entities/radius_alert.dart';

void main() {
  late Directory tempDir;

  RadiusAlert makeAlert({
    String id = 'r1',
    String fuelType = 'diesel',
    double threshold = 1.55,
    double centerLat = 48.1,
    double centerLng = 2.2,
    double radiusKm = 10,
    String label = 'Home',
    DateTime? createdAt,
    bool enabled = true,
  }) {
    return RadiusAlert(
      id: id,
      fuelType: fuelType,
      threshold: threshold,
      centerLat: centerLat,
      centerLng: centerLng,
      radiusKm: radiusKm,
      label: label,
      createdAt: createdAt ?? DateTime(2026, 1, 1, 10, 0),
      enabled: enabled,
    );
  }

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_radius_alerts_');
    Hive.init(tempDir.path);
  });

  setUp(() async {
    // Reopen a clean alerts box for every test. Mirrors the pattern
    // used by the legacy alerts repository test.
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

  group('RadiusAlertStore', () {
    test('list returns an empty list when the box is empty', () async {
      final store = RadiusAlertStore();
      expect(await store.list(), isEmpty);
    });

    test('upsert persists an alert retrievable via list', () async {
      final store = RadiusAlertStore();
      final alert = makeAlert(id: 'a1');

      await store.upsert(alert);

      final all = await store.list();
      expect(all, hasLength(1));
      expect(all.single.id, 'a1');
      expect(all.single.threshold, alert.threshold);
      expect(all.single.centerLat, alert.centerLat);
    });

    test('upsert overwrites an existing alert with the same id', () async {
      final store = RadiusAlertStore();
      await store.upsert(makeAlert(id: 'a1', threshold: 1.50));
      await store.upsert(makeAlert(id: 'a1', threshold: 1.30));

      final all = await store.list();
      expect(all, hasLength(1));
      expect(all.single.threshold, 1.30);
    });

    test('remove deletes only the targeted alert', () async {
      final store = RadiusAlertStore();
      await store.upsert(makeAlert(id: 'a1'));
      await store.upsert(makeAlert(
        id: 'a2',
        createdAt: DateTime(2026, 1, 2),
      ));

      await store.remove('a1');

      final all = await store.list();
      expect(all, hasLength(1));
      expect(all.single.id, 'a2');
    });

    test('remove is a no-op when the id is unknown', () async {
      final store = RadiusAlertStore();
      await store.upsert(makeAlert(id: 'a1'));

      await store.remove('does-not-exist');

      final all = await store.list();
      expect(all, hasLength(1));
      expect(all.single.id, 'a1');
    });

    test('list ignores non-radius-alert keys in the shared box', () async {
      // Legacy per-station alerts live under the 'alerts' key (a
      // list of maps). list() must filter those out so we don't
      // crash on unrelated payloads.
      final box = Hive.box(HiveBoxes.alerts);
      await box.put('alerts', [
        {'id': 'legacy', 'stationId': 's', 'targetPrice': 1.5},
      ]);

      final store = RadiusAlertStore();
      await store.upsert(makeAlert(id: 'radius-only'));

      final all = await store.list();
      expect(all, hasLength(1));
      expect(all.single.id, 'radius-only');
    });

    test('list returns alerts oldest-first by createdAt', () async {
      final store = RadiusAlertStore();
      await store.upsert(
        makeAlert(id: 'newer', createdAt: DateTime(2026, 3, 1)),
      );
      await store.upsert(
        makeAlert(id: 'oldest', createdAt: DateTime(2025, 12, 1)),
      );
      await store.upsert(
        makeAlert(id: 'middle', createdAt: DateTime(2026, 1, 15)),
      );

      final all = await store.list();
      expect(all.map((a) => a.id).toList(), ['oldest', 'middle', 'newer']);
    });

    test('list returns empty list when the alerts box is closed', () async {
      final box = Hive.box(HiveBoxes.alerts);
      await box.close();

      final store = RadiusAlertStore();
      expect(await store.list(), isEmpty);
      // Restore for teardown
      await Hive.openBox(HiveBoxes.alerts);
    });
  });

  group('RadiusAlertStore lastEvaluatedAt (#1012 phase 1)', () {
    test('getLastEvaluatedAt returns null for an unknown id', () async {
      final store = RadiusAlertStore();
      expect(await store.getLastEvaluatedAt('does-not-exist'), isNull);
    });

    test('recordEvaluatedAt persists a timestamp readable by getLastEvaluatedAt',
        () async {
      final store = RadiusAlertStore();
      final t = DateTime.utc(2026, 4, 22, 9, 30);

      await store.recordEvaluatedAt('a1', t);

      expect(await store.getLastEvaluatedAt('a1'), equals(t));
    });

    test('recordEvaluatedAt overwrites the previous timestamp for the same id',
        () async {
      final store = RadiusAlertStore();
      final t0 = DateTime.utc(2026, 4, 22, 9);
      final t1 = DateTime.utc(2026, 4, 23, 9);

      await store.recordEvaluatedAt('a1', t0);
      await store.recordEvaluatedAt('a1', t1);

      expect(await store.getLastEvaluatedAt('a1'), equals(t1));
    });

    test('recordEvaluatedAt is namespaced per alert id', () async {
      final store = RadiusAlertStore();
      final t0 = DateTime.utc(2026, 4, 22, 9);
      final t1 = DateTime.utc(2026, 4, 23, 9);

      await store.recordEvaluatedAt('a1', t0);
      await store.recordEvaluatedAt('a2', t1);

      expect(await store.getLastEvaluatedAt('a1'), equals(t0));
      expect(await store.getLastEvaluatedAt('a2'), equals(t1));
      expect(await store.getLastEvaluatedAt('a3'), isNull);
    });

    test('lastEvaluatedAt records do not pollute list()', () async {
      // The side-table uses a different key prefix; list() must not
      // pick those entries up and try to deserialize them as
      // RadiusAlert payloads.
      final store = RadiusAlertStore();
      await store.recordEvaluatedAt('a1', DateTime.utc(2026, 4, 22));

      expect(await store.list(), isEmpty);
    });

    test('remove drops the matching lastEvaluatedAt record', () async {
      final store = RadiusAlertStore();
      await store.upsert(makeAlert(id: 'a1'));
      await store.recordEvaluatedAt('a1', DateTime.utc(2026, 4, 22));

      await store.remove('a1');

      expect(await store.getLastEvaluatedAt('a1'), isNull);
    });

    test(
        'a freshly-loaded RadiusAlert defaults frequencyPerDay to 1 '
        '(pre-#1012 hive payload backwards compat)', () async {
      // Simulate a Hive payload written before #1012 — no
      // frequencyPerDay key.
      final box = Hive.box(HiveBoxes.alerts);
      await box.put('${RadiusAlertStore.keyPrefix}legacy', {
        'id': 'legacy',
        'fuelType': 'diesel',
        'threshold': 1.5,
        'centerLat': 48.1,
        'centerLng': 2.2,
        'radiusKm': 10.0,
        'label': 'Old',
        'createdAt': DateTime(2025, 12, 1).toIso8601String(),
        'enabled': true,
      });

      final store = RadiusAlertStore();
      final all = await store.list();
      expect(all, hasLength(1));
      expect(all.single.frequencyPerDay, 1);
    });
  });
}
