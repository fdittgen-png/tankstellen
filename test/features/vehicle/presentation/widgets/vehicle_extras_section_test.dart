import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/features/vehicle/presentation/widgets/vehicle_extras_section.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('extras_widget_');
    Hive.init(tempDir.path);
    await Hive.openBox<String>(HiveBoxes.serviceReminders);
    await Hive.openBox<String>(HiveBoxes.obd2Baselines);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  group('VehicleExtrasSection (extracted from #563 edit_vehicle_screen)', () {
    testWidgets('build() returns the reset calibration action in the list',
        (tester) async {
      // Tall canvas so all rows fit without virtualization —
      // scrollUntilVisible would work too, but a simpler viewport
      // keeps the test focused on the widget's contract.
      tester.view.physicalSize = const Size(900, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Builder(
                builder: (context) => ListView(
                  children: VehicleExtrasSection.build(
                    context: context,
                    vehicleId: 'v1',
                    adapterMac: null,
                    adapterName: null,
                    onAdapterPaired: (_, _) {},
                    onAdapterForget: () {},
                    onResetVolumetricEfficiency: () {},
                    currentOdometerKm: null,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The reset OutlinedButton must be present — the VE reset
      // test depends on this label being scroll-reachable. #1219
      // renamed it to explicitly call out volumetric efficiency so
      // users can distinguish it from the baseline reset above.
      expect(find.text('Reset volumetric efficiency'), findsOneWidget);
    });

    testWidgets(
        'volumetric-efficiency reset uses the local_gas_station_outlined '
        'icon — distinct from the baseline reset\'s tune_outlined glyph '
        'so users can tell at a glance which side of the calibration '
        'pipeline they\'re nuking (#1219)', (tester) async {
      tester.view.physicalSize = const Size(900, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Builder(
                builder: (context) => ListView(
                  children: VehicleExtrasSection.build(
                    context: context,
                    vehicleId: 'v1',
                    adapterMac: null,
                    adapterName: null,
                    onAdapterPaired: (_, _) {},
                    onAdapterForget: () {},
                    onResetVolumetricEfficiency: () {},
                    currentOdometerKm: null,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The OutlinedButton hosting the η_v reset action must carry the
      // fuel-pump glyph — distinct from the baseline reset's tune icon.
      final resetButton = find.ancestor(
        of: find.text('Reset volumetric efficiency'),
        matching: find.byType(OutlinedButton),
      );
      expect(resetButton, findsOneWidget);
      expect(
        find.descendant(
          of: resetButton,
          matching: find.byIcon(Icons.local_gas_station_outlined),
        ),
        findsOneWidget,
      );
    });
  });
}
