// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/app/startup/storage_failure_gate.dart';
import 'package:tankstellen/app/widgets/storage_recovery_screen.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/core/storage/hive_cipher_loader.dart';
import 'package:tankstellen/core/telemetry/storage/startup_failure_store.dart';

import '../helpers/hive_temp_dir.dart';

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

  group('the storage phase routes every failure to the right screen', () {
    // #4118 — these two used to read `app_initializer.dart` AS TEXT and
    // assert that a catch-all sat after the specific catch. They broke
    // the moment the catches moved into `storage_failure_gate.dart` —
    // which is the honest verdict of a test that pins prose, not
    // behaviour: the routing was intact, the string had moved.
    //
    // The gate takes the storage phase as a function, so the real thing
    // can be driven now. #4116 is the reason this matters: four
    // source-scanning tests guarded the first-frame box opens and none
    // of them RAN the code, so a self-recursive alias shipped with
    // 16,626 tests green.
    late Directory tmp;

    setUp(() {
      tmp = Directory.systemTemp.createTempSync('brick_recovery_test');
      StartupFailureStore.directoryProvider = () async => tmp;
    });

    tearDown(() async {
      StartupFailureStore.resetForTest();
      await closeHiveAndDeleteTemp(tmp);
    });

    /// Drives the gate with a storage phase that throws [fault] and
    /// returns the cause the screen was mounted with.
    ///
    /// [fault] is `Object` because the whole point is that the gate must
    /// cope with whatever the storage phase throws — including an
    /// `Error`, which is what a bug of ours looks like.
    Future<StorageRecoveryCause?> causeFor(
        WidgetTester tester, Object fault) async {
      // `runAsync`: the gate awaits StartupFailureStore's real file I/O,
      // and a testWidgets body runs in a fake-async zone that never
      // completes it (the first attempt hung for the full 10-minute
      // timeout rather than failing).
      final ok = await tester.runAsync(
          // ignore: only_throw_errors
          () => runStoragePhaseGuarded(() async => throw fault));
      expect(ok, isFalse, reason: 'startup cannot continue without storage');
      await tester.pump();
      final host = tester.widgetList<StorageRecoveryHost>(
          find.byType(StorageRecoveryHost));
      return host.isEmpty ? null : host.first.cause;
    }

    testWidgets('a corrupt box is the only fault that may claim damage',
        (tester) async {
      final cause = await causeFor(
          tester, const HiveCorruptionException('box unreadable'));
      expect(cause, StorageRecoveryCause.corruptBox);
    });

    testWidgets('a lost key says RESTORE, not damage', (tester) async {
      final cause =
          await causeFor(tester, const StorageKeyLostException('no key'));
      expect(cause, StorageRecoveryCause.keyLost);
    });

    testWidgets('anything else lands on the harmless branch',
        (tester) async {
      // The #4116 asymmetry: claiming "not damaged" wrongly costs a
      // restart, claiming "damaged" wrongly costs the user their
      // favourites and history for good. A cipher fault, a TraceStorage
      // fault or a bug of ours must never reach the destructive copy.
      final cause = await causeFor(
          tester, const StorageInitException('cipher unavailable'));
      expect(cause, StorageRecoveryCause.unknown);

      final onAPlainError = await causeFor(tester, StateError('a bug'));
      expect(onAPlainError, StorageRecoveryCause.unknown);
    });

    testWidgets('every branch persists the cause Hive-INDEPENDENTLY, so the '
        'next launch can replay it', (tester) async {
      // Hive is the thing that is down, so the error spool cannot record
      // anything — only a plain file survives to the next launch.
      for (final fault in <Object>[
        const HiveCorruptionException('box unreadable'),
        const StorageKeyLostException('no key'),
        const StorageInitException('cipher unavailable'),
      ]) {
        for (final f in tmp.listSync()) {
          f.deleteSync(recursive: true);
        }
        await causeFor(tester, fault);
        expect(tmp.listSync(), isNotEmpty,
            reason: 'nothing was written for $fault — that launch would '
                'be undiagnosable');
      }
    });

    testWidgets('a storage phase that succeeds mounts nothing and lets '
        'startup continue', (tester) async {
      final ok =
          await tester.runAsync(() => runStoragePhaseGuarded(() async {}));
      await tester.pump();

      expect(ok, isTrue);
      expect(find.byType(StorageRecoveryHost), findsNothing);
      expect(tmp.listSync(), isEmpty);
    });
  });

  group('the guarded cipher path stays guarded (#3149)', () {
    late String hiveBoxesSource;

    setUpAll(() {
      hiveBoxesSource =
          File('lib/core/storage/hive_boxes.dart').readAsStringSync();
    });

    test('HiveBoxes.init loads the cipher via the guarded path', () {
      expect(hiveBoxesSource, contains('await HiveCipherLoader.loadGuarded()'),
          reason: 'the secure-storage read must be inside the typed '
              're-tag so a PlatformException cannot escape untyped');
      expect(
          RegExp(r'await _loadCipher\(\)').hasMatch(hiveBoxesSource), isFalse,
          reason: 'no init path may bypass the guard');
    });

    test('the replay of a persisted brick record is still wired', () {
      final initSource = File('lib/app/app_initializer.dart').readAsStringSync();
      expect(initSource, contains('StartupFailureStore.drain()'),
          reason: 'a persisted brick record must be replayed into the '
              'trace pipeline on the next successful launch');
      expect(initSource, contains("'where': 'startupFailureReplay'"));
    });
  });
}
