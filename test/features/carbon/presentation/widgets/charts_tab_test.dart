import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/carbon/domain/monthly_summary.dart';
import 'package:tankstellen/features/carbon/presentation/widgets/charts_tab.dart';
import 'package:tankstellen/features/carbon/presentation/widgets/monthly_bar_chart.dart';
import 'package:tankstellen/features/consumption/data/trip_history_repository.dart';
import 'package:tankstellen/features/consumption/providers/trip_history_provider.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';

import '../../../../helpers/pump_app.dart';

class _FixedTripHistoryList extends TripHistoryList {
  _FixedTripHistoryList(this._value);
  final List<TripHistoryEntry> _value;

  @override
  List<TripHistoryEntry> build() => _value;
}

class _FixedActiveVehicle extends ActiveVehicleProfile {
  _FixedActiveVehicle(this._value);
  final VehicleProfile? _value;

  @override
  VehicleProfile? build() => _value;
}

MonthlySummary _s(DateTime month, {double cost = 80, double co2 = 100}) =>
    MonthlySummary(
      month: month,
      totalCost: cost,
      totalLiters: 50,
      totalCo2Kg: co2,
      fillUpCount: 1,
    );

void main() {
  group('ChartsTab', () {
    testWidgets('renders summary row + two monthly bar charts',
        (tester) async {
      // Tall viewport so both charts sit on-screen and the ListView
      // mounts both subtrees on the first frame.
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final summaries = [
        _s(DateTime(2026, 1), cost: 60, co2: 80),
        _s(DateTime(2026, 2), cost: 80, co2: 110),
        _s(DateTime(2026, 3), cost: 70, co2: 95),
      ];

      await pumpApp(
        tester,
        ChartsTab(
          summaries: summaries,
          totalCost: 210,
          totalCo2: 285,
        ),
        overrides: [
          tripHistoryListProvider
              .overrideWith(() => _FixedTripHistoryList(const [])),
          activeVehicleProfileProvider
              .overrideWith(() => _FixedActiveVehicle(null)),
        ],
      );

      // Both bar charts are mounted. skipOffstage: false because
      // ListView may sliver the second chart out of the initial pass.
      expect(
        find.byType(MonthlyBarChart, skipOffstage: false),
        findsNWidgets(2),
      );
      // Summary row labels render.
      expect(find.text('Total cost'), findsOneWidget);
      expect(find.text('Total CO2'), findsOneWidget);
      // Section titles render below the summary.
      expect(
        find.text('Monthly costs', skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.text('Monthly CO2 emissions', skipOffstage: false),
        findsOneWidget,
      );
    });

    testWidgets('builds without throwing when summaries are empty',
        (tester) async {
      await pumpApp(
        tester,
        const ChartsTab(
          summaries: [],
          totalCost: 0,
          totalCo2: 0,
        ),
        overrides: [
          tripHistoryListProvider
              .overrideWith(() => _FixedTripHistoryList(const [])),
          activeVehicleProfileProvider
              .overrideWith(() => _FixedActiveVehicle(null)),
        ],
      );

      // Two charts are still rendered (they handle the empty data
      // path themselves) and the summary row is present.
      expect(
        find.byType(MonthlyBarChart, skipOffstage: false),
        findsNWidgets(2),
      );
      expect(find.text('Total cost'), findsOneWidget);
    });
  });
}
