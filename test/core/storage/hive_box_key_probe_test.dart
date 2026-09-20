// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tankstellen/core/storage/hive_box_key_probe.dart';

import '../../helpers/hive_temp_dir.dart';

/// #4341 — the probe reads Hive's own frame checksums to say which key a
/// box file was written with, without opening (and so without
/// truncating) anything. Real Hive files throughout: the probe's whole
/// claim is that it agrees with the format Hive writes.
void main() {
  late Directory dir;
  final key = HiveAesCipher(Hive.generateSecureKey());
  final otherKey = HiveAesCipher(Hive.generateSecureKey());

  Future<void> writeBox(String name, {HiveAesCipher? cipher}) async {
    final box = await Hive.openBox<dynamic>(name, encryptionCipher: cipher);
    await box.put('k', 'value of $name');
    await box.close();
  }

  BoxKeyVerdict inspect(HiveAesCipher? cipher) =>
      HiveBoxKeyProbe.inspect(dir.path, cipher);

  setUp(() {
    dir = Directory.systemTemp.createTempSync('hive_box_key_probe_test');
    Hive.init(dir.path);
  });

  tearDown(() async {
    await closeHiveAndDeleteTemp(dir);
  });

  test('no box files: consistent with any key, or none', () {
    expect(inspect(null), BoxKeyVerdict.consistent);
    expect(inspect(key), BoxKeyVerdict.consistent);
    expect(HiveBoxKeyProbe.inspect('${dir.path}/missing', null),
        BoxKeyVerdict.consistent);
  });

  test('ciphertext under the key is consistent; under another key it is '
      'key loss — with or without a stored key', () async {
    await writeBox('settings', cipher: key);

    expect(inspect(key), BoxKeyVerdict.consistent);
    expect(inspect(otherKey), BoxKeyVerdict.keyLost);
    expect(inspect(null), BoxKeyVerdict.keyLost);
  });

  test('plaintext boxes are never evidence', () async {
    await writeBox('isolate_error_spool');
    await writeBox('box_schema');

    expect(inspect(null), BoxKeyVerdict.consistent);
    expect(inspect(key), BoxKeyVerdict.consistent);
  });

  test('empty and torn files are no evidence', () async {
    File('${dir.path}/empty.hive').createSync();
    // A length prefix promising more bytes than the file holds.
    File('${dir.path}/torn.hive').writeAsBytesSync([200, 0, 0, 0, 1, 2, 3, 4]);

    expect(inspect(null), BoxKeyVerdict.consistent);
  });

  test('one box under the key outvotes a damaged first frame elsewhere',
      () async {
    await writeBox('settings', cipher: key);
    await writeBox('favorites', cipher: otherKey); // stands in for damage

    expect(inspect(key), BoxKeyVerdict.consistent,
        reason: 'a lost key leaves NO box readable under it');
  });

  test('smallest first: one small box under the key settles the verdict '
      'without reading a single byte of the large boxes', () async {
    // Several large first records, named to sort around the small one, so
    // no directory listing order can reach the small box first by luck.
    const large = ['aaa_datasets', 'mmm_cache', 'zzz_trip_history'];
    for (final name in large) {
      final box = await Hive.openBox<dynamic>(name, encryptionCipher: key);
      await box.put('dataset', 'y' * (1024 * 1024));
      await box.close();
    }
    await writeBox('nnn_settings', cipher: key);

    final read = <String, int>{};
    final verdict = HiveBoxKeyProbe.inspect(dir.path, key,
        onRead: (file, bytes) =>
            read[file.uri.pathSegments.last] = bytes);

    expect(verdict, BoxKeyVerdict.consistent);
    expect(read.keys, ['nnn_settings.hive'],
        reason: 'the large boxes must never be read: $read');
    expect(read['nnn_settings.hive'], lessThan(200));
  });

  test('...and the order changes no verdict: a restore still reads every '
      'box and is still key loss', () async {
    for (final name in ['aaa_big', 'zzz_small']) {
      final box = await Hive.openBox<dynamic>(name, encryptionCipher: otherKey);
      await box.put('v', name == 'aaa_big' ? 'y' * 100000 : 'y');
      await box.close();
    }
    final read = <String>[];
    expect(
        HiveBoxKeyProbe.inspect(dir.path, key,
            onRead: (file, _) => read.add(file.uri.pathSegments.last)),
        BoxKeyVerdict.keyLost);
    expect(read, ['zzz_small.hive', 'aaa_big.hive']);
  });

  test('an unknown or unreadable directory answers unknown and never throws',
      () async {
    expect(() => HiveBoxKeyProbe.inspect(null, key), returnsNormally);
    expect(HiveBoxKeyProbe.inspect(null, key), BoxKeyVerdict.unknown);

    // A directory the process may not list: the scan itself throws.
    final locked = Directory('${dir.path}/locked')..createSync();
    Process.runSync('chmod', ['000', locked.path]);
    addTearDown(() => Process.runSync('chmod', ['755', locked.path]));
    expect(() => HiveBoxKeyProbe.inspect(locked.path, null), returnsNormally);
    expect(HiveBoxKeyProbe.inspect(locked.path, null), BoxKeyVerdict.unknown);
  }, testOn: 'mac-os || linux');
}
