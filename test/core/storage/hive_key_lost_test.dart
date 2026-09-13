// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/core/storage/hive_cipher_loader.dart';
import 'package:tankstellen/core/storage/impl/hive_directory_resolver.dart';

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
/// The check therefore has to run BEFORE the first open, and the signal
/// is cheap and exact: a new key plus box files that predate it. A
/// genuine first run mints a key too, and passes — it has no box files.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  late Directory dir;

  /// Stand in for the platform keystore. [stored] is what a `read`
  /// answers — null being the restored / first-run case.
  void mockSecureStorage({String? stored}) {
    var current = stored;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'read':
          return current;
        case 'write':
          current = (call.arguments as Map)['value'] as String?;
          return null;
        default:
          return null;
      }
    });
  }

  setUp(() {
    dir = Directory.systemTemp.createTempSync('hive_key_lost_test');
    Hive.init(dir.path);
    HiveCipherLoader.setKeyGeneratedForTest(value: false);
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await Hive.close();
    dir.deleteSync(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    HiveCipherLoader.setKeyGeneratedForTest(value: false);
    HiveCipherLoader.resetCipherLoaderForTest();
    HiveDirectoryResolver.hivePathForTest = null;
  });

  group('the flag the verdict rests on', () {
    test('the REAL loader flips it when it has to mint a key', () async {
      // Executed, not source-scanned: #4116 shipped because every test
      // of that batch read the file as text instead of running it.
      mockSecureStorage();

      await HiveCipherLoader.loadGuarded();

      expect(HiveCipherLoader.keyGeneratedThisLaunch, isTrue);
    });

    test('and leaves it alone when the key was already there', () async {
      mockSecureStorage(
          stored: base64UrlEncode(Hive.generateSecureKey()));

      await HiveCipherLoader.loadGuarded();

      expect(HiveCipherLoader.keyGeneratedThisLaunch, isFalse,
          reason: 'an ordinary launch must never be able to reach the '
              'restore verdict');
    });
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

  test('a new key with boxes already on disk stops the launch', () async {
    // The old phone's box files, restored onto a phone whose KeyStore
    // key did not come with them.
    final box = await Hive.openBox<dynamic>(
      HiveBoxes.settings,
      encryptionCipher: HiveAesCipher(Hive.generateSecureKey()),
    );
    await box.put('theme', 'dark');
    await box.close();

    mockSecureStorage();
    await HiveCipherLoader.loadGuarded();
    HiveDirectoryResolver.hivePathForTest = dir.path;

    expect(
      HiveCipherLoader.assertKeyMatchesExistingBoxes,
      throwsA(isA<StorageKeyLostException>()),
      reason: 'letting the launch continue means Hive truncates the '
          'restored boxes, as the test above measures',
    );
  });

  test('a genuine first run is not stopped', () async {
    // Same new key, no box files — the case that must stay silent, or
    // every fresh install lands on a recovery screen.
    mockSecureStorage();
    await HiveCipherLoader.loadGuarded();
    HiveDirectoryResolver.hivePathForTest = dir.path;

    expect(HiveCipherLoader.keyGeneratedThisLaunch, isTrue);
    expect(HiveCipherLoader.assertKeyMatchesExistingBoxes, returnsNormally,
        reason: 'a new key is normal on a first run; stopping there '
            'would put every fresh install on a recovery screen');
  });

  test('an unknown Hive path never invents a stop', () async {
    // `hasExistingBoxFiles` gates a hard stop, so an unreadable or
    // unresolved directory must answer "no boxes", never "maybe".
    HiveCipherLoader.setKeyGeneratedForTest(value: true);

    HiveDirectoryResolver.hivePathForTest = null;
    expect(HiveDirectoryResolver.hasExistingBoxFiles, isFalse);
    expect(HiveCipherLoader.assertKeyMatchesExistingBoxes, returnsNormally);

    HiveDirectoryResolver.hivePathForTest = '${dir.path}/does-not-exist';
    expect(HiveDirectoryResolver.hasExistingBoxFiles, isFalse);
    expect(HiveCipherLoader.assertKeyMatchesExistingBoxes, returnsNormally);
  });
}
