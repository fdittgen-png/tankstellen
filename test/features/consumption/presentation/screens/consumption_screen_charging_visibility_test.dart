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

/// #892 — the Charging tab on `ConsumptionScreen` is gated by the
/// active vehicle's powertrain. ICE vehicles see Fuel + Trajets only;
/// hybrid and EV vehicles see all three tabs. Switching live from EV
/// to ICE while Charging was selected snaps the selection to Trajets
/// so the user doesn't land on a non-existent index.

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

/// Mutable active-vehicle notifier so one test can flip the vehicle
/// type after the initial pump — mirrors the real vehicle switcher.
class _MutableActiveVehicle extends ActiveVehicleProfile {
  _MutableActiveVehicle(this._initial);
  final VehicleProfile? _initial;

  @override
  VehicleProfile? build() => _initial;

  void set(VehicleProfile? next) {
    state = next;
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
  name: 'ICE commuter',
  type: VehicleType.combustion,
);

const _evVehicle = VehicleProfile(
  id: 'v-ev',
  name: 'Daily EV',
  type: VehicleType.ev,
);

const _hybridVehicle = VehicleProfile(
  id: 'v-hybrid',
  name: 'Plug-in hybrid',
  type: VehicleType.hybrid,
);

Future<_MutableActiveVehicle> _pumpScreen(
  WidgetTester tester, {
  required VehicleProfile? activeVehicle,
  List<VehicleProfile> vehicles = const [],
  List<FillUp> fillUps = const [],
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
      activeVehicleProfileProvider.overrideWith(() => activeNotifier),
      vehicleProfileListProvider
          .overrideWith(() => _FixedVehicleProfileList(vehicles)),
    ],
  );
  return activeNotifier;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ConsumptionScreen Charging visibility (#892)', () {
    testWidgets('ICE vehicle -> 2 tabs, no Charging label', (tester) async {
      await _pumpScreen(
        tester,
        activeVehicle: _iceVehicle,
        vehicles: const [_iceVehicle],
      );

      expect(find.byKey(const Key('consumption_tab_fuel')), findsOneWidget);
      expect(
        find.byKey(const Key('consumption_tab_trajets')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('consumption_tab_charging')),
        findsNothing,
      );

      // The text "Charging" must not appear in the tab row — the tab
      // bar is the only place in the AppBar that would render that
      // label. Other call sites (menus, badges) live off-screen for
      // this scaffold.
      expect(find.text('Charging'), findsNothing);
    });

    testWidgets('EV vehicle -> 3 tabs including Charging', (tester) async {
      await _pumpScreen(
        tester,
        activeVehicle: _evVehicle,
        vehicles: const [_evVehicle],
      );

      expect(find.byKey(const Key('consumption_tab_fuel')), findsOneWidget);
      expect(
        find.byKey(const Key('consumption_tab_trajets')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('consumption_tab_charging')),
        findsOneWidget,
      );
    });

    testWidgets('Hybrid vehicle -> 3 tabs including Charging', (tester) async {
      await _pumpScreen(
        tester,
        activeVehicle: _hybridVehicle,
        vehicles: const [_hybridVehicle],
      );

      expect(find.byKey(const Key('consumption_tab_fuel')), findsOneWidget);
      expect(
        find.byKey(const Key('consumption_tab_trajets')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('consumption_tab_charging')),
        findsOneWidget,
      );
    });

    testWidgets(
        'switching EV -> ICE while Charging selected snaps to Trajets '
        'without crashing',
        (tester) async {
      final activeNotifier = await _pumpScreen(
        tester,
        activeVehicle: _evVehicle,
        vehicles: const [_evVehicle, _iceVehicle],
      );

      // Start on the Charging tab (index 2). The user explicitly
      // navigated there before switching vehicles.
      await tester.tap(find.byKey(const Key('consumption_tab_charging')));
      await tester.pumpAndSettle();

      // Flip the active vehicle to ICE — the Charging tab must
      // disappear. The screen rebuilds without throwing.
      activeNotifier.set(_iceVehicle);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        find.byKey(const Key('consumption_tab_charging')),
        findsNothing,
      );
      expect(find.text('Charging'), findsNothing);

      // The now-visible tab row has 2 entries; the selection must be
      // Trajets (the previously-adjacent tab) so the body still shows
      // something meaningful.
      final tabBar = tester.widget<TabBar>(find.byType(TabBar));
      expect(tabBar.controller!.length, 2);
      expect(tabBar.controller!.index, 1);
    });
  });
}
