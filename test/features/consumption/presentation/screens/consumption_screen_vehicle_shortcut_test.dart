import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tankstellen/features/consumption/domain/entities/fill_up.dart';
import 'package:tankstellen/features/consumption/presentation/screens/consumption_screen.dart';
import 'package:tankstellen/features/consumption/providers/consumption_providers.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';

import '../../../../helpers/pump_app.dart';

/// #702 originally surfaced an "edit vehicle" shortcut in the
/// ConsumptionScreen AppBar. #1313 removed it (alongside the
/// trip-history shortcut) — the Conso title bar is now reserved for
/// export-CSV, the carbon dashboard, and the OBD2 status chip.
/// This test guards the deletion: regardless of whether a vehicle is
/// active, the shortcut must NOT render.
class _FixedFillUpList extends FillUpList {
  @override
  List<FillUp> build() => const [];
}

class _OneActiveVehicle extends ActiveVehicleProfile {
  @override
  VehicleProfile? build() => const VehicleProfile(
        id: 'daily-driver',
        name: 'Daily Driver',
        type: VehicleType.combustion,
      );
}

class _NoActiveVehicle extends ActiveVehicleProfile {
  @override
  VehicleProfile? build() => null;
}

Future<void> _pump(
  WidgetTester tester, {
  required bool withActiveVehicle,
}) async {
  final router = GoRouter(
    initialLocation: '/consumption',
    routes: [
      GoRoute(
        path: '/consumption',
        builder: (_, _) => const ConsumptionScreen(),
      ),
      GoRoute(path: '/consumption/add', builder: (_, _) => const SizedBox()),
      GoRoute(path: '/consumption/pick-station',
          builder: (_, _) => const SizedBox()),
      GoRoute(path: '/carbon', builder: (_, _) => const SizedBox()),
    ],
  );
  await pumpApp(
    tester,
    MaterialApp.router(routerConfig: router),
    overrides: [
      fillUpListProvider.overrideWith(() => _FixedFillUpList()),
      activeVehicleProfileProvider.overrideWith(
        () => withActiveVehicle ? _OneActiveVehicle() : _NoActiveVehicle(),
      ),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ConsumptionScreen vehicle shortcut removed (#1313)', () {
    testWidgets('no Edit-vehicle IconButton when a vehicle is active',
        (tester) async {
      await _pump(tester, withActiveVehicle: true);
      expect(find.byKey(const Key('open_active_vehicle')), findsNothing);
    });

    testWidgets('no Edit-vehicle IconButton when no vehicle is active',
        (tester) async {
      await _pump(tester, withActiveVehicle: false);
      expect(find.byKey(const Key('open_active_vehicle')), findsNothing);
    });

    testWidgets('no trip-history IconButton (the Trajets sub-tab covers it)',
        (tester) async {
      await _pump(tester, withActiveVehicle: true);
      expect(find.byKey(const Key('open_trip_history')), findsNothing);
    });
  });
}
