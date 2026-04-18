import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
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

    testWidgets(
      'picking a fuel from the dropdown writes the canonical apiValue '
      'to the controller (typed FuelType source of truth, #695)',
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

        // Open the dropdown.
        await tester.tap(find.byType(DropdownButtonFormField<FuelType?>));
        await tester.pumpAndSettle();
        // Pick DIESEL (upper-case label from the dropdown).
        await tester.tap(find.text('DIESEL').last);
        await tester.pumpAndSettle();

        expect(fuel.text, FuelType.diesel.apiValue,
            reason:
                'Dropdown must write the canonical lower-case apiValue so '
                'the rest of the app can parse it via FuelType.fromString');
      },
    );

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

    testWidgets(
      'fuel picker offers the same combustion FuelTypes as the search form '
      'and does NOT expose Electric or the synthetic "all" option (#695)',
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

        await tester.tap(find.byType(DropdownButtonFormField<FuelType?>));
        await tester.pumpAndSettle();

        for (final f in [
          FuelType.e5,
          FuelType.e10,
          FuelType.e98,
          FuelType.diesel,
          FuelType.dieselPremium,
          FuelType.e85,
          FuelType.lpg,
          FuelType.cng,
        ]) {
          expect(find.text(f.apiValue.toUpperCase()), findsWidgets,
              reason: '${f.apiValue} must appear as an option');
        }
        expect(find.text(FuelType.electric.apiValue.toUpperCase()),
            findsNothing,
            reason: 'Electric is configured via the EV section, not here');
        expect(find.text(FuelType.all.apiValue.toUpperCase()), findsNothing,
            reason: 'The synthetic "all" sentinel must not be pickable');
      },
    );
  });
}
