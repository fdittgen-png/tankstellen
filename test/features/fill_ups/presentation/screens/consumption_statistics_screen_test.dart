// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/utils/price_formatter.dart';
import 'package:tankstellen/features/carbon/presentation/widgets/monthly_bar_chart.dart';
import 'package:tankstellen/features/fill_ups/domain/entities/fill_up.dart';
import 'package:tankstellen/features/fill_ups/presentation/screens/consumption_statistics_screen.dart';
import 'package:tankstellen/features/fill_ups/presentation/widgets/monthly_fuel_comparison_card.dart';
import 'package:tankstellen/features/fill_ups/presentation/widgets/monthly_metric_chart.dart';
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

    // #4175 — ONE evolution chart with a metric selector, where there
    // used to be four stacked cards. It sits below the fold, so scroll
    // it into view before asserting it built. The page's own list is
    // keyed because the pinned fuel filter is also a Scrollable now and
    // `find.byType(Scrollable).first` would reach the wrong one.
    await tester.scrollUntilVisible(
      find.byKey(const Key('monthly_line_litres')),
      300,
      scrollable: find.descendant(
        of: find.byKey(const Key('consumption_stats_list')),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.byKey(const Key('monthly_line_litres')), findsOneWidget);
    expect(find.byType(MonthlyMetricChart), findsOneWidget);
  });

  testWidgets('#4175 — the metric selector swaps the series in place, '
      'without a second chart card', (tester) async {
    await pumpApp(
      tester,
      const ConsumptionStatisticsPage(),
      overrides: overrides(twoMonths),
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('metric_spend')),
      300,
      scrollable: find.descendant(
        of: find.byKey(const Key('consumption_stats_list')),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.byKey(const Key('monthly_line_litres')), findsOneWidget);

    await tester.tap(find.byKey(const Key('metric_spend')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('monthly_line_spend')), findsOneWidget);
    expect(find.byKey(const Key('monthly_line_litres')), findsNothing,
        reason: 'the point of the selector is ONE chart, not a second '
            'one appearing beside the first');
    expect(find.byType(MonthlyMetricChart), findsOneWidget);
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

      // All-fuels view stacks the ADDITIVE metric and shows the legend.
      // #4175 — litres is the default metric and it is additive, so the
      // stacked bar is what renders; a line cannot express a per-fuel
      // composition, which is why that encoding survived the redesign.
      final list = find.descendant(
        of: find.byKey(const Key('consumption_stats_list')),
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(
        find.byKey(const Key('fuel_stack_legend')),
        300,
        scrollable: list,
      );
      expect(find.byKey(const Key('fuel_stack_legend')), findsOneWidget);
      expect(find.byType(MonthlyBarChart), findsOneWidget);

      // A RATIO metric cannot be stacked — an average of averages is
      // not an average — so selecting price/L drops the legend and
      // renders the line instead, in the same card.
      await tester.tap(find.byKey(const Key('metric_pricePerLitre')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('fuel_stack_legend')), findsNothing);
      expect(find.byType(MonthlyMetricChart), findsOneWidget);

      // Selecting one fuel drops the stack for the additive metric too:
      // there is only one series left to draw. The filter is PINNED
      // now, so there is no scrolling back up to reach it.
      await tester.tap(find.byKey(const Key('metric_litres')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('fuel_filter_FuelTypeE85')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('fuel_stack_legend')), findsNothing);
      expect(find.byType(MonthlyMetricChart), findsOneWidget);
    },
  );

  testWidgets(
    '#4175 — en_XA at 320 dp + 1.3x: the redesigned page does not '
    'overflow',
    (tester) async {
      // #3950 pinned this constraint for the month table and it is the
      // gate for every change here: tinted icon discs, a pinned filter
      // row and a metric-selector row all add width to a page that was
      // already tight under the pseudo-locale.
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      final mixed = <FillUp>[
        _f('jan-e5', DateTime(2026, 1, 10), 40, 60, 10000),
        _f('jan-e85', DateTime(2026, 1, 20), 30, 25, 10500,
            fuel: FuelType.e85),
        _f('feb-e5', DateTime(2026, 2, 3), 50, 75, 11000),
      ];
      await pumpApp(
        tester,
        const ConsumptionStatisticsPage(),
        overrides: overrides(mixed),
        locale: const Locale('en', 'XA'),
      );

      expect(tester.takeException(), isNull,
          reason: 'the page overflows at 320 dp under the pseudo-locale');

      // The metric selector and the fuel filter both SCROLL rather than
      // wrap, so neither can push the page wider however long a
      // localized metric name turns out to be.
      await tester.scrollUntilVisible(
        find.byKey(const Key('metric_litres')),
        300,
        scrollable: find.descendant(
          of: find.byKey(const Key('consumption_stats_list')),
          matching: find.byType(Scrollable),
        ),
      );
      expect(tester.takeException(), isNull);
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
