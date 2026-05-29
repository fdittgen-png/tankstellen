// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tankstellen/features/consumption/data/trip_history_repository.dart';
import 'package:tankstellen/features/consumption/domain/entities/fill_up.dart';
import 'package:tankstellen/features/consumption/presentation/screens/consumption_screen.dart';
import 'package:tankstellen/features/consumption/providers/charging_logs_provider.dart';
import 'package:tankstellen/features/consumption/providers/consumption_providers.dart';
import 'package:tankstellen/features/consumption/providers/trip_history_provider.dart';
import 'package:tankstellen/features/ev/domain/entities/charging_log.dart';
import 'package:tankstellen/features/feature_management/application/feature_flags_provider.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';

import '../../../../helpers/pump_app.dart';

/// #2223 — the vehicles (car) entry point moved from the trailing
/// AppBar actions to the leading slot, so the car icon reads as part
/// of the title. These tests guard that placement: the `open_vehicles`
/// IconButton is the AppBar `leading`, sits left of the trailing
/// actions, keeps its `/vehicles` target, and is not duplicated among
/// the trailing actions. The original trailing actions (export,
/// settings) are unaffected.
class _ObdEnabledFlags extends FeatureFlags {
  @override
  Set<Feature> build() => <Feature>{
        Feature.showConsumptionTab,
        Feature.obd2TripRecording,
      };
}

class _FixedFillUpList extends FillUpList {
  @override
  List<FillUp> build() => const [];
}

class _FixedChargingLogs extends ChargingLogs {
  @override
  Future<List<ChargingLog>> build() async => const [];
}

class _FixedActiveVehicle extends ActiveVehicleProfile {
  @override
  VehicleProfile? build() => const VehicleProfile(
        id: 'daily-driver',
        name: 'Daily Driver',
        type: VehicleType.combustion,
      );
}

class _FixedVehicleProfileList extends VehicleProfileList {
  @override
  List<VehicleProfile> build() => const [];
}

class _FixedTripHistoryList extends TripHistoryList {
  @override
  List<TripHistoryEntry> build() => const [];
}

String? _lastVehiclesVisit;

Future<void> _pumpTrajets(WidgetTester tester) async {
  _lastVehiclesVisit = null;
  final router = GoRouter(
    initialLocation: '/trajets-tab',
    routes: [
      GoRoute(
        path: '/trajets-tab',
        builder: (_, _) => const ConsumptionScreen(
          section: ConsumptionSection.trajets,
        ),
      ),
      GoRoute(
        path: '/consumption/pick-station',
        builder: (_, _) => const SizedBox(),
      ),
      GoRoute(path: '/carbon', builder: (_, _) => const SizedBox()),
      GoRoute(
        path: '/vehicles',
        builder: (_, _) {
          _lastVehiclesVisit = '/vehicles';
          return const Scaffold(body: Text('VehiclesStub'));
        },
      ),
    ],
  );

  await pumpApp(
    tester,
    MaterialApp.router(routerConfig: router),
    overrides: [
      fillUpListProvider.overrideWith(() => _FixedFillUpList()),
      chargingLogsProvider.overrideWith(() => _FixedChargingLogs()),
      activeVehicleProfileProvider.overrideWith(() => _FixedActiveVehicle()),
      vehicleProfileListProvider.overrideWith(() => _FixedVehicleProfileList()),
      tripHistoryListProvider.overrideWith(() => _FixedTripHistoryList()),
      featureFlagsProvider.overrideWith(() => _ObdEnabledFlags()),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ConsumptionScreen vehicles icon in title/leading (#2223)', () {
    testWidgets('car icon is the AppBar leading widget', (tester) async {
      await _pumpTrajets(tester);

      // Present exactly once (the leading slot — not duplicated in
      // the trailing actions).
      expect(find.byKey(const Key('open_vehicles')), findsOneWidget);

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.leading, isA<IconButton>());
      expect((appBar.leading! as IconButton).key, const Key('open_vehicles'));

      // It carries the car icon.
      expect(
        find.descendant(
          of: find.byKey(const Key('open_vehicles')),
          matching: find.byIcon(Icons.directions_car_outlined),
        ),
        findsOneWidget,
      );
    });

    testWidgets('car icon sits to the left of the trailing actions',
        (tester) async {
      await _pumpTrajets(tester);
      final iconX =
          tester.getCenter(find.byKey(const Key('open_vehicles'))).dx;
      final exportX =
          tester.getCenter(find.byKey(const Key('export_backup'))).dx;
      // Leading is on the start (left) side; export is a trailing action.
      expect(iconX, lessThan(exportX));
    });

    testWidgets('trailing export action is unaffected', (tester) async {
      await _pumpTrajets(tester);
      expect(find.byKey(const Key('export_backup')), findsOneWidget);
    });

    testWidgets('tapping the car icon still navigates to /vehicles',
        (tester) async {
      await _pumpTrajets(tester);
      await tester.tap(find.byKey(const Key('open_vehicles')));
      await tester.pumpAndSettle();
      expect(_lastVehiclesVisit, '/vehicles');
    });
  });
}
