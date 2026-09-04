// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3950 — the consumption-statistics page's month comparison reuses the
// ONE `MonthlyMetricsTable` of the Trajets month card, so both carry the
// same hierarchy: headline value (title role) > label (body) > previous
// value + percentage (label role), delta arrow tinted by sentiment.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/utils/price_formatter.dart';
import 'package:tankstellen/features/fill_ups/domain/entities/consumption_stats.dart';
import 'package:tankstellen/features/fill_ups/domain/services/fill_up_monthly_stats_aggregator.dart';
import 'package:tankstellen/features/fill_ups/presentation/widgets/monthly_fuel_comparison_card.dart';
import 'package:tankstellen/features/fill_ups/presentation/widgets/monthly_insights_table.dart';

import '../../../../helpers/pump_app.dart';
import '../../../../helpers/text_hierarchy.dart';

ConsumptionStats _stats({
  required int fillUpCount,
  required double totalLiters,
  required double totalSpent,
  required double? avgConsumption,
  required double? avgCostPerKm,
  required double? avgPricePerLiter,
}) =>
    ConsumptionStats(
      fillUpCount: fillUpCount,
      totalLiters: totalLiters,
      totalSpent: totalSpent,
      totalDistanceKm: 0,
      avgConsumptionL100km: avgConsumption,
      avgCostPerKm: avgCostPerKm,
      avgPricePerLiter: avgPricePerLiter,
    );

final _previous = MonthlyFuelStats(
  month: DateTime(2026, 1),
  stats: _stats(
    fillUpCount: 2,
    totalLiters: 80,
    totalSpent: 140,
    avgConsumption: 7.0,
    avgCostPerKm: 0.12,
    avgPricePerLiter: 1.75,
  ),
);

final _current = MonthlyFuelStats(
  month: DateTime(2026, 2),
  stats: _stats(
    fillUpCount: 3,
    totalLiters: 100,
    totalSpent: 160,
    avgConsumption: 6.0,
    avgCostPerKm: 0.10,
    avgPricePerLiter: 1.60,
  ),
);

void main() {
  setUp(() => PriceFormatter.setCountry('GB'));

  testWidgets('renders the shared MonthlyMetricsTable with six rows and a '
      'previous column when two months exist', (tester) async {
    await pumpApp(
      tester,
      MonthlyFuelComparisonCard(months: [_previous, _current]),
    );

    expect(find.byType(MonthlyMetricsTable), findsOneWidget);
    final table = tester.widget<Table>(find.byType(Table));
    expect(table.children.length, 6);
    for (final row in table.children) {
      expect(row.children.length, 4);
    }
    expect(find.text('This month vs last month'), findsOneWidget);
    expect(find.text('100.0'), findsOneWidget);
    expect(find.text('80.0'), findsOneWidget);
    // Percentage under the previous value: (100 − 80) / 80 = +25 %.
    expect(find.text('+25%'), findsOneWidget);
    // Litres up → neutral arrow; consumption down → success arrow.
    expect(find.byIcon(Icons.arrow_upward), findsWidgets);
    expect(find.byIcon(Icons.arrow_downward), findsWidgets);
  });

  testWidgets('a single month hides the previous column and explains why',
      (tester) async {
    await pumpApp(tester, MonthlyFuelComparisonCard(months: [_current]));

    final table = tester.widget<Table>(find.byType(Table));
    for (final row in table.children) {
      expect(row.children.length, 2);
    }
    expect(
      find.text('Log fill-ups across at least two months to compare.'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.arrow_upward), findsNothing);
    expect(find.byIcon(Icons.arrow_downward), findsNothing);
  });

  testWidgets('headline values are the largest text in the table; labels '
      'never wrap; previous values are label-sized', (tester) async {
    await pumpApp(
      tester,
      MonthlyFuelComparisonCard(months: [_previous, _current]),
    );

    // The headline column is the second cell of every row; its Texts are
    // the peers that may tie with the focal figure.
    final table = tester.widget<Table>(find.byType(Table));
    final currentCells = table.children.map((r) => r.children[1]).toSet();
    expectFocalNumberLargest(
      tester,
      within: find.byType(Table),
      focal: find.text('100.0'),
      peers: find.descendant(
        of: find.byWidgetPredicate(currentCells.contains),
        matching: find.byType(Text),
      ),
    );
    final sizes = textFontSizesUnder(tester, find.byType(Table));
    double sizeOf(String text) => sizes.entries
        .singleWhere((e) => (e.key.widget as Text).data == text)
        .value;
    expect(sizeOf('80.0'), lessThan(sizeOf('Total liters')));
    expect(sizeOf('+25%'), lessThan(sizeOf('Total liters')));

    final label = tester.widget<Text>(find.text('Total liters'));
    expect(label.maxLines, 1);
    expect(label.overflow, TextOverflow.ellipsis);
  });

  testWidgets('en_XA at 320 dp + 1.3x text scale: no overflow, no figure '
      'wraps', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1.0;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pumpApp(
      tester,
      MonthlyFuelComparisonCard(months: [_previous, _current]),
      locale: const Locale('en', 'XA'),
    );

    expect(tester.takeException(), isNull,
        reason: 'the month comparison overflows at 320 dp under en_XA / 1.3x');
    for (final v in ['100.0', '80.0', '160.00 £', '140.00 £']) {
      final text = tester.widget<Text>(find.text(v));
      expect(text.softWrap, isFalse);
      expect(text.maxLines, 1);
    }
  });
}
