import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/presentation/widgets/vehicle_type_selector.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

void main() {
  group('VehicleTypeSelector (extracted from #563 edit_vehicle_screen)', () {
    testWidgets('renders all three drivetrain segments', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: VehicleTypeSelector(
              selected: VehicleType.combustion,
              onChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Combustion'), findsOneWidget);
      expect(find.text('Hybrid'), findsOneWidget);
      expect(find.text('Electric'), findsOneWidget);
    });

    testWidgets('forwards the tapped segment via onChanged', (tester) async {
      VehicleType? picked;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: VehicleTypeSelector(
              selected: VehicleType.combustion,
              onChanged: (t) => picked = t,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Electric'));
      await tester.pumpAndSettle();
      expect(picked, VehicleType.ev);
    });
  });
}
