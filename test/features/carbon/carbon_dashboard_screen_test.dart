import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/storage/storage_providers.dart';
import 'package:tankstellen/features/carbon/presentation/screens/carbon_dashboard_screen.dart';
import 'package:tankstellen/features/carbon/presentation/widgets/fuel_vs_ev_card.dart';
import 'package:tankstellen/features/carbon/presentation/widgets/milestones_card.dart';
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

  testWidgets('renders charts tab with bar charts when data exists',
      (tester) async {
    await pumpApp(
      tester,
      const CarbonDashboardScreen(),
      overrides: [
        settingsStorageProvider.overrideWithValue(_FakeSettingsStorage()),
        fillUpListProvider.overrideWith(_FakeFillUpList.new),
      ],
    );
    // Two bar charts on the Charts tab
    expect(find.byType(MonthlyBarChart), findsNWidgets(2));
    expect(find.text('Monthly costs'), findsOneWidget);
    expect(find.text('Monthly CO2 emissions'), findsOneWidget);
  });

  testWidgets('switches to achievements tab showing milestones + EV card',
      (tester) async {
    await pumpApp(
      tester,
      const CarbonDashboardScreen(),
      overrides: [
        settingsStorageProvider.overrideWithValue(_FakeSettingsStorage()),
        fillUpListProvider.overrideWith(_FakeFillUpList.new),
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
