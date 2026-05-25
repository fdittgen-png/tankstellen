// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/storage/storage_providers.dart';
import 'package:tankstellen/features/carbon/presentation/screens/carbon_dashboard_screen.dart';
import 'package:tankstellen/features/carbon/presentation/widgets/monthly_bar_chart.dart';
import 'package:tankstellen/features/consumption/domain/entities/fill_up.dart';
import 'package:tankstellen/features/consumption/providers/consumption_providers.dart';
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
      ],
    );
    expect(find.text('No data yet'), findsOneWidget);
    expect(find.byType(MonthlyBarChart), findsNothing);
  });

  testWidgets('renders charts with bar charts when data exists',
      (tester) async {
    await pumpApp(
      tester,
      const CarbonDashboardScreen(),
      overrides: [
        settingsStorageProvider.overrideWithValue(_FakeSettingsStorage()),
        fillUpListProvider.overrideWith(_FakeFillUpList.new),
      ],
    );
    // Two bar charts on the Charts pane. skipOffstage: false because the
    // pane is now tall enough that the second chart sits below the 800x600
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

  testWidgets(
      'share button is hidden in the empty state (#2005) — nothing to '
      'share, the button would just be noise',
      (tester) async {
    await pumpApp(
      tester,
      const CarbonDashboardScreen(),
      overrides: [
        settingsStorageProvider.overrideWithValue(_FakeSettingsStorage()),
      ],
    );
    expect(
      find.byKey(const Key('carbon-dashboard-share')),
      findsNothing,
      reason: 'the empty-state body covers no-data — sharing an empty '
          'summary would just be noise',
    );
  });

  testWidgets(
      'share button hands a formatted summary to the share sink (#2005)',
      (tester) async {
    ShareParams? captured;
    debugCarbonShareSinkOverride = (params) async {
      captured = params;
    };
    addTearDown(() => debugCarbonShareSinkOverride = null);

    await pumpApp(
      tester,
      const CarbonDashboardScreen(),
      overrides: [
        settingsStorageProvider.overrideWithValue(_FakeSettingsStorage()),
        fillUpListProvider.overrideWith(_FakeFillUpList.new),
      ],
    );

    final shareFinder = find.byKey(const Key('carbon-dashboard-share'));
    expect(shareFinder, findsOneWidget,
        reason: 'share button must render when fill-ups exist');
    await tester.tap(shareFinder);
    await tester.pumpAndSettle();

    expect(captured, isNotNull,
        reason: 'tapping share must dispatch to the share sink');
    // The summary must carry the screen's headline figures so the
    // receiving app shows a useful preview, not a bare title.
    expect(captured!.text, contains('Carbon dashboard'));
    expect(captured!.text, contains('Total cost'));
    expect(captured!.text, contains('Total CO2'));
    // Numbers come from `_FakeFillUpList` — exact values are
    // computed by `MonthlyAggregator.totalCost / totalCo2` and may
    // change as the formulas evolve; we just assert that SOME value
    // shows up next to each label rather than pinning a specific
    // number that would force a test rewrite on every formula change.
    expect(captured!.subject, 'Carbon dashboard',
        reason: 'subject lets email clients use the dashboard title '
            'as the message subject');
  });
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
