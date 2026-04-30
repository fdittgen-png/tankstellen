import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tankstellen/features/consumption/domain/entities/fill_up.dart';
import 'package:tankstellen/features/consumption/presentation/screens/consumption_screen.dart';
import 'package:tankstellen/features/consumption/providers/consumption_providers.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';

import '../../../../helpers/pump_app.dart';

/// #1313 supersedes the original #702 vehicle-shortcut behaviour: the
/// Edit-vehicle IconButton (and the trip-history IconButton) were
/// removed from the Conso AppBar so its action row stays as compact as
/// the other bottom-tab roots. These tests now lock the shortcuts'
/// non-existence so the icons never sneak back via copy-paste.
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
      GoRoute(path: '/vehicles/edit', builder: (_, _) => const SizedBox()),
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

  group('ConsumptionScreen AppBar shortcuts (#1313 removal)', () {
    testWidgets(
      'Edit-vehicle IconButton is NOT rendered when a vehicle is active',
      (tester) async {
        await _pump(tester, withActiveVehicle: true);
        expect(
          find.byKey(const Key('open_active_vehicle')),
          findsNothing,
          reason: '#1313 removed the active-vehicle shortcut from the '
              'Conso AppBar; only export-CSV + carbon-leaf remain.',
        );
      },
    );

    testWidgets(
      'Trip-history IconButton is NOT rendered (#1313 removal)',
      (tester) async {
        await _pump(tester, withActiveVehicle: true);
        expect(
          find.byKey(const Key('open_trip_history')),
          findsNothing,
          reason: '#1313 removed the trip-history shortcut from the '
              'Conso AppBar; the Trajets sub-tab is the canonical entry.',
        );
      },
    );

    testWidgets(
      'Neither shortcut renders without an active vehicle either',
      (tester) async {
        await _pump(tester, withActiveVehicle: false);
        expect(find.byKey(const Key('open_active_vehicle')), findsNothing);
        expect(find.byKey(const Key('open_trip_history')), findsNothing);
      },
    );
  });
}
