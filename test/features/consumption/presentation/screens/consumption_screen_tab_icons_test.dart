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

/// #1163 — counterpart to `favorites_screen_tab_icons_test.dart`.
/// Lock that the Conso sub-tabs keep their icon-above-label rendering.
/// If anyone strips an icon from `ConsumptionScreen` to "match" Favoris
/// the wrong way round, this test fails.
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

class _FixedActiveVehicle extends ActiveVehicleProfile {
  final VehicleProfile? _value;
  _FixedActiveVehicle(this._value);

  @override
  VehicleProfile? build() => _value;
}

class _FixedVehicleProfileList extends VehicleProfileList {
  final List<VehicleProfile> _value;
  _FixedVehicleProfileList(this._value);

  @override
  List<VehicleProfile> build() => _value;
}

const _evVehicle = VehicleProfile(
  id: 'v-ev',
  name: 'Tesla Model 3',
  type: VehicleType.ev,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ConsumptionScreen sub-tab icons (#1163)', () {
    testWidgets('every TabSwitcher entry renders a leading Icon',
        (tester) async {
      final router = GoRouter(
        initialLocation: '/consumption',
        routes: [
          GoRoute(
            path: '/consumption',
            builder: (_, _) => const ConsumptionScreen(),
          ),
          GoRoute(
            path: '/consumption/add',
            builder: (_, _) => const SizedBox(),
          ),
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
              .overrideWith(() => _FixedChargingLogs(const [])),
          activeVehicleProfileProvider
              .overrideWith(() => _FixedActiveVehicle(_evVehicle)),
          vehicleProfileListProvider
              .overrideWith(() => _FixedVehicleProfileList(const [_evVehicle])),
        ],
      );

      // EV profile keeps the Charging tab visible → 3 Tab widgets.
      final tabs = tester.widgetList<Tab>(find.byType(Tab)).toList();
      expect(tabs, hasLength(3),
          reason: 'EV profile must render Fuel + Trips + Charging');

      // Every Tab must carry an icon — the visual contract this issue
      // locked across both Conso and Favoris.
      for (final tab in tabs) {
        expect(tab.icon, isNotNull,
            reason: 'Conso sub-tab is missing its leading icon — #1163.');
      }

      // Spot-check the specific icons defined in `consumption_screen.dart`.
      // We use findsAtLeast(1) because some of these icons (e.g.
      // ev_station_outlined) also appear in the empty-state body for
      // an EV profile with no logs — the tab assertion above is the
      // strict per-tab guarantee.
      expect(find.byIcon(Icons.local_gas_station_outlined), findsAtLeast(1));
      expect(find.byIcon(Icons.route_outlined), findsAtLeast(1));
      expect(find.byIcon(Icons.ev_station_outlined), findsAtLeast(1));
    });
  });
}
