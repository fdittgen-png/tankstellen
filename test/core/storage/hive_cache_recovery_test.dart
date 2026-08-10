// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/core/storage/hive_cache_recovery.dart';
import 'package:tankstellen/core/storage/hive_cipher_loader.dart';

/// #3689 — [HiveCacheRecovery] reopens the cache box after its handle died.
void main() {
  late Directory tmp;
  final cipher = HiveAesCipher(List<int>.filled(32, 7));

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('hive_cache_recovery_test');
    Hive.init(tmp.path);
    HiveCipherLoader.cipherLoader = () async => cipher;
  });

  tearDown(() async {
    HiveCipherLoader.resetCipherLoaderForTest();
    await Hive.deleteFromDisk();
    await tmp.delete(recursive: true);
  });

  test('recover reopens the box with the cipher — data intact', () async {
    final box =
        await Hive.openBox<dynamic>(HiveBoxes.cache, encryptionCipher: cipher);
    await box.put('kept', 42);

    expect(await HiveCacheRecovery.recover(), isTrue);

    final reopened = Hive.box<dynamic>(HiveBoxes.cache);
    expect(reopened.isOpen, isTrue);
    expect(reopened.get('kept'), 42);
    await reopened.put('writable', true); // the point of the recovery
  });

  test('recover also works when the box is fully closed', () async {
    final box =
        await Hive.openBox<dynamic>(HiveBoxes.cache, encryptionCipher: cipher);
    await box.put('kept', 1);
    await box.close();

    expect(await HiveCacheRecovery.recover(), isTrue);
    expect(Hive.box<dynamic>(HiveBoxes.cache).get('kept'), 1);
  });

  test('a file damaged beyond reopen is reset to an EMPTY writable box '
      '(the cache is refetchable; write-dead-until-restart loses more)',
      () async {
    final box =
        await Hive.openBox<dynamic>(HiveBoxes.cache, encryptionCipher: cipher);
    await box.put('doomed', 1);
    await box.close();
    // Overwrite the box file with garbage the cipher can't decode.
    File('${tmp.path}/${HiveBoxes.cache}.hive')
        .writeAsBytesSync(List<int>.generate(64, (i) => 255 - i));

    expect(await HiveCacheRecovery.recover(), isTrue);

    final fresh = Hive.box<dynamic>(HiveBoxes.cache);
    expect(fresh.isEmpty, isTrue);
    await fresh.put('alive', true);
    expect(fresh.get('alive'), isTrue);
  });

  test('concurrent recoveries share one flight', () async {
    await Hive.openBox<dynamic>(HiveBoxes.cache, encryptionCipher: cipher);

    final a = HiveCacheRecovery.recover();
    final b = HiveCacheRecovery.recover();
    expect(identical(a, b), isTrue);
    expect(await a, isTrue);
    // After completion a NEW recovery starts a fresh flight.
    expect(await HiveCacheRecovery.recover(), isTrue);
  });
}
