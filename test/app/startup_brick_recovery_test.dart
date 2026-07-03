// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/core/storage/hive_cipher_loader.dart';

/// #3149 — the startup-brick gap around #2294: `run()` caught ONLY
/// HiveCorruptionException, while `_loadCipher()` (FlutterSecureStorage)
/// sat outside the HiveError re-tag, and TraceStorage.init / loadApiKey /
/// ensureDefaultProfile were unguarded — any of those faulting froze the
/// user on the splash with zero telemetry (handlers install only in
/// `_launch`). These tests pin:
///
///  1. a fake secure-storage throw surfaces as the typed
///     StorageInitException (with the cause attached) that `run()` routes
///     to the SAME StorageRecoveryHost as a corrupted box;
///  2. structurally, `run()` carries a catch-all after the specific
///     catch, both persist the cause Hive-independently
///     (StartupFailureStore), and the next launch replays it.
///
/// The persistence + replay round-trip itself is unit-tested in
/// test/core/telemetry/storage/startup_failure_store_test.dart; the
/// structural source-scan mirrors the #2294 test
/// (test/app/widgets/storage_recovery_screen_test.dart).
void main() {
  group('secure-storage fault → typed StorageInitException (#3149)', () {
    tearDown(HiveCipherLoader.resetCipherLoaderForTest);

    test('a PlatformException from the cipher load is re-tagged with the '
        'cause + original stack preserved', () async {
      final fault = PlatformException(
          code: 'keystore_unavailable',
          message: 'BAD_DECRYPT after OS credential reset');
      HiveCipherLoader.cipherLoader = () async => throw fault;

      try {
        await HiveCipherLoader.loadGuarded();
        fail('must throw');
      } on StorageInitException catch (e, st) {
        expect(e.cause, same(fault),
            reason: 'the recovery path + persisted record need the root '
                'cause, not just the re-tag');
        expect(e.toString(), contains('secure-storage'));
        expect(st.toString(), contains('startup_brick_recovery_test'),
            reason: 'Error.throwWithStackTrace must preserve the original '
                'throwing stack');
      }
    });

    test('StorageInitException is a sibling of HiveCorruptionException, '
        'not a subtype (run() catches it via the catch-all)', () {
      const e = StorageInitException('msg');
      expect(e, isNot(isA<HiveCorruptionException>()));
      expect(e, isA<Exception>());
    });
  });

  group('AppInitializer wires unknown storage failures to recovery (#3149)',
      () {
    late String initSource;
    late String hiveBoxesSource;

    setUpAll(() {
      initSource = File('lib/app/app_initializer.dart').readAsStringSync();
      hiveBoxesSource =
          File('lib/core/storage/hive_boxes.dart').readAsStringSync();
    });

    test('HiveBoxes.init / initInIsolate load the cipher via the guarded '
        'path', () {
      expect(hiveBoxesSource, contains('await HiveCipherLoader.loadGuarded()'),
          reason: 'the secure-storage read must be inside the typed '
              're-tag so a PlatformException cannot escape untyped');
      expect(
          RegExp(r'await _loadCipher\(\)').hasMatch(hiveBoxesSource), isFalse,
          reason: 'no init path may bypass the guard');
    });

    test('run() has a catch-all AFTER the specific HiveCorruptionException '
        'catch, routing to the same StorageRecoveryHost', () {
      final specific = initSource.indexOf('on HiveCorruptionException');
      expect(specific, isNonNegative);
      final rest = initSource.substring(specific);
      final catchAll = rest.indexOf('} catch (e, st) {');
      expect(catchAll, isNonNegative,
          reason: 'unknown storage failures (cipher, trace box, profile '
              'seed) must not escape uncaught — no Zone handler exists yet');
      // The catch-all block must route to the recovery host too.
      final afterCatchAll = rest.substring(catchAll);
      final block = afterCatchAll.substring(
          0, afterCatchAll.indexOf("StartupTimer.instance.mark('storage_ready')"));
      // #3272 — wrapped in a bare ProviderScope (missing_provider_scope).
      expect(block,
          contains('runApp(const ProviderScope(child: StorageRecoveryHost()))'));
      expect(block, contains('errorLogger.log(ErrorLayer.storage'));
    });

    test('both storage-brick catches persist the cause Hive-independently '
        'and the next launch replays it', () {
      final specific = initSource.indexOf('on HiveCorruptionException');
      final upToStorageReady = initSource.substring(
          specific, initSource.indexOf("mark('storage_ready')"));
      expect(
          RegExp(r'StartupFailureStore\.persist')
              .allMatches(upToStorageReady)
              .length,
          2,
          reason: 'Hive is down in both paths — the spool cannot record; '
              'only the plain file survives for the next launch');
      expect(initSource, contains('StartupFailureStore.drain()'),
          reason: 'a persisted brick record must be replayed into the '
              'trace pipeline on the next successful launch');
      expect(initSource, contains("'where': 'startupFailureReplay'"));
    });
  });
}
