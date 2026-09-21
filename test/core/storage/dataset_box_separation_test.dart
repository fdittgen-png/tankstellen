// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/services/persistent_dataset.dart';
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
    HiveOpenTiming.reset();
  });

  tearDown(() async {
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
