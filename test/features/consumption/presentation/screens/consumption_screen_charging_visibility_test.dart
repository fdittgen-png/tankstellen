import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tankstellen/features/consumption/domain/entities/fill_up.dart';
import 'package:tankstellen/features/consumption/presentation/screens/consumption_screen.dart';
import 'package:tankstellen/features/consumption/providers/charging_logs_provider.dart';
import 'package:tankstellen/features/consumption/providers/consumption_providers.dart';
import 'package:tankstellen/features/ev/domain/entities/charging_log.dart';
import 'package:tankstellen/features/feature_management/application/feature_flags_provider.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';

import '../../../../helpers/pump_app.dart';

/// Enables the consumption surface. #1901 — Trajets is no longer a tab
/// of this screen, so the Fuel section just needs the Conso surface
/// flag; the OBD2 flag no longer changes the tab count here.
class _ObdEnabledFlags extends FeatureFlags {
  @override
  Set<Feature> build() => <Feature>{
        Feature.showConsumptionTab,
        Feature.obd2TripRecording,
      };
}

/// #892 / #1901 — the Charging slot on the Fuel section of
/// [ConsumptionScreen] is hidden for ICE vehicles (combustion) and
/// visible for hybrid / EV profiles. The underlying
/// `chargingLogsProvider` stays untouched, so flipping back to a
/// hybrid/EV restores the logs unchanged.
///
/// #1901 — Trajets is now a separate destination, so the Fuel section
/// is just Fuel (ICE) or a Fuel / Charging switcher (EV/hybrid):
///   1. ICE vehicle → no switcher, Fuel only, no "Charging" label
///   2. EV vehicle → 2-entry Fuel / Charging switcher
///   3. Hybrid vehicle → 2-entry Fuel / Charging switcher
///   4. Live switch EV → ICE while on Charging sub-tab → switcher
///      disappears, no crash, screen falls back to plain Fuel

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
      GoRoute(path: '/trip-history', builder: (_, _) => const SizedBox()),
      GoRoute(path: '/vehicles/edit', builder: (_, _) => const SizedBox()),
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
      featureFlagsProvider.overrideWith(() => _ObdEnabledFlags()),
    ],
  );

  return activeNotifier;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ConsumptionScreen Charging tab visibility (#892 / #1901)', () {
    /// Matches a [Tab] whose `text` carries the given label — the Fuel
    /// section's AppBar title is also 'Fuel', so the bare text finder
    /// would be ambiguous.
    Finder tabLabelled(String label) => find.descendant(
          of: find.byType(Tab),
          matching: find.text(label),
        );

    testWidgets(
      'ICE vehicle active → no Fuel/Charging switcher, no "Charging" [AC1]',
      (tester) async {
        await _pumpScreen(
          tester,
          activeVehicle: _iceVehicle,
          vehicles: const [_iceVehicle],
        );

        // #1901 — a pure-combustion vehicle gets no Fuel/Charging
        // switcher at all: the Fuel section renders the fill-up list
        // directly with no `Tab` widgets.
        expect(find.byType(Tab), findsNothing,
            reason: 'ICE vehicle has no Fuel/Charging switcher');

        // The localised tab labels for Charging must not appear.
        expect(find.text('Charging'), findsNothing);
        expect(find.text('Aufladung'), findsNothing);
        expect(find.text('Laden'), findsNothing);
        expect(find.text('Recharge'), findsNothing);
      },
    );

    testWidgets(
      'EV vehicle active → 2-entry Fuel / Charging switcher [AC2]',
      (tester) async {
        await _pumpScreen(
          tester,
          activeVehicle: _evVehicle,
          vehicles: const [_evVehicle],
        );

        expect(tabLabelled('Fuel'), findsOneWidget);
        expect(
          tabLabelled('Charging'),
          findsOneWidget,
          reason: 'Charging tab must render for EV vehicles',
        );
        // #1901 — Trajets is no longer a tab of this screen.
        expect(find.byType(Tab), findsNWidgets(2));
      },
    );

    testWidgets(
      'Hybrid vehicle active → 2-entry Fuel / Charging switcher [AC3]',
      (tester) async {
        await _pumpScreen(
          tester,
          activeVehicle: _hybridVehicle,
          vehicles: const [_hybridVehicle],
        );

        expect(
          tabLabelled('Charging'),
          findsOneWidget,
          reason: 'Charging tab must render for hybrid vehicles',
        );
        expect(find.byType(Tab), findsNWidgets(2));
      },
    );

    testWidgets(
      'Live switch EV → ICE while on Charging sub-tab: '
      'switcher disappears, no crash, screen falls back to Fuel [AC4]',
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
        expect(tabLabelled('Charging'), findsOneWidget);

        // Tap onto Charging so we're ON the tab that will vanish.
        await tester.tap(tabLabelled('Charging'));
        await tester.pumpAndSettle();

        // Flip the active vehicle to ICE — the switcher should vanish.
        activeNotifier.setVehicle(_iceVehicle);
        await tester.pumpAndSettle();

        // No exception was surfaced by the harness (TestWidgetsFlutter
        // Binding rethrows on pump if one occurred).
        expect(tester.takeException(), isNull);

        // #1901 — a combustion vehicle has no Fuel/Charging switcher
        // at all: the screen falls back to the plain fuel list, the
        // `Tab` widgets and the TabBar are gone.
        expect(find.text('Charging'), findsNothing);
        expect(find.byType(Tab), findsNothing);
        expect(find.byType(TabBar), findsNothing);

        // Flip back to EV — the Fuel/Charging switcher must return and
        // the logs must still be available from the unchanged provider.
        activeNotifier.setVehicle(_evVehicle);
        await tester.pumpAndSettle();
        expect(
          tabLabelled('Charging'),
          findsOneWidget,
          reason: 'Charging tab must come back when vehicle is EV again',
        );
      },
    );
  });
}
