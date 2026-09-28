// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/utils/price_formatter.dart';
import 'package:tankstellen/features/fill_ups/domain/entities/fill_up.dart';
import 'package:tankstellen/features/fill_ups/presentation/widgets/fill_up_card.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// #4437 A — a fill-up card shows the money the fill was paid in, and a
/// settled one names the rate's source and date beside the converted
/// figure.
void main() {
  setUp(() => PriceFormatter.setCountry('DE'));
  tearDown(() => PriceFormatter.setCountry('FR'));

  // The Gandria receipt (#4428).
  final gandria = FillUp(
    id: 'gandria',
    date: DateTime(2026, 9, 20),
    liters: 25.61,
    totalCost: 51.73,
    odometerKm: 10500,
    fuelType: FuelType.e5,
    stationName: 'Piccadilly-SOCAR',
    currency: 'CHF',
    scannedPricePerLiter: 2.020,
  );

  Future<void> pump(WidgetTester tester, FillUp fillUp) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(body: FillUpCard(fillUp: fillUp)),
      ),
    );
    await tester.pumpAndSettle();
  }

  String subtitle(WidgetTester tester) => tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => t.data ?? '')
      .join('\n');

  testWidgets('a CHF record shows CHF for the total and the per-litre',
      (tester) async {
    await pump(tester, gandria);
    final text = subtitle(tester);
    expect(text, contains('51,73 CHF'));
    expect(text, contains('2,020 CHF/L'));
    expect(text, isNot(contains('€')),
        reason: 'the profile symbol must never be painted on a CHF fill');
    // Unsettled + foreign: the card says how to count it.
    expect(find.byKey(const Key('fill_up_settle_hint')), findsOneWidget);
  });

  testWidgets('settled: the entered amount, the rate, its source and date',
      (tester) async {
    await pump(tester, gandria.settledByCard(amount: 55.12, currency: 'EUR'));
    final text = subtitle(tester);
    // The EUR figure is the amount ENTERED — 55,12 €, not 51,73 × rate.
    expect(text, contains('55,12 €'));
    expect(text, contains('1 CHF = 1,0655 €'));
    expect(text, contains('card settlement'));
    expect(text, contains('Sep 20, 2026'));
    expect(find.byKey(const Key('fill_up_rate_card')), findsOneWidget);
    expect(find.byKey(const Key('fill_up_settle_hint')), findsNothing);
  });

  testWidgets('a hand-typed rate is labelled — and marked — differently',
      (tester) async {
    await pump(tester, gandria.settledByHandRate(rate: 1.07, currency: 'EUR'));
    expect(subtitle(tester), contains('entered by hand'));
    expect(subtitle(tester), isNot(contains('card settlement')));
    expect(find.byKey(const Key('fill_up_rate_by_hand')), findsOneWidget);
    expect(find.byIcon(Icons.edit_note), findsOneWidget);
    expect(find.byIcon(Icons.credit_card), findsNothing);
  });

  testWidgets('a home-currency record renders exactly as before',
      (tester) async {
    final eur = gandria.copyWith(currency: 'EUR', stationName: 'Aral');
    await pump(tester, eur);
    final text = subtitle(tester);
    expect(text, contains(PriceFormatter.formatTotal(51.73)));
    expect(find.byKey(const Key('fill_up_settle_hint')), findsNothing);
    expect(find.byKey(const Key('fill_up_rate_card')), findsNothing);
  });
}
