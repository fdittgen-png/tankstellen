// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/features/fill_ups/domain/entities/fill_up.dart';
import 'package:tankstellen/features/fill_ups/providers/consumption_providers.dart';
import 'package:tankstellen/features/profile/data/models/user_profile.dart';
import 'package:tankstellen/features/profile/providers/profile_provider.dart';
import 'package:tankstellen/features/vehicle/data/repositories/vehicle_profile_repository.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/presentation/screens/edit_vehicle_screen.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// Widget tests for the pump-calibration reset action on
/// [EditVehicleScreen] (#3901, replacing the #815 η_v reset).
///
/// Covers the confirm-then-reset flow on the Calibration topic screen
/// (#3900): tapping the button opens a destructive-action dialog, and
/// only the explicit confirm commits the change back to the profile
/// repository — pump gain 1.0, samples 0, updatedAt null.
void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('pump_gain_reset_widget_');
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

  VehicleProfile calibrated() => VehicleProfile(
        id: 'v1',
        name: 'Peugeot 107',
        pumpGain: 0.93,
        pumpGainSamples: 6,
        pumpGainUpdatedAt: DateTime.utc(2026, 8, 30),
      );

  group('EditVehicleScreen — pump-calibration reset (#3901)', () {
    testWidgets('renders the reset action on the Calibration topic; the '
        'old volumetric-efficiency reset is gone', (tester) async {
      final repo = VehicleProfileRepository(_FakeSettings());
      await repo.save(calibrated());

      await _pumpEditScreen(tester, repo: repo, vehicleId: 'v1');
      await _openCalibrationTopic(tester);
      await tester.dragUntilVisible(
        find.text('Reset pump calibration'),
        find.byType(ListView).last,
        const Offset(0, -200),
      );
      expect(find.text('Reset pump calibration'), findsOneWidget);
      expect(find.textContaining('volumetric efficiency'), findsNothing);
      expect(find.textContaining('Reset learner'), findsNothing);
    });

    testWidgets('Cancel leaves the profile untouched', (tester) async {
      final repo = VehicleProfileRepository(_FakeSettings());
      await repo.save(calibrated());

      await _pumpEditScreen(tester, repo: repo, vehicleId: 'v1');
      await _openCalibrationTopic(tester);
      await tester.dragUntilVisible(
        find.text('Reset pump calibration'),
        find.byType(ListView).last,
        const Offset(0, -200),
      );
      await tester.tap(find.text('Reset pump calibration'));
      await tester.pumpAndSettle();

      expect(find.text('Reset pump calibration?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      final stored = repo.getById('v1')!;
      expect(stored.pumpGain, 0.93);
      expect(stored.pumpGainSamples, 6);
      expect(stored.pumpGainUpdatedAt, isNotNull);
    });

    testWidgets(
      'confirming the reset writes gain 1.0, samples 0, updatedAt null '
      'back to the profile',
      (tester) async {
        final repo = VehicleProfileRepository(_FakeSettings());
        await repo.save(calibrated());

        await _pumpEditScreen(tester, repo: repo, vehicleId: 'v1');
        await _openCalibrationTopic(tester);
        await tester.dragUntilVisible(
          find.text('Reset pump calibration'),
          find.byType(ListView).last,
          const Offset(0, -200),
        );
        await tester.tap(find.text('Reset pump calibration'));
        await tester.pumpAndSettle();

        // The dialog's confirm action and the outer page button share
        // the same label — find the one inside the AlertDialog.
        final confirm = find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Reset pump calibration'),
        );
        expect(confirm, findsOneWidget);
        await tester.tap(confirm);
        await tester.pumpAndSettle();

        final stored = repo.getById('v1')!;
        expect(stored.pumpGain, 1.0);
        expect(stored.pumpGainSamples, 0);
        expect(stored.pumpGainUpdatedAt, isNull);
      },
    );
  });
}

/// #3900 — the calibration resets live on the Calibration topic screen.
Future<void> _openCalibrationTopic(WidgetTester tester) async {
  final tile = find.byKey(const Key('vehicleTopic_calibration'));
  await tester.dragUntilVisible(
    tile,
    find.byType(ListView).first,
    const Offset(0, -200),
  );
  await tester.ensureVisible(tile);
  await tester.pumpAndSettle();
  await tester.tap(tile);
  await tester.pumpAndSettle();
}

Future<void> _pumpEditScreen(
  WidgetTester tester, {
  required VehicleProfileRepository repo,
  required String vehicleId,
}) async {
  // Tall surface so every section renders at once (#1545 root cause).
  await tester.binding.setSurfaceSize(const Size(1200, 3200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        vehicleProfileRepositoryProvider.overrideWithValue(repo),
        // The vehicle save-actions extension reads [fillUpListProvider]
        // (for `latestOdometerKm`) and the post-save side-effect calls
        // [activeProfileProvider]. Both reach Hive boxes the widget-test
        // setUp doesn't initialise — stub them (#1545).
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

class _EmptyFillUpList extends FillUpList {
  @override
  List<FillUp> build() => const [];
}

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
