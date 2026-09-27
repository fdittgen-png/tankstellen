// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/domain/exchange_rate_provider.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/storage/storage_keys.dart';
import 'package:tankstellen/core/storage/storage_providers.dart';
import 'package:tankstellen/features/fill_ups/domain/entities/fill_up.dart';
import 'package:tankstellen/features/fill_ups/providers/exchange_rates_override.dart';

/// #4437 D — the rates the fill-up history holds reach the core
/// `exchangeRatesProvider`, sourced and dated; nothing is inferred.
void main() {
  final gandria = FillUp(
    id: 'gandria',
    date: DateTime(2026, 9, 20),
    liters: 25.61,
    totalCost: 51.73,
    odometerKm: 10500,
    fuelType: FuelType.e5,
    currency: 'CHF',
  );

  Future<ProviderContainer> containerWith(
    List<FillUp> fills, {
    bool wired = true,
  }) async {
    final storage = _FakeSettingsStorage();
    await storage.putSetting(StorageKeys.consumptionLog,
        <Map<String, dynamic>>[for (final f in fills) f.toJson()]);
    final c = ProviderContainer(overrides: [
      settingsStorageProvider.overrideWithValue(storage),
      if (wired) ...exchangeRatesOverrides(),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  test('a settled fill supplies one directed, sourced, dated rate', () async {
    final c = await containerWith(
        [gandria.settledByCard(amount: 55.12, currency: 'EUR')]);
    final rates = c.read(exchangeRatesProvider).rates;
    expect(rates, hasLength(1));
    expect(rates.single.baseCurrency, 'CHF');
    expect(rates.single.quoteCurrency, 'EUR');
    expect(rates.single.source, kRateSourceCardSettlement);
    expect(rates.single.capturedAt, DateTime(2026, 9, 20));
  });

  test('an unsettled history supplies none — no rate is ever inferred',
      () async {
    final c = await containerWith([gandria]);
    expect(c.read(exchangeRatesProvider).rates, isEmpty);
  });

  test('without the wiring the core declaration still answers empty',
      () async {
    final c = await containerWith(
        [gandria.settledByCard(amount: 55.12, currency: 'EUR')],
        wired: false);
    expect(c.read(exchangeRatesProvider).rates, isEmpty);
  });
}

class _FakeSettingsStorage implements SettingsStorage {
  final Map<String, dynamic> _data = {};

  @override
  dynamic getSetting(String key) => _data[key];

  @override
  Future<void> putSetting(String key, dynamic value) async {
    if (value == null) {
      _data.remove(key);
    } else {
      _data[key] = value;
    }
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
