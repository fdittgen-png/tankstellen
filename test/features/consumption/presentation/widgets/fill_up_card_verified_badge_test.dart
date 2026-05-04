import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/entities/fill_up.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/fill_up_card.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// Widget tests for the "Verified by adapter" badge on [FillUpCard]
/// (#1401 phase 7b). The chip renders only when both
/// [FillUp.fuelLevelBeforeL] and [FillUp.fuelLevelAfterL] are set — a
/// positive signal that the OBD2 adapter captured the tank delta.
/// Either field missing means we cannot verify and no chip should
/// appear (avoids implying verification on partial data).
void main() {
  FillUp buildFillUp({double? before, double? after}) => FillUp(
        id: 'fv_card_test',
        date: DateTime(2026, 5, 1),
        liters: 45,
        totalCost: 75,
        odometerKm: 10000,
        fuelType: FuelType.e10,
        stationName: 'Test Station',
        fuelLevelBeforeL: before,
        fuelLevelAfterL: after,
      );

  Future<void> pump(WidgetTester tester, FillUp fillUp) {
    return tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(body: FillUpCard(fillUp: fillUp)),
      ),
    );
  }

  testWidgets('no badge when both fuel-level fields are null',
      (tester) async {
    await pump(tester, buildFillUp());
    await tester.pumpAndSettle();

    expect(find.text('Verified by adapter'), findsNothing);
    expect(find.byIcon(Icons.check_circle), findsNothing);
  });

  testWidgets('no badge when only fuelLevelBeforeL is set', (tester) async {
    await pump(tester, buildFillUp(before: 5));
    await tester.pumpAndSettle();

    expect(find.text('Verified by adapter'), findsNothing);
  });

  testWidgets('no badge when only fuelLevelAfterL is set', (tester) async {
    await pump(tester, buildFillUp(after: 50));
    await tester.pumpAndSettle();

    expect(find.text('Verified by adapter'), findsNothing);
  });

  testWidgets('badge renders when both fuel-level fields are set',
      (tester) async {
    await pump(tester, buildFillUp(before: 5, after: 50));
    await tester.pumpAndSettle();

    expect(find.text('Verified by adapter'), findsOneWidget);
    // The chip uses Icons.check_circle as the leading icon — verifies
    // visual identity matches the design (check + label).
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });
}
