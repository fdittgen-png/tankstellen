// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/core/storage/stores/settings_hive_store.dart';

/// The secure-storage portion of SettingsHiveStore talks to the platform
/// keychain via method channels. Tests mock that channel so setApiKey/
/// deleteApiKey run through without touching the real device. The in-
/// memory cache on SettingsHiveStore then holds the value for the
/// synchronous getApiKey() contract.
void _mockSecureStorage({
  Map<String, String?> initial = const {},
}) {
  final store = Map<String, String?>.from(initial);
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async {
    final args = (call.arguments as Map?) ?? {};
    final key = args['key'] as String? ?? '';
    switch (call.method) {
      case 'read':
        return store[key];
      case 'write':
        store[key] = args['value'] as String?;
        return null;
      case 'delete':
        store.remove(key);
        return null;
      case 'readAll':
        return Map<String, String?>.from(store);
      case 'deleteAll':
        store.clear();
        return null;
      case 'containsKey':
        return store.containsKey(key);
    }
    return null;
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SettingsHiveStore store;
  late Directory tempDir;

  setUp(() async {
    _mockSecureStorage();
    tempDir = await Directory.systemTemp.createTemp('settings_store_test_');
    Hive.init(tempDir.path);
    await HiveStorage.initForTest();
    store = SettingsHiveStore();
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('Settings key/value', () {
    test('getSetting returns null for missing keys', () {
      expect(store.getSetting('never-set'), isNull);
    });

    test('putSetting + getSetting round-trip a value', () async {
      await store.putSetting('favourite_fuel', 'diesel');
      expect(store.getSetting('favourite_fuel'), 'diesel');
    });

    test('putSetting overwrites existing values', () async {
      await store.putSetting('radius', 10);
      await store.putSetting('radius', 25);
      expect(store.getSetting('radius'), 25);
    });
  });

  group('Setup completion state', () {
    test('isSetupComplete / isSetupSkipped default to false', () {
      expect(store.isSetupComplete, isFalse);
      expect(store.isSetupSkipped, isFalse);
    });

    test('skipSetup flips both getters to true', () async {
      await store.skipSetup();
      expect(store.isSetupSkipped, isTrue);
      expect(store.isSetupComplete, isTrue);
    });

    test('resetSetupSkip returns them to false', () async {
      await store.skipSetup();
      await store.resetSetupSkip();
      expect(store.isSetupSkipped, isFalse);
      expect(store.isSetupComplete, isFalse);
    });

    test('isSetupComplete reflects only the explicit setup-skip flag', () async {
      // No bundled Tankerkönig key (#713) — wizard completion must depend
      // on the explicit flag, not on key availability.
      expect(store.hasApiKey('de'), isFalse);
      expect(store.isSetupComplete, isFalse);
    });
  });

  group('Per-country API keys (#3746)', () {
    test('without a custom key, getApiKey returns null (#713 — Tankerkönig '
        'TOS forbid bundling any key, including demo keys, in public source)',
        () async {
      await SettingsHiveStore.loadApiKey();
      expect(store.getApiKey('de'), isNull);
      expect(store.hasApiKey('de'), isFalse);
      expect(store.hasCustomApiKey('de'), isFalse);
    });

    test('setApiKey persists the user key and flips hasApiKey', () async {
      await store.setApiKey('de', 'custom-key-123');
      expect(store.getApiKey('de'), 'custom-key-123');
      expect(store.hasApiKey('de'), isTrue);
      expect(store.hasCustomApiKey('de'), isTrue);
    });

    test('country slots are independent — setting DE leaves KR/CL/GB empty',
        () async {
      await SettingsHiveStore.loadApiKey();
      await store.setApiKey('de', 'tankerkoenig-key');
      expect(store.getApiKey('kr'), isNull);
      expect(store.getApiKey('cl'), isNull);
      expect(store.getApiKey('gb'), isNull);

      await store.setApiKey('kr', 'opinet-key');
      expect(store.getApiKey('de'), 'tankerkoenig-key');
      expect(store.getApiKey('kr'), 'opinet-key');
    });

    test('country codes are case-insensitive and stored lowercase', () async {
      await store.setApiKey('DE', 'upper-set');
      expect(store.getApiKey('de'), 'upper-set');
      expect(store.getApiKey('De'), 'upper-set');
      await store.deleteApiKey('dE');
      expect(store.getApiKey('DE'), isNull);
    });

    test('deleteApiKey clears the user key and returns to null', () async {
      await store.setApiKey('de', 'custom-key-123');
      await store.deleteApiKey('de');
      expect(store.getApiKey('de'), isNull);
      expect(store.hasApiKey('de'), isFalse);
      expect(store.hasCustomApiKey('de'), isFalse);
    });

    test('deleteAllApiKeys wipes every country slot', () async {
      await store.setApiKey('de', 'k1');
      await store.setApiKey('kr', 'k2');
      await store.deleteAllApiKeys();
      expect(store.getApiKey('de'), isNull);
      expect(store.getApiKey('kr'), isNull);
    });

    test('legacy single-slot key migrates to the DE slot on first read '
        'and the legacy slot survives one release', () async {
      // Simulate a pre-#3746 install: only the bare 'api_key' entry exists.
      _mockSecureStorage(initial: {'api_key': 'legacy-tankerkoenig'});
      await SettingsHiveStore.loadApiKey();

      // First DE read migrates lazily.
      expect(store.getApiKey('de'), 'legacy-tankerkoenig');
      expect(store.hasApiKey('de'), isTrue);
      // Other countries never inherit the legacy slot.
      expect(store.getApiKey('kr'), isNull);
      expect(store.getApiKey('gb'), isNull);

      // A reload now finds the migrated per-country slot.
      await SettingsHiveStore.loadApiKey();
      expect(store.getApiKey('de'), 'legacy-tankerkoenig');
    });

    test('deleting the DE key also clears the legacy slot so the migration '
        'cannot resurrect it', () async {
      _mockSecureStorage(initial: {'api_key': 'legacy-tankerkoenig'});
      await SettingsHiveStore.loadApiKey();
      expect(store.getApiKey('de'), 'legacy-tankerkoenig');

      await store.deleteApiKey('de');
      expect(store.getApiKey('de'), isNull);

      await SettingsHiveStore.loadApiKey();
      expect(store.getApiKey('de'), isNull);
    });
  });

  group('EV API key', () {
    test('without a custom key, getEvApiKey returns the bundled default',
        () async {
      await SettingsHiveStore.loadEvApiKey();
      expect(store.getEvApiKey(), SettingsHiveStore.defaultEvApiKey);
      expect(store.hasEvApiKey(), isTrue);
      expect(store.hasCustomEvApiKey(), isFalse);
    });

    test('setEvApiKey overrides the default', () async {
      await store.setEvApiKey('ev-custom');
      expect(store.getEvApiKey(), 'ev-custom');
      expect(store.hasCustomEvApiKey(), isTrue);
    });
  });

  group('Resilience — settings box closed (#3370 / #3377)', () {
    // A write racing app teardown (background-scan `closeIsolateBoxes`, OBD2
    // disconnect at shutdown) must NEVER surface a `FileSystemException: File
    // closed` to PlatformDispatcher.onError — it is dropped silently because
    // the app is going away. These guard the never-throw contract.

    test('putSetting drops silently when the box is closed (no throw)',
        () async {
      await Hive.box<dynamic>(HiveBoxes.settings).close();
      await expectLater(store.putSetting('k', 'v'), completes);
    });

    test('skipSetup drops silently when the box is closed (no throw)',
        () async {
      await Hive.box<dynamic>(HiveBoxes.settings).close();
      await expectLater(store.skipSetup(), completes);
    });

    test('resetSetupSkip drops silently when the box is closed (no throw)',
        () async {
      await Hive.box<dynamic>(HiveBoxes.settings).close();
      await expectLater(store.resetSetupSkip(), completes);
    });
  });

  group('Supabase anon key', () {
    test('null by default', () async {
      await SettingsHiveStore.loadSupabaseAnonKey();
      expect(store.getSupabaseAnonKey(), isNull);
    });

    test('setSupabaseAnonKey + getSupabaseAnonKey round-trip',
        () async {
      await store.setSupabaseAnonKey('supa-abc');
      expect(store.getSupabaseAnonKey(), 'supa-abc');
    });

    test('deleteSupabaseAnonKey clears the cached value', () async {
      await store.setSupabaseAnonKey('supa-abc');
      await store.deleteSupabaseAnonKey();
      expect(store.getSupabaseAnonKey(), isNull);
    });
  });
}
