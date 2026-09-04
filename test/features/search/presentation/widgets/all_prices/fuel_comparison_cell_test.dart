// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/features/search/presentation/widgets/all_prices/fuel_comparison_cell.dart';
import 'package:tankstellen/features/search/providers/all_prices_comparison_model.dart';

import '../../../../../helpers/mock_providers.dart';
import '../../../../../helpers/pump_app.dart';

/// #3945 — a MODELLED cost per 100 km must never look like a measured one.
///
/// The measured figure is bold and fuel-coloured; the estimate is the muted
/// italic label role with a ≈ prefix and a semantics label that says so out
/// loud, because the visual prefix is not spoken.
void main() {
  const measured = FuelCellData(
    fuel: FuelType.e85,
    label: 'E85',
    price: 0.839,
    costPer100km: 5.4535,
    litersPer100km: 6.5,
  );

  const estimated = FuelCellData(
    fuel: FuelType.e10,
    label: 'E10',
    price: 2.089,
    costPer100km: 10.86,
    litersPer100km: 5.2,
    isCostEstimated: true,
  );

  Future<void> pumpCell(WidgetTester tester, FuelCellData data) => pumpApp(
    tester,
    SizedBox(width: 70, child: FuelComparisonCell(data: data)),
    overrides: standardTestOverrides().overrides,
  );

  Text costLine(WidgetTester tester, String text) =>
      tester.widget<Text>(find.text(text));

  testWidgets('a measured cost renders plain and bold, with the measured '
      'semantics', (tester) async {
    await pumpCell(tester, measured);

    expect(find.text('5,45 €'), findsOneWidget);
    expect(find.textContaining('≈'), findsNothing);

    final style = costLine(tester, '5,45 €').style!;
    expect(style.fontWeight, FontWeight.w700);
    expect(style.fontStyle, isNot(FontStyle.italic));

    final semantics = tester.getSemantics(find.byType(FuelComparisonCell));
    expect(semantics.label, contains('E85 0,839'));
    expect(semantics.label, contains('5,45 €'));
    expect(semantics.label, isNot(contains('estimated')));
  });

  testWidgets('an estimated cost carries the ≈ prefix in the italic label '
      'style, with its own semantics', (tester) async {
    await pumpCell(tester, estimated);

    expect(find.text('≈ 10,86 €'), findsOneWidget);
    expect(find.text('10,86 €'), findsNothing);

    final style = costLine(tester, '≈ 10,86 €').style!;
    expect(style.fontStyle, FontStyle.italic);
    expect(style.fontWeight, isNot(FontWeight.w700));

    final semantics = tester.getSemantics(find.byType(FuelComparisonCell));
    expect(semantics.label, contains('E10 2,089'));
    expect(semantics.label, contains('10,86 €'));
    expect(semantics.label, contains('estimated'));
    expect(semantics.label, contains('5,2 L/100 km'));
  });

  testWidgets('the champion cell keeps the estimate readable on its filled '
      'background', (tester) async {
    await pumpCell(
      tester,
      const FuelCellData(
        fuel: FuelType.e10,
        label: 'E10',
        price: 2.029,
        isBestInResults: true,
        deltaToBest: 0,
        costPer100km: 10.55,
        litersPer100km: 5.2,
        isCostEstimated: true,
      ),
    );

    final style = costLine(tester, '≈ 10,55 €').style!;
    expect(style.fontStyle, FontStyle.italic);
    expect(style.color, Colors.white);
  });

  testWidgets('a cell without a cost figure shows neither form', (
    tester,
  ) async {
    await pumpCell(
      tester,
      const FuelCellData(fuel: FuelType.e98, label: 'E98', price: 2.189),
    );

    expect(find.textContaining('€'), findsNothing);
    expect(find.textContaining('≈'), findsNothing);
  });
}
