// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

// ignore_for_file: implementation_imports
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/src/binary/binary_reader_impl.dart';
import 'package:hive/src/registry/type_registry_impl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tankstellen/core/storage/hive_box_key_probe.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/core/storage/hive_cipher_loader.dart';
import 'package:tankstellen/core/storage/hive_deferred_user_boxes.dart';
import 'package:tankstellen/core/storage/hive_isolate_ownership.dart';
import 'package:tankstellen/core/storage/hive_trip_box_encryption.dart';
import 'package:tankstellen/core/storage/impl/hive_directory_resolver.dart';

import '../../helpers/hive_temp_dir.dart';

/// #4341 adversarial verification, part 3 of 3 — the real app launch
/// path: `HiveBoxes.init` over every box the app opens, the background
/// isolate entry, and upgrades from a master-built install. Part 1:
/// `hive_box_key_probe_adversarial_test.dart`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  final other = HiveAesCipher(Hive.generateSecureKey());

  BoxKeyVerdict inspect(HiveAesCipher? c, [String? path]) =>
      HiveBoxKeyProbe.inspect(path ?? dir.path, c);

  /// Hive's own answer: does its reader accept the first frame under [c]?
  /// null = no frame at all (Hive would stop reading at offset 0 for any
  /// cipher).
  bool hiveAcceptsFirstFrame(File f, HiveAesCipher? c) {
    final bytes = f.readAsBytesSync();
    final reader = BinaryReaderImpl(bytes, TypeRegistryImpl.nullImpl);
    return reader.readFrame(cipher: c, lazy: true) != null;
  }

  setUp(() {
    dir = Directory.systemTemp.createTempSync('hive_probe_adv');
    Hive.init(dir.path);
  });

  tearDown(() async {
    await closeHiveAndDeleteTemp(dir);
  });

  // ---------------------------------------------------------------------
  // 7 + 11 — the real app launch path
  // ---------------------------------------------------------------------
  group('7/11 — real HiveBoxes.init, every box the app opens, master upgrade',
      () {
    const channel =
        MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    const pathChannel = MethodChannel('plugins.flutter.io/path_provider');
    String? storedKey;
    var keyWrites = 0;

    /// Verbatim copy of origin/master's `HiveCipherLoader._loadCipher`
    /// (minus the launch-local flag) — the pre-#4341 build.
    Future<HiveAesCipher> masterLoadCipher() async {
      const secureStorage = FlutterSecureStorage();
      final existing = await secureStorage.read(key: 'hive_encryption_key');
      if (existing != null) {
        return HiveAesCipher(base64Url.decode(existing));
      }
      final k = Hive.generateSecureKey();
      await secureStorage.write(
          key: 'hive_encryption_key', value: base64UrlEncode(k));
      return HiveAesCipher(k);
    }

    Future<void> launch({required bool master}) async {
      await Hive.close();
      HiveIsolateOwnership.resetForTest();
      HiveDeferredUserBoxes.resetForTest();
      HiveDirectoryResolver.hivePathForTest = null;
      if (master) {
        HiveCipherLoader.cipherLoader = masterLoadCipher;
      } else {
        HiveCipherLoader.resetCipherLoaderForTest();
      }
      await HiveBoxes.init();
    }

    Map<String, List<int>> snapshot() => {
          for (final f in dir.listSync().whereType<File>())
            if (f.path.endsWith('.hive'))
              f.uri.pathSegments.last: f.readAsBytesSync(),
        };

    HiveAesCipher stored() => HiveAesCipher(base64Url.decode(storedKey!));

    setUp(() {
      storedKey = null;
      keyWrites = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        switch (call.method) {
          case 'read':
            return storedKey;
          case 'write':
            keyWrites++;
            storedKey = (call.arguments as Map)['value'] as String?;
            return null;
          default:
            return null;
        }
      });
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(pathChannel, (call) async => dir.path);
    });

    tearDown(() async {
      await Hive.close();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(pathChannel, null);
      HiveCipherLoader.resetCipherLoaderForTest();
      HiveDirectoryResolver.hivePathForTest = null;
      HiveIsolateOwnership.resetForTest();
      HiveDeferredUserBoxes.resetForTest();
      HiveTripBoxEncryption.resetForTesting();
    });

    /// Replica of `HiveBoxes._openDeferred` (hive_boxes.dart) — the real
    /// `initDeferred()` memoizes per process, so a second test in this file
    /// would silently skip it. Includes the loader re-probe it performs
    /// while the first-frame boxes are open.
    Future<void> openDeferredLikeApp() async {
      final cipher = await HiveCipherLoader.loadGuarded();
      const encryptedDeferred = {
        HiveBoxes.obd2Baselines, HiveBoxes.obd2TripHistory,
        HiveBoxes.obd2PausedTrips, HiveBoxes.obd2ActiveTrip,
        HiveBoxes.obd2SupportedPids, HiveBoxes.obd2NegotiatedProtocol,
        HiveBoxes.serviceReminders,
      };
      const deferred = {
        ...encryptedDeferred, HiveBoxes.priceSnapshots,
        HiveBoxes.trafficSignalsCache,
      };
      await Future.wait(encryptedDeferred
          .map((n) => HiveTripBoxEncryption.migrate(n, cipher)));
      await Future.wait([
        for (final n in deferred)
          Hive.openBox<String>(n,
              encryptionCipher:
                  encryptedDeferred.contains(n) ? cipher : null),
        Hive.openBox<dynamic>(HiveBoxes.datasets, encryptionCipher: cipher),
        for (final n in HiveDeferredUserBoxes.names)
          HiveDeferredUserBoxes.ensureOpen(n),
      ]);
    }

    /// A master-built install that has been used: first-frame + deferred
    /// boxes, every plaintext side box, writes + deletes (compaction), a
    /// legacy plaintext trip box migrated through the staging box.
    Future<void> useLikeMaster() async {
      // A pre-#3611 plaintext trip box, so the staging migration runs.
      final legacyTrips = await Hive.openBox<String>(HiveBoxes.obd2TripHistory);
      await legacyTrips.put('t1', '{"km":12.3}');
      await legacyTrips.close();

      await launch(master: true);
      await openDeferredLikeApp();
      for (final name in [
        HiveBoxes.settings, HiveBoxes.profiles, HiveBoxes.favorites,
        HiveBoxes.cache, HiveBoxes.alerts, HiveBoxes.priceHistory,
        HiveBoxes.datasets, HiveBoxes.featureFlags, HiveBoxes.appProfile,
      ]) {
        expect(Hive.isBoxOpen(name), isTrue, reason: 'open after init: $name');
        final b = Hive.box<dynamic>(name);
        for (var i = 0; i < 120; i++) {
          await b.put('$name-$i', {'n': i, 'pad': 'p' * 64});
        }
        for (var i = 0; i < 90; i++) {
          await b.delete('$name-$i'); // default compaction fires
        }
      }
      for (final name in [
        HiveBoxes.obd2Baselines, HiveBoxes.obd2TripHistory,
        HiveBoxes.obd2SupportedPids, HiveBoxes.obd2NegotiatedProtocol,
        HiveBoxes.serviceReminders, HiveBoxes.obd2PausedTrips,
        HiveBoxes.obd2ActiveTrip, HiveBoxes.priceSnapshots,
        HiveBoxes.trafficSignalsCache,
      ]) {
        await Hive.box<String>(name).put('x', '{"v":1}');
      }
      for (final name in [
        HiveBoxes.isolateErrorSpool, HiveBoxes.errorTraces,
        'health_counters', 'obd2_connect_traces',
      ]) {
        await (await Hive.openBox<dynamic>(name)).put('e', 'x');
      }
    }

    test('7 — every box file the app writes is thisKey or plaintext, and the '
        'whole directory is consistent while boxes are OPEN (.lock present)',
        () async {
      await useLikeMaster();
      expect(keyWrites, 1);
      expect(dir.listSync().any((e) => e.path.endsWith('.lock')), isTrue);
      final k = stored();

      expect(inspect(k), BoxKeyVerdict.consistent);
      expect(inspect(null), BoxKeyVerdict.keyLost);
      expect(inspect(other), BoxKeyVerdict.keyLost);

      const encrypted = {
        'settings', 'profiles', 'favorites', 'cache', 'alerts',
        'price_history', 'datasets', 'obd2_baselines', 'obd2_trip_history',
        'obd2_supported_pids', 'obd2_negotiated_protocol',
        'service_reminders', 'obd2_paused_trips', 'obd2_active_trip',
      };
      final seen = <String>{};
      for (final f in dir.listSync().whereType<File>()) {
        if (!f.path.endsWith('.hive')) continue;
        final name = f.uri.pathSegments.last.replaceAll('.hive', '');
        seen.add(name);
        expect(f.lengthSync(), greaterThan(0), reason: name);
        final single = Directory.systemTemp.createTempSync('one');
        f.copySync('${single.path}/$name.hive');
        final underOther = inspect(other, single.path);
        final underKey = inspect(k, single.path);
        single.deleteSync(recursive: true);
        expect(underKey, BoxKeyVerdict.consistent, reason: name);
        if (encrypted.contains(name)) {
          expect(underOther, BoxKeyVerdict.keyLost, reason: '$name is keyed');
          expect(hiveAcceptsFirstFrame(f, k), isTrue, reason: name);
        } else {
          expect(underOther, BoxKeyVerdict.consistent,
              reason: '$name is plaintext');
          expect(hiveAcceptsFirstFrame(f, null), isTrue, reason: name);
        }
      }
      expect(seen.containsAll(encrypted), isTrue, reason: '$seen');
      expect(seen.any((n) => n.endsWith('_enc_staging')), isFalse,
          reason: 'staging promoted and deleted');
    });

    test('11 — upgrade from master: a used install launches, writes no key, '
        'and every box file is byte-for-byte untouched by the new launch',
        () async {
      await useLikeMaster();
      await launch(master: true); // a second master launch
      await openDeferredLikeApp();
      await Hive.close();
      final before = snapshot();

      for (var n = 1; n <= 3; n++) {
        await expectLater(launch(master: false), completes, reason: 'launch $n');
        expect(snapshot(), before, reason: 'launch $n: no truncation');
        expect(Hive.box<dynamic>(HiveBoxes.settings).get('settings-119'),
            isNotNull);
      }
      await openDeferredLikeApp(); // re-probes; must not throw either
      expect(Hive.box<String>(HiveBoxes.obd2TripHistory).get('t1'),
          '{"km":12.3}');
      expect(keyWrites, 1);
    });

    test('7b — background isolate entry (HiveIsolateBoxes.initInIsolate): a '
        'used install opens; a restored image is refused byte-for-byte',
        () async {
      await useLikeMaster();
      await Hive.close();
      HiveCipherLoader.resetCipherLoaderForTest();
      HiveDirectoryResolver.hivePathForTest = null;
      await expectLater(HiveBoxes.initInIsolate(), completes);
      await Hive.close();

      // Now the restore: same files, keystore lost.
      final before = snapshot();
      storedKey = null;
      HiveDirectoryResolver.hivePathForTest = null;
      await expectLater(HiveBoxes.initInIsolate(),
          throwsA(isA<StorageKeyLostException>()));
      expect(snapshot(), before);
      expect(keyWrites, 1);
    });

    test('11b — master user killed during the very first launch (key written, '
        'boxes opened, nothing encrypted written) upgrades cleanly', () async {
      await launch(master: true);
      await Hive.close();
      expect(storedKey, isNotNull);
      await expectLater(launch(master: false), completes);
      expect(keyWrites, 1);
    });

    test('11c — master key written but process died BEFORE any box file '
        'existed upgrades cleanly', () async {
      await masterLoadCipher();
      await expectLater(launch(master: false), completes);
      expect(keyWrites, 1);
    });

    test('11d — master install whose ONLY non-empty encrypted box is the '
        'deferred trip history, plus plaintext boxes', () async {
      await launch(master: true);
      await openDeferredLikeApp();
      await Hive.box<String>(HiveBoxes.obd2TripHistory).put('t', 'x');
      await Hive.close();
      await expectLater(launch(master: false), completes);
    });
  });
}
