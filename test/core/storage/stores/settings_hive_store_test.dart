import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
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

    test('#555 regression — isSetupComplete must NOT piggy-back on the '
        'bundled Tankerkoenig key being available', () async {
      // hasApiKey() is always true because of the #521 default key;
      // isSetupComplete must depend on the explicit setup-skip flag
      // instead. This was the regression that permanently bypassed
      // the wizard on fresh installs.
      expect(store.hasApiKey(), isTrue);
      expect(store.isSetupComplete, isFalse);
    });
  });

  group('Tankerkoenig API key', () {
    test('without a custom key, getApiKey returns the bundled community '
        'default so German search works out of the box (#521)', () async {
      // Reload into the in-memory cache. _mockSecureStorage is empty.
      await SettingsHiveStore.loadApiKey();
      expect(store.getApiKey(), SettingsHiveStore.defaultTankerkoenigKey);
      expect(store.hasApiKey(), isTrue);
      expect(store.hasCustomApiKey(), isFalse);
    });

    test('setApiKey overrides the default and flips hasCustomApiKey',
        () async {
      await store.setApiKey('custom-key-123');
      expect(store.getApiKey(), 'custom-key-123');
      expect(store.hasCustomApiKey(), isTrue);
    });

    test('deleteApiKey clears the custom key and falls back to default',
        () async {
      await store.setApiKey('custom-key-123');
      await store.deleteApiKey();
      expect(store.getApiKey(), SettingsHiveStore.defaultTankerkoenigKey);
      expect(store.hasCustomApiKey(), isFalse);
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
