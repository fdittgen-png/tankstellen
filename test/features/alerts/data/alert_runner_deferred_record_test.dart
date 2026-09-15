// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #4185 — a runner's dedup / cooldown row is written when a notification
// ACTUALLY went out, not when the runner decided to fire. Written early, it
// says "we told you" about something the budget refused and the user never
// saw — and suppresses the same finding for its whole window.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/notifications/notification_service.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/features/alerts/data/radius_alert_dedup.dart';
import 'package:tankstellen/features/alerts/data/radius_alert_runner.dart';
import 'package:tankstellen/features/alerts/data/radius_alert_store.dart';
import 'package:tankstellen/features/alerts/data/velocity_alert_cooldown.dart';
import 'package:tankstellen/features/alerts/data/velocity_alert_runner.dart';
import 'package:tankstellen/features/alerts/data/price_snapshot_store.dart';
import 'package:tankstellen/features/alerts/data/models/price_snapshot.dart';
import 'package:tankstellen/features/alerts/domain/entities/radius_alert.dart';
import 'package:tankstellen/features/alerts/domain/radius_alert_evaluator.dart';
import 'package:tankstellen/features/alerts/domain/station_price_sample.dart';
import 'package:tankstellen/features/alerts/domain/velocity_alert_detector.dart';

class _Notifier implements NotificationService {
  final List<String> titles = [];
  @override
  Future<bool> requestPermission() async => true;
  @override
  Future<bool> areNotificationsEnabled() async => true;
  @override
  Future<void> initialize() async {}
  @override
  Future<void> showPriceAlert({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async =>
      titles.add(title);
  @override
  Future<void> showServiceReminder(
      {required int id, required String title, required String body}) async {}
  @override
  Future<void> cancelNotification(int id) async {}
  @override
  Future<void> cancelAll() async {}
}

void main() {
  late Directory tmpDir;
  final now = DateTime.utc(2026, 9, 15, 12);

  setUp(() async {
    tmpDir = Directory.systemTemp.createTempSync('deferred_record_');
    Hive.init(tmpDir.path);
    await Hive.openBox<dynamic>(HiveBoxes.alerts);
    await Hive.openBox<dynamic>(HiveBoxes.settings);
    await Hive.openBox<String>(HiveBoxes.priceSnapshots);
  });

  tearDown(() async {
    await Hive.close();
    tmpDir.deleteSync(recursive: true);
  });

  StationPriceSample sample(String id, double price) => StationPriceSample(
        stationId: id,
        name: 'S$id',
        fuelType: FuelType.e10.apiValue,
        pricePerLiter: price,
        lat: 52.5,
        lng: 13.4,
      );

  RadiusAlert alert() => RadiusAlert(
        id: 'r1',
        label: 'Home',
        fuelType: FuelType.e10.apiValue,
        threshold: 1.700,
        centerLat: 52.5,
        centerLng: 13.4,
        radiusKm: 5,
        createdAt: DateTime.utc(2026, 9, 1),
      );

  group('radius runner', () {
    Future<void> seedAlert(RadiusAlertStore store) =>
        store.upsert(alert());

    test('recordFire: false detects and leaves the dedup untouched — the '
        'next scan still sees the finding', () async {
      final store = RadiusAlertStore();
      final dedup = RadiusAlertDedup();
      await seedAlert(store);
      final runner = RadiusAlertRunner(
        store: store,
        dedup: dedup,
        notifier: _Notifier(),
        copyBuilder: (e) =>
            const RadiusAlertCopy(title: 'Home', body: '1 station'),
      );

      final fired = await runner.run(
        now: now,
        samplesFor: (_) async => [sample('s1', 1.650)],
        recordFire: false,
      );

      expect(fired, hasLength(1));
      expect(runner.pendingFires, hasLength(1));
      expect(
          await dedup.shouldNotifyAlert(
              alertId: 'r1', cheapestPrice: 1.650, now: now),
          isTrue,
          reason: 'nothing was sent, so nothing may be suppressed');
    });

    test('recordFire writes the rows, and only then does the window '
        'suppress — the price-drop escape hatch still re-fires', () async {
      final store = RadiusAlertStore();
      final dedup = RadiusAlertDedup();
      await seedAlert(store);
      final runner = RadiusAlertRunner(
        store: store,
        dedup: dedup,
        notifier: _Notifier(),
        copyBuilder: (e) =>
            const RadiusAlertCopy(title: 'Home', body: '1 station'),
      );
      await runner.run(
        now: now,
        samplesFor: (_) async => [sample('s1', 1.650)],
        recordFire: false,
      );

      await runner.recordFire(runner.pendingFires.single, now);

      expect(
          await dedup.shouldNotifyAlert(
              alertId: 'r1', cheapestPrice: 1.650, now: now),
          isFalse,
          reason: 'this one WAS sent');
      expect(
          await dedup.shouldNotifyAlert(
              alertId: 'r1', cheapestPrice: 1.600, now: now),
          isTrue,
          reason: 'a further drop is a new thing to say (#1012 phase 2)');
      expect(
          await dedup.shouldNotify(
              alertId: 'r1', stationId: 's1', currentPrice: 1.650, now: now),
          isFalse,
          reason: 'the per-station row was written too');
    });
  });

  group('velocity runner', () {
    Future<VelocityAlertEvent?> detect(
      VelocityAlertRunner runner, {
      required bool recordFire,
    }) async {
      final snapshots = PriceSnapshotStore(now: () => now);
      for (final id in ['s1', 's2', 's3']) {
        await snapshots.recordSnapshot(PriceSnapshot(
          stationId: id,
          fuelType: FuelType.e10.apiValue,
          price: 1.900,
          timestamp: now.subtract(const Duration(hours: 3)),
          lat: 52.5,
          lng: 13.4,
        ));
      }
      return runner.run(
        observations: [
          for (final id in ['s1', 's2', 's3']) sample(id, 1.650),
        ],
        now: now,
        recordFire: recordFire,
      );
    }

    test('recordFire: false leaves the cooldown clear; recordFired stamps it',
        () async {
      final cooldown = VelocityAlertCooldown();
      final runner = VelocityAlertRunner(
        snapshotStore: PriceSnapshotStore(now: () => now),
        cooldown: cooldown,
        notifier: _Notifier(),
        copyBuilder: (e) =>
            const VelocityAlertCopy(title: 'E10 dropped', body: '3 stations'),
      );

      final event = await detect(runner, recordFire: false);
      expect(event, isNotNull, reason: 'the movement is still detected');
      expect(
          await cooldown.canFire(
              fuelType: event!.fuelType,
              now: now,
              cooldown: const Duration(hours: 6)),
          isTrue,
          reason: 'nothing was sent, so the next scan may still say it');

      await runner.recordFired(event, now);
      expect(
          await cooldown.canFire(
              fuelType: event.fuelType,
              now: now,
              cooldown: const Duration(hours: 6)),
          isFalse);
    });
  });
}
