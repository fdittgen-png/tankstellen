import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/vehicle/presentation/widgets/vehicle_identity_section.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

void main() {
  group('VehicleIdentitySection (extracted from #563 edit_vehicle_screen)',
      () {
    testWidgets('renders the name + VIN fields and the decode/info actions',
        (tester) async {
      final nameCtrl = TextEditingController();
      final vinCtrl = TextEditingController();
      final vinFocus = FocusNode();
      addTearDown(() {
        nameCtrl.dispose();
        vinCtrl.dispose();
        vinFocus.dispose();
      });

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Form(
              child: VehicleIdentitySection(
                nameController: nameCtrl,
                vinController: vinCtrl,
                vinFocus: vinFocus,
                accent: Colors.blue,
                decodingVin: false,
                onDecodeVin: () {},
                onShowVinInfo: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Name'), findsOneWidget);
      expect(find.text('VIN (optional)'), findsOneWidget);
      expect(find.byTooltip('Decode VIN'), findsOneWidget);
      expect(find.byTooltip('What is a VIN?'), findsOneWidget);
    });

    testWidgets('shows a progress spinner when decodingVin is true',
        (tester) async {
      final nameCtrl = TextEditingController();
      final vinCtrl = TextEditingController();
      final vinFocus = FocusNode();
      addTearDown(() {
        nameCtrl.dispose();
        vinCtrl.dispose();
        vinFocus.dispose();
      });

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Form(
              child: VehicleIdentitySection(
                nameController: nameCtrl,
                vinController: vinCtrl,
                vinFocus: vinFocus,
                accent: Colors.blue,
                decodingVin: true,
                onDecodeVin: () {},
                onShowVinInfo: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byTooltip('Decode VIN'), findsNothing);
    });
  });
}
