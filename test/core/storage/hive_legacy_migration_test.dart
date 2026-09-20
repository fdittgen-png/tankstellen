// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/core/storage/hive_legacy_migration.dart';
import 'package:tankstellen/core/storage/impl/hive_directory_resolver.dart';

import '../../helpers/hive_temp_dir.dart';

/// #4372 — the #1686 plaintext→encrypted migration opened each box WITH
/// the key first and expected a plaintext file to throw. Hive does not
/// throw there: its crash recovery reads the plaintext frames as corrupt
/// and truncates the file, so the plaintext branch was unreachable and an
/// old plaintext box came back empty. Real plaintext Hive files
/// throughout — the premise is about what Hive's reader does to them.
void main() {
  late Directory dir;
  final key = HiveAesCipher(Hive.generateSecureKey());

  File boxFile(String name) => File('${dir.path}/$name.hive');

  Future<void> writePlaintext(String name, Map<dynamic, dynamic> data) async {
    final box = await Hive.openBox<dynamic>(name);
    await box.putAll(data);
    await box.close();
  }

  Future<Map<dynamic, dynamic>> readKeyed(String name) async {
    final box = await Hive.openBox<dynamic>(name, encryptionCipher: key);
    final map = Map<dynamic, dynamic>.from(box.toMap());
    await box.close();
    return map;
  }

  const favorites = {
    'station-1': '{"id":"station-1"}',
    'station-2': '{"id":"station-2"}',
    7: 'an int key',
  };

  setUp(() {
    dir = Directory.systemTemp.createTempSync('hive_legacy_migration_test');
    Hive.init(dir.path);
    HiveDirectoryResolver.hivePathForTest = dir.path;
  });

  tearDown(() async {
    HiveDirectoryResolver.hivePathForTest = null;
    await closeHiveAndDeleteTemp(dir);
  });

  test('a plaintext box keeps every record and ends up encrypted', () async {
    await writePlaintext(HiveBoxes.favorites, favorites);

    await HiveLegacyMigration.migrateLegacyPlaintextBox(
        HiveBoxes.favorites, key);

    expect(await readKeyed(HiveBoxes.favorites), favorites);
    final plainOpen = await Hive.openBox<dynamic>(HiveBoxes.favorites);
    expect(plainOpen.isEmpty, isTrue,
        reason: 'the file must now be ciphertext, unreadable without the key');
    await plainOpen.close();
  });

  test('runOnce migrates every plaintext box and then records the flag',
      () async {
    await writePlaintext(HiveBoxes.favorites, favorites);
    await writePlaintext(HiveBoxes.settings, {'theme': 'dark'});
    final meta = await Hive.openBox<int>(HiveBoxes.boxSchema);

    await HiveLegacyMigration.runOnce(
        [HiveBoxes.favorites, HiveBoxes.settings], key, meta);

    expect(await readKeyed(HiveBoxes.favorites), favorites);
    expect(await readKeyed(HiveBoxes.settings), {'theme': 'dark'});
    expect(HiveLegacyMigration.isNeeded(meta), isFalse);
  });

  test('a box already under the key is not rewritten', () async {
    final box =
        await Hive.openBox<dynamic>(HiveBoxes.favorites, encryptionCipher: key);
    await box.putAll(favorites);
    await box.close();
    final before = boxFile(HiveBoxes.favorites).readAsBytesSync();

    await HiveLegacyMigration.migrateLegacyPlaintextBox(
        HiveBoxes.favorites, key);

    expect(boxFile(HiveBoxes.favorites).readAsBytesSync(), before);
    expect(await readKeyed(HiveBoxes.favorites), favorites);
  });

  test('a failure mid-copy leaves the plaintext file intact, the flag unset, '
      'and the next launch migrates', () async {
    await writePlaintext(HiveBoxes.favorites, favorites);
    final before = boxFile(HiveBoxes.favorites).readAsBytesSync();
    final meta = await Hive.openBox<int>(HiveBoxes.boxSchema);
    HiveLegacyMigration.stagingWriter = (staging, entries) async {
      await staging.put(entries.keys.first, entries.values.first);
      throw const FileSystemException('disk full');
    };
    addTearDown(HiveLegacyMigration.resetForTest);

    await expectLater(
        HiveLegacyMigration.runOnce([HiveBoxes.favorites], key, meta),
        throwsA(isA<FileSystemException>()),
        reason: 'the launch must stop rather than let Phase 2 open the '
            'plaintext file with the key');
    expect(boxFile(HiveBoxes.favorites).readAsBytesSync(), before,
        reason: 'the plaintext file is the only complete copy');
    expect(HiveLegacyMigration.isNeeded(meta), isTrue);

    HiveLegacyMigration.resetForTest();
    await HiveLegacyMigration.runOnce([HiveBoxes.favorites], key, meta);
    expect(await readKeyed(HiveBoxes.favorites), favorites);
    expect(
        File('${dir.path}/${HiveLegacyMigration.stagingBoxName(HiveBoxes.favorites)}.hive')
            .existsSync(),
        isFalse);
  });

  test('a crash after the plaintext delete is recovered from the staging box',
      () async {
    // The state between "plaintext deleted" and "records promoted": only
    // the verified keyed staging box holds the records.
    final staging = await Hive.openBox<dynamic>(
        HiveLegacyMigration.stagingBoxName(HiveBoxes.favorites),
        encryptionCipher: key);
    await staging.putAll(favorites);
    await staging.close();

    await HiveLegacyMigration.migrateLegacyPlaintextBox(
        HiveBoxes.favorites, key);

    expect(await readKeyed(HiveBoxes.favorites), favorites);
    expect(
        File('${dir.path}/${HiveLegacyMigration.stagingBoxName(HiveBoxes.favorites)}.hive')
            .existsSync(),
        isFalse);
  });

  test('an unknown Hive path takes the normal path and touches nothing',
      () async {
    await writePlaintext(HiveBoxes.favorites, favorites);
    final before = boxFile(HiveBoxes.favorites).readAsBytesSync();
    HiveDirectoryResolver.hivePathForTest = null;

    await HiveLegacyMigration.migrateLegacyPlaintextBox(
        HiveBoxes.favorites, key);

    expect(boxFile(HiveBoxes.favorites).readAsBytesSync(), before);
  });
}
