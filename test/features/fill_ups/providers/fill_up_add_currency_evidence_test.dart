// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/country/country_detection_provider.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/core/utils/price_formatter.dart';
import 'package:tankstellen/features/fill_ups/data/repositories/fill_up_repository.dart';
import 'package:tankstellen/features/fill_ups/domain/entities/fill_up.dart';
import 'package:tankstellen/features/fill_ups/providers/consumption_providers.dart';

import '../../../fakes/fake_hive_storage.dart';
import '../../../helpers/silence_error_logger.dart';

/// #4428 — `FillUpList.add` is the ONE save where the device's own
/// location is evidence about the record being written: the driver is
/// logging the fill they just made. These prove the wiring reaches
/// `FillUpRepository.save`, which is where the rule lives.
class _FakeDetected extends DetectedCountry {
  _FakeDetected(this._code);
  final String? _code;
  @override
  String? build() => _code;
}

void main() {
  silenceErrorLoggerSpool();
  late FakeHiveStorage fakeStorage;

  setUp(() {
    fakeStorage = FakeHiveStorage();
    PriceFormatter.setCountry('DE');
  });
  tearDown(() => PriceFormatter.setCountry('FR'));

  ProviderContainer containerDetecting(String? code) {
    final c = ProviderContainer(overrides: [
      hiveStorageProvider.overrideWithValue(fakeStorage),
      detectedCountryProvider.overrideWith(() => _FakeDetected(code)),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  FillUp gandria() => FillUp(
        id: 'gandria',
        date: DateTime(2026, 9, 20),
        liters: 25.61,
        totalCost: 51.73,
        odometerKm: 120450,
        fuelType: FuelType.e10,
      );

  String? storedCurrency() =>
      FillUpRepository(fakeStorage).getAll().single.currency;

  test('logged in Switzerland on an EUR profile: unknown, never EUR',
      () async {
    final c = containerDetecting('CH');
    await c.read(fillUpListProvider.notifier).add(gandria());
    expect(storedCurrency(), isNull);
  });

  test('logged at home: the profile currency, exactly as before', () async {
    final c = containerDetecting('DE');
    await c.read(fillUpListProvider.notifier).add(gandria());
    expect(storedCurrency(), 'EUR');
  });

  test('nothing detected yet: the profile currency, exactly as before',
      () async {
    final c = containerDetecting(null);
    await c.read(fillUpListProvider.notifier).add(gandria());
    expect(storedCurrency(), 'EUR');
  });

  test('a scanned CHF receipt beats the location either way', () async {
    final c = containerDetecting('CH');
    await c
        .read(fillUpListProvider.notifier)
        .add(gandria().copyWith(currency: 'CHF'));
    expect(storedCurrency(), 'CHF');
  });
}
