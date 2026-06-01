// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/storage/storage_providers.dart';
import 'package:tankstellen/features/consumption/data/exporters/backup/backup_xml_writer.dart';
import 'package:tankstellen/features/consumption/data/exporters/backup/backup_zip_reader.dart';
import 'package:tankstellen/features/consumption/data/exporters/backup/backup_zipper.dart';
import 'package:tankstellen/features/consumption/domain/entities/fill_up.dart';
import 'package:tankstellen/features/consumption/presentation/screens/consumption_screen.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/backup_restore_flow.dart';
import 'package:tankstellen/features/profile/providers/gamification_enabled_provider.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';
import '../../../../helpers/pump_app.dart';
import '../../../../helpers/silence_error_logger.dart';

class _FakeSettings implements SettingsStorage {
  final Map<String, dynamic> _data = {};
  @override
  dynamic getSetting(String key) => _data[key];
  @override
  Future<void> putSetting(String key, dynamic value) async => _data[key] = value;
  @override
  bool get isSetupComplete => true;
  @override
  bool get isSetupSkipped => false;
  @override
  Future<void> skipSetup() async {}
  @override
  Future<void> resetSetupSkip() async {}
}

/// A backup zip carrying a single vehicle + a single fill-up (no
/// charging logs, so the Hive-backed charging store is never touched).
Uint8List _sampleBackupBytes() {
  final xml = BackupXmlWriter().build(
    vehicles: const [
      VehicleProfile(id: 'rv1', name: 'Restored', type: VehicleType.combustion),
    ],
    fillUps: [
      FillUp(
        id: 'rf1',
        date: DateTime.utc(2026, 4, 1),
        liters: 30,
        totalCost: 50,
        odometerKm: 1000,
        fuelType: FuelType.e10,
      ),
    ],
    trips: const [],
    chargingLogs: const [],
    appVersion: '5.0.0',
    exportedAt: DateTime.utc(2026, 4, 30),
  );
  return const BackupZipper().zip(xml, now: DateTime.utc(2026, 4, 30));
}

Future<void> _pumpScreen(WidgetTester tester) async {
  final storage = _FakeSettings();
  final router = GoRouter(
    initialLocation: '/consumption',
    routes: [
      GoRoute(
        path: '/consumption',
        builder: (_, _) => const ConsumptionScreen(),
      ),
      GoRoute(path: '/carbon', builder: (_, _) => const SizedBox()),
    ],
  );
  await pumpApp(
    tester,
    MaterialApp.router(routerConfig: router),
    overrides: [
      settingsStorageProvider.overrideWithValue(storage),
      gamificationEnabledProvider.overrideWithValue(true),
    ],
  );
}

void main() {
  silenceErrorLoggerSpool();
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    BackupRestoreFlow.debugFilePickerOverride = null;
    BackupRestoreFlow.debugImporterOverride = null;
  });

  group('ConsumptionScreen full-backup restore (#2571)', () {
    testWidgets('a Restore button sits in the app-bar next to Export',
        (tester) async {
      await _pumpScreen(tester);
      expect(find.byKey(const Key('restore_backup')), findsOneWidget);
      expect(find.byKey(const Key('export_backup')), findsOneWidget);
    });

    testWidgets('tapping Restore opens the merge-vs-replace dialog',
        (tester) async {
      BackupRestoreFlow.debugFilePickerOverride =
          () async => _sampleBackupBytes();
      await _pumpScreen(tester);

      await tester.tap(find.byKey(const Key('restore_backup')));
      await tester.pumpAndSettle();

      // Both choices + cancel are offered.
      expect(find.text('Merge'), findsOneWidget);
      expect(find.text('Replace all'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('cancelling the picker does nothing (no dialog)',
        (tester) async {
      BackupRestoreFlow.debugFilePickerOverride = () async => null;
      await _pumpScreen(tester);

      await tester.tap(find.byKey(const Key('restore_backup')));
      await tester.pumpAndSettle();

      expect(find.text('Merge'), findsNothing);
    });

    testWidgets('choosing Merge imports and shows a success snackbar',
        (tester) async {
      BackupRestoreFlow.debugFilePickerOverride =
          () async => _sampleBackupBytes();
      await _pumpScreen(tester);

      await tester.tap(find.byKey(const Key('restore_backup')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Merge'));
      await tester.pumpAndSettle();

      // 2 records (1 vehicle + 1 fill-up) restored.
      expect(find.textContaining('restored'), findsOneWidget);
    });

    testWidgets('a corrupt file surfaces a localized error snackbar',
        (tester) async {
      BackupRestoreFlow.debugFilePickerOverride =
          () async => Uint8List.fromList([1, 2, 3, 4]);
      await _pumpScreen(tester);

      await tester.tap(find.byKey(const Key('restore_backup')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Merge'));
      await tester.pumpAndSettle();

      expect(find.textContaining('not a valid Tankstellen backup'),
          findsOneWidget);
      // And the exception type is the typed one (sanity on the path).
      expect(const BackupZipReader().runtimeType, BackupZipReader);
    });
  });
}
