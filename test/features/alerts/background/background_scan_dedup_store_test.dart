// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tankstellen/features/alerts/background/background_scan_dedup_store.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';

/// #2415 — cross-trigger scan cooldown. Verifies two background triggers
/// firing close together can't both run a scan, while a legitimately-spaced
/// scan still proceeds.
void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_bg_scan_dedup_');
    Hive.init(tempDir.path);
  });

  setUp(() async {
    if (Hive.isBoxOpen(HiveBoxes.alerts)) {
      await Hive.box<dynamic>(HiveBoxes.alerts).close();
    }
    await Hive.openBox<dynamic>(HiveBoxes.alerts);
    await Hive.box<dynamic>(HiveBoxes.alerts).clear();
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('BackgroundScanDedupStore', () {
    const cooldown = Duration(minutes: 10);
    final t0 = DateTime.utc(2026, 5, 30, 8);

    test('first scan is always allowed (no row recorded)', () async {
      final store = BackgroundScanDedupStore();
      expect(await store.shouldScan(now: t0, cooldown: cooldown), isTrue);
      expect(await store.lastScanAt(), isNull);
    });

    test('a second trigger inside the cooldown is suppressed', () async {
      final store = BackgroundScanDedupStore();
      await store.recordScan(now: t0, trigger: 'workmanager_periodic');

      // 2 minutes later: still inside the 10-minute window → skip.
      final later = t0.add(const Duration(minutes: 2));
      expect(await store.shouldScan(now: later, cooldown: cooldown), isFalse);
    });

    test('a trigger after the cooldown elapses is allowed again', () async {
      final store = BackgroundScanDedupStore();
      await store.recordScan(now: t0, trigger: 'android_widget');

      // Exactly at the boundary → allowed (>= cooldown).
      final atBoundary = t0.add(cooldown);
      expect(
          await store.shouldScan(now: atBoundary, cooldown: cooldown), isTrue);

      // Well past → allowed.
      final later = t0.add(const Duration(hours: 1));
      expect(await store.shouldScan(now: later, cooldown: cooldown), isTrue);
    });

    test('records the trigger tag and timestamp', () async {
      final store = BackgroundScanDedupStore();
      await store.recordScan(now: t0, trigger: 'ios_bg_refresh');
      expect(await store.lastScanAt(), t0);
      final box = Hive.box<dynamic>(HiveBoxes.alerts);
      expect(box.get(BackgroundScanDedupStore.lastTriggerKey), 'ios_bg_refresh');
    });

    test('a backwards clock jump is treated as stale and allowed', () async {
      final store = BackgroundScanDedupStore();
      await store.recordScan(now: t0, trigger: 'workmanager_periodic');
      // Device clock jumps *backwards* — last scan now looks "in the future".
      final earlier = t0.subtract(const Duration(minutes: 5));
      expect(await store.shouldScan(now: earlier, cooldown: cooldown), isTrue);
    });

    test('clear removes the dedup row', () async {
      final store = BackgroundScanDedupStore();
      await store.recordScan(now: t0, trigger: 'workmanager_periodic');
      await store.clear();
      expect(await store.lastScanAt(), isNull);
      expect(await store.shouldScan(now: t0, cooldown: cooldown), isTrue);
    });
  });
}
