import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/features/alerts/data/models/price_snapshot.dart';
import 'package:tankstellen/features/alerts/data/price_snapshot_store.dart';

void main() {
  late Directory tempDir;

  PriceSnapshot makeSnapshot({
    String stationId = 's1',
    String fuelType = 'e10',
    double price = 1.899,
    DateTime? at,
    double lat = 43.5,
    double lng = 3.5,
  }) {
    return PriceSnapshot(
      stationId: stationId,
      fuelType: fuelType,
      price: price,
      timestamp: at ?? DateTime.utc(2026, 4, 22, 12),
      lat: lat,
      lng: lng,
    );
  }

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_price_snapshots_');
    Hive.init(tempDir.path);
  });

  setUp(() async {
    if (Hive.isBoxOpen(HiveBoxes.priceSnapshots)) {
      await Hive.box<String>(HiveBoxes.priceSnapshots).close();
    }
    await Hive.openBox<String>(HiveBoxes.priceSnapshots);
    await Hive.box<String>(HiveBoxes.priceSnapshots).clear();
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('PriceSnapshotStore', () {
    test('records a snapshot and reads it back', () async {
      final now = DateTime.utc(2026, 4, 22, 12);
      final store = PriceSnapshotStore(now: () => now);
      final snap = makeSnapshot(at: now);

      await store.recordSnapshot(snap);

      final all = await store.all();
      expect(all, hasLength(1));
      final read = all.single;
      expect(read.stationId, 's1');
      expect(read.fuelType, 'e10');
      expect(read.price, closeTo(1.899, 0.0001));
      expect(read.timestamp, now);
      expect(read.lat, closeTo(43.5, 0.0001));
      expect(read.lng, closeTo(3.5, 0.0001));
    });

    test('auto-prunes snapshots older than the 6 h retention window',
        () async {
      final now = DateTime.utc(2026, 4, 22, 12);
      final store = PriceSnapshotStore(now: () => now);

      // Seed with a snapshot from 8 h ago — will be pruned on next
      // write — and one from 2 h ago — will survive.
      await store.recordSnapshot(makeSnapshot(
          stationId: 's_old', at: now.subtract(const Duration(hours: 8))));
      await store.recordSnapshot(makeSnapshot(
          stationId: 's_recent',
          at: now.subtract(const Duration(hours: 2))));

      // Trigger pruning by adding a fresh snapshot.
      await store.recordSnapshot(makeSnapshot(
          stationId: 's_fresh', at: now));

      final remaining = await store.all();
      final ids = remaining.map((s) => s.stationId).toSet();
      expect(ids, {'s_recent', 's_fresh'});
      expect(ids, isNot(contains('s_old')));
    });

    test('snapshotsOlderThan returns only older entries', () async {
      final now = DateTime.utc(2026, 4, 22, 12);
      final store = PriceSnapshotStore(now: () => now);

      await store.recordSnapshot(makeSnapshot(
          stationId: 's_fresh', at: now.subtract(const Duration(minutes: 5))));
      await store.recordSnapshot(makeSnapshot(
          stationId: 's_hourAgo',
          at: now.subtract(const Duration(hours: 1, minutes: 10))));

      final older = await store.snapshotsOlderThan(const Duration(hours: 1));
      expect(older.map((s) => s.stationId), ['s_hourAgo']);
    });
  });
}
