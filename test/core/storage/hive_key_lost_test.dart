// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/core/storage/hive_cipher_loader.dart';
import 'package:tankstellen/core/storage/hive_deferred_user_boxes.dart';
import 'package:tankstellen/core/storage/hive_isolate_ownership.dart';
import 'package:tankstellen/core/storage/impl/hive_directory_resolver.dart';

import '../../helpers/hive_temp_dir.dart';

/// #4118 — a restored install must not be told its data is damaged.
///
/// Android Auto-Backup and device-to-device transfer copy the app's
/// files, but the KeyStore master key behind `FlutterSecureStorage` is
/// hardware-bound and never travels. So the encrypted boxes came back
/// while the only key that reads them stayed on the old phone; every box
/// then failed to open, and the startup path called that corruption —
/// advising the user to clear the very data the restore had brought
/// back, with no mention that TankSync still held whatever was synced.
///
/// The harm is quieter and worse than "the app shows an error". Opening
/// an encrypted box under the wrong key does NOT throw: Hive's crash
/// recovery reads the undecryptable frames, decides the box is corrupt
/// and truncates the file — measured below at 93 bytes in, 0 bytes out.
/// So the restore's own data is destroyed on first launch, silently,
/// while the app starts looking perfectly healthy and completely empty.
///
/// The check therefore has to run BEFORE the first open — and, since
/// #4341, before a replacement key is written: #4118 decided after the
/// write, so the stopped launch left a key behind that the NEXT launch
/// trusted, and that launch truncated the boxes anyway.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  late Directory dir;

  /// A keystore that outlives the process, like the real one: [storedKey]
  /// persists across launches and every write is counted. [readFault] /
  /// [writeFault] stand in for a keychain that answers with an error.
  var keyWrites = 0;
  String? storedKey;
  PlatformException? readFault;
  PlatformException? writeFault;
  // #4373 — every call, with the Android options it carried.
  final calls = <(String, Map<Object?, Object?>)>[];

  void installKeystore({String? initial}) {
    storedKey = initial;
    keyWrites = 0;
    readFault = null;
    writeFault = null;
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add((
        call.method,
        (call.arguments as Map)['options'] as Map<Object?, Object?>
      ));
      switch (call.method) {
        case 'read':
          if (readFault case final fault?) throw fault;
          return storedKey;
        case 'write':
          if (writeFault case final fault?) throw fault;
          keyWrites++;
          storedKey = (call.arguments as Map)['value'] as String?;
          return null;
        default:
          return null;
      }
    });
  }

  Map<String, List<int>> snapshot() => {
        for (final f in dir.listSync().whereType<File>())
          if (f.path.endsWith('.hive'))
            f.uri.pathSegments.last: f.readAsBytesSync(),
      };

  /// Box files written under a key this install does not have — the
  /// restored image.
  Future<void> writeRestoredImage() async {
    final oldKey = HiveAesCipher(Hive.generateSecureKey());
    final settings = await Hive.openBox<dynamic>(HiveBoxes.settings,
        encryptionCipher: oldKey);
    await settings.put('theme', 'dark');
    await settings.close();
    final favorites = await Hive.openBox<dynamic>(HiveBoxes.favorites,
        encryptionCipher: oldKey);
    await favorites.put('station-1', '{"id":"station-1"}');
    await favorites.close();
  }

  setUp(() {
    dir = Directory.systemTemp.createTempSync('hive_key_lost_test');
    Hive.init(dir.path);
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await closeHiveAndDeleteTemp(dir);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    HiveCipherLoader.resetCipherLoaderForTest();
    HiveDirectoryResolver.hivePathForTest = null;
  });

  test('opening under the wrong key DESTROYS the box — which is why the '
      'check cannot wait for the open to fail', () async {
    // The premise this whole fix rests on. If Hive threw here, a
    // post-hoc verdict would be enough; it does not throw, it truncates.
    final box = await Hive.openBox<dynamic>(
      HiveBoxes.settings,
      encryptionCipher: HiveAesCipher(Hive.generateSecureKey()),
    );
    await box.put('theme', 'dark');
    await box.put('lang', 'fr');
    await box.close();
    final file = File('${dir.path}/${HiveBoxes.settings}.hive');
    expect(file.lengthSync(), greaterThan(0));

    final reopened = await Hive.openBox<dynamic>(
      HiveBoxes.settings,
      encryptionCipher: HiveAesCipher(Hive.generateSecureKey()),
    );

    expect(reopened.isEmpty, isTrue, reason: 'no error is raised at all');
    await reopened.close();
    expect(file.lengthSync(), 0,
        reason: 'the restored data is not merely unreadable — it is gone, '
            'so any check that runs after the open is too late');
  });

  group('the REAL loader decides before it writes a key', () {
    // Executed, not source-scanned: #4116 shipped because every test of
    // that batch read the file as text instead of running it.
    setUp(() => HiveDirectoryResolver.hivePathForTest = dir.path);

    test('a key-less install with ciphertext on disk is stopped, and no key '
        'is written', () async {
      await writeRestoredImage();
      installKeystore();

      await expectLater(HiveCipherLoader.loadGuarded(),
          throwsA(isA<StorageKeyLostException>()),
          reason: 'the key-loss screen, not the cause-unknown one');
      expect(keyWrites, 0);
    });

    test('a genuine first run mints and stores exactly one key', () async {
      installKeystore();

      final cipher = await HiveCipherLoader.loadGuarded();

      expect(keyWrites, 1);
      expect(base64Url.decode(storedKey!), hasLength(32));
      expect(cipher.calculateKeyCrc(),
          HiveAesCipher(base64Url.decode(storedKey!)).calculateKeyCrc());
    });

    test('a stored key is returned as it is, and never rewritten', () async {
      final key = base64UrlEncode(Hive.generateSecureKey());
      installKeystore(initial: key);

      await HiveCipherLoader.loadGuarded();

      expect(keyWrites, 0);
      expect(storedKey, key);
    });

    test('a directory that cannot be inspected mints no key — retryable, '
        'never a guess', () async {
      installKeystore();
      HiveDirectoryResolver.hivePathForTest = null;

      await expectLater(HiveCipherLoader.loadGuarded(),
          throwsA(isA<StorageInitException>()));
      expect(keyWrites, 0,
          reason: 'with nothing known about the files, a written key could '
              'authorise the truncating open on the next launch');
    });

    test('...but does not stop an install that already has its key',
        () async {
      installKeystore(initial: base64UrlEncode(Hive.generateSecureKey()));
      HiveDirectoryResolver.hivePathForTest = null;

      await expectLater(HiveCipherLoader.loadGuarded(), completes);
    });

    test('a keychain read failure stays a cause-unknown failure and writes '
        'nothing', () async {
      await writeRestoredImage();
      installKeystore();
      readFault = PlatformException(code: 'keystore_unavailable');

      await expectLater(HiveCipherLoader.loadGuarded(),
          throwsA(isA<StorageInitException>()),
          reason: 'a read that failed is not evidence the key is gone');
      expect(keyWrites, 0);
    });

    test('a malformed stored key fails closed and is not replaced', () async {
      installKeystore(initial: 'not-a-key');

      await expectLater(HiveCipherLoader.loadGuarded(),
          throwsA(isA<StorageInitException>()));
      expect(keyWrites, 0);
      expect(storedKey, 'not-a-key');
    });

    test('a failed key write surfaces, and the next launch mints again',
        () async {
      installKeystore();
      writeFault = PlatformException(code: 'keystore_write_failed');

      await expectLater(HiveCipherLoader.loadGuarded(),
          throwsA(isA<StorageInitException>()));
      expect(storedKey, isNull);

      writeFault = null;
      await HiveCipherLoader.loadGuarded();
      expect(keyWrites, 1);
    });
  });

  /// #4341 — these run the REAL launch (`HiveBoxes.init`, the real cipher
  /// loader) against the keystore fake above, which survives between
  /// launches; only process-local state is reset in between.
  group('later launches (#4341)', () {
    const pathChannel = MethodChannel('plugins.flutter.io/path_provider');

    /// One fresh-process launch of the storage phase: close every handle,
    /// clear the process-local registries, then run the real init.
    Future<void> launch() async {
      await Hive.close();
      HiveIsolateOwnership.resetForTest();
      HiveDeferredUserBoxes.resetForTest();
      HiveDirectoryResolver.hivePathForTest = null;
      await HiveBoxes.init();
    }

    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(pathChannel, (call) async => dir.path);
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(pathChannel, null);
      HiveIsolateOwnership.resetForTest();
      HiveDeferredUserBoxes.resetForTest();
    });

    test('a restored image is stopped on EVERY launch, byte-for-byte intact, '
        'and no replacement key is ever written', () async {
      await writeRestoredImage();
      final before = snapshot();
      expect(before.values.every((b) => b.isNotEmpty), isTrue);
      installKeystore();

      for (var n = 1; n <= 3; n++) {
        await expectLater(launch(), throwsA(isA<StorageKeyLostException>()),
            reason: 'launch $n: the recovery verdict must stand until the '
                'user resolves it — a process restart is not a resolution');
        expect(snapshot(), before,
            reason: 'launch $n: the restored ciphertext must survive '
                'untouched');
      }
      expect(keyWrites, 0,
          reason: 'a key written while the verdict stands is exactly what '
              'lets the next launch open the boxes under the wrong key');
      expect(storedKey, isNull);
    });

    test('an install #4118 already stopped — its replacement key stored — '
        'is stopped too, not truncated', () async {
      await writeRestoredImage();
      final before = snapshot();
      installKeystore(initial: base64UrlEncode(Hive.generateSecureKey()));

      for (var n = 1; n <= 2; n++) {
        await expectLater(launch(), throwsA(isA<StorageKeyLostException>()));
        expect(snapshot(), before, reason: 'launch $n');
      }
      expect(keyWrites, 0);
    });

    test('a keystore read that fails ONCE deletes nothing and the next '
        'launch opens the boxes (#4373)', () async {
      // The plugin's Android default, resetOnError: true, answers a failed
      // read by deleting the entry — the Hive key — and reporting "absent".
      final key = Hive.generateSecureKey();
      final box = await Hive.openBox<dynamic>(HiveBoxes.settings,
          encryptionCipher: HiveAesCipher(key));
      await box.put('theme', 'dark');
      await box.close();
      installKeystore(initial: base64UrlEncode(key));
      readFault = PlatformException(code: 'keystore_busy');

      await expectLater(launch(), throwsA(isA<StorageInitException>()),
          reason: 'retryable, not "key lost" and not a minted key');
      readFault = null;
      await launch();

      expect(Hive.box<dynamic>(HiveBoxes.settings).get('theme'), 'dark');
      expect(keyWrites, 0);
      expect(calls.map((c) => c.$1), isNot(anyOf(contains('delete'),
          contains('deleteAll'))));
      expect(calls, isNotEmpty);
      for (final (method, options) in calls) {
        expect(options['resetOnError'], 'false',
            reason: '$method must not let the plugin delete on error');
      }
    });

    test('a fresh install shows no key-loss screen: one key, and the next '
        'launch reads what the first wrote', () async {
      installKeystore();

      await launch();
      await Hive.box<dynamic>(HiveBoxes.settings).put('theme', 'dark');
      await launch();

      expect(keyWrites, 1);
      expect(Hive.box<dynamic>(HiveBoxes.settings).get('theme'), 'dark');
    });

    test('a stray plaintext box (the pre-bind error spool) is no evidence '
        'of a lost key', () async {
      final spool = await Hive.openBox<String>(HiveBoxes.isolateErrorSpool);
      await spool.put('e1', '{"error":"early"}');
      await spool.close();
      installKeystore();

      await expectLater(launch(), completes);
      expect(keyWrites, 1);
    });

    test('a legacy plaintext box is migrated with its data, not refused as '
        'a lost key (#1686, #4372)', () async {
      // Was an OBSERVATION of #4372: the migration's cipher-first open
      // truncated this box. The migration now classifies the file first,
      // so the record survives the real launch.
      final legacy = await Hive.openBox<dynamic>(HiveBoxes.favorites);
      await legacy.put('station-1', '{"id":"station-1"}');
      await legacy.close();
      installKeystore();

      await expectLater(launch(), completes);
      expect(keyWrites, 1);
      expect(Hive.box<dynamic>(HiveBoxes.favorites).get('station-1'),
          '{"id":"station-1"}');
    });
  });
}
