import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/vehicle/presentation/widgets/vehicle_save_bar.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

void main() {
  group('VehicleSaveBar (extracted from #563 edit_vehicle_screen)', () {
    testWidgets('renders the Save filled button and forwards taps',
        (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            bottomNavigationBar: VehicleSaveBar(onSave: () => tapped++),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.widgetWithText(FilledButton, 'Save'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pump();
      expect(tapped, 1);
    });
  });
}
