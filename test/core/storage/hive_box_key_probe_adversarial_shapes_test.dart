// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tankstellen/core/storage/hive_box_key_probe.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/core/storage/hive_legacy_migration.dart';
import 'package:tankstellen/core/storage/impl/hive_directory_resolver.dart';

/// #4341 adversarial verification, part 2 of 3 (large first values, lazy
/// boxes and key encodings, plaintext boxes, mixed directories, a probe
/// racing compaction in another isolate, directory shape) — every file is
/// produced by the REAL Hive 2.2.3 writer. Part 1:
/// `hive_box_key_probe_adversarial_test.dart`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  final key = HiveAesCipher(Hive.generateSecureKey());
  final other = HiveAesCipher(Hive.generateSecureKey());

  BoxKeyVerdict inspect(HiveAesCipher? c, [String? path]) =>
      HiveBoxKeyProbe.inspect(path ?? dir.path, c);

  File boxFile(String name) => File('${dir.path}/$name.hive');

  Future<void> writeBox(String name,
      {HiveAesCipher? cipher, Map<dynamic, dynamic>? data}) async {
    final box = await Hive.openBox<dynamic>(name, encryptionCipher: cipher);
    await box.putAll(data ?? {'k': 'value of $name'});
    await box.close();
  }

  setUp(() {
    dir = Directory.systemTemp.createTempSync('hive_probe_adv');
    Hive.init(dir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  group('5 — very large first values', () {
    for (final size in [70 * 1024, 5 * 1024 * 1024]) {
      test('first value of $size bytes', () async {
        await writeBox('datasets',
            cipher: key, data: {'dataset:DE': 'y' * size, 'second': 'z'});
        final f = boxFile('datasets');
        expect(f.lengthSync(), greaterThan(size));
        final sw = Stopwatch()..start();
        expect(inspect(key), BoxKeyVerdict.consistent);
        sw.stop();
        // ignore: avoid_print
        print('probe over a ${f.lengthSync()}-byte first frame: '
            '${sw.elapsedMicroseconds} µs');
        expect(inspect(other), BoxKeyVerdict.keyLost);
        expect(inspect(null), BoxKeyVerdict.keyLost);

        // Truncated in the middle of that big frame → no evidence.
        final raf = f.openSync(mode: FileMode.append);
        raf.truncateSync(size ~/ 2);
        raf.closeSync();
        expect(inspect(null), BoxKeyVerdict.consistent);
      });
    }
  });

  group('6 — lazy boxes and key encodings', () {
    test('lazy box under the key', () async {
      final lazy = await Hive.openLazyBox<dynamic>('lazy', encryptionCipher: key);
      await lazy.put(7, 'seven');
      await lazy.close();
      expect(inspect(key), BoxKeyVerdict.consistent);
      expect(inspect(null), BoxKeyVerdict.keyLost);
    });

    test('int keys 0 / 0xFFFFFFFF, add() auto-increment, 255-byte string and '
        'utf8 string keys', () async {
      for (final (name, k) in [
        ('int0', 0),
        ('intmax', 0xFFFFFFFF),
        ('str255', 'k' * 255),
        ('utf8', 'Zürich-ß'),
      ]) {
        await writeBox(name, cipher: key, data: {k: 'v'});
      }
      final added = await Hive.openBox<String>('added', encryptionCipher: key);
      await added.add('a');
      await added.close();

      for (final f in dir.listSync().whereType<File>()) {
        final single = Directory.systemTemp.createTempSync('one');
        addTearDown(() => single.deleteSync(recursive: true));
        f.copySync('${single.path}/x.hive');
        expect(inspect(key, single.path), BoxKeyVerdict.consistent,
            reason: f.path);
        expect(inspect(other, single.path), BoxKeyVerdict.keyLost,
            reason: f.path);
      }
    });
  });

  // OBSERVATION — tracked as #4372. The #1686 migration's cipher-first
  // open truncates a legacy plaintext box. This pins the CURRENT loss and
  // never asserts the data survives; #4372 flips it when it lands.
  test('OBSERVATION (pre-existing, not #4341; #4372): the #1686 legacy '
      'migration probe opens a plaintext box WITH the cipher, which '
      'truncates it', () async {
    await writeBox('favorites', data: {'station-1': '{"id":"station-1"}'});
    expect(boxFile('favorites').lengthSync(), greaterThan(0));
    await HiveLegacyMigration.migrateLegacyPlaintextBox('favorites', key);
    final box = await Hive.openBox<dynamic>('favorites', encryptionCipher: key);
    // ignore: avoid_print
    print('legacy favorites after migration: ${box.toMap()} '
        '(file ${boxFile('favorites').lengthSync()} bytes)');
    expect(box.get('station-1'), isNull,
        reason: 'documents the pre-existing loss; flip if migration is fixed');
  });

  group('8 — plaintext boxes are never another key', () {
    test('spool, schema stamps, flags, app profile, snapshots, traces, '
        'health counters, connect traces, legacy plaintext favorites', () async {
      for (final name in [
        HiveBoxes.isolateErrorSpool,
        HiveBoxes.boxSchema,
        HiveBoxes.featureFlags,
        HiveBoxes.appProfile,
        HiveBoxes.priceSnapshots,
        HiveBoxes.trafficSignalsCache,
        HiveBoxes.errorTraces,
        'health_counters',
        'obd2_connect_traces',
        HiveBoxes.favorites, // pre-#1686 legacy plaintext
      ]) {
        await writeBox(name, data: {'a': 1, 2: 'b'});
      }
      for (final c in [null, key, other]) {
        expect(inspect(c), BoxKeyVerdict.consistent, reason: '$c');
      }
    });
  });

  group('9 — mixed', () {
    test('keyed + plaintext → consistent; keyed + corrupt → consistent',
        () async {
      await writeBox('settings', cipher: key);
      await writeBox('box_schema', data: {'settings': 4});
      expect(inspect(key), BoxKeyVerdict.consistent);

      await writeBox('favorites', cipher: key, data: {'f': 'x' * 40});
      final f = boxFile('favorites');
      final b = f.readAsBytesSync();
      b[b.length - 6] ^= 0x01; // single bit flip inside the frame body
      f.writeAsBytesSync(b);
      expect(inspect(key), BoxKeyVerdict.consistent);
    });

    test('plaintext + a bit-flipped plaintext box, no keyed box: keyLost '
        '(documented residual — see report)', () async {
      await writeBox('box_schema', data: {'settings': 4});
      await writeBox(HiveBoxes.isolateErrorSpool, data: {'e': 'x' * 40});
      final f = boxFile(HiveBoxes.isolateErrorSpool);
      final b = f.readAsBytesSync();
      b[b.length - 6] ^= 0x01;
      f.writeAsBytesSync(b);
      expect(inspect(null), BoxKeyVerdict.keyLost);
    });
  });

  group('concurrency — probe while Hive writes and compacts', () {
    test('a probe in ANOTHER isolate never sees keyLost while the only keyed '
        'box is being written, deleted and compacted (.hivec + rename)',
        () async {
      final rawKey = Hive.generateSecureKey();
      final k = HiveAesCipher(rawKey);
      final box = await Hive.openBox<dynamic>('cache', encryptionCipher: k);
      await box.put('seed', 'x' * 200);
      final path = dir.path;
      final prober = Isolate.run(() {
        final c = HiveAesCipher(rawKey);
        final counts = <String, int>{};
        final sw = Stopwatch()..start();
        while (sw.elapsedMilliseconds < 2500) {
          final v = HiveBoxKeyProbe.inspect(path, c).name;
          counts[v] = (counts[v] ?? 0) + 1;
        }
        return counts;
      });
      var compactions = 0;
      final sw = Stopwatch()..start();
      while (sw.elapsedMilliseconds < 2400) {
        for (var i = 0; i < 80; i++) {
          await box.put('k$i', 'v' * (50 + i));
        }
        for (var i = 0; i < 80; i++) {
          await box.delete('k$i');
        }
        await box.compact();
        compactions++;
      }
      final counts = await prober;
      await box.close();
      // ignore: avoid_print
      print('cross-isolate probe verdicts: $counts over $compactions '
          'compaction rounds');
      expect(counts.keys, isNot(contains('keyLost')));
    });
  });

  group('10 — directory shape', () {
    test('foreign boxes in a nested subfolder are ignored (Hive never opens '
        'them either)', () async {
      final nested = Directory('${dir.path}/crash_journal')..createSync();
      Hive.init(nested.path);
      await writeBox('settings', cipher: other);
      Hive.init(dir.path);
      expect(inspect(null), BoxKeyVerdict.consistent);
      expect(inspect(key), BoxKeyVerdict.consistent);
    });

    test('non-Hive files: .lock, .hivec, text, random bytes named .hive',
        () async {
      await writeBox('settings', cipher: key);
      File('${dir.path}/settings.lock').writeAsStringSync('');
      File('${dir.path}/startup_failure.json').writeAsStringSync('{"a":1}');
      final rnd = Random(99);
      File('${dir.path}/random.hive').writeAsBytesSync(
          List.generate(4096, (_) => rnd.nextInt(256)));
      File('${dir.path}/notes.hive')
          .writeAsStringSync('SELECT * FROM t; -- not a Hive box');
      expect(inspect(key), BoxKeyVerdict.consistent);
      expect(inspect(null), BoxKeyVerdict.keyLost,
          reason: 'settings.hive is foreign to a key-less install');
      boxFile('settings').deleteSync();
      expect(inspect(null), BoxKeyVerdict.consistent,
          reason: 'random/text .hive files have length > size → no frame');
    });

    test('iOS migrateAndResolve: restored legacy Documents boxes are moved, '
        'then judged in Application Support', () async {
      final legacy = Directory('${dir.path}/Documents')..createSync();
      final support = Directory('${dir.path}/Library/Application Support');
      Hive.init(legacy.path);
      await writeBox('settings', cipher: other);
      await writeBox('favorites', cipher: other);
      await Hive.close();
      Hive.init(dir.path);

      final resolved =
          HiveDirectoryResolver.migrateAndResolve(legacy, support);
      expect(resolved, support.path);
      expect(inspect(null, resolved), BoxKeyVerdict.keyLost);
      expect(inspect(key, resolved), BoxKeyVerdict.keyLost);
      expect(inspect(other, resolved), BoxKeyVerdict.consistent);
    });

    test('a symlinked .hive is skipped (followLinks: false)', () async {
      final elsewhere = Directory.systemTemp.createTempSync('elsewhere');
      addTearDown(() => elsewhere.deleteSync(recursive: true));
      Hive.init(elsewhere.path);
      await writeBox('settings', cipher: other);
      Hive.init(dir.path);
      Link('${dir.path}/settings.hive')
          .createSync('${elsewhere.path}/settings.hive');
      expect(inspect(null), BoxKeyVerdict.consistent);
    }, testOn: 'mac-os || linux');
  });

}
