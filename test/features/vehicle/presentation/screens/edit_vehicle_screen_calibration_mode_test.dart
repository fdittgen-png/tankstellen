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
  });

  // #1217 — race regression: the screen-level Save button rebuilt the
  // profile via `_ctrl.buildProfile(...)` without threading the live
  // calibrationMode, so any value the segmented button persisted was
  // overwritten with the freezed default `rule` on the very next Save.
  // These tests guard the form-controller fix end-to-end through the
  // screen's Save action and across a re-pump round-trip.
  group('EditVehicleScreen — calibration mode persistence (#1217)', () {
    testWidgets(
        'toggling Fuzzy then tapping Save persists fuzzy through the form rebuild',
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
      await tester.pumpAndSettle();

      await tester.tap(find.text('Fuzzy'));
      await tester.pumpAndSettle();

      // Tap the pinned bottom Save bar — the screen-level path that
      // rebuilds the profile via _ctrl.buildProfile.
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      // The persisted value must still be Fuzzy. Before the #1217 fix
      // the screen-level Save would overwrite it with the freezed
      // default `rule`.
      expect(repo.getById('v1')!.calibrationMode,
          VehicleCalibrationMode.fuzzy);
    });

    testWidgets(
        'toggling Fuzzy + editing the name + Save persists both changes',
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
      await tester.pumpAndSettle();

      await tester.tap(find.text('Fuzzy'));
      await tester.pumpAndSettle();

      // Scroll back up so the Name field re-mounts (the screen uses a
      // ListView which may virtualize the top-of-list field after we
      // dragged down to reach Fuzzy).
      await tester.dragUntilVisible(
        find.byIcon(Icons.directions_car_outlined),
        find.byType(ListView),
        const Offset(0, 400),
      );
      await tester.pumpAndSettle();

      // Change the name field — covers the worst-case "Save fires for
      // any field change" path called out in the issue body. The Name
      // TextFormField is the first one in the form (Identity card top).
      final nameField = find.byType(TextFormField).first;
      await tester.enterText(nameField, 'My Renamed Car');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      final saved = repo.getById('v1')!;
      expect(saved.name, 'My Renamed Car');
      expect(saved.calibrationMode, VehicleCalibrationMode.fuzzy);
    });

    testWidgets(
        're-opening the screen after Save shows Fuzzy as the selected segment',
        (tester) async {
      final repo = VehicleProfileRepository(_FakeSettings());
      await repo.save(const VehicleProfile(id: 'v1', name: 'Car'));

      await _pumpEditScreen(tester, repo: repo, vehicleId: 'v1', appKey: 'A');

      await tester.dragUntilVisible(
        find.byKey(const Key('calibrationModeSegmentedButton')),
        find.byType(ListView),
        const Offset(0, -200),
      );
      await tester.ensureVisible(find.text('Fuzzy'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Fuzzy'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      // Re-pump the same screen with the now-stored profile; pass a
      // distinct [appKey] so Flutter rebuilds [MaterialApp]'s
      // [Navigator] state from scratch (the previous Save popped the
      // only route, leaving the reused Navigator with an empty
      // history, which crashes a same-keyed re-pump).
      await _pumpEditScreen(tester, repo: repo, vehicleId: 'v1', appKey: 'B');

      await tester.dragUntilVisible(
        find.byKey(const Key('calibrationModeSegmentedButton')),
        find.byType(ListView),
        const Offset(0, -200),
      );

      final segmented =
          tester.widget<SegmentedButton<VehicleCalibrationMode>>(
        find.byKey(const Key('calibrationModeSegmentedButton')),
      );
      expect(segmented.selected, {VehicleCalibrationMode.fuzzy});
    });
  });
}

Future<void> _pumpEditScreen(
  WidgetTester tester, {
  required VehicleProfileRepository repo,
  required String vehicleId,
  String? appKey,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        vehicleProfileRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp(
        key: appKey == null ? null : ValueKey(appKey),
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
