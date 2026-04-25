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

  // #1012 phase 2 — the runner now fires one notification per alert
  // per cycle, so the dedup *decision* moved from per-(alert, station)
  // to per-alert. The per-station ledger still exists (phase 3 deep-
  // links use it), but `shouldNotifyAlert` is the gate.
  group('RadiusAlertDedup alert-level (#1012 phase 2)', () {
    test('first alert-level notification is always allowed', () async {
      final dedup = RadiusAlertDedup();
      final allowed = await dedup.shouldNotifyAlert(
        alertId: 'a1',
        cheapestPrice: 1.550,
        now: DateTime.utc(2026, 4, 22, 12),
      );
      expect(allowed, isTrue);
    });

    test(
        'within 12 h with the cheapest unchanged → suppressed (per-alert window)',
        () async {
      final dedup = RadiusAlertDedup();
      final t0 = DateTime.utc(2026, 4, 22, 12);
      await dedup.recordAlertFire(
          alertId: 'a1', cheapestPrice: 1.550, now: t0);

      final allowed = await dedup.shouldNotifyAlert(
        alertId: 'a1',
        cheapestPrice: 1.550,
        now: t0.add(const Duration(hours: 11, minutes: 59)),
      );
      expect(allowed, isFalse);
    });

    test(
        'within 12 h but cheapest dropped further → fires (further-drop override preserved)',
        () async {
      final dedup = RadiusAlertDedup();
      final t0 = DateTime.utc(2026, 4, 22, 12);
      await dedup.recordAlertFire(
          alertId: 'a1', cheapestPrice: 1.550, now: t0);

      // 4 h later the cheapest match dropped another cent — the user
      // wants to know the new floor even though the dedup window is
      // still active.
      final allowed = await dedup.shouldNotifyAlert(
        alertId: 'a1',
        cheapestPrice: 1.540,
        now: t0.add(const Duration(hours: 4)),
      );
      expect(allowed, isTrue);
    });

    test('sub-epsilon wiggle on the cheapest is still suppressed',
        () async {
      final dedup = RadiusAlertDedup();
      final t0 = DateTime.utc(2026, 4, 22, 12);
      await dedup.recordAlertFire(
          alertId: 'a1', cheapestPrice: 1.550, now: t0);

      final allowed = await dedup.shouldNotifyAlert(
        alertId: 'a1',
        cheapestPrice: 1.5495,
        now: t0.add(const Duration(hours: 1)),
      );
      expect(allowed, isFalse);
    });

    test('alert-level notification re-fires once 12 h elapsed', () async {
      final dedup = RadiusAlertDedup();
      final t0 = DateTime.utc(2026, 4, 22, 12);
      await dedup.recordAlertFire(
          alertId: 'a1', cheapestPrice: 1.550, now: t0);

      final allowed = await dedup.shouldNotifyAlert(
        alertId: 'a1',
        cheapestPrice: 1.550,
        now: t0.add(const Duration(hours: 12, minutes: 1)),
      );
      expect(allowed, isTrue);
    });

    test('alert-level dedup is scoped per alertId', () async {
      final dedup = RadiusAlertDedup();
      final t0 = DateTime.utc(2026, 4, 22, 12);
      await dedup.recordAlertFire(
          alertId: 'a1', cheapestPrice: 1.550, now: t0);

      // a2 hasn't been recorded — must fire.
      expect(
        await dedup.shouldNotifyAlert(
          alertId: 'a2',
          cheapestPrice: 1.550,
          now: t0.add(const Duration(minutes: 5)),
        ),
        isTrue,
      );
    });

    test(
        'per-station fire records remain readable after alert-level fire (phase 3 deep-link prereq)',
        () async {
      // Phase 3 will deep-link to the cheapest station shown in a
      // grouped notification. Its tap handler reads the per-station
      // ledger to know "what price did we tell the user about this
      // station?". The runner stamps both ledgers in one cycle, so we
      // pin here that they coexist and the per-station read still
      // works after the alert-level row is written.
      final dedup = RadiusAlertDedup();
      final t0 = DateTime.utc(2026, 4, 22, 12);
      await dedup.recordAlertFire(
          alertId: 'a1', cheapestPrice: 1.500, now: t0);
      await dedup.recordFire(
          alertId: 'a1', stationId: 's1', price: 1.500, now: t0);
      await dedup.recordFire(
          alertId: 'a1', stationId: 's2', price: 1.520, now: t0);

      // Per-station gate still suppresses repeats within the window.
      expect(
        await dedup.shouldNotify(
          alertId: 'a1',
          stationId: 's1',
          currentPrice: 1.500,
          now: t0.add(const Duration(hours: 1)),
        ),
        isFalse,
      );
      expect(
        await dedup.shouldNotify(
          alertId: 'a1',
          stationId: 's2',
          currentPrice: 1.520,
          now: t0.add(const Duration(hours: 1)),
        ),
        isFalse,
      );
      // And the per-station further-drop override still works.
      expect(
        await dedup.shouldNotify(
          alertId: 'a1',
          stationId: 's2',
          currentPrice: 1.500,
          now: t0.add(const Duration(hours: 1)),
        ),
        isTrue,
      );
    });

    test('clearForAlert wipes both alert-level and per-station rows',
        () async {
      final dedup = RadiusAlertDedup();
      final t0 = DateTime.utc(2026, 4, 22, 12);
      await dedup.recordAlertFire(
          alertId: 'a1', cheapestPrice: 1.550, now: t0);
      await dedup.recordFire(
          alertId: 'a1', stationId: 's1', price: 1.550, now: t0);
      await dedup.recordAlertFire(
          alertId: 'a2', cheapestPrice: 1.560, now: t0);

      await dedup.clearForAlert('a1');

      // a1 alert-level row gone — shouldNotifyAlert returns true.
      expect(
        await dedup.shouldNotifyAlert(
          alertId: 'a1',
          cheapestPrice: 1.550,
          now: t0.add(const Duration(minutes: 1)),
        ),
        isTrue,
      );
      // a2 alert-level row preserved.
      expect(
        await dedup.shouldNotifyAlert(
          alertId: 'a2',
          cheapestPrice: 1.560,
          now: t0.add(const Duration(minutes: 1)),
        ),
        isFalse,
      );
    });
  });
}
