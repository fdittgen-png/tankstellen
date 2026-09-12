// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/core/storage/hive_first_frame_boxes.dart';
import 'package:tankstellen/core/storage/hive_open_timing.dart';

/// #4116 — this file exists because the app stopped starting and 16,626
/// tests passed.
///
/// `openAll` is the batch that opens the boxes the first frame cannot be
/// painted without. Every test of it read the SOURCE TEXT with a regex —
/// "all six domain boxes open with a cipher", "the batch is concurrent",
/// "nothing deep-feature is on the first-frame path" — and every one
/// still passed while the code they described recursed into itself until
/// the stack blew. `HiveStorage.initForTest()`, which every widget test
/// uses, has its own hand-written open list and never calls this path at
/// all.
///
/// So these tests RUN it. They assert almost nothing clever; their whole
/// value is that the production startup path is executed by something
/// before it reaches a device.
void main() {
  late Directory tmpDir;

  setUp(() {
    tmpDir = Directory.systemTemp.createTempSync('hive_first_frame_');
    Hive.init(tmpDir.path);
    HiveOpenTiming.reset();
  });

  tearDown(() async {
    await Hive.close();
    tmpDir.deleteSync(recursive: true);
  });

  test('openAll actually runs, and every first-frame box is open after it',
      () async {
    // No cipher: the encryption path needs FlutterSecureStorage, and what
    // is under test here is the batch, not the key.
    await HiveFirstFrameBoxes.openAll(null);

    for (final box in [
      HiveBoxes.settings,
      HiveBoxes.profiles,
      HiveBoxes.favorites,
      HiveBoxes.cache,
      HiveBoxes.priceHistory,
      HiveBoxes.alerts,
      HiveBoxes.isolateErrorSpool,
      HiveBoxes.featureFlags,
      HiveBoxes.appProfile,
      HiveBoxes.boxSchema,
    ]) {
      expect(Hive.isBoxOpen(box), isTrue,
          reason: '$box gates the first frame and must be open once '
              'openAll returns');
    }
  });

  test('the boxes come back at the TYPES the app reads them at', () async {
    // #4053 — opening a box at the wrong type throws "already open and of
    // type Box<String>" the next time anyone asks for it, which is how 15
    // traces in one field export were produced.
    await HiveFirstFrameBoxes.openAll(null);
    expect(() => Hive.box<String>(HiveBoxes.isolateErrorSpool), returnsNormally);
    expect(() => Hive.box<int>(HiveBoxes.boxSchema), returnsNormally);
    expect(() => Hive.box<dynamic>(HiveBoxes.settings), returnsNormally);
  });

  test('#4110 — the timing wrapper RAN, not merely got mentioned in the '
      'source', () async {
    expect(HiveOpenTiming.slowest, isNull, reason: 'nothing opened yet');
    await HiveFirstFrameBoxes.openAll(null);

    final slowest = HiveOpenTiming.slowest;
    expect(slowest, isNotNull,
        reason: 'if openAll bypassed HiveOpenTiming the startup trace '
            'would silently stop naming the long pole, and #4110 step 2 '
            'would be waiting for data that never arrives');
    expect(slowest!.$2, greaterThanOrEqualTo(0));
  });

  test('openAll is idempotent — a second call on open boxes does not throw',
      () async {
    // The startup path can re-enter after a recovered failure; an open
    // box must not turn the retry into a crash.
    await HiveFirstFrameBoxes.openAll(null);
    await expectLater(HiveFirstFrameBoxes.openAll(null), completes);
  });
}
