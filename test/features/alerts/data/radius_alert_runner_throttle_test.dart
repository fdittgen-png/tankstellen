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

/// Per-alert frequency throttling tests for the radius-alerts runner
/// (#1012 phase 1). Today every active alert is evaluated on every
/// WorkManager cycle — phase 1 lets the user cap that to 1/2/3/4
/// times a day per alert. The tests below pin every branch of the
/// throttler so a future refactor can't silently regress to the old
/// "evaluate on every cycle" cadence.
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

RadiusAlertCopy _copy(RadiusAlertGroupedEvent event) {
  final lines = event.matches
      .map((m) => '${m.stationId} ${m.pricePerLiter.toStringAsFixed(3)}')
      .toList();
  if (event.truncatedMoreCount > 0) {
    lines.add('+ ${event.truncatedMoreCount} more');
  }
  return RadiusAlertCopy(
    title:
        '${event.alert.fuelType.toUpperCase()} near ${event.alert.label}',
    body: lines.join('\n'),
  );
}

void main() {
  late Directory tempDir;

  RadiusAlert makeAlert({
    String id = 'r1',
    int frequencyPerDay = 1,
    double threshold = 1.55,
  }) {
    return RadiusAlert(
      id: id,
      fuelType: 'diesel',
      threshold: threshold,
      centerLat: 43.5,
      centerLng: 3.5,
      radiusKm: 10,
      label: 'Home',
      createdAt: DateTime(2026, 1, 1),
      frequencyPerDay: frequencyPerDay,
    );
  }

  StationPriceSample sample({double price = 1.540}) => StationPriceSample(
        stationId: 's1',
        lat: 43.505,
        lng: 3.505,
        fuelType: 'diesel',
        pricePerLiter: price,
      );

  setUpAll(() async {
    tempDir =
        await Directory.systemTemp.createTemp('hive_radius_runner_throttle_');
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

  group('RadiusAlertRunner per-alert frequency throttling (#1012 phase 1)',
      () {
    test('frequencyPerDay=1, last evaluated 23 h ago → SKIPPED', () async {
      final store = RadiusAlertStore();
      final dedup = RadiusAlertDedup();
      final notifier = _FakeNotifier();
      final runner = RadiusAlertRunner(
        store: store,
        dedup: dedup,
        notifier: notifier,
        copyBuilder: _copy,
      );

      final alert = makeAlert(frequencyPerDay: 1);
      await store.upsert(alert);

      final now = DateTime.utc(2026, 4, 22, 12);
      // Pre-seed a "last evaluated" timestamp 23 h ago — under the
      // 24 h gap that frequency=1 requires.
      await store.recordEvaluatedAt(
        alert.id,
        now.subtract(const Duration(hours: 23)),
      );

      var samplesCalled = 0;
      final fired = await runner.run(
        now: now,
        samplesFor: (a) async {
          samplesCalled++;
          return [sample(price: 1.400)];
        },
      );

      expect(fired, isEmpty);
      expect(notifier.priceAlerts, isEmpty);
      expect(samplesCalled, 0,
          reason:
              'Throttled alerts must short-circuit before the samples callback');
      // The throttler must NOT update lastEvaluatedAt for skipped
      // alerts — otherwise the gap would slide forward forever and
      // the alert would never re-evaluate.
      expect(
        await store.getLastEvaluatedAt(alert.id),
        equals(now.subtract(const Duration(hours: 23))),
      );
    });

    test('frequencyPerDay=1, last evaluated 25 h ago → EVALUATED', () async {
      final store = RadiusAlertStore();
      final dedup = RadiusAlertDedup();
      final notifier = _FakeNotifier();
      final runner = RadiusAlertRunner(
        store: store,
        dedup: dedup,
        notifier: notifier,
        copyBuilder: _copy,
      );

      final alert = makeAlert(frequencyPerDay: 1);
      await store.upsert(alert);

      final now = DateTime.utc(2026, 4, 22, 12);
      await store.recordEvaluatedAt(
        alert.id,
        now.subtract(const Duration(hours: 25)),
      );

      var samplesCalled = 0;
      final fired = await runner.run(
        now: now,
        samplesFor: (a) async {
          samplesCalled++;
          return [sample(price: 1.400)];
        },
      );

      expect(samplesCalled, 1);
      expect(fired, hasLength(1));
      expect(notifier.priceAlerts, hasLength(1));
      // Successful evaluation must refresh the timestamp so the next
      // gap starts now.
      expect(await store.getLastEvaluatedAt(alert.id), equals(now));
    });

    test('frequencyPerDay=4, last evaluated 5 h ago → SKIPPED', () async {
      final store = RadiusAlertStore();
      final dedup = RadiusAlertDedup();
      final notifier = _FakeNotifier();
      final runner = RadiusAlertRunner(
        store: store,
        dedup: dedup,
        notifier: notifier,
        copyBuilder: _copy,
      );

      final alert = makeAlert(frequencyPerDay: 4);
      await store.upsert(alert);

      final now = DateTime.utc(2026, 4, 22, 12);
      // Frequency=4 → 6 h gap. 5 h ago is still inside the window.
      await store.recordEvaluatedAt(
        alert.id,
        now.subtract(const Duration(hours: 5)),
      );

      var samplesCalled = 0;
      final fired = await runner.run(
        now: now,
        samplesFor: (a) async {
          samplesCalled++;
          return [sample(price: 1.400)];
        },
      );

      expect(fired, isEmpty);
      expect(notifier.priceAlerts, isEmpty);
      expect(samplesCalled, 0);
    });

    test('frequencyPerDay=4, last evaluated 7 h ago → EVALUATED', () async {
      final store = RadiusAlertStore();
      final dedup = RadiusAlertDedup();
      final notifier = _FakeNotifier();
      final runner = RadiusAlertRunner(
        store: store,
        dedup: dedup,
        notifier: notifier,
        copyBuilder: _copy,
      );

      final alert = makeAlert(frequencyPerDay: 4);
      await store.upsert(alert);

      final now = DateTime.utc(2026, 4, 22, 12);
      await store.recordEvaluatedAt(
        alert.id,
        now.subtract(const Duration(hours: 7)),
      );

      var samplesCalled = 0;
      final fired = await runner.run(
        now: now,
        samplesFor: (a) async {
          samplesCalled++;
          return [sample(price: 1.400)];
        },
      );

      expect(samplesCalled, 1);
      expect(fired, hasLength(1));
      expect(notifier.priceAlerts, hasLength(1));
    });

    test('lastEvaluatedAt == null → EVALUATED regardless of frequency',
        () async {
      // A user who creates a brand-new alert (or upgrades from a
      // pre-#1012 build) has no last-evaluated record. The
      // throttler must let that first cycle through so the alert
      // doesn't sit silent until 24 h later.
      final store = RadiusAlertStore();
      final dedup = RadiusAlertDedup();
      final notifier = _FakeNotifier();
      final runner = RadiusAlertRunner(
        store: store,
        dedup: dedup,
        notifier: notifier,
        copyBuilder: _copy,
      );

      final alert = makeAlert(frequencyPerDay: 1);
      await store.upsert(alert);
      // Deliberately NO recordEvaluatedAt seed.
      expect(await store.getLastEvaluatedAt(alert.id), isNull);

      final now = DateTime.utc(2026, 4, 22, 12);
      var samplesCalled = 0;
      final fired = await runner.run(
        now: now,
        samplesFor: (a) async {
          samplesCalled++;
          return [sample(price: 1.400)];
        },
      );

      expect(samplesCalled, 1);
      expect(fired, hasLength(1));
      // After the first evaluation the throttler now has a record.
      expect(await store.getLastEvaluatedAt(alert.id), equals(now));
    });

    test('no-match cycle still records the evaluation timestamp', () async {
      // If the alert had no in-range stations the runner must still
      // record the timestamp — otherwise an alert with a tight
      // radius would re-query the StationService on every cycle and
      // burn the API budget.
      final store = RadiusAlertStore();
      final dedup = RadiusAlertDedup();
      final notifier = _FakeNotifier();
      final runner = RadiusAlertRunner(
        store: store,
        dedup: dedup,
        notifier: notifier,
        copyBuilder: _copy,
      );

      final alert = makeAlert(frequencyPerDay: 1, threshold: 1.40);
      await store.upsert(alert);

      final now = DateTime.utc(2026, 4, 22, 12);
      final fired = await runner.run(
        now: now,
        // Sample exists but is above threshold → no match.
        samplesFor: (a) async => [sample(price: 1.600)],
      );

      expect(fired, isEmpty);
      expect(notifier.priceAlerts, isEmpty);
      expect(await store.getLastEvaluatedAt(alert.id), equals(now));
    });
  });
}
