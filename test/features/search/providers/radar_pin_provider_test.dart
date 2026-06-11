// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #2785 — the radar auto-pin preference defaults ON and persists across
// controller builds; a stored explicit false (a deliberate opt-out) is
// honoured.
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/storage/storage_keys.dart';
import 'package:tankstellen/core/storage/storage_providers.dart';
import 'package:tankstellen/features/search/providers/radar_pin_provider.dart';

import '../../../fakes/fake_storage_repository.dart';
import '../../../helpers/silence_error_logger.dart';

ProviderContainer _container(FakeStorageRepository storage) {
  final c = ProviderContainer(overrides: [
    storageRepositoryProvider.overrideWithValue(storage),
  ]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  silenceErrorLoggerSpool();

  test('defaults to true when no value is stored (#2785)', () {
    final c = _container(FakeStorageRepository());
    expect(c.read(radarAutoPinProvider), isTrue);
  });

  test('a stored explicit false is honoured (deliberate opt-out)', () {
    final storage = FakeStorageRepository();
    unawaited(storage.putSetting(StorageKeys.radarAutoPin, false));
    final c = _container(storage);
    expect(c.read(radarAutoPinProvider), isFalse);
  });

  test('set persists the value and republishes state', () async {
    final storage = FakeStorageRepository();
    final c = _container(storage);
    expect(c.read(radarAutoPinProvider), isTrue);

    await c.read(radarAutoPinProvider.notifier).set(false);
    expect(c.read(radarAutoPinProvider), isFalse);
    expect(storage.getSetting(StorageKeys.radarAutoPin), isFalse);

    // A fresh controller reads the persisted value back.
    final c2 = _container(storage);
    expect(c2.read(radarAutoPinProvider), isFalse);
  });
}
