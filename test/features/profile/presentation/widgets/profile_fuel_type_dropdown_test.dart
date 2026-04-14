import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/profile/presentation/widgets/profile_fuel_type_dropdown.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

void main() {
  group('ProfileFuelTypeDropdown', () {
    Future<void> pumpDropdown(
      WidgetTester tester, {
      required FuelType value,
      ValueChanged<FuelType>? onChanged,
    }) {
      return tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ProfileFuelTypeDropdown(
              value: value,
              onChanged: onChanged ?? (_) {},
            ),
          ),
        ),
      );
    }

    testWidgets('renders the displayName of the selected fuel type',
        (tester) async {
      await pumpDropdown(tester, value: FuelType.e10);
      expect(find.text(FuelType.e10.displayName), findsOneWidget);
    });

    testWidgets('opening the menu lists every FuelType except `all`',
        (tester) async {
      await pumpDropdown(tester, value: FuelType.e10);
      await tester.tap(find.byType(DropdownButtonFormField<FuelType>));
      await tester.pumpAndSettle();

      // The "all" wildcard must not appear as a profile preference.
      expect(find.text(FuelType.all.displayName), findsNothing);
      // A few real fuel types should appear in the open menu.
      expect(find.text(FuelType.e5.displayName), findsAtLeast(1));
      expect(find.text(FuelType.diesel.displayName), findsAtLeast(1));
    });

    testWidgets('forwards selection to onChanged when user picks a new fuel',
        (tester) async {
      FuelType? captured;
      await pumpDropdown(
        tester,
        value: FuelType.e10,
        onChanged: (v) => captured = v,
      );
      await tester.tap(find.byType(DropdownButtonFormField<FuelType>));
      await tester.pumpAndSettle();
      // .last is the menu entry (the field label is .first).
      await tester.tap(find.text(FuelType.diesel.displayName).last);
      await tester.pumpAndSettle();
      expect(captured, FuelType.diesel);
    });
  });
}
