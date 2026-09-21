// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/fill_ups/domain/services/price_baseline.dart';
import 'package:tankstellen/features/fill_ups/domain/services/savings_ledger.dart';
import 'package:tankstellen/features/fill_ups/presentation/widgets/savings_card.dart';
import 'package:tankstellen/features/fill_ups/providers/savings_provider.dart';

import '../../../../helpers/pump_app.dart';

/// #4136 — the savings card, and mostly what it refuses to claim.
void main() {
  SavingsEntry entry(double amount) => SavingsEntry(
        fillUpId: 'f',
        date: DateTime.utc(2026, 9, 1),
        litres: 50,
        pricePaid: 1.70 - amount / 50,
        referencePrice: 1.70,
      );

  Future<void> pump(WidgetTester tester, SavingsLedger ledger) => pumpApp(
        tester,
        const SavingsCard(),
        overrides: [savingsLedgerProvider.overrideWithValue(ledger)],
      );

  testWidgets('with too little history it shows no number at all',
      (tester) async {
    await pump(tester, const SavingsLedger.unavailable());

    expect(find.textContaining('few more fill-ups'), findsOneWidget);
    // A computed-looking zero would read as "you have saved nothing",
    // which is a claim the app cannot support.
    expect(find.textContaining('0,00'), findsNothing);
  });

  testWidgets('it names the reference the saving is measured against',
      (tester) async {
    await pump(
      tester,
      SavingsLedger(
        entries: [entry(5)],
        baseline: const PriceBaseline(
          typicalPricePerLitre: 1.70,
          typicalLitres: 45,
          sampleCount: 6,
        ),
      ),
    );

    // Trust rule 4: a stated saving names what it was measured against,
    // or it is not reproducible.
    expect(find.textContaining('Your usual'), findsOneWidget);
  });

  testWidgets('a net LOSS is shown, and shown as a loss', (tester) async {
    await pump(
      tester,
      SavingsLedger(
        entries: [entry(-8)],
        baseline: const PriceBaseline(
          typicalPricePerLitre: 1.70,
          typicalLitres: 45,
          sampleCount: 6,
        ),
      ),
    );

    // A card that hid the bad months would be a marketing number.
    final ctx = tester.element(find.byType(SavingsCard));
    final scheme = Theme.of(ctx).colorScheme;
    final texts = tester.widgetList<Text>(find.byType(Text));
    final coloured = texts.where((t) => t.style?.color == scheme.error);
    expect(coloured, isNotEmpty,
        reason: 'a negative total must read as one');
  });
}
