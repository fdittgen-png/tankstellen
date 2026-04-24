import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/features/vehicle/data/repositories/vehicle_profile_repository.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/presentation/screens/edit_vehicle_screen.dart';
import 'package:tankstellen/features/vehicle/providers/calibration_mode_providers.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// Widget tests for the #894 calibration-mode segmented button on the
/// edit-vehicle screen. Covers: both segments render, tapping Fuzzy
/// persists the change through the profile repository and enqueues a
/// replay.
void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('calib_mode_widget_');
    Hive.init(tempDir.path);
    await Hive.openBox<String>(HiveBoxes.serviceReminders);
    await Hive.openBox<String>(HiveBoxes.obd2Baselines);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('EditVehicleScreen — calibration mode (#894)', () {
    testWidgets('renders both segments for a saved vehicle', (tester) async {
      final repo = VehicleProfileRepository(_FakeSettings());
      await repo.save(const VehicleProfile(id: 'v1', name: 'Car'));

      await _pumpEditScreen(tester, repo: repo, vehicleId: 'v1');

      await tester.dragUntilVisible(
        find.byKey(const Key('calibrationModeSegmentedButton')),
        find.byType(ListView),
        const Offset(0, -200),
      );

      expect(find.text('Rule-based'), findsOneWidget);
      expect(find.text('Fuzzy'), findsOneWidget);
      expect(find.text('Calibration mode'), findsOneWidget);
    });

    testWidgets('tapping Fuzzy persists the profile and enqueues a replay',
        (tester) async {
      final repo = VehicleProfileRepository(_FakeSettings());
      await repo.save(const VehicleProfile(id: 'v1', name: 'Car'));

      final container = ProviderContainer(
        overrides: [
          vehicleProfileRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            localizationsDelegates:
                AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: EditVehicleScreen(vehicleId: 'v1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.dragUntilVisible(
        find.byKey(const Key('calibrationModeSegmentedButton')),
        find.byType(ListView),
        const Offset(0, -200),
      );
      // Extra scroll to make sure the segments themselves (not just
      // the card header) are fully inside the viewport so the tap
      // doesn't fall on an off-screen pixel.
      await tester.drag(find.byType(ListView), const Offset(0, -120));
      await tester.pumpAndSettle();

      // Precondition: repo still on rule mode.
      expect(repo.getById('v1')!.calibrationMode,
          VehicleCalibrationMode.rule);
      expect(
        container.read(calibrationReplayQueueProvider),
        isEmpty,
      );

      await tester.tap(find.text('Fuzzy'));
      await tester.pumpAndSettle();

      // Post-condition: mode flipped, replay requested.
      expect(repo.getById('v1')!.calibrationMode,
          VehicleCalibrationMode.fuzzy);
      expect(
        container.read(calibrationReplayQueueProvider),
        contains('v1'),
      );
    });

    testWidgets('rule mode is selected by default for fresh profiles',
        (tester) async {
      final repo = VehicleProfileRepository(_FakeSettings());
      await repo.save(const VehicleProfile(id: 'v1', name: 'Car'));

      await _pumpEditScreen(tester, repo: repo, vehicleId: 'v1');

      await tester.dragUntilVisible(
        find.byKey(const Key('calibrationModeSegmentedButton')),
        find.byType(ListView),
        const Offset(0, -200),
      );

      final segmented =
          tester.widget<SegmentedButton<VehicleCalibrationMode>>(
        find.byKey(const Key('calibrationModeSegmentedButton')),
      );
      expect(segmented.selected, {VehicleCalibrationMode.rule});
    });
  });
}

Future<void> _pumpEditScreen(
  WidgetTester tester, {
  required VehicleProfileRepository repo,
  required String vehicleId,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        vehicleProfileRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: EditVehicleScreen(vehicleId: vehicleId),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _FakeSettings implements SettingsStorage {
  final Map<String, dynamic> _data = {};

  @override
  dynamic getSetting(String key) => _data[key];

  @override
  Future<void> putSetting(String key, dynamic value) async {
    if (value == null) {
      _data.remove(key);
    } else {
      _data[key] = value;
    }
  }

  @override
  bool get isSetupComplete => false;

  @override
  bool get isSetupSkipped => false;

  @override
  Future<void> skipSetup() async {}

  @override
  Future<void> resetSetupSkip() async {}
}
