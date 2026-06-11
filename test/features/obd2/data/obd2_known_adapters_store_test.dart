// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/features/obd2/data/obd2_known_adapters_store.dart';
import '../../../helpers/silence_error_logger.dart';

class _FakeSettingsStorage implements SettingsStorage {
  final Map<String, dynamic> data = {};
  bool throwOnPut = false;
  bool throwOnGet = false;
  @override
  dynamic getSetting(String key) {
    if (throwOnGet) throw StateError('hive read failed');
    return data[key];
  }

  @override
  Future<void> putSetting(String key, dynamic value) async {
    if (throwOnPut) throw StateError('disk full');
    data[key] = value;
  }

  @override
  bool get isSetupComplete => false;
  @override
  bool get isSetupSkipped => false;
  @override
  Future<void> skipSetup() async {}
  @override
  Future<void> resetSetupSkip() async {}
}

void main() {
  silenceErrorLoggerSpool();

  late _FakeSettingsStorage storage;
  late KnownObd2AdaptersStore store;

  setUp(() {
    storage = _FakeSettingsStorage();
    store = KnownObd2AdaptersStore(storage);
  });

  group('KnownObd2AdaptersStore (#3181 first-connect discriminator)', () {
    test('an unseen deviceId is NOT known-good (the first-connect signal)',
        () {
      expect(store.isKnownGood('AA:BB:CC:DD:EE:01'), isFalse);
    });

    test('markKnownGood + isKnownGood round-trips, case-insensitively',
        () async {
      await store.markKnownGood('aa:bb:cc:dd:ee:01');
      expect(store.isKnownGood('AA:BB:CC:DD:EE:01'), isTrue);
      expect(store.isKnownGood('aa:bb:cc:dd:ee:01'), isTrue);
      expect(store.isKnownGood('AA:BB:CC:DD:EE:02'), isFalse);
    });

    test('keeps MULTIPLE adapters known-good (the LastGoodAdapterStore '
        'single-pin gap that motivated this store)', () async {
      await store.markKnownGood('ADAPTER-1');
      await store.markKnownGood('ADAPTER-2');
      expect(store.isKnownGood('ADAPTER-1'), isTrue);
      expect(store.isKnownGood('ADAPTER-2'), isTrue);
    });

    test('caps at maxIds, evicting the OLDEST id', () async {
      for (var i = 0; i < KnownObd2AdaptersStore.maxIds + 1; i++) {
        await store.markKnownGood('ID-$i');
      }
      expect(store.isKnownGood('ID-0'), isFalse,
          reason: 'oldest id falls off the front past the cap');
      expect(store.isKnownGood('ID-1'), isTrue);
      expect(store.isKnownGood('ID-${KnownObd2AdaptersStore.maxIds}'), isTrue);
    });

    test('re-marking an id refreshes it to the freshest slot (no eviction)',
        () async {
      for (var i = 0; i < KnownObd2AdaptersStore.maxIds; i++) {
        await store.markKnownGood('ID-$i');
      }
      await store.markKnownGood('ID-0'); // refresh, not duplicate
      await store.markKnownGood('NEW');
      expect(store.isKnownGood('ID-0'), isTrue,
          reason: 're-marked id moved to the fresh end, so ID-1 evicts first');
      expect(store.isKnownGood('ID-1'), isFalse);
    });

    test('an empty id is ignored', () async {
      await store.markKnownGood('  ');
      expect(storage.data, isEmpty);
    });

    test('storage faults degrade to "never connected" (best-effort)',
        () async {
      storage.throwOnGet = true;
      expect(store.isKnownGood('AA'), isFalse);
      storage.throwOnGet = false;
      storage.throwOnPut = true;
      await expectLater(store.markKnownGood('AA'), completes);
    });

    test('type drift in the stored value degrades to false', () {
      storage.data['obdKnownGoodAdapterIds'] = 'not-a-list';
      expect(store.isKnownGood('AA'), isFalse);
      storage.data['obdKnownGoodAdapterIds'] = [42, true];
      expect(store.isKnownGood('AA'), isFalse);
    });
  });
}
