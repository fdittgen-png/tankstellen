// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/storage/storage_keys.dart';
import 'package:tankstellen/core/storage/storage_providers.dart';
import 'package:tankstellen/core/utils/price_formatter.dart';
import 'package:tankstellen/features/fill_ups/domain/entities/fill_up.dart';
import 'package:tankstellen/features/fill_ups/presentation/widgets/settle_fill_up_sheet.dart';
import 'package:tankstellen/features/fill_ups/providers/consumption_providers.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// #4437 C — the settle sheet: attach what the card charged to a SAVED
/// foreign fill-up, or type a rate that stays labelled as hand-entered.
void main() {
  setUp(() => PriceFormatter.setCountry('DE'));
  tearDown(() => PriceFormatter.setCountry('FR'));

  final gandriaDate = DateTime(2026, 9, 20, 14, 5);
  FillUp gandria({String? currency = 'CHF'}) => FillUp(
        id: 'gandria',
        date: gandriaDate,
        liters: 25.61,
        totalCost: 51.73,
        odometerKm: 10500,
        fuelType: FuelType.e5,
        currency: currency,
      );

  Future<ProviderContainer> pumpSheet(
      WidgetTester tester, FillUp seeded) async {
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final storage = _FakeSettingsStorage();
    await storage.putSetting(
        StorageKeys.consumptionLog, <Map<String, dynamic>>[seeded.toJson()]);
    final container = ProviderContainer(overrides: [
      settingsStorageProvider.overrideWithValue(storage),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(body: SettleFillUpSheet(fillUp: seeded)),
      ),
    ));
    await tester.pumpAndSettle();
    return container;
  }

  FillUp stored(ProviderContainer c) =>
      c.read(fillUpListProvider).singleWhere((f) => f.id == 'gandria');

  testWidgets('the settled EUR amount is stored verbatim, sourced and dated',
      (tester) async {
    final c = await pumpSheet(tester, gandria());
    expect(find.textContaining('Paid in CHF'), findsOneWidget);
    await tester.enterText(
        find.byKey(const Key('settle_amount_field')), '55,12');
    await tester.tap(find.byKey(const Key('settle_save')));
    await tester.pumpAndSettle();

    final f = stored(c);
    expect(f.settledAmount, 55.12);
    expect(f.settledCurrency, 'EUR');
    expect(f.rateSource, kRateSourceCardSettlement);
    // The transaction date — not the moment the statement was typed in.
    expect(f.rateCapturedAt, gandriaDate);
    // The native record is untouched.
    expect(f.totalCost, 51.73);
    expect(f.currency, 'CHF');
    expect(f.liters, 25.61);
  });

  testWidgets('a typed rate is stored as entered by hand', (tester) async {
    final c = await pumpSheet(tester, gandria());
    await tester.tap(find.text('Exchange rate'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('settle_rate_field')), '1.07');
    await tester.tap(find.byKey(const Key('settle_save')));
    await tester.pumpAndSettle();

    final f = stored(c);
    expect(f.rateSource, kRateSourceEnteredByHand);
    expect(f.settledAmount, closeTo(51.73 * 1.07, 1e-9));
  });

  testWidgets('an unknown-currency record must be TOLD its currency',
      (tester) async {
    final c = await pumpSheet(tester, gandria(currency: null));
    // No preselection: saving without a pick is refused.
    await tester.tap(find.byKey(const Key('settle_save')));
    await tester.pumpAndSettle();
    expect(stored(c).currency, isNull);
    expect(find.text('Required'), findsOneWidget);

    await tester.tap(find.byKey(const Key('settle_currency_picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CHF').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settle_save')));
    await tester.pumpAndSettle();
    expect(stored(c).currency, 'CHF');
    expect(stored(c).isSettled, isFalse);
  });

  testWidgets('Remove settlement returns the record to its native amount',
      (tester) async {
    final c = await pumpSheet(
        tester, gandria().settledByCard(amount: 55.12, currency: 'EUR'));
    await tester.tap(find.byKey(const Key('settle_remove')));
    await tester.pumpAndSettle();
    expect(stored(c).isSettled, isFalse);
    expect(stored(c).bookedSpend, (51.73, 'CHF'));
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
