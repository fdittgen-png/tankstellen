// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/core/storage/hive_cipher_loader.dart';
import 'package:tankstellen/core/storage/hive_deferred_user_boxes.dart';
import 'package:tankstellen/core/storage/hive_open_timing.dart';
import 'package:tankstellen/core/storage/hive_trip_box_encryption.dart';

import '../../helpers/hive_temp_dir.dart';

/// #4546 — the deferred box opens (the encrypted trip history among
/// them) used plain `Hive.openBox`, so the startup trace's `boxOpens`
/// could not show what they cost. Drives the REAL `initDeferred` once
/// (it memoizes per process — keep this the only test in the file).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('hive_deferred_timing_');
    Hive.init(dir.path);
    final cipher = HiveAesCipher(Hive.generateSecureKey());
    HiveCipherLoader.cipherLoader = () async => cipher;
    HiveDeferredUserBoxes.arm(cipher);
    HiveOpenTiming.reset();
  });

  tearDown(() async {
    HiveCipherLoader.resetCipherLoaderForTest();
    HiveDeferredUserBoxes.resetForTest();
    HiveTripBoxEncryption.resetForTesting();
    HiveOpenTiming.reset();
    await closeHiveAndDeleteTemp(dir);
  });

  test('every deferred box open is timed in the deferred phase', () async {
    await HiveBoxes.initDeferred();

    final deferred = {
      for (final r in HiveOpenTiming.opens)
        if (r.phase == HiveOpenTiming.deferredPhase) r.name,
    };
    expect(
        deferred,
        containsAll(<String>[
          HiveBoxes.obd2TripHistory,
          HiveBoxes.obd2ActiveTrip,
          HiveBoxes.obd2PausedTrips,
          HiveBoxes.obd2Baselines,
        ]));
    expect(HiveOpenTiming.openedBoxes, isEmpty,
        reason: 'deferred opens must not count as first-frame opens');
  });
}
