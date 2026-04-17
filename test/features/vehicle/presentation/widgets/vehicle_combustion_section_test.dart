import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/vehicle/presentation/widgets/vehicle_combustion_section.dart';

import '../../../../helpers/pump_app.dart';

/// Rejects empty/non-numeric input — matches the shape of the real
/// validator the EditVehicleScreen hands down.
String? _requireNumber(String? v) {
  if (v == null || v.trim().isEmpty) return 'Required';
  if (double.tryParse(v.replaceAll(',', '.')) == null) {
    return 'Not a number';
  }
  return null;
}

void main() {
  group('VehicleCombustionSection', () {
    testWidgets('renders section title, tank field, fuel type field',
        (tester) async {
      final tank = TextEditingController();
      final fuel = TextEditingController();
      addTearDown(tank.dispose);
      addTearDown(fuel.dispose);

      await pumpApp(
        tester,
        VehicleCombustionSection(
          tankController: tank,
          fuelTypeController: fuel,
          numberValidator: _requireNumber,
        ),
      );

      expect(find.text('Combustion'), findsOneWidget);
      expect(find.text('Tank capacity (L)'), findsOneWidget);
      expect(find.text('Preferred fuel'), findsOneWidget);
    });

    testWidgets('user-typed tank capacity flows to the controller',
        (tester) async {
      final tank = TextEditingController();
      final fuel = TextEditingController();
      addTearDown(tank.dispose);
      addTearDown(fuel.dispose);

      await pumpApp(
        tester,
        VehicleCombustionSection(
          tankController: tank,
          fuelTypeController: fuel,
          numberValidator: _requireNumber,
        ),
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Tank capacity (L)'),
        '55',
      );
      expect(tank.text, '55');
    });

    testWidgets('user-typed preferred fuel flows to the controller',
        (tester) async {
      final tank = TextEditingController();
      final fuel = TextEditingController();
      addTearDown(tank.dispose);
      addTearDown(fuel.dispose);

      await pumpApp(
        tester,
        VehicleCombustionSection(
          tankController: tank,
          fuelTypeController: fuel,
          numberValidator: _requireNumber,
        ),
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Preferred fuel'),
        'Diesel',
      );
      expect(fuel.text, 'Diesel');
    });

    testWidgets('tank field runs the injected numberValidator on submit',
        (tester) async {
      final tank = TextEditingController();
      final fuel = TextEditingController();
      final formKey = GlobalKey<FormState>();
      addTearDown(tank.dispose);
      addTearDown(fuel.dispose);

      await pumpApp(
        tester,
        Form(
          key: formKey,
          child: VehicleCombustionSection(
            tankController: tank,
            fuelTypeController: fuel,
            numberValidator: _requireNumber,
          ),
        ),
      );

      // Empty on submit → validator fires.
      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Required'), findsOneWidget);

      // Non-numeric fails too.
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Tank capacity (L)'),
        'abc',
      );
      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Not a number'), findsOneWidget);

      // Valid number passes.
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Tank capacity (L)'),
        '55',
      );
      expect(formKey.currentState!.validate(), isTrue);
    });

    testWidgets('fuel type field shows its example hint text',
        (tester) async {
      // The hint "e.g. Diesel, E10" is a small UX contract —
      // pin it so a casual edit doesn't accidentally drop the
      // example that users rely on to know what format to type.
      final tank = TextEditingController();
      final fuel = TextEditingController();
      addTearDown(tank.dispose);
      addTearDown(fuel.dispose);

      await pumpApp(
        tester,
        VehicleCombustionSection(
          tankController: tank,
          fuelTypeController: fuel,
          numberValidator: _requireNumber,
        ),
      );

      expect(find.text('e.g. Diesel, E10'), findsOneWidget);
    });
  });
}
