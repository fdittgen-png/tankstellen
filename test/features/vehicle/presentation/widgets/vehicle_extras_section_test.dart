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

      // The reset-calibration OutlinedButton must be present — the
      // VE reset test depends on this label being scroll-reachable.
      expect(find.text('Reset calibration'), findsOneWidget);
    });
  });
}
