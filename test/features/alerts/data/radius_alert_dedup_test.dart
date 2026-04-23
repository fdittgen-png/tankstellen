import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/features/alerts/data/radius_alert_dedup.dart';

/// Covers the per-alert-per-station rate limit that keeps the BG
/// isolate from re-notifying every 1 h cycle while a station is
/// below the user's threshold (#578 phase 3).
void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_radius_dedup_');
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

  group('RadiusAlertDedup', () {
    test('first notification is always allowed', () async {
      final dedup = RadiusAlertDedup();
      final allowed = await dedup.shouldNotify(
        alertId: 'a1',
        stationId: 's1',
        currentPrice: 1.550,
        now: DateTime.utc(2026, 4, 22, 12),
      );
      expect(allowed, isTrue);
    });

    test(
        'second notification within 12 h at the same price is suppressed',
        () async {
      final dedup = RadiusAlertDedup();
      final t0 = DateTime.utc(2026, 4, 22, 12);
      await dedup.recordFire(
          alertId: 'a1', stationId: 's1', price: 1.550, now: t0);

      final allowed = await dedup.shouldNotify(
        alertId: 'a1',
        stationId: 's1',
        currentPrice: 1.550,
        now: t0.add(const Duration(hours: 11, minutes: 59)),
      );
      expect(allowed, isFalse);
    });

    test('further price drop bypasses the dedup window', () async {
      final dedup = RadiusAlertDedup();
      final t0 = DateTime.utc(2026, 4, 22, 12);
      await dedup.recordFire(
          alertId: 'a1', stationId: 's1', price: 1.550, now: t0);

      // 4 h later the station dropped another cent — user wants to know.
      final allowed = await dedup.shouldNotify(
        alertId: 'a1',
        stationId: 's1',
        currentPrice: 1.540,
        now: t0.add(const Duration(hours: 4)),
      );
      expect(allowed, isTrue);
    });

    test('a 0.1 ct wiggle inside the window is treated as noise', () async {
      final dedup = RadiusAlertDedup();
      final t0 = DateTime.utc(2026, 4, 22, 12);
      await dedup.recordFire(
          alertId: 'a1', stationId: 's1', price: 1.550, now: t0);

      // Sub-epsilon "drop" — Tankerkoenig prices jitter by 0.001 € all
      // the time. Suppressing these keeps the notification channel sane.
      final allowed = await dedup.shouldNotify(
        alertId: 'a1',
        stationId: 's1',
        currentPrice: 1.5495,
        now: t0.add(const Duration(hours: 2)),
      );
      expect(allowed, isFalse);
    });

    test('notification re-fires once the 12 h window has elapsed', () async {
      final dedup = RadiusAlertDedup();
      final t0 = DateTime.utc(2026, 4, 22, 12);
      await dedup.recordFire(
          alertId: 'a1', stationId: 's1', price: 1.550, now: t0);

      final allowed = await dedup.shouldNotify(
        alertId: 'a1',
        stationId: 's1',
        currentPrice: 1.550,
        now: t0.add(const Duration(hours: 12, minutes: 1)),
      );
      expect(allowed, isTrue);
    });

    test(
        'dedup is scoped per (alertId, stationId) — other pairs untouched',
        () async {
      final dedup = RadiusAlertDedup();
      final t0 = DateTime.utc(2026, 4, 22, 12);
      await dedup.recordFire(
          alertId: 'a1', stationId: 's1', price: 1.550, now: t0);

      // Different station, same alert.
      expect(
        await dedup.shouldNotify(
          alertId: 'a1',
          stationId: 's2',
          currentPrice: 1.550,
          now: t0.add(const Duration(minutes: 1)),
        ),
        isTrue,
      );
      // Different alert, same station.
      expect(
        await dedup.shouldNotify(
          alertId: 'a2',
          stationId: 's1',
          currentPrice: 1.550,
          now: t0.add(const Duration(minutes: 1)),
        ),
        isTrue,
      );
    });

    test('clearForAlert removes only that alert\'s rows', () async {
      final dedup = RadiusAlertDedup();
      final t0 = DateTime.utc(2026, 4, 22, 12);
      await dedup.recordFire(
          alertId: 'a1', stationId: 's1', price: 1.550, now: t0);
      await dedup.recordFire(
          alertId: 'a1', stationId: 's2', price: 1.555, now: t0);
      await dedup.recordFire(
          alertId: 'a2', stationId: 's1', price: 1.560, now: t0);

      await dedup.clearForAlert('a1');

      // a1 rows gone — shouldNotify returns true again.
      expect(
        await dedup.shouldNotify(
          alertId: 'a1',
          stationId: 's1',
          currentPrice: 1.550,
          now: t0.add(const Duration(minutes: 1)),
        ),
        isTrue,
      );
      // a2 row preserved — still suppressed within 12 h.
      expect(
        await dedup.shouldNotify(
          alertId: 'a2',
          stationId: 's1',
          currentPrice: 1.560,
          now: t0.add(const Duration(minutes: 1)),
        ),
        isFalse,
      );
    });
  });
}
