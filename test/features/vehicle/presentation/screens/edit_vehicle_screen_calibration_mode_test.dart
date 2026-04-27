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
import 'package:tankstellen/features/vehicle/presentation/widgets/vehicle_form_controllers.dart';
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
      // Ensure the Fuzzy segment is fully inside the viewport so the
      // tap doesn't fall on an off-screen pixel. `ensureVisible` is
      // resilient to layout shifts when sibling sections appear above
      // or below — important because the edit screen accretes content
      // (e.g. #1004 phase 6 auto-record card) without each PR being
      // expected to retune fixed-pixel scrolls.
      await tester.ensureVisible(find.text('Fuzzy'));
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

    // #1217 — VehicleFormControllers.buildProfile didn't thread the
    // calibrationMode through, so the screen-level Save rebuilt the
    // profile with the constructor default and overwrote whatever
    // the segmented-button selector had just persisted.
    testWidgets('Fuzzy + immediate Save persists the chosen mode (#1217)',
        (tester) async {
      final repo = VehicleProfileRepository(_FakeSettings());
      await repo.save(const VehicleProfile(id: 'v1', name: 'Car'));

      await _pumpEditScreen(tester, repo: repo, vehicleId: 'v1');

      await tester.dragUntilVisible(
        find.byKey(const Key('calibrationModeSegmentedButton')),
        find.byType(ListView),
        const Offset(0, -200),
      );
      await tester.ensureVisible(find.text('Fuzzy'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.text('Fuzzy'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Selector wrote fuzzy. Now tap the screen-level Save (the
      // pinned bottom bar) and expect Hive still holds fuzzy after.
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(repo.getById('v1')!.calibrationMode,
          VehicleCalibrationMode.fuzzy);
    });

    testWidgets(
        'Fuzzy + edit name + Save still persists the chosen mode (#1217)',
        (tester) async {
      final repo = VehicleProfileRepository(_FakeSettings());
      await repo.save(const VehicleProfile(id: 'v1', name: 'Car'));

      await _pumpEditScreen(tester, repo: repo, vehicleId: 'v1');

      await tester.dragUntilVisible(
        find.byKey(const Key('calibrationModeSegmentedButton')),
        find.byType(ListView),
        const Offset(0, -200),
      );
      await tester.ensureVisible(find.text('Fuzzy'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.text('Fuzzy'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Edit the name field (any other field's edit must not flip
      // calibrationMode back to rule on Save).
      await tester.dragUntilVisible(
        find.widgetWithText(TextFormField, 'Car'),
        find.byType(ListView),
        const Offset(0, 200),
      );
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Car'), 'Polo');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final stored = repo.getById('v1')!;
      expect(stored.name, 'Polo');
      expect(stored.calibrationMode, VehicleCalibrationMode.fuzzy);
    });

    testWidgets(
        'Fuzzy + Save survives the round-trip through the repo (#1217)',
        (tester) async {
      // Persistence-survival proof: after the screen-level Save, the
      // repository (the same in-memory facade that wraps Hive in
      // production) holds Fuzzy. Re-loading the controllers from the
      // repo's record reproduces what an app restart would see. The
      // actual Hive byte-level round-trip is covered by
      // `vehicle_profile_test.dart`.
      final repo = VehicleProfileRepository(_FakeSettings());
      await repo.save(const VehicleProfile(id: 'v1', name: 'Car'));

      await _pumpEditScreen(tester, repo: repo, vehicleId: 'v1');

      await tester.dragUntilVisible(
        find.byKey(const Key('calibrationModeSegmentedButton')),
        find.byType(ListView),
        const Offset(0, -200),
      );
      await tester.ensureVisible(find.text('Fuzzy'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.text('Fuzzy'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // The persisted profile holds Fuzzy — i.e. the next time the
      // user opens this vehicle's edit screen, the segmented button
      // will render Fuzzy as selected (the selector reads it directly
      // from `profile.calibrationMode`, no longer threaded through
      // VehicleFormSnapshot since #1226).
      final reloaded = repo.getById('v1')!;
      expect(reloaded.calibrationMode, VehicleCalibrationMode.fuzzy);

      // Loading the controllers off the persisted profile must not
      // crash; the segmented button reads the mode straight off the
      // profile via the selector widget.
      final freshControllers = VehicleFormControllers();
      addTearDown(freshControllers.dispose);
      freshControllers.load(reloaded);
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
