import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/features/vehicle/data/obd2_vin_reader.dart';
import 'package:tankstellen/features/vehicle/data/repositories/vehicle_profile_repository.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/presentation/screens/edit_vehicle_screen.dart';
import 'package:tankstellen/features/vehicle/providers/obd2_vin_reader_provider.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// Widget tests for the "Read VIN from car" button on
/// [EditVehicleScreen] (#1162).
///
/// The OBD2 read is faked via a [_FakeVinReaderService] override on
/// [vinReaderServiceProvider] so no Bluetooth stack is required. The
/// button is gated on the active profile's `pairedAdapterMac` field;
/// these tests cover both the hidden (no adapter) and visible (paired)
/// states plus the success / failure UX branches.
void main() {
  group('EditVehicleScreen — Read-VIN-from-car button (#1162)', () {
    testWidgets(
      'button is visible but disabled with a hint when the vehicle has '
      'no paired adapter (#1328)',
      (tester) async {
        await _pumpWithProfile(tester, withPairedAdapter: false);

        // #1328 — the button is always rendered so users discover the
        // feature. With no paired adapter it is disabled (onPressed
        // null) and a small helper text is shown underneath.
        final buttonFinder = find.byKey(const Key('vehicleReadVinFromCar'));
        expect(buttonFinder, findsOneWidget);
        final button = tester.widget<OutlinedButton>(buttonFinder);
        expect(button.onPressed, isNull,
            reason: 'No paired adapter → button must render disabled');
        expect(
          find.byKey(const Key('vehicleReadVinNoAdapterHint')),
          findsOneWidget,
        );
        expect(
          find.text('Pair an OBD2 adapter first to read VIN automatically'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'button is visible and enabled with a tooltip when the vehicle '
      'has a paired adapter',
      (tester) async {
        await _pumpWithProfile(tester, withPairedAdapter: true);

        final buttonFinder = find.byKey(const Key('vehicleReadVinFromCar'));
        expect(buttonFinder, findsOneWidget);
        final button = tester.widget<OutlinedButton>(buttonFinder);
        expect(button.onPressed, isNotNull,
            reason: 'Paired adapter → button must be tappable');
        expect(find.text('Read VIN from car'), findsOneWidget);
        expect(
          find.byTooltip('Read VIN from the paired OBD2 adapter'),
          findsOneWidget,
        );
        // The "no adapter" hint is gone when paired.
        expect(
          find.byKey(const Key('vehicleReadVinNoAdapterHint')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'tapping the button on a successful read populates the VIN field',
      (tester) async {
        await _pumpWithProfile(
          tester,
          withPairedAdapter: true,
          readerResult: const ObdVinResult.success('VF36B8HZL8R123456'),
        );

        await tester.tap(find.byKey(const Key('vehicleReadVinFromCar')));
        await tester.pumpAndSettle();

        // The VIN field should now show the decoded value. We look for
        // the TextField with the localized label.
        final field = tester.widget<TextField>(
          find.descendant(
            of: find.widgetWithText(TextFormField, 'VIN (optional)'),
            matching: find.byType(TextField),
          ),
        );
        expect(field.controller?.text, 'VF36B8HZL8R123456');
      },
    );

    testWidgets(
      'tapping the button on an `unsupported` failure shows the '
      'pre-2005 snackbar and leaves the VIN field unchanged',
      (tester) async {
        await _pumpWithProfile(
          tester,
          withPairedAdapter: true,
          readerResult: const ObdVinResult.failure(
            ObdVinFailureReason.unsupported,
          ),
        );

        await tester.tap(find.byKey(const Key('vehicleReadVinFromCar')));
        await tester.pump(); // tick the snackbar in
        await tester.pump(const Duration(milliseconds: 500));

        expect(
          find.text(
            'VIN not available (Mode 09 PID 02 unsupported on pre-2005 '
            'vehicles)',
          ),
          findsOneWidget,
        );
        // The VIN field stays empty so the user can still type one.
        final field = tester.widget<TextField>(
          find.descendant(
            of: find.widgetWithText(TextFormField, 'VIN (optional)'),
            matching: find.byType(TextField),
          ),
        );
        expect(field.controller?.text, isEmpty);
      },
    );

    testWidgets(
      'tapping the button on a generic (timeout/io/malformed) failure '
      'shows the manual-entry snackbar',
      (tester) async {
        await _pumpWithProfile(
          tester,
          withPairedAdapter: true,
          readerResult: const ObdVinResult.failure(
            ObdVinFailureReason.timeout,
          ),
        );

        await tester.tap(find.byKey(const Key('vehicleReadVinFromCar')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(
          find.text('VIN read failed — please enter manually'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'the visible button + surrounding interactive elements meet the '
      'Android tap-target guideline (#566)',
      (tester) async {
        await _pumpWithProfile(tester, withPairedAdapter: true);

        final handle = tester.ensureSemantics();
        await expectLater(
          tester,
          meetsGuideline(androidTapTargetGuideline),
        );
        handle.dispose();
      },
    );
  });
}

/// Pumps [EditVehicleScreen] in edit-mode with a stored profile that
/// either has or does not have a paired adapter. The OBD2 reader is
/// always faked so the test never touches a real transport.
Future<void> _pumpWithProfile(
  WidgetTester tester, {
  required bool withPairedAdapter,
  ObdVinResult? readerResult,
}) async {
  final repo = VehicleProfileRepository(_FakeSettings());
  await repo.save(
    VehicleProfile(
      id: 'v1',
      name: 'My Test Car',
      pairedAdapterMac:
          withPairedAdapter ? 'AA:BB:CC:DD:EE:FF' : null,
    ),
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        vehicleProfileRepositoryProvider.overrideWithValue(repo),
        vinReaderServiceProvider.overrideWithValue(
          _FakeVinReaderService(
            result: readerResult ??
                const ObdVinResult.failure(ObdVinFailureReason.io),
          ),
        ),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: EditVehicleScreen(vehicleId: 'v1'),
      ),
    ),
  );
  // The screen loads the existing profile in a post-frame callback;
  // settle so the paired-adapter UI renders before the test asserts.
  await tester.pumpAndSettle();
}

class _FakeVinReaderService implements VinReaderService {
  final ObdVinResult result;

  const _FakeVinReaderService({required this.result});

  @override
  Future<ObdVinResult> readVin({required String pairedAdapterMac}) async =>
      result;
}

/// Minimal in-memory [SettingsStorage] so the repository can run
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
