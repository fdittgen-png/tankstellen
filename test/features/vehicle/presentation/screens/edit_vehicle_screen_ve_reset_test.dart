// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/features/consumption/domain/entities/fill_up.dart';
import 'package:tankstellen/features/consumption/providers/consumption_providers.dart';
import 'package:tankstellen/features/profile/data/models/user_profile.dart';
import 'package:tankstellen/features/profile/providers/profile_provider.dart';
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
        find.text('Reset volumetric efficiency'),
        find.byType(ListView),
        const Offset(0, -200),
      );
      expect(find.text('Reset volumetric efficiency'), findsOneWidget);
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
        find.text('Reset volumetric efficiency'),
        find.byType(ListView),
        const Offset(0, -200),
      );
      await tester.tap(find.text('Reset volumetric efficiency'));
      await tester.pumpAndSettle();

      expect(find.text('Reset volumetric efficiency?'), findsOneWidget);
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
          find.text('Reset volumetric efficiency'),
          find.byType(ListView),
          const Offset(0, -200),
        );
        await tester.tap(find.text('Reset volumetric efficiency'));
        await tester.pumpAndSettle();

        // The dialog's confirm action and the outer page button share
        // the same label — find the one inside the AlertDialog.
        final confirm = find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Reset volumetric efficiency'),
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
  // The edit-vehicle screen has grown tall (#779 baseline + #1529
  // collapse toggle + service reminders + #815 reset button). The
  // 800×600 default surface forces dragUntilVisible to scroll the
  // button on/off-stage as the layout settles, racing pumpAndSettle
  // and producing offstage taps. A tall surface lets every section
  // render at once and avoids the race (#1545 root cause).
  await tester.binding.setSurfaceSize(const Size(1200, 3200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        vehicleProfileRepositoryProvider.overrideWithValue(repo),
        // The vehicle save-actions widget reads
        // [fillUpListProvider] (for `latestOdometerKm`) and the
        // post-save side-effect calls [activeProfileProvider] (for
        // `syncActiveProfile`). Both production providers reach
        // Hive boxes the widget-test setUp doesn't initialise.
        // Stub them so the build + post-save flow succeed without
        // touching Hive (#1545).
        fillUpListProvider.overrideWith(() => _EmptyFillUpList()),
        activeProfileProvider.overrideWith(() => _NullActiveProfile()),
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

/// Test stub for [FillUpList] — returns an empty list so the
/// odometer-lookup helper inside `vehicle_save_actions.dart` resolves
/// to null without ever touching the production Hive-backed
/// repository (#1545).
class _EmptyFillUpList extends FillUpList {
  @override
  List<FillUp> build() => const [];
}

/// Test stub for [ActiveProfile] — returns null so
/// `syncActiveProfile` short-circuits without reading the production
/// `profileRepositoryProvider`, which itself depends on a Hive box
/// the widget-test setUp doesn't initialise (#1545).
class _NullActiveProfile extends ActiveProfile {
  @override
  UserProfile? build() => null;
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
