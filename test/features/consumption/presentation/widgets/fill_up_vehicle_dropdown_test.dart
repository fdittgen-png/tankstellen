import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/fill_up_vehicle_dropdown.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// Tests for [FillUpVehicleDropdown] (#727 extract from
/// `add_fill_up_screen.dart`). The parent screen's setState + fuel
/// derivation happen in the callback; the widget itself just renders
/// the dropdown and forwards the picked value + resolved
/// [VehicleProfile].
void main() {
  const vehicles = <VehicleProfile>[
    VehicleProfile(id: 'veh-peugeot', name: 'Peugeot 107'),
    VehicleProfile(id: 'veh-renault', name: 'Renault Clio'),
  ];

  Future<void> pumpDropdown(
    WidgetTester tester, {
    String? vehicleId,
    void Function(String id, VehicleProfile selected)? onChanged,
    Locale locale = const Locale('en'),
  }) {
    return tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Form(
            child: FillUpVehicleDropdown(
              vehicleId: vehicleId,
              vehicles: vehicles,
              onChanged: onChanged ?? (_, _) {},
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('renders the localised label and car icon', (tester) async {
    await pumpDropdown(tester, vehicleId: 'veh-peugeot');
    await tester.pumpAndSettle();

    expect(find.text('Vehicle'), findsOneWidget);
    expect(find.byIcon(Icons.directions_car_outlined), findsOneWidget);
  });

  testWidgets('preselects the initial vehicle', (tester) async {
    await pumpDropdown(tester, vehicleId: 'veh-peugeot');
    await tester.pumpAndSettle();

    expect(find.text('Peugeot 107'), findsOneWidget);
  });

  testWidgets(
      'forwards both id AND resolved VehicleProfile on change — '
      'the parent screen needs the VehicleProfile to derive the default fuel',
      (tester) async {
    String? capturedId;
    VehicleProfile? capturedProfile;
    await pumpDropdown(
      tester,
      vehicleId: 'veh-peugeot',
      onChanged: (id, profile) {
        capturedId = id;
        capturedProfile = profile;
      },
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FillUpVehicleDropdown));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Renault Clio').last);
    await tester.pumpAndSettle();

    expect(capturedId, 'veh-renault');
    expect(capturedProfile?.name, 'Renault Clio');
  });

  testWidgets(
      'validator rejects a null selection (the field is mandatory per #713)',
      (tester) async {
    final formKey = GlobalKey<FormState>();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Form(
            key: formKey,
            child: FillUpVehicleDropdown(
              vehicleId: null,
              vehicles: vehicles,
              onChanged: (_, _) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    // ARB key `fillUpVehicleRequired` resolves to this on English locale.
    expect(find.text('Vehicle is required'), findsOneWidget);
  });
}
