// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
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
  /// Helper that builds the section with the #2885 multi-fuel params.
  Widget buildSection({
    required TextEditingController tank,
    required TextEditingController fuel,
    TextEditingController? power,
    bool multiFuelCapable = false,
    ValueChanged<bool>? onMultiFuel,
    ValueChanged<FuelType?>? onFuelChanged,
  }) =>
      VehicleCombustionSection(
        tankController: tank,
        fuelTypeController: fuel,
        // Epic #3015 — an empty power controller when the caller doesn't
        // care about the field. Tests that exercise the power field pass
        // their own.
        powerKwController: power ?? TextEditingController(),
        multiFuelCapable: multiFuelCapable,
        onMultiFuelCapableChanged: onMultiFuel ?? (_) {},
        onFuelTypeChanged: onFuelChanged ?? (_) {},
        numberValidator: _requireNumber,
      );

  group('VehicleCombustionSection', () {
    testWidgets('renders section title, tank field, fuel type field',
        (tester) async {
      final tank = TextEditingController();
      final fuel = TextEditingController();
      addTearDown(tank.dispose);
      addTearDown(fuel.dispose);

      await pumpApp(tester, buildSection(tank: tank, fuel: fuel));

      expect(find.text('Combustion'), findsOneWidget);
      expect(find.text('Tank capacity (L)'), findsOneWidget);
      expect(find.text('Preferred fuel'), findsOneWidget);
    });

    testWidgets(
      '#2885 — multi-fuel switch is SHOWN for E10 and E85 but HIDDEN for '
      'diesel / E5 (single-fuel grades)',
      (tester) async {
        const switchKey = Key('vehicle_multi_fuel_capable_switch');

        for (final fuelCode in ['e10', 'e85']) {
          final tank = TextEditingController();
          final fuel = TextEditingController(text: fuelCode);
          addTearDown(tank.dispose);
          addTearDown(fuel.dispose);
          await pumpApp(tester, buildSection(tank: tank, fuel: fuel));
          expect(find.byKey(switchKey), findsOneWidget,
              reason: '$fuelCode is a flex-fuel grade — offer the switch');
        }

        for (final fuelCode in ['diesel', 'e5', 'lpg']) {
          final tank = TextEditingController();
          final fuel = TextEditingController(text: fuelCode);
          addTearDown(tank.dispose);
          addTearDown(fuel.dispose);
          await pumpApp(tester, buildSection(tank: tank, fuel: fuel));
          expect(find.byKey(switchKey), findsNothing,
              reason: '$fuelCode is single-fuel — hide the switch');
        }
      },
    );

    testWidgets('#2885 — toggling the multi-fuel switch fires the callback',
        (tester) async {
      final tank = TextEditingController();
      final fuel = TextEditingController(text: 'e85');
      addTearDown(tank.dispose);
      addTearDown(fuel.dispose);
      bool? captured;

      await pumpApp(
        tester,
        buildSection(
          tank: tank,
          fuel: fuel,
          multiFuelCapable: false,
          onMultiFuel: (v) => captured = v,
        ),
      );

      await tester.tap(find.byKey(const Key('vehicle_multi_fuel_capable_switch')));
      await tester.pump();
      expect(captured, isTrue);
    });

    testWidgets(
      '#2885 — changing the fuel dropdown notifies onFuelTypeChanged',
      (tester) async {
        final tank = TextEditingController();
        final fuel = TextEditingController(text: 'e10');
        addTearDown(tank.dispose);
        addTearDown(fuel.dispose);
        FuelType? changed;

        await pumpApp(
          tester,
          buildSection(
            tank: tank,
            fuel: fuel,
            onFuelChanged: (v) => changed = v,
          ),
        );

        await tester.tap(find.byType(DropdownButtonFormField<FuelType?>));
        await tester.pumpAndSettle();
        await tester.tap(find.text(FuelType.diesel.displayName).last);
        await tester.pumpAndSettle();

        expect(changed, equals(FuelType.diesel));
        expect(fuel.text, FuelType.diesel.apiValue);
      },
    );

    testWidgets('user-typed tank capacity flows to the controller',
        (tester) async {
      final tank = TextEditingController();
      final fuel = TextEditingController();
      addTearDown(tank.dispose);
      addTearDown(fuel.dispose);

      await pumpApp(tester, buildSection(tank: tank, fuel: fuel));

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

        await pumpApp(tester, buildSection(tank: tank, fuel: fuel));

        // Open the dropdown.
        await tester.tap(find.byType(DropdownButtonFormField<FuelType?>));
        await tester.pumpAndSettle();
        // Pick "Diesel" (displayName from the shared dropdown, #713).
        await tester.tap(find.text(FuelType.diesel.displayName).last);
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
          child: buildSection(tank: tank, fuel: fuel),
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

        await pumpApp(tester, buildSection(tank: tank, fuel: fuel));

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
          expect(find.text(f.displayName), findsWidgets,
              reason: '${f.displayName} must appear as an option');
        }
        expect(find.text(FuelType.electric.displayName), findsNothing,
            reason: 'Electric is configured via the EV section, not here');
        expect(find.text(FuelType.all.displayName), findsNothing,
            reason: 'The synthetic "all" sentinel must not be pickable');
      },
    );
  });
}
