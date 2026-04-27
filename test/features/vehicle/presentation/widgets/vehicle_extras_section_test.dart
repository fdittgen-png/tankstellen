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
    Future<void> pump(WidgetTester tester) async {
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
    }

    testWidgets(
        'build() renders the renamed η_v reset action — the screen-level '
        'tests scroll until this label is visible, so a regression '
        'silently breaks the η_v reset flow', (tester) async {
      await pump(tester);

      // The reset-volumetric-efficiency OutlinedButton must be present.
      expect(find.text('Reset volumetric efficiency'), findsOneWidget);
    });

    testWidgets(
        'build() groups both resets under a "Calibration" card with '
        'distinct icons and captions so users can tell them apart '
        '(#1219 — the whole point of this issue)', (tester) async {
      await pump(tester);

      // 1. The card has a "Calibration" header.
      expect(find.text('Calibration'), findsOneWidget);

      // 2. Both reset buttons are rendered with their renamed labels.
      expect(
        find.text('Reset driving-situation baseline'),
        findsOneWidget,
        reason: 'Baseline reset label must be the renamed value.',
      );
      expect(
        find.text('Reset volumetric efficiency'),
        findsOneWidget,
        reason: 'η_v reset label must be the renamed value.',
      );

      // 3. Each reset has its caption directly beneath.
      expect(
        find.textContaining('Welford samples'),
        findsOneWidget,
        reason: 'Baseline-reset caption must be present.',
      );
      expect(
        find.textContaining('η_v constant'),
        findsOneWidget,
        reason: 'η_v-reset caption must be present.',
      );

      // 4. Distinct icons on the two buttons. The baseline reset uses
      // restart_alt; the η_v reset uses tune. Asserting both appear at
      // least once is enough — duplicate visual cues defeat the whole
      // disambiguation effort.
      expect(find.byIcon(Icons.restart_alt), findsWidgets);
      expect(find.byIcon(Icons.tune), findsWidgets);
    });
  });
}
