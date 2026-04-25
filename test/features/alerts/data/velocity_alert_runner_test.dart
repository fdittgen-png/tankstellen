import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tankstellen/core/notifications/notification_service.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/features/alerts/data/models/price_snapshot.dart';
import 'package:tankstellen/features/alerts/data/price_snapshot_store.dart';
import 'package:tankstellen/features/alerts/data/velocity_alert_cooldown.dart';
import 'package:tankstellen/features/alerts/data/velocity_alert_runner.dart';
import 'package:tankstellen/features/alerts/domain/entities/velocity_alert_config.dart';
import 'package:tankstellen/features/alerts/domain/velocity_alert_detector.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

/// Captures every notification the runner fires. Stand-in for
/// [LocalNotificationService] — the BG-isolate hook just needs
/// `showPriceAlert` to reach it.
class _FakeNotifier implements NotificationService {
  final List<({int id, String title, String body, String? payload})>
      priceAlerts = [];

  @override
  Future<void> initialize() async {}

  @override
  Future<void> showPriceAlert({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    priceAlerts.add((id: id, title: title, body: body, payload: payload));
  }

  @override
  Future<void> showServiceReminder({
    required int id,
    required String title,
    required String body,
  }) async {}

  @override
  Future<void> cancelNotification(int id) async {}

  @override
  Future<void> cancelAll() async {}
}

VelocityAlertCopy _copy(VelocityAlertEvent event) => VelocityAlertCopy(
      title: '${event.fuelType.displayName.toUpperCase()} dropped',
      body:
          '${event.stationCount} stations dropped by up to ${event.maxDropCents.round()}¢',
    );

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_velocity_runner_');
    Hive.init(tempDir.path);
  });

  setUp(() async {
    for (final name in [HiveBoxes.priceSnapshots]) {
      if (Hive.isBoxOpen(name)) {
        await Hive.box<String>(name).close();
      }
      await Hive.openBox<String>(name);
      await Hive.box<String>(name).clear();
    }
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

  // User sits at this point; stations are clustered within ~2 km.
  const userLat = 43.5;
  const userLng = 3.5;
  final nearbyCoords = <String, List<double>>{
    's1': [userLat, 3.51],
    's2': [userLat, 3.49],
    's3': [userLat, 3.52],
  };
  final now = DateTime.utc(2026, 4, 22, 12);
  final hourPlus =
      now.subtract(const Duration(hours: 1, minutes: 10));

  VelocityStationObservation obs(String id, double price) {
    final c = nearbyCoords[id]!;
    return VelocityStationObservation(
      stationId: id,
      price: price,
      lat: c[0],
      lng: c[1],
    );
  }

  PriceSnapshot priorSnap(String id, double price) {
    final c = nearbyCoords[id]!;
    return PriceSnapshot(
      stationId: id,
      fuelType: 'e10',
      price: price,
      timestamp: hourPlus,
      lat: c[0],
      lng: c[1],
    );
  }

  group('VelocityAlertRunner (background hook)', () {
    test(
        'fires a single notification when threshold is met and cooldown is idle',
        () async {
      final snapshotStore = PriceSnapshotStore(now: () => now);
      final cooldown = VelocityAlertCooldown();
      final notifier = _FakeNotifier();
      final runner = VelocityAlertRunner(
        snapshotStore: snapshotStore,
        cooldown: cooldown,
        notifier: notifier,
        copyBuilder: _copy,
      );

      // Seed yesterday's baseline snapshots.
      await snapshotStore.recordSnapshot(priorSnap('s1', 1.900));
      await snapshotStore.recordSnapshot(priorSnap('s2', 1.900));
      await snapshotStore.recordSnapshot(priorSnap('s3', 1.900));

      final event = await runner.run(
        observations: [
          obs('s1', 1.860), // -4 ct
          obs('s2', 1.860), // -4 ct
          obs('s3', 1.860), // -4 ct
        ],
        now: now,
        userLat: userLat,
        userLng: userLng,
      );

      expect(event, isNotNull);
      expect(event!.stationCount, 3);
      expect(notifier.priceAlerts, hasLength(1));
      expect(notifier.priceAlerts.single.title, contains('E10'));
      expect(notifier.priceAlerts.single.body, contains('3 stations'));
    });

    test('suppresses a second notification while cooldown is active', () async {
      final snapshotStore = PriceSnapshotStore(now: () => now);
      final cooldown = VelocityAlertCooldown();
      final notifier = _FakeNotifier();
      final runner = VelocityAlertRunner(
        snapshotStore: snapshotStore,
        cooldown: cooldown,
        notifier: notifier,
        copyBuilder: _copy,
      );

      // Prime the cooldown as if we'd just fired.
      await cooldown.recordFired(fuelType: FuelType.e10, now: now);

      await snapshotStore.recordSnapshot(priorSnap('s1', 1.900));
      await snapshotStore.recordSnapshot(priorSnap('s2', 1.900));

      final event = await runner.run(
        observations: [
          obs('s1', 1.860),
          obs('s2', 1.860),
        ],
        now: now.add(const Duration(minutes: 5)),
        userLat: userLat,
        userLng: userLng,
      );

      // Detector still emits the event — the cooldown gate is the
      // one that mutes the notification.
      expect(event, isNotNull);
      expect(notifier.priceAlerts, isEmpty);
    });

    test('persists config via saveConfig and loadConfig round-trips', () async {
      final snapshotStore = PriceSnapshotStore(now: () => now);
      final cooldown = VelocityAlertCooldown();
      final notifier = _FakeNotifier();
      final runner = VelocityAlertRunner(
        snapshotStore: snapshotStore,
        cooldown: cooldown,
        notifier: notifier,
        copyBuilder: _copy,
      );

      // Default config when nothing is persisted.
      final initial = await runner.loadConfig();
      expect(initial.fuelType, FuelType.e10);
      expect(initial.minDropCents, 3);
      expect(initial.minStations, 2);
      expect(initial.radiusKm, 15);
      expect(initial.cooldownHours, 6);

      // Save a custom config (e.g. diesel / 5 ct / 3 stations).
      const custom = VelocityAlertConfig(
        fuelType: FuelType.diesel,
        minDropCents: 5,
        minStations: 3,
        radiusKm: 20,
        cooldownHours: 12,
      );
      await runner.saveConfig(custom);

      final reloaded = await runner.loadConfig();
      expect(reloaded.fuelType, FuelType.diesel);
      expect(reloaded.minDropCents, 5);
      expect(reloaded.minStations, 3);
      expect(reloaded.radiusKm, 20);
      expect(reloaded.cooldownHours, 12);
    });
  });
}
