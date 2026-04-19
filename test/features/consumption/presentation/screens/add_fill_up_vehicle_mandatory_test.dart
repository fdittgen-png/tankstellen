import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/presentation/screens/add_fill_up_screen.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';

import '../../../../helpers/pump_app.dart';

/// Vehicle list stub — one combustion car, no configured fuel.
class _OneVehicleList extends VehicleProfileList {
  @override
  List<VehicleProfile> build() => const [
        VehicleProfile(
          id: 'car-1',
          name: 'Daily Driver',
          type: VehicleType.combustion,
        ),
      ];
}

class _EmptyVehicleList extends VehicleProfileList {
  @override
  List<VehicleProfile> build() => const [];
}

void main() {
  group('AddFillUpScreen vehicle-mandatory (#713)', () {
    testWidgets(
        'with 0 vehicles shows the empty-state CTA and no form dropdowns',
        (tester) async {
      await pumpApp(
        tester,
        const AddFillUpScreen(),
        overrides: [
          vehicleProfileListProvider.overrideWith(() => _EmptyVehicleList()),
        ],
      );

      expect(find.textContaining('Add a vehicle'), findsWidgets);
      expect(find.byType(DropdownButtonFormField<String>), findsNothing,
          reason: 'No vehicle dropdown when zero vehicles exist');
    });

    testWidgets(
        'with >=1 vehicle, the dropdown has NO "no vehicle" null option',
        (tester) async {
      await pumpApp(
        tester,
        const AddFillUpScreen(),
        overrides: [
          vehicleProfileListProvider.overrideWith(() => _OneVehicleList()),
        ],
      );

      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget,
          reason: 'Vehicle picker is rendered as a non-nullable dropdown');
      // The historical "No vehicle" / "Aucun véhicule" option must not
      // appear anywhere — vehicle is mandatory.
      expect(find.text('No vehicle'), findsNothing);
      expect(find.text('Aucun véhicule'), findsNothing);
    });

    testWidgets('default vehicle is pre-selected on first build',
        (tester) async {
      await pumpApp(
        tester,
        const AddFillUpScreen(),
        overrides: [
          vehicleProfileListProvider.overrideWith(() => _OneVehicleList()),
        ],
      );

      // The only vehicle must be displayed in the picker value.
      expect(find.text('Daily Driver'), findsWidgets);
    });
  });
}
