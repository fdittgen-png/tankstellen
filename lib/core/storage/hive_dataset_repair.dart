// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import 'hive_boxes.dart';
import '../background/hive_isolate_lock.dart';

/// Repairs datasets routed into the first-frame cache by the deferred-open
/// race. Run BEFORE the foreground opens either file. Opening/decoding and
/// compacting the polluted cache happens in a worker, with the validated key.
abstract final class HiveDatasetRepair {
  static const marker = 'dataset_routing_repaired_v1';

  @visibleForTesting
  static Future<HiveIsolateLock> Function() lockFactory = HiveIsolateLock.create;

  static Future<void> runOnce(String? path, HiveAesCipher? cipher) async {
    final schema = Hive.box<int>(HiveBoxes.boxSchema);
    if (path == null || schema.get(marker) == 1) return;
    final lock = await lockFactory();
    // An active background scan owns the files. Retry on a later launch,
    // without adding a lock wait to the startup critical path.
    if (!await lock.acquire(timeout: Duration.zero)) return;
    try {
      await compute(_repair, (path, cipher));
      await schema.put(marker, 1);
    } finally {
      lock.release();
    }
  }

  static Future<void> _repair((String, HiveAesCipher?) args) async {
    Hive.init(args.$1);
    try {
      if (!await Hive.boxExists(HiveBoxes.cache)) return;
      final cache = await Hive.openBox<dynamic>(
        HiveBoxes.cache,
        encryptionCipher: args.$2,
      );
      final keys = cache.keys
          .whereType<String>()
          .where((key) => key.startsWith('dataset:'))
          .toList();
      if (keys.isEmpty) {
        // A previous process may have died after deleting the last source
        // key but before compaction. Finish reclaiming those frames on retry.
        await cache.compact();
        return;
      }
      final datasets = await Hive.openBox<dynamic>(
        HiveBoxes.datasets,
        encryptionCipher: args.$2,
      );
      for (final key in keys) {
        final misplaced = cache.get(key);
        final existing = datasets.get(key);
        if (existing == null || _storedAt(misplaced) > _storedAt(existing)) {
          // A failed copy leaves the source intact; a retry is idempotent.
          await datasets.put(key, misplaced);
          await datasets.flush();
        }
        await cache.delete(key);
      }
      await cache.flush();
      // Hive otherwise retains deleted multi-MB frames until its count-based
      // threshold fires, charging the next startup for decoding them again.
      await cache.compact();
    } finally {
      await Hive.close();
    }
  }

  static int _storedAt(dynamic raw) {
    final data = raw is Map ? raw['data'] : null;
    final stamp = data is Map ? data['storedAt'] : null;
    return stamp is int ? stamp : 0;
  }
}
