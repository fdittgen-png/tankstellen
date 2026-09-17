// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

// ignore_for_file: implementation_imports
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:archive/archive.dart' show getCrc32;
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/src/binary/binary_reader_impl.dart';
import 'package:hive/src/binary/binary_writer_impl.dart';
import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/crypto/crc32.dart';
import 'package:hive/src/registry/type_registry_impl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tankstellen/core/storage/hive_box_key_probe.dart';

/// #4341 adversarial verification, part 1 of 3 (CRC parity, healthy
/// boxes, empty files, compaction, torn writes) — every file is produced
/// by the REAL Hive 2.2.3 writer, and each verdict is cross-checked
/// against Hive's own frame reader (BinaryReaderImpl.readFrame), the code
/// that decides whether an open truncates. Parts 2 and 3:
/// `hive_box_key_probe_adversarial_shapes_test.dart` and
/// `hive_box_key_probe_adversarial_launch_test.dart`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  final key = HiveAesCipher(Hive.generateSecureKey());
  final other = HiveAesCipher(Hive.generateSecureKey());

  BoxKeyVerdict inspect(HiveAesCipher? c, [String? path]) =>
      HiveBoxKeyProbe.inspect(path ?? dir.path, c);

  File boxFile(String name) => File('${dir.path}/$name.hive');

  /// Hive's own answer: does its reader accept the first frame under [c]?
  /// null = no frame at all (Hive would stop reading at offset 0 for any
  /// cipher).
  bool hiveAcceptsFirstFrame(File f, HiveAesCipher? c) {
    final bytes = f.readAsBytesSync();
    final reader = BinaryReaderImpl(bytes, TypeRegistryImpl.nullImpl);
    return reader.readFrame(cipher: c, lazy: true) != null;
  }

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

  group('CRC implementation parity', () {
    test("archive's getCrc32(seed) == Hive's Crc32.compute(crc: seed) for "
        'random data and random seeds', () {
      final rnd = Random(4341);
      for (var i = 0; i < 2000; i++) {
        final data =
            Uint8List.fromList(List.generate(rnd.nextInt(300), (_) => rnd.nextInt(256)));
        final seed = rnd.nextInt(1 << 32);
        expect(getCrc32(data, seed), Crc32.compute(data, crc: seed));
        expect(getCrc32(data), Crc32.compute(data));
      }
    });

    test('for a fixed frame body the seed -> CRC map is injective: seed 0 and '
        'a non-zero key CRC can never both validate the same frame', () {
      final rnd = Random(1);
      for (var i = 0; i < 500; i++) {
        final data = Uint8List.fromList(
            List.generate(8 + rnd.nextInt(64), (_) => rnd.nextInt(256)));
        final s1 = rnd.nextInt(1 << 32);
        var s2 = rnd.nextInt(1 << 32);
        if (s2 == s1) s2 ^= 1;
        expect(getCrc32(data, s1), isNot(getCrc32(data, s2)));
      }
    });
  });

  group('1 — healthy encrypted boxes under the stored key', () {
    test('many records (int + string keys, mixed values)', () async {
      final box = await Hive.openBox<dynamic>('settings', encryptionCipher: key);
      for (var i = 0; i < 400; i++) {
        await box.put(i.isEven ? i : 's$i', {'i': i, 'txt': 'x' * (i % 50)});
      }
      await box.close();
      expect(hiveAcceptsFirstFrame(boxFile('settings'), key), isTrue);
      expect(inspect(key), BoxKeyVerdict.consistent);
      expect(inspect(other), BoxKeyVerdict.keyLost);
      expect(inspect(null), BoxKeyVerdict.keyLost);
    });

    test('exactly one record', () async {
      await writeBox('favorites', cipher: key, data: {'only': 1});
      expect(inspect(key), BoxKeyVerdict.consistent);
      expect(inspect(other), BoxKeyVerdict.keyLost);
      expect(inspect(null), BoxKeyVerdict.keyLost);
    });

    test('FIRST record is a delete frame: Hive-written [put k][delete k], '
        'sliced at the frame boundary so the delete frame leads', () async {
      final box = await Hive.openBox<dynamic>('alerts', encryptionCipher: key);
      await box.put('k', 'v');
      final putLen = boxFile('alerts').lengthSync();
      await box.delete('k');
      await box.close();
      final all = boxFile('alerts').readAsBytesSync();
      boxFile('alerts').writeAsBytesSync(all.sublist(putLen));

      final first = BinaryReaderImpl(
              boxFile('alerts').readAsBytesSync(), TypeRegistryImpl.nullImpl)
          .readFrame(cipher: key, lazy: true);
      expect(first, isNotNull);
      expect(first!.deleted, isTrue,
          reason: 'the scenario really is delete-first');

      expect(inspect(key), BoxKeyVerdict.consistent);
      expect(inspect(other), BoxKeyVerdict.keyLost);
      expect(inspect(null), BoxKeyVerdict.keyLost);
    });

    test('a stale handle writing after another handle truncated the file '
        'leaves a ZERO-FILLED prefix (writeOnlyAppend is not O_APPEND): no '
        'evidence for the probe, no frame for Hive', () async {
      final box = await Hive.openBox<dynamic>('alerts', encryptionCipher: key);
      await box.put('k', 'v');
      final raf = boxFile('alerts').openSync(mode: FileMode.append);
      raf.truncateSync(0);
      raf.closeSync();
      await box.delete('k');
      await box.close();
      final bytes = boxFile('alerts').readAsBytesSync();
      expect(bytes.take(8).every((b) => b == 0), isTrue);
      expect(hiveAcceptsFirstFrame(boxFile('alerts'), key), isFalse);
      for (final c in [key, other, null]) {
        expect(inspect(c), BoxKeyVerdict.consistent);
      }
    });

    test('delete frame produced by BinaryWriterImpl.writeFrame directly '
        '(plaintext vs keyed seed only differ in the CRC)', () {
      Uint8List frame(HiveCipher? c) {
        final w = BinaryWriterImpl(TypeRegistryImpl.nullImpl)
          ..writeFrame(Frame.deleted('gone'), cipher: c);
        return w.toBytes();
      }

      File('${dir.path}/keyed.hive').writeAsBytesSync(frame(key));
      expect(inspect(key), BoxKeyVerdict.consistent);
      expect(inspect(null), BoxKeyVerdict.keyLost);
      File('${dir.path}/keyed.hive').deleteSync();

      File('${dir.path}/plain.hive').writeAsBytesSync(frame(null));
      expect(inspect(key), BoxKeyVerdict.consistent);
      expect(inspect(other), BoxKeyVerdict.consistent);
      expect(inspect(null), BoxKeyVerdict.consistent);
    });
  });

  group('2 — empty box files are never evidence', () {
    test('opened+closed with no writes (0 bytes) and a manual 0-byte file',
        () async {
      await (await Hive.openBox<dynamic>('favorites', encryptionCipher: key)).close();
      await Hive.close();
      File('${dir.path}/cache.hive').createSync();
      expect(boxFile('favorites').lengthSync(), 0);

      for (final c in [key, other, null]) {
        expect(inspect(c), BoxKeyVerdict.consistent, reason: '$c');
      }
    });

    test('1..7-byte stubs (a torn length prefix) are no evidence', () {
      for (var n = 1; n < 8; n++) {
        File('${dir.path}/stub$n.hive')
            .writeAsBytesSync(List.filled(n, 0x20));
      }
      expect(inspect(null), BoxKeyVerdict.consistent);
      expect(inspect(key), BoxKeyVerdict.consistent);
    });

    test('empty stored-key boxes alongside plaintext and keyed boxes',
        () async {
      await (await Hive.openBox<dynamic>('favorites', encryptionCipher: key)).close();
      await writeBox('box_schema', data: {'settings': 4});
      await writeBox('settings', cipher: key);
      expect(inspect(key), BoxKeyVerdict.consistent);
    });

    test('empty boxes do not rescue a real restore (the foreign box still '
        'counts)', () async {
      await (await Hive.openBox<dynamic>('favorites', encryptionCipher: key)).close();
      await writeBox('settings', cipher: other);
      expect(inspect(key), BoxKeyVerdict.keyLost);
      expect(inspect(null), BoxKeyVerdict.keyLost);
    });
  });

  group('3 — compaction', () {
    test('automatic compaction after deletes (first record deleted first)',
        () async {
      final box = await Hive.openBox<dynamic>('cache', encryptionCipher: key);
      for (var i = 0; i < 200; i++) {
        await box.put('k$i', 'v' * 100);
      }
      final before = boxFile('cache').lengthSync();
      for (var i = 0; i < 150; i++) {
        await box.delete('k$i'); // crosses 60 deleted / 15 % → compacts
      }
      await box.close();
      expect(boxFile('cache').lengthSync(), lessThan(before),
          reason: 'compaction really ran');
      expect(File('${dir.path}/cache.hivec').existsSync(), isFalse);
      expect(inspect(key), BoxKeyVerdict.consistent);
      expect(inspect(null), BoxKeyVerdict.keyLost);
    });

    test('explicit compact() leaving an EMPTY file (every key deleted)',
        () async {
      final box = await Hive.openBox<dynamic>('alerts', encryptionCipher: key);
      await box.put('a', 1);
      await box.delete('a');
      await box.compact();
      await box.close();
      expect(boxFile('alerts').lengthSync(), 0);
      expect(inspect(other), BoxKeyVerdict.consistent);
    });

    test('a stray foreign .hivec (crash mid-compaction) is ignored', () async {
      await writeBox('settings', cipher: key);
      await writeBox('tmp', cipher: other);
      boxFile('tmp').renameSync('${dir.path}/settings.hivec');
      expect(inspect(key), BoxKeyVerdict.consistent);
      expect(inspect(null), BoxKeyVerdict.keyLost,
          reason: 'only settings.hive (foreign to no-key) counts');
    });
  });

  group('4 — torn writes', () {
    test('torn FINAL record: first frame intact → still under the key',
        () async {
      await writeBox('profiles',
          cipher: key, data: {for (var i = 0; i < 10; i++) 'p$i': 'x' * 300});
      final f = boxFile('profiles');
      final raf = f.openSync(mode: FileMode.append);
      raf.truncateSync(f.lengthSync() - 57);
      raf.closeSync();
      expect(inspect(key), BoxKeyVerdict.consistent);
      expect(inspect(null), BoxKeyVerdict.keyLost);
    });

    test('torn FIRST record: no evidence either way, exactly like Hive',
        () async {
      await writeBox('profiles', cipher: key, data: {'big': 'x' * 5000});
      final f = boxFile('profiles');
      final raf = f.openSync(mode: FileMode.append);
      raf.truncateSync(2000);
      raf.closeSync();
      expect(hiveAcceptsFirstFrame(f, key), isFalse);
      expect(inspect(key), BoxKeyVerdict.consistent);
      expect(inspect(null), BoxKeyVerdict.consistent);
      expect(inspect(other), BoxKeyVerdict.consistent);
    });

    test('torn first record in one box does not hide a restore in another',
        () async {
      await writeBox('profiles', cipher: other, data: {'big': 'x' * 5000});
      final raf = boxFile('profiles').openSync(mode: FileMode.append);
      raf.truncateSync(100);
      raf.closeSync();
      await writeBox('settings', cipher: other);
      expect(inspect(null), BoxKeyVerdict.keyLost);
    });

    test('power-loss zero-filled first frame (length intact) reads as FOREIGN; '
        'outvoted by any keyed box', () async {
      await writeBox('favorites', cipher: key, data: {'s': 'x' * 400});
      final f = boxFile('favorites');
      final b = f.readAsBytesSync();
      for (var i = 8; i < b.length; i++) {
        b[i] = 0;
      }
      f.writeAsBytesSync(b);
      expect(hiveAcceptsFirstFrame(f, key), isFalse);
      // Only this box: the verdict is keyLost (documented residual — Hive
      // would truncate this box to 0 under ANY key).
      expect(inspect(key), BoxKeyVerdict.keyLost);
      await writeBox('settings', cipher: key);
      expect(inspect(key), BoxKeyVerdict.consistent);
    });
  });
}
