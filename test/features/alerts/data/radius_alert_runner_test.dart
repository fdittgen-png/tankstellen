import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tankstellen/core/notifications/notification_service.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/features/alerts/data/radius_alert_dedup.dart';
import 'package:tankstellen/features/alerts/data/radius_alert_runner.dart';
import 'package:tankstellen/features/alerts/data/radius_alert_store.dart';
import 'package:tankstellen/features/alerts/domain/entities/radius_alert.dart';
import 'package:tankstellen/features/alerts/domain/radius_alert_evaluator.dart';

/// Captures every notification the runner emits. Stand-in for
/// [LocalNotificationService] — the service layer only needs
/// `showPriceAlert` to reach it.
class _FakeNotifier implements NotificationService {
  final List<({int id, String title, String body})> priceAlerts = [];

  @override
  Future<void> initialize() async {}

  @override
  Future<void> showPriceAlert({
    required int id,
    required String title,
    required String body,
  }) async {
    priceAlerts.add((id: id, title: title, body: body));
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

RadiusAlertCopy _copy(RadiusAlertNotification event) => RadiusAlertCopy(
      title: '${event.alert.fuelType.toUpperCase()} near ${event.alert.label}',
      body: 'A station is at ${event.price.toStringAsFixed(3)}',
    );

void main() {
  late Directory tempDir;

  RadiusAlert makeAlert({
    String id = 'r1',
    String fuelType = 'diesel',
    double threshold = 1.55,
    double centerLat = 43.5,
    double centerLng = 3.5,
    double radiusKm = 10,
    String label = 'Home',
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
      createdAt: DateTime(2026, 1, 1),
      enabled: enabled,
    );
  }

  StationPriceSample sample({
    String stationId = 's1',
    double lat = 43.505,
    double lng = 3.505,
    String fuelType = 'diesel',
    double price = 1.540,
  }) {
    return StationPriceSample(
      stationId: stationId,
      lat: lat,
      lng: lng,
      fuelType: fuelType,
      pricePerLiter: price,
    );
  }

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_radius_runner_');
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

  group('RadiusAlertRunner', () {
    test('fires a notification when a sample is at or below threshold',
        () async {
      final store = RadiusAlertStore();
      final dedup = RadiusAlertDedup();
      final notifier = _FakeNotifier();
      final runner = RadiusAlertRunner(
        store: store,
        dedup: dedup,
        notifier: notifier,
        copyBuilder: _copy,
      );

      final alert = makeAlert(id: 'r1');
      await store.upsert(alert);

      final fired = await runner.run(
        now: DateTime.utc(2026, 4, 22, 12),
        samplesFor: (a) async => [
          sample(stationId: 's1', price: 1.540), // below 1.55
        ],
      );

      expect(fired, hasLength(1));
      expect(notifier.priceAlerts, hasLength(1));
      expect(notifier.priceAlerts.single.title, contains('DIESEL'));
      expect(notifier.priceAlerts.single.title, contains('Home'));
      expect(notifier.priceAlerts.single.body, contains('1.540'));
    });

    test('skips disabled alerts entirely', () async {
      final store = RadiusAlertStore();
      final dedup = RadiusAlertDedup();
      final notifier = _FakeNotifier();
      final runner = RadiusAlertRunner(
        store: store,
        dedup: dedup,
        notifier: notifier,
        copyBuilder: _copy,
      );

      await store.upsert(makeAlert(id: 'r1', enabled: false));

      var samplesCalled = 0;
      final fired = await runner.run(
        now: DateTime.utc(2026, 4, 22, 12),
        samplesFor: (a) async {
          samplesCalled++;
          return [sample(price: 1.400)];
        },
      );

      expect(fired, isEmpty);
      expect(notifier.priceAlerts, isEmpty);
      expect(samplesCalled, 0,
          reason:
              'Disabled alerts should short-circuit before the samples callback runs');
    });

    test('no notification when no sample is below threshold', () async {
      final store = RadiusAlertStore();
      final dedup = RadiusAlertDedup();
      final notifier = _FakeNotifier();
      final runner = RadiusAlertRunner(
        store: store,
        dedup: dedup,
        notifier: notifier,
        copyBuilder: _copy,
      );

      await store.upsert(makeAlert(id: 'r1', threshold: 1.40));

      final fired = await runner.run(
        now: DateTime.utc(2026, 4, 22, 12),
        samplesFor: (a) async => [
          sample(stationId: 's1', price: 1.600),
          sample(stationId: 's2', price: 1.550),
        ],
      );

      expect(fired, isEmpty);
      expect(notifier.priceAlerts, isEmpty);
    });

    test('no notification when samples are outside the radius', () async {
      final store = RadiusAlertStore();
      final dedup = RadiusAlertDedup();
      final notifier = _FakeNotifier();
      final runner = RadiusAlertRunner(
        store: store,
        dedup: dedup,
        notifier: notifier,
        copyBuilder: _copy,
      );

      await store.upsert(makeAlert(id: 'r1', radiusKm: 1));

      final fired = await runner.run(
        now: DateTime.utc(2026, 4, 22, 12),
        samplesFor: (a) async => [
          // ~50 km away from (43.5, 3.5)
          sample(stationId: 'far', lat: 44.0, lng: 3.5, price: 1.300),
        ],
      );

      expect(fired, isEmpty);
      expect(notifier.priceAlerts, isEmpty);
    });

    test(
        'second cycle at the same price is suppressed by the 12 h dedup window',
        () async {
      final store = RadiusAlertStore();
      final dedup = RadiusAlertDedup();
      final notifier = _FakeNotifier();
      final runner = RadiusAlertRunner(
        store: store,
        dedup: dedup,
        notifier: notifier,
        copyBuilder: _copy,
      );

      await store.upsert(makeAlert(id: 'r1'));

      final t0 = DateTime.utc(2026, 4, 22, 12);
      await runner.run(
        now: t0,
        samplesFor: (a) async => [sample(stationId: 's1', price: 1.540)],
      );

      // A second run 1 h later with the same price — should NOT re-fire.
      final fired = await runner.run(
        now: t0.add(const Duration(hours: 1)),
        samplesFor: (a) async => [sample(stationId: 's1', price: 1.540)],
      );

      expect(fired, isEmpty);
      expect(notifier.priceAlerts, hasLength(1),
          reason:
              'Exactly one notification should have been fired across the two cycles');
    });

    test('further price drop inside the dedup window re-fires', () async {
      final store = RadiusAlertStore();
      final dedup = RadiusAlertDedup();
      final notifier = _FakeNotifier();
      final runner = RadiusAlertRunner(
        store: store,
        dedup: dedup,
        notifier: notifier,
        copyBuilder: _copy,
      );

      await store.upsert(makeAlert(id: 'r1'));

      final t0 = DateTime.utc(2026, 4, 22, 12);
      await runner.run(
        now: t0,
        samplesFor: (a) async => [sample(stationId: 's1', price: 1.540)],
      );

      // 2 h later the station dropped by another cent — user wants it.
      final fired = await runner.run(
        now: t0.add(const Duration(hours: 2)),
        samplesFor: (a) async => [sample(stationId: 's1', price: 1.530)],
      );

      expect(fired, hasLength(1));
      expect(notifier.priceAlerts, hasLength(2));
      expect(notifier.priceAlerts.last.body, contains('1.530'));
    });

    test(
        're-fires once the dedup window has elapsed even at the same price',
        () async {
      final store = RadiusAlertStore();
      final dedup = RadiusAlertDedup();
      final notifier = _FakeNotifier();
      final runner = RadiusAlertRunner(
        store: store,
        dedup: dedup,
        notifier: notifier,
        copyBuilder: _copy,
      );

      await store.upsert(makeAlert(id: 'r1'));

      final t0 = DateTime.utc(2026, 4, 22, 12);
      await runner.run(
        now: t0,
        samplesFor: (a) async => [sample(stationId: 's1', price: 1.540)],
      );

      // 13 h later — same price, but the reminder has aged out.
      final fired = await runner.run(
        now: t0.add(const Duration(hours: 13)),
        samplesFor: (a) async => [sample(stationId: 's1', price: 1.540)],
      );

      expect(fired, hasLength(1));
      expect(notifier.priceAlerts, hasLength(2));
    });

    test('multiple in-range stations each get their own notification',
        () async {
      final store = RadiusAlertStore();
      final dedup = RadiusAlertDedup();
      final notifier = _FakeNotifier();
      final runner = RadiusAlertRunner(
        store: store,
        dedup: dedup,
        notifier: notifier,
        copyBuilder: _copy,
      );

      await store.upsert(makeAlert(id: 'r1'));

      final fired = await runner.run(
        now: DateTime.utc(2026, 4, 22, 12),
        samplesFor: (a) async => [
          sample(stationId: 's1', price: 1.540),
          sample(stationId: 's2', price: 1.545, lat: 43.51, lng: 3.51),
        ],
      );

      expect(fired, hasLength(2));
      expect(notifier.priceAlerts, hasLength(2));
      expect(
        notifier.priceAlerts.map((n) => n.id).toSet().length,
        2,
        reason:
            'Each (alert, station) pair must resolve to a distinct notification id',
      );
    });

    test('one alert failing does not block the rest', () async {
      final store = RadiusAlertStore();
      final dedup = RadiusAlertDedup();
      final notifier = _FakeNotifier();
      final runner = RadiusAlertRunner(
        store: store,
        dedup: dedup,
        notifier: notifier,
        copyBuilder: _copy,
      );

      await store.upsert(makeAlert(id: 'bad'));
      await store.upsert(makeAlert(id: 'good'));

      final fired = await runner.run(
        now: DateTime.utc(2026, 4, 22, 12),
        samplesFor: (a) async {
          if (a.id == 'bad') {
            throw StateError('upstream API down');
          }
          return [sample(stationId: 's1', price: 1.540)];
        },
      );

      // Exactly one good alert survived.
      expect(fired, hasLength(1));
      expect(notifier.priceAlerts, hasLength(1));
    });

    test(
        'integration: create alert → price drop → notification pushed → dedup persisted',
        () async {
      // Full service-level integration: store → runner → dedup →
      // notifier, exercising the same code path the BG isolate takes
      // minus the real StationService.
      final store = RadiusAlertStore();
      final dedup = RadiusAlertDedup();
      final notifier = _FakeNotifier();
      final runner = RadiusAlertRunner(
        store: store,
        dedup: dedup,
        notifier: notifier,
        copyBuilder: _copy,
      );

      // 1. User creates a radius alert via the phase-2 create sheet.
      await store.upsert(makeAlert(id: 'r1', threshold: 1.55));

      // 2. BG cycle sees a station above threshold — no fire.
      final firedAbove = await runner.run(
        now: DateTime.utc(2026, 4, 22, 12),
        samplesFor: (a) async => [sample(stationId: 's1', price: 1.600)],
      );
      expect(firedAbove, isEmpty);
      expect(notifier.priceAlerts, isEmpty);

      // 3. Next BG cycle: price dropped below threshold — fire.
      final firedDrop = await runner.run(
        now: DateTime.utc(2026, 4, 22, 13),
        samplesFor: (a) async => [sample(stationId: 's1', price: 1.540)],
      );
      expect(firedDrop, hasLength(1));
      expect(notifier.priceAlerts, hasLength(1));

      // 4. Dedup persisted — immediate re-run is silent.
      final firedRepeat = await runner.run(
        now: DateTime.utc(2026, 4, 22, 13, 30),
        samplesFor: (a) async => [sample(stationId: 's1', price: 1.540)],
      );
      expect(firedRepeat, isEmpty);
      expect(notifier.priceAlerts, hasLength(1));
    });
  });
}
