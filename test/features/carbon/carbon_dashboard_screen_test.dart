import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/storage/storage_providers.dart';
import 'package:tankstellen/features/carbon/presentation/screens/carbon_dashboard_screen.dart';
import 'package:tankstellen/features/carbon/presentation/widgets/fuel_vs_ev_card.dart';
import 'package:tankstellen/features/carbon/presentation/widgets/milestones_card.dart';
import 'package:tankstellen/features/carbon/presentation/widgets/monthly_bar_chart.dart';
import 'package:tankstellen/features/consumption/domain/entities/fill_up.dart';
import 'package:tankstellen/features/consumption/providers/consumption_providers.dart';
import 'package:tankstellen/features/profile/providers/gamification_enabled_provider.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

import '../../helpers/pump_app.dart';

class _FakeSettingsStorage implements SettingsStorage {
  final Map<String, dynamic> _data = {};

  @override
  dynamic getSetting(String key) => _data[key];

  @override
  Future<void> putSetting(String key, dynamic value) async {
    _data[key] = value;
  }

  @override
  bool get isSetupComplete => false;
  @override
  bool get isSetupSkipped => false;
  @override
  Future<void> skipSetup() async {}
  @override
  Future<void> resetSetupSkip() async {}
}

FillUp _f(
  String id,
  DateTime date, {
  double liters = 50,
  double cost = 80,
  double odometer = 10000,
}) =>
    FillUp(
      id: id,
      date: date,
      liters: liters,
      totalCost: cost,
      odometerKm: odometer,
      fuelType: FuelType.diesel,
    );

void main() {
  testWidgets('renders empty state when no fill-ups', (tester) async {
    await pumpApp(
      tester,
      const CarbonDashboardScreen(),
      overrides: [
        settingsStorageProvider.overrideWithValue(_FakeSettingsStorage()),
        gamificationEnabledProvider.overrideWith((ref) => true),
      ],
    );
    expect(find.text('No data yet'), findsOneWidget);
    expect(find.byType(MonthlyBarChart), findsNothing);
  });

  testWidgets('renders charts tab with bar charts when data exists',
      (tester) async {
    await pumpApp(
      tester,
      const CarbonDashboardScreen(),
      overrides: [
        settingsStorageProvider.overrideWithValue(_FakeSettingsStorage()),
        fillUpListProvider.overrideWith(_FakeFillUpList.new),
        gamificationEnabledProvider.overrideWith((ref) => true),
      ],
    );
    // Two bar charts on the Charts tab. skipOffstage: false because the
    // tab is now tall enough that the second chart sits below the 800x600
    // test viewport — the assertion is "the chart is in the tree", not
    // "the chart is in the initial scroll window".
    expect(
      find.byType(MonthlyBarChart, skipOffstage: false),
      findsNWidgets(2),
    );
    expect(
      find.text('Monthly costs', skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.text('Monthly CO2 emissions', skipOffstage: false),
      findsOneWidget,
    );
  });

  testWidgets('switches to achievements tab showing milestones + EV card',
      (tester) async {
    await pumpApp(
      tester,
      const CarbonDashboardScreen(),
      overrides: [
        settingsStorageProvider.overrideWithValue(_FakeSettingsStorage()),
        fillUpListProvider.overrideWith(_FakeFillUpList.new),
        gamificationEnabledProvider.overrideWith((ref) => true),
      ],
    );
    await tester.tap(find.text('Achievements'));
    await tester.pumpAndSettle();
    expect(
      find.byType(MilestonesCard, skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.byType(FuelVsEvCard, skipOffstage: false),
      findsOneWidget,
    );
    expect(find.text('Milestones'), findsOneWidget);
  });

  // -------------------------------------------------------------------------
  // #1194 — gamification opt-out gating
  // -------------------------------------------------------------------------
  testWidgets(
    'shows both Charts and Achievements tabs when gamification is enabled',
    (tester) async {
      await pumpApp(
        tester,
        const CarbonDashboardScreen(),
        overrides: [
          settingsStorageProvider.overrideWithValue(_FakeSettingsStorage()),
          fillUpListProvider.overrideWith(_FakeFillUpList.new),
          gamificationEnabledProvider.overrideWith((ref) => true),
        ],
      );
      // Both tabs are present (one TabBar with two Tab children).
      expect(find.byType(TabBar), findsOneWidget);
      expect(find.byType(Tab), findsNWidgets(2));
      expect(find.text('Charts'), findsOneWidget);
      expect(find.text('Achievements'), findsOneWidget);
    },
  );

  testWidgets(
    'collapses to a single Charts pane when gamification is disabled',
    (tester) async {
      await pumpApp(
        tester,
        const CarbonDashboardScreen(),
        overrides: [
          settingsStorageProvider.overrideWithValue(_FakeSettingsStorage()),
          fillUpListProvider.overrideWith(_FakeFillUpList.new),
          gamificationEnabledProvider.overrideWith((ref) => false),
        ],
      );
      // No TabBar, no Achievements tab — just the Charts pane.
      expect(find.byType(TabBar), findsNothing);
      expect(find.text('Achievements'), findsNothing);
      // Charts content is still rendered. skipOffstage: false — the
      // pane is taller than 600 px since the trip-length and
      // speed-consumption cards landed.
      expect(
        find.byType(MonthlyBarChart, skipOffstage: false),
        findsNWidgets(2),
      );
      expect(
        find.text('Monthly costs', skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.text('Monthly CO2 emissions', skipOffstage: false),
        findsOneWidget,
      );
    },
  );
}

class _FakeFillUpList extends FillUpList {
  @override
  List<FillUp> build() {
    return [
      _f('1', DateTime(2026, 1, 5), liters: 40, cost: 60, odometer: 10000),
      _f('2', DateTime(2026, 2, 5), liters: 50, cost: 80, odometer: 11000),
      _f('3', DateTime(2026, 3, 5), liters: 45, cost: 70, odometer: 12000),
    ];
  }
}
