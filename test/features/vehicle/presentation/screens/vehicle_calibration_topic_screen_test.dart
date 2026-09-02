// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/features/vehicle/presentation/screens/topics/vehicle_calibration_topic_screen.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// The Calibration topic screen (#3900) — the reset actions carried over
/// from the dissolved `VehicleExtrasSection` (glyphs per #1219 / #3651
/// so users can tell at a glance which side of the calibration pipeline
/// they are nuking) and the plain-language calibration-mode
/// descriptions.
void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('calibration_topic_');
    Hive.init(tempDir.path);
    await Hive.openBox<String>(HiveBoxes.serviceReminders);
    await Hive.openBox<String>(HiveBoxes.obd2Baselines);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Future<void> pump(
    WidgetTester tester, {
    VoidCallback? onResetVolumetricEfficiency,
    VoidCallback? onResetFromCatalog,
  }) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: VehicleCalibrationTopicScreen(
            vehicleId: 'v1',
            onDisplacementChanged: (_) {},
            onVolumetricEfficiencyChanged: (_) {},
            onAfrChanged: (_) {},
            onFuelDensityChanged: (_) {},
            onResetVolumetricEfficiency: onResetVolumetricEfficiency ?? () {},
            onResetFromCatalog: onResetFromCatalog ?? () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('VehicleCalibrationTopicScreen (#3900)', () {
    testWidgets(
        'volumetric-efficiency reset uses the local_gas_station_outlined '
        'icon — distinct from the baseline reset\'s tune_outlined glyph '
        '(#1219)', (tester) async {
      var taps = 0;
      await pump(tester, onResetVolumetricEfficiency: () => taps++);

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
      await tester.tap(resetButton);
      expect(taps, 1);
    });

    testWidgets(
        'renders the reset-from-vehicle-database action (#3651) with the '
        'restore glyph and fires its callback on tap', (tester) async {
      var resetTapped = 0;
      await pump(tester, onResetFromCatalog: () => resetTapped++);

      final button = find.ancestor(
        of: find.text('Reset from vehicle database'),
        matching: find.byType(OutlinedButton),
      );
      expect(button, findsOneWidget);
      expect(
        find.descendant(
          of: button,
          matching: find.byIcon(Icons.settings_backup_restore),
        ),
        findsOneWidget,
      );
      await tester.tap(button);
      expect(resetTapped, 1);
    });

    testWidgets('baseline section + the baseline reset ride the topic',
        (tester) async {
      await pump(tester);
      expect(find.byKey(const Key('vehicleBaselineAggregateBar')),
          findsOneWidget);
      expect(find.byKey(const Key('resetBaselinesButton')), findsOneWidget);
    });
  });
}
