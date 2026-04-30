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

/// #892 — the Charging tab on [ConsumptionScreen] is hidden for ICE
/// vehicles (combustion) and visible for hybrid / EV profiles. The
/// underlying `chargingLogsProvider` stays untouched, so flipping back
/// to a hybrid/EV restores the logs unchanged.
///
/// These tests map 1:1 to the acceptance criteria on the issue:
///   1. ICE vehicle → 2 tabs, no "Charging" label
///   2. EV vehicle → 3 tabs, "Charging" label present
///   3. Hybrid vehicle → 3 tabs
///   4. Live switch EV → ICE while on Charging tab → 2 tabs, no
///      crash, user lands on Trajets (index 1)

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

/// Mutable active-vehicle notifier so a single test can flip the
/// powertrain mid-flight (acceptance criterion #5).
class _MutableActiveVehicle extends ActiveVehicleProfile {
  final VehicleProfile? initialValue;
  _MutableActiveVehicle(this.initialValue);

  @override
  VehicleProfile? build() => initialValue;

  void setVehicle(VehicleProfile? vehicle) {
    state = vehicle;
  }
}

class _FixedVehicleProfileList extends VehicleProfileList {
  final List<VehicleProfile> _value;
  _FixedVehicleProfileList(this._value);

  @override
  List<VehicleProfile> build() => _value;
}

const _iceVehicle = VehicleProfile(
  id: 'v-ice',
  name: 'Peugeot 107',
  type: VehicleType.combustion,
);

const _evVehicle = VehicleProfile(
  id: 'v-ev',
  name: 'Tesla Model 3',
  type: VehicleType.ev,
);

const _hybridVehicle = VehicleProfile(
  id: 'v-hybrid',
  name: 'Toyota Prius',
  type: VehicleType.hybrid,
);

Future<_MutableActiveVehicle> _pumpScreen(
  WidgetTester tester, {
  required VehicleProfile? activeVehicle,
  List<VehicleProfile> vehicles = const [],
  List<ChargingLog> chargingLogs = const [],
}) async {
  final activeNotifier = _MutableActiveVehicle(activeVehicle);

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
    ],
  );

  await pumpApp(
    tester,
    MaterialApp.router(routerConfig: router),
    overrides: [
      fillUpListProvider.overrideWith(() => _FixedFillUpList(const [])),
      chargingLogsProvider
          .overrideWith(() => _FixedChargingLogs(chargingLogs)),
      activeVehicleProfileProvider.overrideWith(() => activeNotifier),
      vehicleProfileListProvider
          .overrideWith(() => _FixedVehicleProfileList(vehicles)),
    ],
  );

  return activeNotifier;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ConsumptionScreen Charging tab visibility (#892)', () {
    testWidgets(
      'ICE vehicle active → 2 tabs, no "Charging" label [AC1]',
      (tester) async {
        await _pumpScreen(
          tester,
          activeVehicle: _iceVehicle,
          vehicles: const [_iceVehicle],
        );

        // #923 phase 3a — tabs now come from the canonical
        // `TabSwitcher` widget whose entries carry no per-tab `key:`.
        // Assert on the localised label instead.
        expect(
          find.text('Fuel'),
          findsOneWidget,
          reason: 'Fuel tab must always render',
        );
        expect(
          find.text('Trips'),
          findsOneWidget,
          reason: 'Trajets tab must render for ICE vehicles',
        );
        expect(
          find.text('Charging'),
          findsNothing,
          reason: 'Charging tab must be hidden for combustion vehicles',
        );

        // Exactly 2 Tab widgets on screen.
        expect(find.byType(Tab), findsNWidgets(2));

        // The localised tab labels for Charging must not appear.
        expect(find.text('Charging'), findsNothing);
        expect(find.text('Aufladung'), findsNothing);
        expect(find.text('Laden'), findsNothing);
        expect(find.text('Recharge'), findsNothing);
      },
    );

    testWidgets(
      'EV vehicle active → 3 tabs including Charging [AC2]',
      (tester) async {
        await _pumpScreen(
          tester,
          activeVehicle: _evVehicle,
          vehicles: const [_evVehicle],
        );

        expect(find.text('Fuel'), findsOneWidget);
        expect(find.text('Trips'), findsOneWidget);
        expect(
          find.text('Charging'),
          findsOneWidget,
          reason: 'Charging tab must render for EV vehicles',
        );
        expect(find.byType(Tab), findsNWidgets(3));
      },
    );

    testWidgets(
      'Hybrid vehicle active → 3 tabs [AC3]',
      (tester) async {
        await _pumpScreen(
          tester,
          activeVehicle: _hybridVehicle,
          vehicles: const [_hybridVehicle],
        );

        expect(
          find.text('Charging'),
          findsOneWidget,
          reason: 'Charging tab must render for hybrid vehicles',
        );
        expect(find.byType(Tab), findsNWidgets(3));
      },
    );

    testWidgets(
      'Live switch EV → ICE while on Charging tab: '
      'tab disappears, no crash, user on Trajets [AC4]',
      (tester) async {
        // Start on the EV profile with the Charging tab visible and a
        // couple of logs seeded so the data layer has state we can
        // observe *doesn't* get cleared by the switch.
        final activeNotifier = await _pumpScreen(
          tester,
          activeVehicle: _evVehicle,
          vehicles: const [_evVehicle, _iceVehicle],
          chargingLogs: [
            ChargingLog(
              id: 'c1',
              vehicleId: 'v-ev',
              date: DateTime.utc(2026, 4, 20),
              kWh: 30.0,
              costEur: 12.0,
              chargeTimeMin: 30,
              odometerKm: 10000,
              stationName: 'Ionity Castelnau',
            ),
          ],
        );

        // Sanity: Charging tab is there.
        expect(find.text('Charging'), findsOneWidget);

        // Tap onto Charging so we're ON the tab that will vanish.
        await tester.tap(find.text('Charging'));
        await tester.pumpAndSettle();

        // Flip the active vehicle to ICE — the tab set should shrink.
        activeNotifier.setVehicle(_iceVehicle);
        await tester.pumpAndSettle();

        // No exception was surfaced by the harness (TestWidgetsFlutter
        // Binding rethrows on pump if one occurred).
        expect(tester.takeException(), isNull);

        // Charging tab is gone.
        expect(find.text('Charging'), findsNothing);

        // We now have exactly 2 tabs.
        expect(find.byType(Tab), findsNWidgets(2));

        // The TabController should have landed on Trajets (index 1)
        // — the closest neighbour to the old Charging index (2).
        // Reach in via the TabBar widget's own `controller`.
        final tabBar = tester.widget<TabBar>(find.byType(TabBar));
        expect(tabBar.controller, isNotNull);
        expect(tabBar.controller!.length, equals(2));
        expect(
          tabBar.controller!.index,
          equals(1),
          reason:
              'When Charging vanishes under the user, the selection '
              'should snap to Trajets (index 1), not Fuel.',
        );

        // Flip back to EV — Charging tab must return and the logs
        // must still be available from the unchanged provider.
        activeNotifier.setVehicle(_evVehicle);
        await tester.pumpAndSettle();
        expect(
          find.text('Charging'),
          findsOneWidget,
          reason: 'Charging tab must come back when vehicle is EV again',
        );
      },
    );
  });
}
