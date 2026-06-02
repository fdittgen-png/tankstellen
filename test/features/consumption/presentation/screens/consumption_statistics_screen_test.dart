// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/utils/price_formatter.dart';
import 'package:tankstellen/features/carbon/presentation/widgets/monthly_bar_chart.dart';
import 'package:tankstellen/features/consumption/domain/entities/fill_up.dart';
import 'package:tankstellen/features/consumption/presentation/screens/consumption_statistics_screen.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/monthly_fuel_comparison_card.dart';
import 'package:tankstellen/features/consumption/providers/consumption_providers.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

import '../../../../helpers/pump_app.dart';
import '../../../../helpers/silence_error_logger.dart';

/// Structural widget coverage for [ConsumptionStatisticsPage] (#2698):
/// the page renders the header stat tiles, the month-over-month
/// comparison card, and at least one evolution chart when ≥2 months of
/// fill-ups exist.
class _FixedFillUpList extends FillUpList {
  _FixedFillUpList(this._value);
  final List<FillUp> _value;

  @override
  List<FillUp> build() => _value;
}

FillUp _f(String id, DateTime date, double liters, double cost, double odo) =>
    FillUp(
      id: id,
      date: date,
      liters: liters,
      totalCost: cost,
      odometerKm: odo,
      fuelType: FuelType.e10,
    );

void main() {
  silenceErrorLoggerSpool();
  setUp(() => PriceFormatter.setCountry('GB'));

  final twoMonths = <FillUp>[
    _f('jan', DateTime(2026, 1, 10), 40, 60, 10000),
    _f('feb1', DateTime(2026, 2, 3), 50, 75, 11000),
    _f('feb2', DateTime(2026, 2, 20), 50, 80, 12000),
  ];

  List<Object> overrides(List<FillUp> fills) => [
    fillUpListProvider.overrideWith(() => _FixedFillUpList(fills)),
  ];

  testWidgets('renders header tiles, comparison card and a chart', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const ConsumptionStatisticsPage(),
      overrides: overrides(twoMonths),
    );

    // Header tiles — at least the litres + fill-ups labels surface.
    expect(find.text('Total liters'), findsWidgets);
    expect(find.text('Consumption statistics'), findsWidgets);

    // Month-over-month comparison card.
    expect(find.byType(MonthlyFuelComparisonCard), findsOneWidget);
    expect(find.text('This month vs last month'), findsOneWidget);

    // At least one evolution chart rendered (CustomPaint-based). The
    // chart sits below the fold of the page ListView, so scroll it into
    // view before asserting it built.
    await tester.scrollUntilVisible(
      find.byKey(const Key('monthly_litres_chart')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const Key('monthly_litres_chart')), findsOneWidget);
    expect(find.byType(MonthlyBarChart), findsWidgets);
  });

  testWidgets('single month hides the previous column with a caption', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const ConsumptionStatisticsPage(),
      overrides: overrides([twoMonths.first]),
    );

    expect(find.byType(MonthlyFuelComparisonCard), findsOneWidget);
    expect(
      find.text('Log fill-ups across at least two months to compare.'),
      findsOneWidget,
    );
  });

  testWidgets('empty fill-up list shows the empty state', (tester) async {
    await pumpApp(
      tester,
      const ConsumptionStatisticsPage(),
      overrides: overrides(const []),
    );

    expect(find.byType(MonthlyFuelComparisonCard), findsNothing);
    expect(find.byType(MonthlyBarChart), findsNothing);
  });
}
