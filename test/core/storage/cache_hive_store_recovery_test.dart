// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/core/storage/stores/cache_hive_store.dart';

/// #3689 — write-path self-heal contract of [CacheHiveStore].
///
/// The field failure (a cache box whose FILE handle died under a foreign
/// compaction while `isBoxOpen` still reports true) cannot be produced
/// through Hive's public API, so these tests drive [writeWithRecovery]
/// with an op that throws the same `FileSystemException: File closed`
/// and assert the recovery orchestration around it.
void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('cache_recovery_test');
    Hive.init(tmp.path);
    await Hive.openBox<dynamic>(HiveBoxes.cache);
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await tmp.delete(recursive: true);
  });

  test('a FileSystemException write triggers ONE recovery and a retry '
      'that lands', () async {
    var recoveries = 0;
    var attempts = 0;
    final store = CacheHiveStore(recover: () async {
      recoveries++;
      return true;
    });

    await store.writeWithRecovery((box) async {
      attempts++;
      if (attempts == 1) {
        throw const FileSystemException('File closed', 'cache.hive');
      }
      await box.put('healed', true);
    });

    expect(recoveries, 1);
    expect(attempts, 2);
    expect(Hive.box<dynamic>(HiveBoxes.cache).get('healed'), isTrue);
  });

  test('failed recovery rethrows so CacheManager\'s storage-layer catch '
      'records it', () async {
    final store = CacheHiveStore(recover: () async => false);

    await expectLater(
      store.writeWithRecovery(
          (_) async => throw const FileSystemException('File closed')),
      throwsA(isA<FileSystemException>()),
    );
  });

  test('a healthy write never invokes recovery', () async {
    var recoveries = 0;
    final store = CacheHiveStore(recover: () async {
      recoveries++;
      return true;
    });

    await store.cacheData('key', {'value': 1});

    expect(recoveries, 0);
    expect(store.getCachedData('key'), {'value': 1});
  });

  test('a closed box stays the #2670 no-op — no recovery attempt', () async {
    await Hive.box<dynamic>(HiveBoxes.cache).close();
    var recoveries = 0;
    final store = CacheHiveStore(recover: () async {
      recoveries++;
      return true;
    });

    await store.cacheData('key', {'value': 1});

    expect(recoveries, 0);
  });
}
