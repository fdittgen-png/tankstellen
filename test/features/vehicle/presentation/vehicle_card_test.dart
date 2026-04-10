import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/presentation/widgets/vehicle_card.dart';

import '../../../helpers/pump_app.dart';

void main() {
  group('VehicleCard', () {
    const evVehicle = VehicleProfile(
      id: 'v1',
      name: 'Model 3',
      type: VehicleType.ev,
      batteryKwh: 60,
      maxChargingKw: 150,
      supportedConnectors: {ConnectorType.ccs, ConnectorType.type2},
    );

    const combustionVehicle = VehicleProfile(
      id: 'v2',
      name: 'Golf',
      type: VehicleType.combustion,
      tankCapacityL: 50,
      preferredFuelType: 'Diesel',
    );

    testWidgets('renders EV name and specs', (tester) async {
      await pumpApp(tester, const VehicleCard(vehicle: evVehicle));

      expect(find.text('Model 3'), findsOneWidget);
      expect(find.textContaining('60'), findsOneWidget);
      expect(find.byIcon(Icons.electric_car), findsOneWidget);
    });

    testWidgets('renders combustion vehicle with tank info', (tester) async {
      await pumpApp(tester, const VehicleCard(vehicle: combustionVehicle));

      expect(find.text('Golf'), findsOneWidget);
      expect(find.textContaining('50'), findsOneWidget);
      expect(find.textContaining('Diesel'), findsOneWidget);
      expect(find.byIcon(Icons.local_gas_station), findsOneWidget);
    });

    testWidgets('shows active check when isActive', (tester) async {
      await pumpApp(
        tester,
        const VehicleCard(vehicle: evVehicle, isActive: true),
      );
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('tapping card invokes onTap', (tester) async {
      var tapped = false;
      await pumpApp(
        tester,
        VehicleCard(vehicle: evVehicle, onTap: () => tapped = true),
      );
      await tester.tap(find.byType(ListTile));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets('popup menu offers Edit and Delete', (tester) async {
      await pumpApp(
        tester,
        VehicleCard(
          vehicle: evVehicle,
          isActive: true,
          onEdit: () {},
          onDelete: () {},
        ),
      );
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });
  });
}
