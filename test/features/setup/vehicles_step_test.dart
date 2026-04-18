import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/features/setup/presentation/widgets/vehicles_step.dart';

import '../../helpers/pump_app.dart';

/// #692 — The onboarding wizard needs an optional Vehicles step so the
/// user can declare their car up front; it MUST be skippable so the
/// app remains fully usable without any vehicle.
void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('veh_step_test_');
    Hive.init(tempDir.path);
    await HiveStorage.initForTest();
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  testWidgets(
    'renders the localized title, "no vehicle" hint, and Add button '
    'when no vehicle is configured',
    (tester) async {
      await pumpApp(tester, const VehiclesStep());
      await tester.pumpAndSettle();

      // English localization (the default for pumpApp)
      expect(find.text('My vehicles (optional)'), findsOneWidget);
      expect(find.text('No vehicle configured yet.'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Add vehicle'),
          findsOneWidget);
      // Skip hint present so the user knows the step is optional.
      expect(
        find.textContaining('Skip to finish setup'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'renders localized title in French',
    (tester) async {
      await pumpApp(
        tester,
        const VehiclesStep(),
        locale: const Locale('fr'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mes véhicules (facultatif)'), findsOneWidget);
      expect(find.text('Aucun véhicule configuré pour le moment.'),
          findsOneWidget);
    },
  );

  testWidgets(
    'renders localized title in German',
    (tester) async {
      await pumpApp(
        tester,
        const VehiclesStep(),
        locale: const Locale('de'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Meine Fahrzeuge (optional)'), findsOneWidget);
      expect(find.text('Noch kein Fahrzeug konfiguriert.'), findsOneWidget);
    },
  );
}
