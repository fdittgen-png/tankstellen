// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:io';
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/services/persistent_dataset.dart';
import 'package:tankstellen/core/cache/cache_manager.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/core/storage/hive_dataset_repair.dart';
import 'package:tankstellen/core/background/hive_isolate_lock.dart';
import 'package:tankstellen/core/storage/hive_deferred_user_boxes.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/core/storage/hive_first_frame_boxes.dart';
import 'package:tankstellen/core/storage/hive_open_timing.dart';
import 'package:tankstellen/core/storage/hive_schema_migration.dart';

import '../../helpers/hive_temp_dir.dart';

/// #4110 — the whole-country datasets are not first-frame work.
///
/// `Hive.openBox` DESERIALIZES every value it reads: `framesFromFile`
/// decrypts each frame and runs it through the type registry. The
/// `dataset:` entries are multi-MB national payloads (~11k
/// `Station.fromJson`) and they lived in the `cache` box — which
/// `HiveFirstFrameBoxes` opens before the app paints. So every cold start
/// rehydrated every cached country on the main isolate, which is exactly
/// the work `PersistentDataset.readAsync` puts through `compute()` to keep
/// off it.
///
/// These RUN the production batch rather than describing it (#4116).
void main() {
  late Directory tmpDir;

  setUp(() {
    tmpDir = Directory.systemTemp.createTempSync('dataset_box_');
    Hive.init(tmpDir.path);
    HiveDatasetRepair.lockFactory = () async => HiveIsolateLock.fromFile(
        File('${tmpDir.path}/hive_bg.lock'));
    HiveOpenTiming.reset();
    HiveDeferredUserBoxes.resetForTest();
  });

  tearDown(() async {
    HiveDeferredUserBoxes.resetForTest();
    HiveDatasetRepair.lockFactory = HiveIsolateLock.create;
    await closeHiveAndDeleteTemp(tmpDir);
  });

  test('the first-frame batch leaves the datasets box CLOSED', () async {
    // The claim the whole change rests on. If the datasets box ever
    // rejoins this batch, the cold start silently pays for it again and
    // nothing else in the suite would notice.
    await HiveFirstFrameBoxes.openAll(null);

    expect(Hive.isBoxOpen(HiveBoxes.datasets), isFalse,
        reason: 'the first frame must not wait on national datasets');
    expect(Hive.isBoxOpen(HiveBoxes.cache), isTrue,
        reason: 'the per-search response cache IS needed to paint, and '
            'moving the datasets out must not have taken it along');
  });

  test(
    'service constructed before deferred open never writes startup cache',
    () async {
      await HiveFirstFrameBoxes.openAll(null);
      final cache = datasetCacheFor(HiveStorage());
      await Hive.openBox<dynamic>(HiveBoxes.datasets);
      await cache.put(
        'dataset:FR:stations',
        {'stations': <dynamic>[]},
        ttl: const Duration(days: 1),
        source: ServiceSource.cache,
      );
      expect(
        Hive.box<dynamic>(HiveBoxes.cache).keys,
        isNot(contains('dataset:FR:stations')),
      );
      expect(
        Hive.box<dynamic>(HiveBoxes.datasets).keys,
        contains('dataset:FR:stations'),
      );
      expect(cache.get('dataset:FR:stations'), isNotNull);
    },
  );

  test(
    'cold async read waits for encrypted disk data instead of a cache miss',
    () async {
      final cipher = HiveAesCipher(List<int>.filled(32, 7));
      HiveDeferredUserBoxes.arm(cipher);
      final cache = datasetCacheFor(HiveStorage());
      final dataset = PersistentDataset<int>(
        cache: cache,
        countryCode: 'FR',
        datasetName: 'stations',
        source: ServiceSource.cache,
        serialize: (value) => {'count': value},
        deserialize: (raw) => raw['count'] as int,
      );
      // The first write must open its own box, not disappear into a no-op.
      await dataset.write(11000, hardTtl: const Duration(days: 1));
      await Hive.box<dynamic>(HiveBoxes.datasets).close();
      HiveDeferredUserBoxes.resetForTest();
      HiveDeferredUserBoxes.arm(cipher);
      expect((await dataset.readAsync())?.value, 11000);
      expect(Hive.isBoxOpen(HiveBoxes.cache), isFalse);
    },
  );

  test(
    'repair preserves newest datasets and itineraries across cold reopen',
    () async {
      final cipher = HiveAesCipher(List<int>.filled(32, 7));
      final cache = await Hive.openBox<dynamic>(
        HiveBoxes.cache,
        encryptionCipher: cipher,
      );
      final datasets = await Hive.openBox<dynamic>(
        HiveBoxes.datasets,
        encryptionCipher: cipher,
      );
      Map<String, dynamic> row(int stamp, Object value) => {
        'data': {'storedAt': stamp, 'payload': value},
      };
      final large = row(
        20,
        List.generate(11000, (i) => {'id': i, 'price': 1.7}),
      );
      await cache.put('dataset:FR:stations', large);
      await cache.put('dataset:DE:stations', row(10, 'old'));
      await datasets.put('dataset:DE:stations', row(30, 'new'));
      await cache.put('itineraries', [
        {'id': 'saved-trip'},
      ]);
      await cache.put('search:FR', row(10, 'last known prices'));
      await cache.close();
      await datasets.close();
      final before = await File('${tmpDir.path}/cache.hive').length();
      final schema = await Hive.openBox<int>(HiveBoxes.boxSchema);
      var ticks = 0;
      final heartbeat = Timer.periodic(const Duration(milliseconds: 1), (_) {
        ticks++;
      });
      try {
        await HiveDatasetRepair.runOnce(tmpDir.path, cipher);
      } finally {
        heartbeat.cancel();
      }
      expect(
        ticks,
        greaterThan(0),
        reason: 'foreground event loop keeps running',
      );
      expect(schema.get(HiveDatasetRepair.marker), 1);
      expect(Hive.isBoxOpen(HiveBoxes.cache), isFalse);
      final repaired = await Hive.openBox<dynamic>(
        HiveBoxes.cache,
        encryptionCipher: cipher,
      );
      final separate = await Hive.openBox<dynamic>(
        HiveBoxes.datasets,
        encryptionCipher: cipher,
      );
      expect(repaired.get('itineraries'), [
        {'id': 'saved-trip'},
      ]);
      expect(repaired.get('search:FR'), row(10, 'last known prices'));
      expect(
        repaired.keys.whereType<String>().where(
          (k) => k.startsWith('dataset:'),
        ),
        isEmpty,
      );
      expect(separate.get('dataset:FR:stations'), large);
      expect(separate.get('dataset:DE:stations'), row(30, 'new'));
      expect(
        await File('${tmpDir.path}/cache.hive').length(),
        lessThan(before ~/ 2),
      );
      // The marker prevents a worker from touching files already open by UI.
      await HiveDatasetRepair.runOnce(tmpDir.path, cipher);
      expect(repaired.isOpen, isTrue);
    },
  );

  test('repair skips a live background owner without stamping completion',
      () async {
    final schema = await Hive.openBox<int>(HiveBoxes.boxSchema);
    final owner = await HiveDatasetRepair.lockFactory();
    expect(await owner.acquire(), isTrue);
    try {
      await HiveDatasetRepair.runOnce(tmpDir.path, null);
      expect(schema.get(HiveDatasetRepair.marker), isNull);
      expect(owner.isLocked, isTrue);
      expect(Hive.isBoxOpen(HiveBoxes.cache), isFalse);
    } finally {
      owner.release();
    }
    await HiveDatasetRepair.runOnce(tmpDir.path, null);
    expect(schema.get(HiveDatasetRepair.marker), 1);
  });

  test('repair reclaims deleted frames after interrupted move', () async {
    final cache = await Hive.openBox<dynamic>(HiveBoxes.cache,
        compactionStrategy: (_, _) => false);
    await cache.put('dataset:FR:stations', 'x' * 100000);
    await cache.delete('dataset:FR:stations');
    await cache.close();
    final file = File('${tmpDir.path}/cache.hive');
    expect(await file.length(), greaterThan(100000));
    await Hive.openBox<int>(HiveBoxes.boxSchema);
    await HiveDatasetRepair.runOnce(tmpDir.path, null);
    expect(await file.length(), lessThan(1000));
  });

  test('it is a box of its own, not an alias of the cache box', () {
    expect(HiveBoxes.datasets, isNot(HiveBoxes.cache));
  });

  test('it is in allBoxes, so local erasure and the export cover it', () {
    // #3867 — a box missing from this set is invisible to
    // LocalDataEraser: "delete all my data" would leave it on disk.
    expect(HiveBoxes.allBoxes, contains(HiveBoxes.datasets));
  });

  test('the schema bump drops the orphaned copies from the cache box', () {
    // The migration is an eviction, not a move: `dataset:` keys written
    // before this change sit in the cache box where nothing reads them
    // now. They are caches with a hard TTL, so dropping them costs one
    // refetch per country, once — and leaving them would keep charging
    // the cold start exactly what this change removed.
    expect(HiveBoxes.currentSchemaVersion, greaterThanOrEqualTo(3));
    expect(HiveSchemaMigration.evictableCachePrefixes,
        contains(PersistentDataset.keyPrefix));
  });
}
