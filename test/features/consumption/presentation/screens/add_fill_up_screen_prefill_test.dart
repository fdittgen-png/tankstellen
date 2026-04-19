import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/presentation/screens/add_fill_up_screen.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/fill_up_numeric_field.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';

import '../../../../helpers/pump_app.dart';

/// Seed one vehicle so the AddFillUpScreen does NOT show its
/// "Add a vehicle first" empty-state CTA (#706).
class _StubVehicleList extends VehicleProfileList {
  @override
  List<VehicleProfile> build() => const [
        VehicleProfile(
          id: 'stub-vehicle',
          name: 'Stub Car',
          type: VehicleType.combustion,
        ),
      ];
}

final _withVehicle = <Object>[
  vehicleProfileListProvider.overrideWith(() => _StubVehicleList()),
];

Finder _fieldByLabel(String label) => find.ancestor(
      of: find.text(label),
      matching: find.byType(FillUpNumericField),
    );

TextField _textFieldFor(WidgetTester tester, String label) {
  final fillUpField = tester.widget<FillUpNumericField>(_fieldByLabel(label));
  return tester.widget<TextField>(
    find.descendant(
      of: find.byWidget(fillUpField),
      matching: find.byType(TextField),
    ),
  );
}

void main() {
  group('AddFillUpScreen pre-fill (#581)', () {
    testWidgets('station name card shown when stationName passed',
        (tester) async {
      await pumpApp(
        tester,
        const AddFillUpScreen(
          stationId: 'abc',
          stationName: 'Total Castelnau',
        ),
        overrides: _withVehicle,
      );

      expect(find.text('Total Castelnau'), findsOneWidget);
      expect(find.text('Station pre-filled'), findsOneWidget);
    });

    testWidgets('preFilledFuelType is selected in the dropdown',
        (tester) async {
      await pumpApp(
        tester,
        const AddFillUpScreen(
          stationId: 'abc',
          stationName: 'Total',
          preFilledFuelType: FuelType.diesel,
        ),
        overrides: _withVehicle,
      );

      // No vehicle auto-selects (no profile default, no active);
      // the fuel dropdown shows the apiValue uppercased.
      expect(find.text('DIESEL'), findsOneWidget);
    });

    testWidgets(
        'pre-filled price auto-computes total cost when liters entered',
        (tester) async {
      await pumpApp(
        tester,
        const AddFillUpScreen(
          stationId: 'abc',
          stationName: 'Total',
          preFilledFuelType: FuelType.e10,
          preFilledPricePerLiter: 1.859,
        ),
        overrides: _withVehicle,
      );

      final litersField = _textFieldFor(tester, 'Liters');
      litersField.controller!.text = '40';
      await tester.pump();

      final costField = _textFieldFor(tester, 'Total cost');
      // 40 * 1.859 = 74.36
      expect(costField.controller!.text, '74.36');
    });

    testWidgets('auto-cost does not clobber a manually typed cost',
        (tester) async {
      await pumpApp(
        tester,
        const AddFillUpScreen(
          stationId: 'abc',
          stationName: 'Total',
          preFilledFuelType: FuelType.e10,
          preFilledPricePerLiter: 2.0,
        ),
        overrides: _withVehicle,
      );

      final costField = _textFieldFor(tester, 'Total cost');
      costField.controller!.text = '99.99'; // user typed
      await tester.pump();

      final litersField = _textFieldFor(tester, 'Liters');
      litersField.controller!.text = '10';
      await tester.pump();

      // Manual 99.99 must not be overwritten by auto 20.00.
      expect(costField.controller!.text, '99.99');
    });

    testWidgets('no auto-compute when preFilledPricePerLiter is null',
        (tester) async {
      await pumpApp(
        tester,
        const AddFillUpScreen(
          stationId: 'abc',
          stationName: 'Total',
        ),
        overrides: _withVehicle,
      );

      final litersField = _textFieldFor(tester, 'Liters');
      litersField.controller!.text = '40';
      await tester.pump();

      final costField = _textFieldFor(tester, 'Total cost');
      expect(costField.controller!.text, '');
    });

    testWidgets('default fuel type is e10 when no pre-fill',
        (tester) async {
      await pumpApp(
        tester,
        const AddFillUpScreen(),
        overrides: _withVehicle,
      );
      // With a vehicle pre-selected, the fuel info card shows the
      // default e10 fuel type.
      expect(find.textContaining('E10'), findsWidgets);
    });
  });
}
