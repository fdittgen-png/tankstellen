import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tankstellen/features/consumption/domain/entities/fill_up.dart';
import 'package:tankstellen/features/consumption/presentation/screens/consumption_screen.dart';
import 'package:tankstellen/features/consumption/providers/charging_logs_provider.dart';
import 'package:tankstellen/features/consumption/providers/consumption_providers.dart';
import 'package:tankstellen/features/ev/domain/entities/charging_log.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';

import '../../../../helpers/pump_app.dart';

/// #582 phase 2 — the ConsumptionScreen grows a Fuel/Charging tab
/// toggle. These tests verify that both tabs render, empty states
/// appear with 0 items, and switching tabs swaps the FAB action.

class _FixedFillUpList extends FillUpList {
  final List<FillUp> _value;
  _FixedFillUpList(this._value);

  @override
  List<FillUp> build() => _value;
}

class _FixedChargingLogs extends ChargingLogs {
  final List<ChargingLog> _value;
  _FixedChargingLogs(this._value);

  @override
  Future<List<ChargingLog>> build() async => _value;
}

class _NoActiveVehicle extends ActiveVehicleProfile {
  @override
  VehicleProfile? build() => null;
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  List<FillUp> fillUps = const [],
  List<ChargingLog> chargingLogs = const [],
}) async {
  final router = GoRouter(
    initialLocation: '/consumption',
    routes: [
      GoRoute(
        path: '/consumption',
        builder: (_, _) => const ConsumptionScreen(),
      ),
      GoRoute(path: '/consumption/add', builder: (_, _) => const SizedBox()),
      GoRoute(
        path: '/consumption/pick-station',
        builder: (_, _) => const SizedBox(),
      ),
      GoRoute(path: '/carbon', builder: (_, _) => const SizedBox()),
      GoRoute(path: '/trip-history', builder: (_, _) => const SizedBox()),
      GoRoute(path: '/vehicles/edit', builder: (_, _) => const SizedBox()),
    ],
  );

  await pumpApp(
    tester,
    MaterialApp.router(routerConfig: router),
    overrides: [
      fillUpListProvider.overrideWith(() => _FixedFillUpList(fillUps)),
      chargingLogsProvider.overrideWith(() => _FixedChargingLogs(chargingLogs)),
      activeVehicleProfileProvider.overrideWith(() => _NoActiveVehicle()),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ConsumptionScreen tab toggle (#582 phase 2)', () {
    testWidgets('renders both Fuel and Charging tab headers', (tester) async {
      await _pumpScreen(tester);
      expect(find.byKey(const Key('consumption_tab_fuel')), findsOneWidget);
      expect(
        find.byKey(const Key('consumption_tab_charging')),
        findsOneWidget,
      );
    });

    testWidgets('Fuel tab shows its empty state with 0 fill-ups',
        (tester) async {
      await _pumpScreen(tester);
      expect(find.textContaining('No fill-ups'), findsOneWidget);
    });

    testWidgets(
        'Charging tab shows its empty state with 0 charging logs',
        (tester) async {
      await _pumpScreen(tester);
      await tester.tap(find.byKey(const Key('consumption_tab_charging')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('charging_empty_state')),
        findsOneWidget,
      );
      expect(find.textContaining('No charging logs'), findsOneWidget);
    });

    testWidgets('FAB rebinds when switching tabs', (tester) async {
      await _pumpScreen(tester);
      expect(find.byKey(const Key('fab_add_fillup')), findsOneWidget);
      expect(find.byKey(const Key('fab_add_charging')), findsNothing);

      await tester.tap(find.byKey(const Key('consumption_tab_charging')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('fab_add_charging')), findsOneWidget);
      expect(find.byKey(const Key('fab_add_fillup')), findsNothing);
    });

    testWidgets('Charging tab renders a card per logged session',
        (tester) async {
      // Phase-3 added a charts header above the log list. On the
      // default 800px test surface the cards end up below the fold,
      // so we enlarge the viewport for this assertion only —
      // `ListView.builder` only mounts items in the visible range.
      tester.view.physicalSize = const Size(900, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final logs = [
        ChargingLog(
          id: 'c1',
          vehicleId: 'v1',
          date: DateTime.utc(2026, 4, 10),
          kWh: 45.2,
          costEur: 18.5,
          chargeTimeMin: 35,
          odometerKm: 12345,
          stationName: 'Ionity Castelnau',
        ),
        ChargingLog(
          id: 'c2',
          vehicleId: 'v1',
          date: DateTime.utc(2026, 4, 15),
          kWh: 30.0,
          costEur: 12.0,
          chargeTimeMin: 20,
          odometerKm: 12500,
          stationName: 'Allego Beziers',
        ),
      ];
      await _pumpScreen(tester, chargingLogs: logs);
      await tester.tap(find.byKey(const Key('consumption_tab_charging')));
      await tester.pumpAndSettle();

      expect(find.text('Ionity Castelnau'), findsOneWidget);
      expect(find.text('Allego Beziers'), findsOneWidget);
    });
  });
}
