import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/presentation/widgets/vehicle_header.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

Future<void> _pump(WidgetTester tester, VehicleHeader header) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: header),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('VehicleHeader (extracted from #563 edit_vehicle_screen)', () {
    testWidgets('renders the typed name and combustion plate chip',
        (tester) async {
      await _pump(
        tester,
        const VehicleHeader(
          name: 'My Peugeot 107',
          accent: Colors.blue,
          type: VehicleType.combustion,
        ),
      );
      expect(find.text('My Peugeot 107'), findsOneWidget);
      expect(find.text('Combustion'), findsOneWidget);
    });

    testWidgets('falls back to the "New vehicle" placeholder on empty name',
        (tester) async {
      await _pump(
        tester,
        const VehicleHeader(
          name: '',
          accent: Colors.blue,
          type: VehicleType.ev,
        ),
      );
      expect(find.text('New vehicle'), findsOneWidget);
      expect(find.text('Electric'), findsOneWidget);
    });
  });
}
