import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/features/vehicle/data/repositories/vehicle_profile_repository.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/presentation/screens/edit_vehicle_screen.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// Regression coverage for #1217 — the bug was that
/// [VehicleFormControllers.buildProfile] constructed a brand-new
/// [VehicleProfile] from a fixed parameter list, so any field NOT on
/// that list (e.g. the long-lived OBD2 pairing, the auto-record
/// toggle, the learned volumetric efficiency, the calibration mode,
/// etc.) was silently wiped on every Save.
///
/// The fix is architectural: [buildProfile] now takes the saved
/// profile as `existing:` and uses `copyWith` semantics, so anything
/// not on the form is preserved automatically. Asserting only on
/// `calibrationMode` (the field reported in #1217) would not prove
/// the architectural fix — this test pins down a representative slice
/// of the larger bug surface so future regressions on similar fields
/// fail loudly.
void main() {
  group('EditVehicleScreen — non-form field persistence (#1217)', () {
    testWidgets(
      'saving from the edit screen preserves every field the form '
      'does not touch',
      (tester) async {
        final repo = VehicleProfileRepository(_FakeSettings());

        // A profile that already has a bunch of non-default values
        // from features that live OUTSIDE the edit form (auto-record,
        // OBD2 pairing, VE learner, calibration mode segment).
        const original = VehicleProfile(
          id: 'v1',
          name: 'My Peugeot 107',
          type: VehicleType.combustion,
          tankCapacityL: 35.0,
          preferredFuelType: 'e10',
          // #894 — set by the calibration-mode segmented button.
          calibrationMode: VehicleCalibrationMode.fuzzy,
          // #1004 — set by the auto-record / pairing flow.
          pairedAdapterMac: 'AA:BB:CC:DD:EE:FF',
          autoRecord: true,
          movementStartThresholdKmh: 7.5,
          disconnectSaveDelaySec: 90,
          backgroundLocationConsent: true,
          // #815 — written by the η_v learner from real driving.
          volumetricEfficiency: 0.92,
          volumetricEfficiencySamples: 50,
          // #950 — written by the reference-vehicle migrator.
          referenceVehicleId: 'peugeot-107-2008-',
        );
        await repo.save(original);

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
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: EditVehicleScreen(vehicleId: 'v1'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Edit a user-visible field so the Save path is genuinely
        // exercised (not a no-op).
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Name'),
          'My Peugeot 107 (renamed)',
        );

        // Tap the bottom Save button; ensureVisible scrolls into the
        // viewport in case the host ListView accretes new sections.
        final saveButton = find.widgetWithText(FilledButton, 'Save');
        await tester.ensureVisible(saveButton);
        await tester.pumpAndSettle();
        await tester.tap(saveButton);
        await tester.pumpAndSettle();

        // Reload from the repository — same source of truth the
        // provider reads from.
        final saved = repo.getById('v1');
        expect(saved, isNotNull);

        // The user-edited field changed.
        expect(saved!.name, 'My Peugeot 107 (renamed)');

        // Every non-form field survives — the architectural fix.
        expect(
          saved.calibrationMode,
          VehicleCalibrationMode.fuzzy,
          reason: '#894 calibration mode must survive Save',
        );
        expect(
          saved.pairedAdapterMac,
          'AA:BB:CC:DD:EE:FF',
          reason: '#1004 long-lived adapter pairing must survive Save',
        );
        expect(
          saved.autoRecord,
          isTrue,
          reason: '#1004 auto-record toggle must survive Save',
        );
        expect(
          saved.movementStartThresholdKmh,
          7.5,
          reason: '#1004 movement threshold must survive Save',
        );
        expect(
          saved.disconnectSaveDelaySec,
          90,
          reason: '#1004 disconnect-save delay must survive Save',
        );
        expect(
          saved.backgroundLocationConsent,
          isTrue,
          reason: '#1004 background-location consent must survive Save',
        );
        expect(
          saved.volumetricEfficiency,
          0.92,
          reason: '#815 learned VE must survive Save',
        );
        expect(
          saved.volumetricEfficiencySamples,
          50,
          reason: '#815 VE sample count must survive Save',
        );
        expect(
          saved.referenceVehicleId,
          'peugeot-107-2008-',
          reason: '#950 reference-vehicle id must survive Save',
        );

        // Sanity: the user-editable combustion fields still round-trip.
        expect(saved.type, VehicleType.combustion);
        expect(saved.tankCapacityL, 35.0);
        expect(saved.preferredFuelType, 'e10');
      },
    );
  });
}

/// Minimal in-memory [SettingsStorage] so the repository round-trips
/// without a Hive box.
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
