import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/presentation/widgets/vehicle_drivetrain_section.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

Future<void> _pump(
  WidgetTester tester, {
  required VehicleType type,
}) async {
  final batteryCtrl = TextEditingController();
  final maxKwCtrl = TextEditingController();
  final minSocCtrl = TextEditingController(text: '20');
  final maxSocCtrl = TextEditingController(text: '80');
  final tankCtrl = TextEditingController();
  final fuelTypeCtrl = TextEditingController(text: 'e10');
  addTearDown(() {
    batteryCtrl.dispose();
    maxKwCtrl.dispose();
    minSocCtrl.dispose();
    maxSocCtrl.dispose();
    tankCtrl.dispose();
    fuelTypeCtrl.dispose();
  });

  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: Form(
            child: VehicleDrivetrainSection(
              type: type,
              onTypeChanged: (_) {},
              accent: Colors.blue,
              batteryController: batteryCtrl,
              maxChargingKwController: maxKwCtrl,
              minSocController: minSocCtrl,
              maxSocController: maxSocCtrl,
              connectors: const {},
              onToggleConnector: (_) {},
              tankController: tankCtrl,
              fuelTypeController: fuelTypeCtrl,
              numberValidator: (_) => null,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('VehicleDrivetrainSection (extracted from #563 edit_vehicle_screen)',
      () {
    testWidgets('renders the combustion fields on a combustion vehicle',
        (tester) async {
      await _pump(tester, type: VehicleType.combustion);
      // Combustion sub-section exposes a tank capacity field.
      expect(find.text('Tank capacity (L)'), findsOneWidget);
      // Type selector still renders all three segments.
      expect(find.text('Combustion'), findsWidgets);
    });

    testWidgets('renders the EV fields on an EV vehicle', (tester) async {
      await _pump(tester, type: VehicleType.ev);
      // EV sub-section exposes the battery capacity field.
      expect(find.text('Battery capacity (kWh)'), findsOneWidget);
      // Combustion-only tank field is gone when type is pure EV.
      expect(find.text('Tank capacity (L)'), findsNothing);
    });
  });
}
