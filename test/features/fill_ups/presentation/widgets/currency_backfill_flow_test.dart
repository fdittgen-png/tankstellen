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
import 'package:tankstellen/features/fill_ups/domain/entities/consumption_stats.dart';
import 'package:tankstellen/features/fill_ups/domain/entities/fill_up.dart';
import 'package:tankstellen/features/fill_ups/presentation/widgets/spend_withheld_notice.dart';
import 'package:tankstellen/features/fill_ups/providers/consumption_providers.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// #4406 — the withheld total says why, offers the bulk statement, and
/// the statement brings the total back and can be undone.
void main() {
  setUp(() => PriceFormatter.setCountry('FR'));

  FillUp fill(String id, DateTime date, double odo, {String? currency}) =>
      FillUp(
        id: id,
        date: date,
        liters: 40,
        totalCost: 70,
        odometerKm: odo,
        fuelType: FuelType.e5,
        currency: currency,
      );

  final history = [
    fill('l1', DateTime(2025, 11, 3), 10000),
    fill('l2', DateTime(2025, 12, 1), 10600),
    fill('s1', DateTime(2026, 2, 2), 11200, currency: 'EUR'),
  ];

  Future<ProviderContainer> pumpFlow(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final storage = _FakeSettingsStorage();
    await storage.putSetting(StorageKeys.consumptionLog,
        <Map<String, dynamic>>[for (final f in history) f.toJson()]);
    final c = ProviderContainer(overrides: [
      settingsStorageProvider.overrideWithValue(storage),
    ]);
    addTearDown(c.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, _) {
              final stats = ConsumptionStats.fromFillUps(
                  ref.watch(fillUpListProvider));
              return Column(children: [
                Text(formatTotalSpent(stats), key: const Key('total')),
                SpendWithheldNotice(stats: stats),
                const StatedCurrencyUndoRow(),
              ]);
            },
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    return c;
  }

  String total(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const Key('total'))).data!;

  testWidgets('say why, state the currency, get the total back, undo it',
      (tester) async {
    final c = await pumpFlow(tester);
    expect(total(tester), '—');
    expect(find.textContaining('2 fill-ups have no recorded currency'),
        findsOneWidget);

    await tester.tap(find.byKey(const Key('currency_backfill_open')));
    await tester.pumpAndSettle();

    // No currency is preselected, so nothing can be applied yet.
    final apply = find.byKey(const Key('currency_backfill_apply'));
    expect(tester.widget<FilledButton>(apply).onPressed, isNull);

    await tester.tap(find.byKey(const Key('currency_backfill_picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('EUR').last);
    await tester.pumpAndSettle();
    expect(find.text('2 fill-ups will be labelled EUR.'), findsOneWidget);
    expect(find.text('Afterwards every fill-up has a currency.'),
        findsOneWidget);

    await tester.tap(apply);
    await tester.pumpAndSettle();

    final fills = c.read(fillUpListProvider);
    expect(fills.every((f) => f.currency == 'EUR'), isTrue);
    expect(
        fills.where((f) => f.currencyStatedAt != null).map((f) => f.id),
        unorderedEquals(['l1', 'l2']));
    // Every changed record is stamped for the LWW sync merge.
    expect(fills.where((f) => f.id != 's1').every((f) => f.updatedAt != null),
        isTrue);
    // The total is back — exactly what stamped records would total.
    expect(total(tester), PriceFormatter.formatTotal(210));
    expect(find.byKey(const Key('spend_withheld_notice')), findsNothing);
    expect(find.text('2 fill-ups labelled EUR.'), findsOneWidget);

    // Reversible after the snackbar is gone.
    await tester.tap(find.byKey(const Key('currency_backfill_undo')));
    await tester.pumpAndSettle();
    expect(c.read(fillUpListProvider).where((f) => f.currency == null),
        hasLength(2));
    expect(total(tester), '—');
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
