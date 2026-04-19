import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tankstellen/features/consumption/domain/entities/fill_up.dart';
import 'package:tankstellen/features/consumption/presentation/screens/consumption_screen.dart';
import 'package:tankstellen/features/consumption/providers/consumption_providers.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';

import '../../../../helpers/pump_app.dart';

/// #702: the consumption tab should shortcut to the active vehicle's
/// edit screen so the user doesn't have to go via Settings →
/// Vehicles when the log is the thing in front of them.
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

String? _lastRoute;
Object? _lastExtra;

Future<void> _pump(
  WidgetTester tester, {
  required bool withActiveVehicle,
}) async {
  _lastRoute = null;
  _lastExtra = null;
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
      GoRoute(
        path: '/vehicles/edit',
        builder: (_, state) {
          _lastRoute = '/vehicles/edit';
          _lastExtra = state.extra;
          return const SizedBox();
        },
      ),
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

  group('ConsumptionScreen vehicle shortcut (#702)', () {
    testWidgets('renders an Edit-vehicle IconButton when a vehicle is active',
        (tester) async {
      await _pump(tester, withActiveVehicle: true);
      expect(find.byKey(const Key('open_active_vehicle')), findsOneWidget);
    });

    testWidgets('tapping the Edit-vehicle button routes to /vehicles/edit '
        'with the active vehicle id as extra', (tester) async {
      await _pump(tester, withActiveVehicle: true);
      await tester.tap(find.byKey(const Key('open_active_vehicle')));
      await tester.pumpAndSettle();
      expect(_lastRoute, '/vehicles/edit');
      expect(_lastExtra, 'daily-driver');
    });

    testWidgets('hides the shortcut when no vehicle is active',
        (tester) async {
      await _pump(tester, withActiveVehicle: false);
      expect(find.byKey(const Key('open_active_vehicle')), findsNothing);
    });
  });
}
