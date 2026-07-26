// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/storage/hive_trip_box_encryption.dart';

void main() {
  late Directory tmp;
  late HiveAesCipher cipher;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('hive_trip_enc_test');
    Hive.init(tmp.path);
    cipher = HiveAesCipher(Hive.generateSecureKey());
  });

  tearDown(() async {
    await Hive.close();
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  group('HiveTripBoxEncryption (#3611)', () {
    test('migrates a plaintext trip box to encrypted, preserving every '
        'entry, and removes the staging box', () async {
      final plain = await Hive.openBox<String>('trip_history');
      await plain.put('t1', '{"distanceKm":12.5}');
      await plain.put('t2', '{"distanceKm":3.1}');
      await plain.close();

      await HiveTripBoxEncryption.migrate('trip_history', cipher);

      final encrypted = await Hive.openBox<String>('trip_history',
          encryptionCipher: cipher);
      expect(encrypted.get('t1'), '{"distanceKm":12.5}');
      expect(encrypted.get('t2'), '{"distanceKm":3.1}');
      await encrypted.close();

      expect(
        await Hive.boxExists(
            HiveTripBoxEncryption.stagingBoxName('trip_history')),
        isFalse,
        reason: 'the staging box is the migration-pending marker and must '
            'be gone once the migration completed',
      );
    });

    test('the plaintext file is actually unreadable as plaintext after '
        'the migration (really encrypted now)', () async {
      final plain = await Hive.openBox<String>('trip_active');
      await plain.put('current', '{"samples":[1,2,3]}');
      await plain.close();

      await HiveTripBoxEncryption.migrate('trip_active', cipher);

      // A cipher-less open of the migrated box must not yield the data.
      Object? plaintextReadResult;
      try {
        final reopened = await Hive.openBox<String>('trip_active');
        plaintextReadResult = reopened.get('current');
        await reopened.close();
      } catch (_) {
        // Throwing is the expected outcome for an encrypted file.
        plaintextReadResult = null;
      }
      expect(plaintextReadResult, isNot('{"samples":[1,2,3]}'),
          reason: 'the migrated file must not be readable without the '
              'cipher');
    });

    test('second launch skips the migration (idempotent fast path)',
        () async {
      final plain = await Hive.openBox<String>('trip_paused');
      await plain.put('p1', '{"pausedAt":"2026-07-26"}');
      await plain.close();

      await HiveTripBoxEncryption.migrate('trip_paused', cipher);
      // Simulate the next launch: migrate again, then write new data
      // and migrate a third time — nothing may be lost or duplicated.
      await HiveTripBoxEncryption.migrate('trip_paused', cipher);

      final box = await Hive.openBox<String>('trip_paused',
          encryptionCipher: cipher);
      await box.put('p2', '{"pausedAt":"2026-07-27"}');
      await box.close();

      await HiveTripBoxEncryption.migrate('trip_paused', cipher);

      final reopened = await Hive.openBox<String>('trip_paused',
          encryptionCipher: cipher);
      expect(reopened.length, 2);
      expect(reopened.get('p1'), '{"pausedAt":"2026-07-26"}');
      expect(reopened.get('p2'), '{"pausedAt":"2026-07-27"}');
      await reopened.close();
    });

    test('a fresh install (no box on disk) migrates as a no-op', () async {
      await expectLater(
        HiveTripBoxEncryption.migrate('trip_fresh', cipher),
        completes,
      );
      final box = await Hive.openBox<String>('trip_fresh',
          encryptionCipher: cipher);
      expect(box.isEmpty, isTrue);
      await box.close();
    });

    test('crash recovery — a surviving staging box is promoted into the '
        'canonical encrypted box on the next launch', () async {
      // Simulate a crash AFTER the plain box was staged + deleted but
      // BEFORE the staging box was promoted: only the staging box exists.
      final staging = await Hive.openBox<String>(
        HiveTripBoxEncryption.stagingBoxName('trip_history'),
        encryptionCipher: cipher,
      );
      await staging.put('t1', '{"distanceKm":42.0}');
      await staging.close();

      await HiveTripBoxEncryption.migrate('trip_history', cipher);

      final box = await Hive.openBox<String>('trip_history',
          encryptionCipher: cipher);
      expect(box.get('t1'), '{"distanceKm":42.0}');
      await box.close();
      expect(
        await Hive.boxExists(
            HiveTripBoxEncryption.stagingBoxName('trip_history')),
        isFalse,
      );
    });

    test('crash recovery — staging AND plain both on disk (crash before '
        'the plain delete) re-runs the copy via upsert without loss',
        () async {
      // The plain box still holds everything; the staging box holds a
      // partial copy from the interrupted first attempt.
      final plain = await Hive.openBox<String>('trip_history');
      await plain.put('t1', '{"distanceKm":1.0}');
      await plain.put('t2', '{"distanceKm":2.0}');
      await plain.close();
      final staging = await Hive.openBox<String>(
        HiveTripBoxEncryption.stagingBoxName('trip_history'),
        encryptionCipher: cipher,
      );
      await staging.put('t1', '{"distanceKm":1.0}'); // partial copy
      await staging.close();

      await HiveTripBoxEncryption.migrate('trip_history', cipher);

      final box = await Hive.openBox<String>('trip_history',
          encryptionCipher: cipher);
      expect(box.length, 2, reason: 'upsert re-copy must complete the set');
      expect(box.get('t2'), '{"distanceKm":2.0}');
      await box.close();
    });

    test('a corrupted plain box degrades gracefully — the encrypted box '
        'still comes up usable afterwards', () async {
      // Garbage bytes Hive cannot parse as frames. Hive's own crash
      // recovery salvages what it can (here: nothing) during the plain
      // open; the migration must complete and leave a WORKING encrypted
      // box behind.
      final file = File('${tmp.path}/trip_corrupt.hive');
      await file.writeAsBytes(List<int>.generate(64, (i) => (i * 37) % 251));

      await expectLater(
        HiveTripBoxEncryption.migrate('trip_corrupt', cipher),
        completes,
      );

      final box = await Hive.openBox<String>('trip_corrupt',
          encryptionCipher: cipher);
      await box.put('t-new', '{"distanceKm":5.0}');
      expect(box.get('t-new'), '{"distanceKm":5.0}');
      await box.close();
    });

    test('fault injection — a plain open that throws (never-throws '
        'contract) is swallowed and the file left on disk', () async {
      final boxFile = File('${tmp.path}/trip_locked.hive')..createSync();
      HiveTripBoxEncryption.plainOpener = (name) async =>
          throw HiveError('injected: box file is unreadable');
      addTearDown(HiveTripBoxEncryption.resetForTesting);

      await expectLater(
        HiveTripBoxEncryption.migrate('trip_locked', cipher),
        completes,
      );
      expect(boxFile.existsSync(), isTrue,
          reason: 'the migration must never delete what it could not read');

      // The box is stamped encrypted, so a second run is a fast-path
      // no-op even while the opener still throws.
      await expectLater(
        HiveTripBoxEncryption.migrate('trip_locked', cipher),
        completes,
      );
    });
  });
}
