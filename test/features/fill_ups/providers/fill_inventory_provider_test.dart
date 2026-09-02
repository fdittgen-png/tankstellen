// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3917 — the persisted last inventory: JSON round-trip through the
// settings box, and the never-throws contract under a faulty store.
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/storage/storage_providers.dart';
import 'package:tankstellen/features/fill_ups/domain/entities/fill_inventory.dart';
import 'package:tankstellen/features/fill_ups/domain/services/pump_gain_learner.dart';
import 'package:tankstellen/features/fill_ups/providers/fill_inventory_provider.dart';

import '../../../helpers/fake_settings_storage.dart';
import '../../../helpers/silence_error_logger.dart';

final _date = DateTime(2026, 9, 1, 9);

final _inventory = FillInventory(
  vehicleId: 'car',
  fillId: 'f2',
  fillDate: _date,
  fuelKey: 'e85',
  isFullTank: true,
  pumpLiters: 35.7,
  skipReason: PumpGainSkipReason.noWindow,
);

/// A settings box whose every read and write throws.
class _BrokenStorage extends FakeSettingsStorage {
  @override
  dynamic getSetting(String key) => throw StateError('box closed');
  @override
  Future<void> putSetting(String key, dynamic value) async =>
      throw StateError('box closed');
}

ProviderContainer _container(FakeSettingsStorage storage) {
  final c = ProviderContainer(
    overrides: [settingsStorageProvider.overrideWithValue(storage)],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  silenceErrorLoggerSpool();

  test('set persists JSON; a fresh container reads it back', () async {
    final storage = FakeSettingsStorage();
    final c = _container(storage);
    expect(c.read(lastFillInventoryProvider), isNull);
    await c.read(lastFillInventoryProvider.notifier).set(_inventory);
    expect(c.read(lastFillInventoryProvider)?.fillId, 'f2');
    final raw = storage.data[kLastFillInventoryKey] as String;
    expect((jsonDecode(raw) as Map)['fillId'], 'f2');

    final fresh = _container(storage);
    expect(fresh.read(lastFillInventoryProvider)?.skipReason,
        PumpGainSkipReason.noWindow);

    await fresh.read(lastFillInventoryProvider.notifier).set(null);
    expect(storage.data[kLastFillInventoryKey], isNull);
  });

  test('a malformed stored payload reads as no inventory', () {
    final storage = FakeSettingsStorage()
      ..data[kLastFillInventoryKey] = '{not json';
    expect(_container(storage).read(lastFillInventoryProvider), isNull);
    final other = FakeSettingsStorage()..data[kLastFillInventoryKey] = 42;
    expect(_container(other).read(lastFillInventoryProvider), isNull);
  });

  test('never throws: a broken settings box neither breaks build nor set, '
      'and the in-memory state still updates', () async {
    final c = _container(_BrokenStorage());
    expect(() => c.read(lastFillInventoryProvider), returnsNormally);
    expect(c.read(lastFillInventoryProvider), isNull);
    await expectLater(
        c.read(lastFillInventoryProvider.notifier).set(_inventory), completes);
    expect(c.read(lastFillInventoryProvider)?.fillId, 'f2',
        reason: 'the sheet must show even when persistence failed');
  });
}
