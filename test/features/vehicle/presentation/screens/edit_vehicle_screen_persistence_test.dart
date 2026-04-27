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

/// Architectural-correctness test for #1226: the edit-vehicle Save
/// pathway must preserve every non-form field on the loaded
/// [VehicleProfile] (calibrationMode, pairedAdapterMac, autoRecord
/// and friends, runtime-calibrated η_v, runtime-cached driving-stats
/// aggregates, VIN-decode metadata, ...). Before this fix,
/// `VehicleFormControllers.buildProfile` constructed a fresh
/// `VehicleProfile(...)` and silently fell back to the freezed
/// `@Default` for each — wiping these on every Save.
///
/// #1217 / #1221 was the minimum-scope thread-through for
/// `calibrationMode` only; this test mounts the real screen and
/// proves the broader bug class is closed via copyWith semantics.
void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir =
        await Directory.systemTemp.createTemp('edit_vehicle_persistence_');
    Hive.init(tempDir.path);
    // Boxes opened by sub-widgets of the edit screen (auto-record,
    // service reminders, baselines).
    await Hive.openBox<String>(HiveBoxes.serviceReminders);
    await Hive.openBox<String>(HiveBoxes.obd2Baselines);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  testWidgets(
      'editing one form field via Save preserves all non-form fields '
      '(#1226)', (tester) async {
    final repo = VehicleProfileRepository(_FakeSettings());
    final stored = VehicleProfile(
      id: 'v1',
      name: 'Car',
      calibrationMode: VehicleCalibrationMode.fuzzy,
      pairedAdapterMac: 'AA:BB:CC:DD:EE:FF',
      autoRecord: true,
      movementStartThresholdKmh: 7.5,
      disconnectSaveDelaySec: 90,
      backgroundLocationConsent: true,
      volumetricEfficiency: 0.92,
      volumetricEfficiencySamples: 120,
      referenceVehicleId: 'ref-vw-polo-2018',
      aggregatesTripCount: 17,
      aggregatesUpdatedAt: DateTime.utc(2026, 4, 1, 12),
    );
    await repo.save(stored);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          vehicleProfileRepositoryProvider.overrideWithValue(repo),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: EditVehicleScreen(vehicleId: 'v1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Edit ONE form-managed field — the name. Every other field on
    // VehicleProfile is either form-managed (and unchanged here) or
    // non-form-managed (and must survive the Save verbatim).
    await tester.dragUntilVisible(
      find.widgetWithText(TextFormField, 'Car'),
      find.byType(ListView),
      const Offset(0, 200),
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Car'),
      'Polo',
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Tap the pinned bottom Save bar.
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final after = repo.getById('v1');
    expect(after, isNotNull);

    // The form-managed change landed.
    expect(after!.name, 'Polo');

    // Every non-form field survives the round-trip via copyWith.
    expect(after.calibrationMode, VehicleCalibrationMode.fuzzy,
        reason: '#1217 / #1221 — must NOT revert to rule');
    expect(after.pairedAdapterMac, 'AA:BB:CC:DD:EE:FF',
        reason: '#1004 — long-lived adapter pairing must survive');
    expect(after.autoRecord, isTrue,
        reason: '#1004 phase 1 — hands-free toggle must survive');
    expect(after.movementStartThresholdKmh, 7.5,
        reason: '#1004 — auto-record movement threshold must survive');
    expect(after.disconnectSaveDelaySec, 90,
        reason: '#1004 — disconnect-save debounce must survive');
    expect(after.backgroundLocationConsent, isTrue,
        reason: '#1004 — bg-location consent must survive');
    expect(after.volumetricEfficiency, 0.92,
        reason: '#815 — runtime-calibrated η_v must survive');
    expect(after.volumetricEfficiencySamples, 120,
        reason: '#815 — η_v sample counter must survive');
    expect(after.referenceVehicleId, 'ref-vw-polo-2018',
        reason: '#950 — VIN-decoder catalog match must survive');
    expect(after.aggregatesTripCount, 17,
        reason: '#1193 — driving-stats aggregate trip count must survive');
    expect(after.aggregatesUpdatedAt, DateTime.utc(2026, 4, 1, 12),
        reason: '#1193 — aggregates timestamp must survive');
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
