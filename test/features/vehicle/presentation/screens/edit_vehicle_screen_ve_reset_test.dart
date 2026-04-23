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
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// Widget tests for the η_v calibration reset action added to
/// [EditVehicleScreen] (#815).
///
/// Covers the confirm-then-reset flow: tapping the button opens a
/// destructive-action dialog, and only the explicit confirm commits
/// the change back to the profile repository.
void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('ve_reset_widget_');
    Hive.init(tempDir.path);
    // The service-reminder section and baseline section both open
    // Hive boxes during their first build. Open them empty so the
    // sections render without throwing.
    await Hive.openBox<String>(HiveBoxes.serviceReminders);
    await Hive.openBox<String>(HiveBoxes.obd2Baselines);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('EditVehicleScreen — η_v reset (#815)', () {
    testWidgets('renders the reset action on an existing vehicle',
        (tester) async {
      final repo = VehicleProfileRepository(_FakeSettings());
      await repo.save(const VehicleProfile(
        id: 'v1',
        name: 'Peugeot 107',
        volumetricEfficiency: 0.72,
        volumetricEfficiencySamples: 5,
      ));

      await _pumpEditScreen(tester, repo: repo, vehicleId: 'v1');

      // Scroll until the reset action is visible — it lives below
      // the service-reminder and baseline sections.
      await tester.dragUntilVisible(
        find.text('Reset calibration'),
        find.byType(ListView),
        const Offset(0, -200),
      );
      expect(find.text('Reset calibration'), findsOneWidget);
    });

    testWidgets('Cancel leaves the profile untouched', (tester) async {
      final repo = VehicleProfileRepository(_FakeSettings());
      await repo.save(const VehicleProfile(
        id: 'v1',
        name: 'Peugeot 107',
        volumetricEfficiency: 0.72,
        volumetricEfficiencySamples: 5,
      ));

      await _pumpEditScreen(tester, repo: repo, vehicleId: 'v1');
      await tester.dragUntilVisible(
        find.text('Reset calibration'),
        find.byType(ListView),
        const Offset(0, -200),
      );
      await tester.tap(find.text('Reset calibration'));
      await tester.pumpAndSettle();

      expect(find.text('Reset calibration?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      final stored = repo.getById('v1')!;
      expect(stored.volumetricEfficiency, 0.72);
      expect(stored.volumetricEfficiencySamples, 5);
    });

    testWidgets(
      'confirming the reset writes η_v=0.85 and samples=0 back to '
      'the profile',
      (tester) async {
        final repo = VehicleProfileRepository(_FakeSettings());
        await repo.save(const VehicleProfile(
          id: 'v1',
          name: 'Peugeot 107',
          volumetricEfficiency: 0.72,
          volumetricEfficiencySamples: 5,
        ));

        await _pumpEditScreen(tester, repo: repo, vehicleId: 'v1');
        await tester.dragUntilVisible(
          find.text('Reset calibration'),
          find.byType(ListView),
          const Offset(0, -200),
        );
        await tester.tap(find.text('Reset calibration'));
        await tester.pumpAndSettle();

        // The dialog's confirm action and the outer page button share
        // the same label — find the one inside the AlertDialog.
        final confirm = find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Reset calibration'),
        );
        expect(confirm, findsOneWidget);
        await tester.tap(confirm);
        await tester.pumpAndSettle();

        final stored = repo.getById('v1')!;
        expect(stored.volumetricEfficiency, 0.85);
        expect(stored.volumetricEfficiencySamples, 0);
      },
    );
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
