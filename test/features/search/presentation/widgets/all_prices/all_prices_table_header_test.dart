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
/// all-prices list. #3939 (Epic #3937) deleted the two-line legend that
/// used to sit under it: what the fill emphasis means and what the second
/// figure in a cell is are now tips in the search surface's dismissible
/// help bubble, not permanent chrome on the one screen whose job is
/// showing stations. The fuel codes are data, so they stay.
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

  testWidgets('#3939 — the permanent legend is GONE from the layout, with '
      'or without a measured consumption', (tester) async {
    for (final cost in const [
      FuelCostModel.empty,
      FuelCostModel(
        litersPer100kmByFuel: {FuelType.e85: 6.0},
        usableFuels: {FuelType.e85, FuelType.e10},
      ),
    ]) {
      await pumpApp(
        tester,
        const AllPricesTableHeader(),
        overrides: overrides(cost: cost),
      );

      expect(find.textContaining('cheapest of these results'), findsNothing);
      expect(find.textContaining('100 km'), findsNothing);
      expect(find.textContaining('log fill-ups'), findsNothing);
    }
  });

  testWidgets('#3939 — the header is one row of fuel codes and nothing '
      'else', (tester) async {
    await pumpApp(
      tester,
      const AllPricesTableHeader(),
      overrides: overrides(),
    );

    // Four column codes, no prose line beneath them.
    expect(find.byType(Text), findsNWidgets(4));
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
