// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/features/obd2/data/last_good_adapter_store.dart';
import '../../../helpers/silence_error_logger.dart';

class _FakeSettingsStorage implements SettingsStorage {
  final Map<String, dynamic> data = {};
  bool throwOnPut = false;
  @override
  dynamic getSetting(String key) => data[key];
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
  late LastGoodAdapterStore store;

  setUp(() {
    storage = _FakeSettingsStorage();
    store = LastGoodAdapterStore(storage);
  });

  group('LastGoodAdapterStore (#3019 / Epic #3013 phase 3)', () {
    test('recall is null before anything is pinned', () {
      expect(store.recall(), isNull);
    });

    test('record + recall round-trips MAC + transport + name', () async {
      await store.record(const LastGoodAdapter(
        mac: 'AA:BB',
        transportKind: 'classic',
        name: 'vLinker FS',
      ));
      final got = store.recall();
      expect(got, isNotNull);
      expect(got!.mac, 'AA:BB');
      expect(got.transportKind, 'classic');
      expect(got.name, 'vLinker FS');
      expect(got.isClassic, isTrue);
    });

    test('recordFrom maps service identity fields, defaulting transport to ble',
        () async {
      await store.recordFrom(mac: 'CC:DD', name: 'Generic ELM');
      final got = store.recall();
      expect(got!.mac, 'CC:DD');
      expect(got.transportKind, 'ble', reason: 'null kind defaults to ble');
      expect(got.isClassic, isFalse);
    });

    test('the FRESHEST connect overwrites the prior pin', () async {
      await store.record(const LastGoodAdapter(mac: 'OLD', transportKind: 'ble'));
      await store.record(const LastGoodAdapter(mac: 'NEW', transportKind: 'classic'));
      expect(store.recall()!.mac, 'NEW');
    });

    test('an empty MAC is never pinned', () async {
      await store.recordFrom(mac: '   ');
      expect(store.recall(), isNull);
    });

    test('clear() forgets the pin', () async {
      await store.record(const LastGoodAdapter(mac: 'AA', transportKind: 'ble'));
      await store.clear();
      expect(store.recall(), isNull);
    });

    test('recall is defensive against Hive type drift', () {
      storage.data['obdLastGoodAdapter'] = 'not-a-map';
      expect(store.recall(), isNull);
      storage.data['obdLastGoodAdapter'] = {'transportKind': 'ble'}; // no mac
      expect(store.recall(), isNull);
    });

    test('record swallows a storage write failure (best-effort)', () async {
      storage.throwOnPut = true;
      // returnsNormally — a write fault must never throw into the connect
      // hot path; it degrades to "no pin".
      await expectLater(
        store.record(const LastGoodAdapter(mac: 'AA', transportKind: 'ble')),
        completes,
      );
    });
  });
}
