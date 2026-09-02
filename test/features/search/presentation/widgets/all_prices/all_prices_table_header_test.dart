// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/features/search/presentation/widgets/all_prices/all_prices_table_header.dart';
import 'package:tankstellen/features/search/providers/all_prices_comparison_model.dart';
import 'package:tankstellen/features/search/providers/all_prices_table_provider.dart';

import '../../../../../helpers/mock_providers.dart';
import '../../../../../helpers/pump_app.dart';

/// #3933 — the sticky column header that names the fuels ONCE above the
/// all-prices list, plus the one-line legend that explains the emphasis
/// and the second number in each cell.
void main() {
  const columns = AllPricesColumns(
    visible: [FuelType.e10, FuelType.e98, FuelType.diesel, FuelType.e85],
    overflow: [FuelType.lpg],
  );

  List<Object> overrides({
    AllPricesColumns cols = columns,
    FuelCostModel cost = FuelCostModel.empty,
  }) => <Object>[
    ...standardTestOverrides().overrides,
    allPricesColumnsProvider.overrideWithValue(cols),
    allPricesFuelCostModelProvider.overrideWithValue(cost),
  ];

  testWidgets('names every visible column once, in the column order', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const AllPricesTableHeader(),
      overrides: overrides(),
    );

    for (final label in ['E10', 'E98', 'Diesel', 'E85']) {
      expect(find.text(label), findsOneWidget);
    }
    // The overflow fuel is named by the per-card expander, not up here.
    expect(find.text('GPL'), findsNothing);
  });

  testWidgets('the legend explains the emphasis and the second number', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const AllPricesTableHeader(),
      overrides: overrides(
        cost: const FuelCostModel(
          litersPer100kmByFuel: {FuelType.e85: 6.0},
          usableFuels: {FuelType.e85, FuelType.e10},
        ),
      ),
    );

    expect(find.textContaining('cheapest of these results'), findsOneWidget);
    expect(find.textContaining('100 km'), findsOneWidget);
  });

  testWidgets('without consumption the legend invites logging fill-ups', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const AllPricesTableHeader(),
      overrides: overrides(),
    );

    expect(find.textContaining('log fill-ups'), findsOneWidget);
  });

  testWidgets('renders nothing when no column set resolved', (tester) async {
    await pumpApp(
      tester,
      const AllPricesTableHeader(),
      overrides: overrides(cols: AllPricesColumns.empty),
    );

    expect(find.byType(SizedBox), findsOneWidget);
    expect(find.text('E10'), findsNothing);
  });
}
