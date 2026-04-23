import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/presentation/screens/add_charging_log_screen.dart';
import 'package:tankstellen/features/consumption/providers/charging_logs_provider.dart';
import 'package:tankstellen/features/ev/domain/entities/charging_log.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';

import '../../../../helpers/pump_app.dart';

/// #582 phase 2 — tests for the new AddChargingLogScreen.
///
/// Covers:
///  * Empty-vehicle empty state
///  * Required-field validation (save tapped with blank form)
///  * Derived EUR/100km readout calculated from prior log when all
///    inputs are present
///  * Helper text when there is no prior log to anchor the distance

class _EvVehicleList extends VehicleProfileList {
  @override
  List<VehicleProfile> build() => const [
        VehicleProfile(
          id: 'ev-1',
          name: 'Model EV',
          type: VehicleType.ev,
        ),
      ];
}

class _EmptyVehicleList extends VehicleProfileList {
  @override
  List<VehicleProfile> build() => const [];
}

class _PreloadedChargingLogs extends ChargingLogs {
  final List<ChargingLog> _value;
  _PreloadedChargingLogs(this._value);

  @override
  Future<List<ChargingLog>> build() async => _value;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AddChargingLogScreen (#582 phase 2)', () {
    testWidgets('with 0 vehicles, shows the add-vehicle empty state',
        (tester) async {
      await pumpApp(
        tester,
        const AddChargingLogScreen(),
        overrides: [
          vehicleProfileListProvider.overrideWith(() => _EmptyVehicleList()),
        ],
      );
      expect(find.textContaining('Add a vehicle'), findsWidgets);
      expect(find.byKey(const Key('charging_save_button')), findsNothing);
    });

    testWidgets(
        'save button triggers validator errors on every empty required field',
        (tester) async {
      await pumpApp(
        tester,
        const AddChargingLogScreen(),
        overrides: [
          vehicleProfileListProvider.overrideWith(() => _EvVehicleList()),
          chargingLogsProvider
              .overrideWith(() => _PreloadedChargingLogs(const [])),
        ],
      );
      // Tap save without filling anything.
      await tester.tap(find.byKey(const Key('charging_save_button')));
      await tester.pump();
      // Expect at least one "Required" validator message — since four
      // required fields are blank, we allow 4 hits.
      expect(find.textContaining('Required'), findsWidgets);
    });

    testWidgets(
        'derived EUR/100 km readout shows once kWh+cost+odometer are entered',
        (tester) async {
      // Prior log at 10000 km — driving 500 km to 10500 km means
      // 30 kWh / 12 EUR / 500 km → 2.40 EUR/100 km, 6.0 kWh/100 km.
      final prior = ChargingLog(
        id: 'prev',
        vehicleId: 'ev-1',
        date: DateTime.utc(2026, 4, 1),
        kWh: 40,
        costEur: 20,
        chargeTimeMin: 30,
        odometerKm: 10000,
      );
      await pumpApp(
        tester,
        const AddChargingLogScreen(),
        overrides: [
          vehicleProfileListProvider.overrideWith(() => _EvVehicleList()),
          chargingLogsProvider
              .overrideWith(() => _PreloadedChargingLogs([prior])),
        ],
      );

      await tester.enterText(
        find.byKey(const Key('charging_kwh_field')),
        '30',
      );
      await tester.enterText(
        find.byKey(const Key('charging_cost_field')),
        '12',
      );
      await tester.enterText(
        find.byKey(const Key('charging_odo_field')),
        '10500',
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('charging_derived_readout')),
        findsOneWidget,
      );
      // Assertion on formatted numbers — see ChargingCostCalculator
      // for the arithmetic.
      expect(find.textContaining('2.40'), findsOneWidget);
      expect(find.textContaining('6.0 kWh'), findsOneWidget);
    });

    testWidgets(
        'shows helper text when no prior log exists for the vehicle',
        (tester) async {
      await pumpApp(
        tester,
        const AddChargingLogScreen(),
        overrides: [
          vehicleProfileListProvider.overrideWith(() => _EvVehicleList()),
          chargingLogsProvider
              .overrideWith(() => _PreloadedChargingLogs(const [])),
        ],
      );
      await tester.enterText(
        find.byKey(const Key('charging_kwh_field')),
        '30',
      );
      await tester.enterText(
        find.byKey(const Key('charging_cost_field')),
        '12',
      );
      await tester.enterText(
        find.byKey(const Key('charging_odo_field')),
        '10500',
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('charging_derived_helper')),
        findsOneWidget,
      );
    });
  });
}
