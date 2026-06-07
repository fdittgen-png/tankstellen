// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

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
import 'package:tankstellen/features/vehicle/presentation/widgets/engine_power_field.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// Widget-level coverage for the engine-power field on the edit-vehicle
/// form (Epic #3015): it renders with the pre-filled kW value, shows the
/// derived PS equivalent as helper text, and an edit persists into the
/// saved [VehicleProfile] via the existing buildProfile / Save flow.
void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('edit_vehicle_power_');
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

  Future<VehicleProfileRepository> pumpScreen(
    WidgetTester tester,
    VehicleProfile stored,
  ) async {
    final repo = VehicleProfileRepository(_FakeSettings());
    await repo.save(stored);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          vehicleProfileRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: EditVehicleScreen(vehicleId: stored.id),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return repo;
  }

  testWidgets('renders the power field pre-filled + derived PS helper',
      (tester) async {
    await pumpScreen(
      tester,
      const VehicleProfile(
        id: 'v1',
        name: 'Golf',
        type: VehicleType.combustion,
        enginePowerKw: 110,
      ),
    );

    // The dedicated power field is in the tree, pre-filled with the
    // profile's kW value.
    final powerField =
        find.byKey(const Key('vehicle_engine_power_field'));
    await tester.dragUntilVisible(
      powerField,
      find.byType(ListView),
      const Offset(0, -200),
    );
    expect(powerField, findsOneWidget);
    final tf = tester.widget<TextFormField>(powerField);
    expect(tf.controller?.text, '110');

    // The derived PS helper text is shown (110 kW ≈ 150 PS).
    expect(find.byType(EnginePowerField), findsOneWidget);
    expect(find.text('≈ 150 PS'), findsOneWidget);
  });

  testWidgets('editing the power value persists into the saved profile',
      (tester) async {
    final repo = await pumpScreen(
      tester,
      const VehicleProfile(
        id: 'v2',
        name: 'Golf',
        type: VehicleType.combustion,
        enginePowerKw: 110,
      ),
    );

    final powerField =
        find.byKey(const Key('vehicle_engine_power_field'));
    await tester.dragUntilVisible(
      powerField,
      find.byType(ListView),
      const Offset(0, -200),
    );
    await tester.enterText(powerField, '96');
    await tester.pump();

    // The PS helper tracks the edited value live (96 kW ≈ 131 PS).
    expect(find.text('≈ 131 PS'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final after = repo.getById('v2');
    expect(after, isNotNull);
    expect(after!.enginePowerKw, 96,
        reason: 'the edited engine power must persist via Save');
  });
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
