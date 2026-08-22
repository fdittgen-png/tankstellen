// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/utils/price_formatter.dart';
import 'package:tankstellen/features/carbon/presentation/widgets/monthly_bar_chart.dart';
import 'package:tankstellen/features/fill_ups/domain/entities/fill_up.dart';
import 'package:tankstellen/features/fill_ups/presentation/screens/consumption_statistics_screen.dart';
import 'package:tankstellen/features/fill_ups/presentation/widgets/monthly_fuel_comparison_card.dart';
import 'package:tankstellen/features/fill_ups/providers/consumption_providers.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';

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

/// #2898 — the stats page now hosts FuelTypeEfficiencyCard, which watches the
/// active-vehicle provider (Hive-backed). In a widget test without Hive that
/// read throws, so override it to a null active vehicle: the per-fuel card then
/// self-hides (this test covers the header tiles / comparison card / chart, not
/// the per-fuel card).
class _NoVehicle extends ActiveVehicleProfile {
  @override
  VehicleProfile? build() => null;
}

FillUp _f(
  String id,
  DateTime date,
  double liters,
  double cost,
  double odo, {
  FuelType fuel = FuelType.e10,
}) => FillUp(
  id: id,
  date: date,
  liters: liters,
  totalCost: cost,
  odometerKm: odo,
  fuelType: fuel,
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
    activeVehicleProfileProvider.overrideWith(() => _NoVehicle()),
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

  testWidgets(
    'multi-fuel logs get the fuel filter chips, the stack legend, and '
    'a per-fuel view on chip tap (#3691)',
    (tester) async {
      final mixed = <FillUp>[
        _f('jan-e5', DateTime(2026, 1, 10), 40, 60, 10000),
        _f(
          'jan-e85',
          DateTime(2026, 1, 20),
          30,
          25,
          10500,
          fuel: FuelType.e85,
        ),
        _f('feb-e5', DateTime(2026, 2, 3), 50, 75, 11000),
        _f(
          'feb-e85',
          DateTime(2026, 2, 20),
          45,
          35,
          12000,
          fuel: FuelType.e85,
        ),
      ];
      await pumpApp(
        tester,
        const ConsumptionStatisticsPage(),
        overrides: overrides(mixed),
      );

      // The filter row: All + one chip per logged fuel.
      expect(find.byKey(const Key('fuel_filter_all')), findsOneWidget);
      expect(
        find.byKey(const Key('fuel_filter_FuelTypeE10')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('fuel_filter_FuelTypeE85')),
        findsOneWidget,
      );

      // All-fuels view stacks the additive charts and shows the legend.
      await tester.scrollUntilVisible(
        find.byKey(const Key('fuel_stack_legend')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byKey(const Key('fuel_stack_legend')), findsOneWidget);

      // Selecting one fuel drops the stack legend (single-series view)
      // and keeps every chart rendered for that fuel alone. The chips
      // sit at the top — scroll back up first.
      await tester.scrollUntilVisible(
        find.byKey(const Key('fuel_filter_FuelTypeE85')),
        -300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const Key('fuel_filter_FuelTypeE85')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('fuel_stack_legend')), findsNothing);
      await tester.scrollUntilVisible(
        find.byKey(const Key('monthly_litres_chart')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byType(MonthlyBarChart), findsWidgets);
    },
  );

  testWidgets('single-fuel logs never show the filter chips', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const ConsumptionStatisticsPage(),
      overrides: overrides(twoMonths),
    );
    expect(find.byKey(const Key('fuel_filter_all')), findsNothing);
  });
}
