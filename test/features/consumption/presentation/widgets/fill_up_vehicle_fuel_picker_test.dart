import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/fill_up_vehicle_fuel_picker.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// Widget tests for [FillUpVehicleFuelPicker] (#713 / #563 extraction).
///
/// The picker constrains the dropdown options to the vehicle's
/// compatibility family (a petrol car shows e10/e5/e98/e85, a diesel
/// shows diesel/dieselPremium, an EV / LPG / CNG / H2 shows only its
/// single applicable fuel). When the inbound `fuelType` is not in the
/// compatible set, the picker silently lands on `compatible.first` so
/// the form never opens with an impossible option pre-selected.
void main() {
  const petrolVehicle = VehicleProfile(
    id: 'veh-petrol',
    name: 'Peugeot 107',
    type: VehicleType.combustion,
    preferredFuelType: 'e10',
  );

  const dieselVehicle = VehicleProfile(
    id: 'veh-diesel',
    name: 'Renault Megane',
    type: VehicleType.combustion,
    preferredFuelType: 'diesel',
  );

  const evVehicle = VehicleProfile(
    id: 'veh-ev',
    name: 'Renault Zoe',
    type: VehicleType.ev,
  );

  Future<void> pumpPicker(
    WidgetTester tester, {
    required List<VehicleProfile> vehicles,
    required String vehicleId,
    required FuelType fuelType,
    ValueChanged<FuelType>? onChanged,
    VoidCallback? onOpenVehicle,
    Locale locale = const Locale('en'),
  }) {
    return tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: FillUpVehicleFuelPicker(
              vehicles: vehicles,
              vehicleId: vehicleId,
              fuelType: fuelType,
              onChanged: onChanged ?? (_) {},
              onOpenVehicle: onOpenVehicle ?? () {},
            ),
          ),
        ),
      ),
    );
  }

  testWidgets(
      'petrol vehicle exposes only petrol-family options (e10/e5/e98/e85)',
      (tester) async {
    await pumpPicker(
      tester,
      vehicles: const [petrolVehicle],
      vehicleId: petrolVehicle.id,
      fuelType: FuelType.e10,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<FuelType>));
    await tester.pumpAndSettle();

    // Petrol family — the four interchangeable petrol grades all show.
    expect(find.text(FuelType.e10.displayName), findsWidgets);
    expect(find.text(FuelType.e5.displayName), findsWidgets);
    expect(find.text(FuelType.e98.displayName), findsWidgets);
    expect(find.text(FuelType.e85.displayName), findsWidgets);

    // Cross-family options must NOT appear — guarding against the
    // pre-#713 behaviour where the picker offered every fuel.
    expect(find.text(FuelType.diesel.displayName), findsNothing);
    expect(find.text(FuelType.electric.displayName), findsNothing);
    expect(find.text(FuelType.lpg.displayName), findsNothing);
  });

  testWidgets(
      'diesel vehicle exposes only diesel-family options '
      '(diesel + dieselPremium)', (tester) async {
    await pumpPicker(
      tester,
      vehicles: const [dieselVehicle],
      vehicleId: dieselVehicle.id,
      fuelType: FuelType.diesel,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<FuelType>));
    await tester.pumpAndSettle();

    expect(find.text(FuelType.diesel.displayName), findsWidgets);
    expect(find.text(FuelType.dieselPremium.displayName), findsWidgets);

    // Petrol options must NOT appear on a diesel — physically incompatible.
    expect(find.text(FuelType.e10.displayName), findsNothing);
    expect(find.text(FuelType.e85.displayName), findsNothing);
    expect(find.text(FuelType.electric.displayName), findsNothing);
  });

  testWidgets(
      'EV vehicle exposes only the single electric option', (tester) async {
    await pumpPicker(
      tester,
      vehicles: const [evVehicle],
      vehicleId: evVehicle.id,
      fuelType: FuelType.electric,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<FuelType>));
    await tester.pumpAndSettle();

    expect(find.text(FuelType.electric.displayName), findsWidgets);
    expect(find.text(FuelType.diesel.displayName), findsNothing);
    expect(find.text(FuelType.e10.displayName), findsNothing);
  });

  testWidgets(
      'incompatible inbound fuelType silently falls back to compatible.first',
      (tester) async {
    // A diesel vehicle but the form was loaded with a stale petrol pre-fill.
    // The picker must NOT crash — it just lands on `compatible.first`
    // (`FuelType.diesel`, since compatibleFuelsFor pins primary first).
    await pumpPicker(
      tester,
      vehicles: const [dieselVehicle],
      vehicleId: dieselVehicle.id,
      fuelType: FuelType.e10,
    );
    await tester.pumpAndSettle();

    final dropdown = tester.widget<DropdownButtonFormField<FuelType>>(
      find.byType(DropdownButtonFormField<FuelType>),
    );
    expect(
      dropdown.initialValue,
      FuelType.diesel,
      reason:
          'When the inbound fuel is not in the vehicle\'s compatible '
          'family, the picker must drop to compatible.first instead of '
          'showing an impossible option (or crashing).',
    );
  });

  testWidgets(
      'picking a different compatible fuel fires onChanged with the new fuel',
      (tester) async {
    FuelType? picked;
    await pumpPicker(
      tester,
      vehicles: const [petrolVehicle],
      vehicleId: petrolVehicle.id,
      fuelType: FuelType.e10,
      onChanged: (f) => picked = f,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<FuelType>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(FuelType.e85.displayName).last);
    await tester.pumpAndSettle();

    expect(picked, FuelType.e85,
        reason:
            'A flex-fuel petrol driver must be able to log E85 even if '
            'the profile preference is E10 — the override is the whole '
            'point of #713.');
  });

  testWidgets('open-in-new IconButton fires onOpenVehicle', (tester) async {
    var taps = 0;
    await pumpPicker(
      tester,
      vehicles: const [petrolVehicle],
      vehicleId: petrolVehicle.id,
      fuelType: FuelType.e10,
      onOpenVehicle: () => taps++,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.open_in_new));
    await tester.pumpAndSettle();

    expect(taps, 1,
        reason:
            'The trailing IconButton is the deep-link to the vehicle '
            'editor; the picker must forward the tap verbatim.');
  });

  testWidgets(
      'label embeds the resolved vehicle name so multi-vehicle users '
      'see which one they are configuring', (tester) async {
    await pumpPicker(
      tester,
      vehicles: const [petrolVehicle, dieselVehicle],
      vehicleId: dieselVehicle.id,
      fuelType: FuelType.diesel,
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Fuel type • Renault Megane'),
      findsOneWidget,
      reason: 'Label is `${'fuelType'} • ${'vehicle.name'}`',
    );
  });
}
