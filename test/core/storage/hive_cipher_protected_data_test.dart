// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/core/storage/hive_cipher_loader.dart';
import 'package:tankstellen/core/storage/hive_deferred_user_boxes.dart';
import 'package:tankstellen/core/storage/hive_isolate_ownership.dart';
import 'package:tankstellen/core/storage/impl/hive_directory_resolver.dart';

import '../../helpers/hive_temp_dir.dart';

/// #4357 — a locked phone is not a lost key.
///
/// The iOS keychain seals its items until the device has been unlocked
/// once after boot. A recording that starts, or is relaunched by Core
/// Bluetooth state restoration, in that window asks for the Hive
/// encryption key and is told "no". The question this file settles is
/// what the app does with that "no".
///
/// The wrong answer is the expensive one. `_loadCipher`'s verdict is
/// computed from whether a key is present, and an ABSENT key with box
/// files on disk means `keyLost` — the permanent, unrecoverable verdict
/// (#4118). Downstream of a wrong "the key is gone" sits the truncating
/// path: a replacement key gets minted, the boxes open under it, and
/// Hive's crash recovery silently zeroes them (93 bytes in, 0 bytes out
/// — measured in `hive_key_lost_test.dart`). A transient lock would
/// then have destroyed the trip it interrupted.
///
/// So the protected-data answer is fenced BEFORE the read, and the
/// classification of a keychain error that still gets through is
/// narrow. Both branches are driven here, and the retryable one is
/// pinned against reaching the mint/open at all.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  const pathChannel = MethodChannel('plugins.flutter.io/path_provider');
  late Directory dir;

  var keyWrites = 0;
  String? storedKey;
  PlatformException? readFault;
  bool? protectedDataAvailable;
  final methods = <String>[];

  void installKeychain({String? initial, bool? protectedData}) {
    storedKey = initial;
    keyWrites = 0;
    readFault = null;
    protectedDataAvailable = protectedData;
    methods.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      methods.add(call.method);
      switch (call.method) {
        case 'isProtectedDataAvailable':
          return protectedDataAvailable;
        case 'read':
          if (readFault case final fault?) throw fault;
          return storedKey;
        case 'write':
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

  /// Box files written under a key this process does not hold — the
  /// shape that makes an absent key mean `keyLost`.
  Future<void> writeEncryptedImage() async {
    final otherKey = HiveAesCipher(Hive.generateSecureKey());
    final settings = await Hive.openBox<dynamic>(HiveBoxes.settings,
        encryptionCipher: otherKey);
    await settings.put('theme', 'dark');
    await settings.close();
  }

  setUp(() {
    dir = Directory.systemTemp.createTempSync('hive_protected_data_test');
    Hive.init(dir.path);
    HiveDirectoryResolver.hivePathForTest = dir.path;
    // The availability probe is platform-gated inside the plugin: it
    // never reaches a channel unless the target platform is iOS/macOS.
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathChannel, (call) async => dir.path);
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await closeHiveAndDeleteTemp(dir);
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      ..setMockMethodCallHandler(channel, null)
      ..setMockMethodCallHandler(pathChannel, null);
    HiveCipherLoader.resetCipherLoaderForTest();
    HiveDirectoryResolver.hivePathForTest = null;
    HiveIsolateOwnership.resetForTest();
    HiveDeferredUserBoxes.resetForTest();
  });

  group('the retryable branch — protected data unavailable', () {
    test('a sealed keychain is a retryable StorageInitException, never a '
        'key-loss verdict', () async {
      await writeEncryptedImage();
      installKeychain(protectedData: false);

      await expectLater(
        HiveCipherLoader.loadGuarded(),
        throwsA(isA<StorageInitException>()
            .having((e) => e.protectedDataUnavailable,
                'protectedDataUnavailable', isTrue)
            .having((e) => e, 'is not a key-loss verdict',
                isNot(isA<StorageKeyLostException>()))),
      );
    });

    test('the sealed read never reaches the keychain, the verdict or the '
        'mint — the truncating path is unreachable', () async {
      await writeEncryptedImage();
      final before = snapshot();
      expect(before.values.single, isNotEmpty);
      installKeychain(protectedData: false);

      await expectLater(HiveCipherLoader.loadGuarded(),
          throwsA(isA<StorageInitException>()));

      expect(methods, ['isProtectedDataAvailable'],
          reason: 'no read and no write may follow a sealed keychain — a '
              'key minted here is exactly what authorises the next '
              'launch to open the boxes under the wrong key');
      expect(keyWrites, 0);
      expect(storedKey, isNull);
      expect(snapshot(), before,
          reason: 'the encrypted image must be byte-identical: a wrong key '
              'does not fail the open, it TRUNCATES the box (#4118)');
    });

    test('a keychain that answers errSecInteractionNotAllowed is classified '
        'the same way, and still writes nothing', () async {
      await writeEncryptedImage();
      installKeychain(protectedData: true);
      readFault = PlatformException(
          code: 'Unexpected security result code',
          message: 'interactionNotAllowed',
          details: kErrSecInteractionNotAllowed);

      await expectLater(
        HiveCipherLoader.loadGuarded(),
        throwsA(isA<StorageInitException>().having(
            (e) => e.protectedDataUnavailable,
            'protectedDataUnavailable',
            isTrue)),
      );
      expect(keyWrites, 0);
      expect(methods, isNot(contains('write')));
    });

    test('the very next launch, once unlocked, reads the key and opens the '
        'boxes with their data intact', () async {
      final key = Hive.generateSecureKey();
      final box = await Hive.openBox<dynamic>(HiveBoxes.settings,
          encryptionCipher: HiveAesCipher(key));
      await box.put('theme', 'dark');
      await box.close();
      await Hive.close();
      installKeychain(
          initial: base64UrlEncode(key), protectedData: false);

      HiveIsolateOwnership.resetForTest();
      HiveDeferredUserBoxes.resetForTest();
      HiveDirectoryResolver.hivePathForTest = null;
      await expectLater(HiveBoxes.init(), throwsA(isA<StorageInitException>()));

      // The user unlocks; nothing else changes.
      protectedDataAvailable = true;
      await Hive.close();
      HiveIsolateOwnership.resetForTest();
      HiveDeferredUserBoxes.resetForTest();
      HiveDirectoryResolver.hivePathForTest = null;
      await HiveBoxes.init();

      expect(Hive.box<dynamic>(HiveBoxes.settings).get('theme'), 'dark',
          reason: 'the key was never lost — only unreadable for a while');
      expect(keyWrites, 0);
    });
  });

  group('the lost branch — a genuinely absent key', () {
    test('an available keychain with no key and ciphertext on disk is still '
        'a key-loss verdict', () async {
      await writeEncryptedImage();
      installKeychain(protectedData: true);

      await expectLater(HiveCipherLoader.loadGuarded(),
          throwsA(isA<StorageKeyLostException>()),
          reason: 'the fence must not swallow the one verdict that is real');
      expect(keyWrites, 0);
    });

    test('an unrelated keychain fault stays cause-unknown, NOT retryable-'
        'protected-data', () async {
      await writeEncryptedImage();
      installKeychain(protectedData: true);
      readFault = PlatformException(code: 'keystore_unavailable');

      await expectLater(
        HiveCipherLoader.loadGuarded(),
        throwsA(isA<StorageInitException>().having(
            (e) => e.protectedDataUnavailable,
            'protectedDataUnavailable',
            isFalse)),
        reason: 'guessing "transient" for a permanent fault is how a user '
            'retries forever',
      );
      expect(keyWrites, 0);
    });

    test('a first run on an available keychain still mints exactly one key',
        () async {
      installKeychain(protectedData: true);

      await HiveCipherLoader.loadGuarded();

      expect(keyWrites, 1);
      expect(base64Url.decode(storedKey!), hasLength(32));
    });
  });

  group('the classifier', () {
    test('accepts only the protected-data faults', () {
      expect(
          isProtectedDataUnavailableFault(PlatformException(
              code: 'Unexpected security result code',
              details: kErrSecInteractionNotAllowed)),
          isTrue);
      expect(
          isProtectedDataUnavailableFault(
              PlatformException(code: 'protected_data_unavailable')),
          isTrue);
      expect(
          isProtectedDataUnavailableFault(PlatformException(
              code: 'Unexpected security result code', details: -25300)),
          isFalse,
          reason: 'errSecItemNotFound is an absent item, not a sealed one');
      expect(isProtectedDataUnavailableFault(StateError('nope')), isFalse);
    });
  });
}
