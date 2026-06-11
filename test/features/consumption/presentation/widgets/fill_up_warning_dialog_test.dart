// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/add_fill_up_warnings.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/fill_up_warning_dialog.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// Widget tests for the #2836 fill-up warning dialog — drives the real
/// [showFillUpWarningDialog] and asserts the rendered warning lines + the
/// fix/save-anyway return values.
void main() {
  Future<bool?> showAndTap(
    WidgetTester tester, {
    required List<FillUpWarning> warnings,
    required FuelType chosenFuel,
    required FuelType? vehicleFuel,
    required String enteredOdoKm,
    required String? previousOdoKm,
    required String tapLabel,
  }) async {
    bool? choice;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                choice = await showFillUpWarningDialog(
                  context: context,
                  warnings: warnings,
                  chosenFuel: chosenFuel,
                  vehicleFuel: vehicleFuel,
                  enteredOdoKm: enteredOdoKm,
                  previousOdoKm: previousOdoKm,
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(tapLabel));
    await tester.pumpAndSettle();
    return choice;
  }

  testWidgets('renders both warning lines and returns true on Save anyway',
      (tester) async {
    final choice = await showAndTap(
      tester,
      warnings: const [
        FillUpWarning.fuelEngineMismatch,
        FillUpWarning.odometerBelowPrevious,
      ],
      chosenFuel: FuelType.e10,
      vehicleFuel: FuelType.diesel,
      enteredOdoKm: '83178',
      previousOdoKm: '83485',
      tapLabel: 'Save anyway',
    );
    expect(choice, isTrue);
  });

  testWidgets('shows the fuel-mismatch copy naming both fuels',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showFillUpWarningDialog(
                context: context,
                warnings: const [FillUpWarning.fuelEngineMismatch],
                chosenFuel: FuelType.e10,
                vehicleFuel: FuelType.diesel,
                enteredOdoKm: '90000',
                previousOdoKm: null,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    // The copy names the chosen fuel and the vehicle fuel (displayName).
    expect(
      find.textContaining(FuelType.e10.displayName),
      findsOneWidget,
    );
    expect(
      find.textContaining(FuelType.diesel.displayName),
      findsOneWidget,
    );
  });

  testWidgets('returns false on Go back and fix', (tester) async {
    final choice = await showAndTap(
      tester,
      warnings: const [FillUpWarning.odometerBelowPrevious],
      chosenFuel: FuelType.diesel,
      vehicleFuel: FuelType.diesel,
      enteredOdoKm: '83178',
      previousOdoKm: '83485',
      tapLabel: 'Go back and fix',
    );
    expect(choice, isFalse);
  });
}
