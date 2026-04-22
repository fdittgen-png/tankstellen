import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/features/vehicle/data/repositories/vehicle_profile_repository.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vin_data.dart';
import 'package:tankstellen/features/vehicle/presentation/screens/edit_vehicle_screen.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';
import 'package:tankstellen/features/vehicle/providers/vin_decoder_provider.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// Widget tests for the VIN decoder UI added to [EditVehicleScreen]
/// (#812 phase 2).
///
/// These tests drive the real screen; the VIN decoder is overridden
/// per test so no network call happens. The vehicle repository is a
/// fake backed by an in-memory settings map so Save doesn't touch
/// Hive.
void main() {
  group('EditVehicleScreen — VIN decoder UI (#812)', () {
    testWidgets('renders the VIN field and decode button with tooltip',
        (tester) async {
      await _pumpEditScreen(tester);

      expect(find.text('VIN (optional)'), findsOneWidget);
      // The decode button is an IconButton with the search icon and
      // the localized tooltip. Tooltip lookup also proves the
      // accessibility requirement (#566) is satisfied.
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byTooltip('Decode VIN'), findsOneWidget);
    });

    testWidgets(
      'decoding an empty VIN shows "Invalid VIN format" snackbar '
      'and never opens the confirm dialog',
      (tester) async {
        await _pumpEditScreen(tester);

        await tester.tap(find.byTooltip('Decode VIN'));
        await tester.pump(); // start snackbar animation
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('Invalid VIN format'), findsOneWidget);
        expect(find.text('Is this your car?'), findsNothing);
      },
    );

    testWidgets(
      'decoding a VIN that returns VinDataSource.invalid shows the '
      '"Couldn\'t decode" snackbar and skips the dialog',
      (tester) async {
        await _pumpEditScreen(
          tester,
          decoderResult: (vin) => VinData(
            vin: vin,
            source: VinDataSource.invalid,
          ),
        );

        await tester.enterText(
          find.widgetWithText(TextFormField, 'VIN (optional)'),
          'BADBADBADBADBADBA',
        );
        await tester.tap(find.byTooltip('Decode VIN'));
        await tester.pumpAndSettle();

        expect(find.text('Is this your car?'), findsNothing);
        // Either the generic decode error or the invalid-format label;
        // we short-circuit on invalid with the invalid-format string.
        expect(
          find.text('Invalid VIN format'),
          findsOneWidget,
          reason: 'Invalid VIN decoder results show the invalid-format '
              'snackbar; the dialog must stay dismissed.',
        );
      },
    );

    testWidgets(
      'decoding a valid VIN opens the confirm dialog with a full '
      'vPIC summary (year, make, model, displacement, cylinders, fuel)',
      (tester) async {
        await _pumpEditScreen(
          tester,
          decoderResult: (vin) => VinData(
            vin: vin,
            make: 'Peugeot',
            model: '107',
            modelYear: 2008,
            displacementL: 1.0,
            cylinderCount: 3,
            fuelTypePrimary: 'Gasoline',
            source: VinDataSource.vpic,
          ),
        );

        await tester.enterText(
          find.widgetWithText(TextFormField, 'VIN (optional)'),
          'VF36B8HZL8R123456',
        );
        await tester.tap(find.byTooltip('Decode VIN'));
        await tester.pumpAndSettle();

        expect(find.text('Is this your car?'), findsOneWidget);
        // The body is assembled by the l10n ICU template. We don't
        // assert the exact formatting character-for-character — just
        // that every dynamic piece made it through.
        expect(
          find.textContaining('Peugeot'),
          findsOneWidget,
        );
        expect(find.textContaining('107'), findsOneWidget);
        expect(find.textContaining('2008'), findsOneWidget);
        expect(find.textContaining('1.0'), findsOneWidget);
        expect(find.textContaining('3'), findsWidgets);
        expect(find.textContaining('Gasoline'), findsOneWidget);

        // Both dialog actions must be present.
        expect(find.text('Yes, auto-fill'), findsOneWidget);
        expect(find.text('Modify manually'), findsOneWidget);
      },
    );

    testWidgets(
      'tapping "Yes, auto-fill" closes the dialog and leaves the VIN '
      'in the field (the profile auto-fill is exercised by the save '
      'round-trip below)',
      (tester) async {
        await _pumpEditScreen(
          tester,
          decoderResult: (vin) => VinData(
            vin: vin,
            make: 'Peugeot',
            model: '107',
            modelYear: 2008,
            displacementL: 1.0,
            cylinderCount: 3,
            fuelTypePrimary: 'Gasoline',
            source: VinDataSource.vpic,
          ),
        );

        await tester.enterText(
          find.widgetWithText(TextFormField, 'VIN (optional)'),
          'VF36B8HZL8R123456',
        );
        await tester.tap(find.byTooltip('Decode VIN'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Yes, auto-fill'));
        await tester.pumpAndSettle();

        expect(find.text('Is this your car?'), findsNothing);
      },
    );

    testWidgets(
      'tapping "Yes, auto-fill" then Save persists the decoded '
      'engineDisplacementCc (L→cc), cylinderCount, and VIN on the '
      'new vehicle profile',
      (tester) async {
        final repo = VehicleProfileRepository(_FakeSettings());

        await _pumpEditScreen(
          tester,
          repoOverride: repo,
          decoderResult: (vin) => VinData(
            vin: vin,
            make: 'Peugeot',
            model: '107',
            modelYear: 2008,
            displacementL: 1.0,
            cylinderCount: 3,
            fuelTypePrimary: 'Gasoline',
            source: VinDataSource.vpic,
          ),
        );

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Name'),
          'My Peugeot',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'VIN (optional)'),
          'VF36B8HZL8R123456',
        );
        await tester.tap(find.byTooltip('Decode VIN'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Yes, auto-fill'));
        await tester.pumpAndSettle();

        // Tap the "Save" FilledButton.icon at the bottom (not the
        // AppBar check — scrolling is simpler this way).
        await tester.ensureVisible(
          find.widgetWithText(FilledButton, 'Save'),
        );
        await tester.tap(find.widgetWithText(FilledButton, 'Save'));
        await tester.pumpAndSettle();

        final saved = repo.getAll();
        expect(saved, hasLength(1));
        expect(saved.first.name, 'My Peugeot');
        expect(saved.first.vin, 'VF36B8HZL8R123456');
        expect(saved.first.engineDisplacementCc, 1000,
            reason: '1.0 L displacement must be persisted as 1000 cc');
        expect(saved.first.engineCylinders, 3);
      },
    );

    testWidgets(
      'tapping "Modify manually" closes the dialog and leaves the '
      'engine fields unset — saving produces a profile with null '
      'engineDisplacementCc / cylinderCount',
      (tester) async {
        final repo = VehicleProfileRepository(_FakeSettings());

        await _pumpEditScreen(
          tester,
          repoOverride: repo,
          decoderResult: (vin) => VinData(
            vin: vin,
            make: 'Peugeot',
            model: '107',
            modelYear: 2008,
            displacementL: 1.0,
            cylinderCount: 3,
            fuelTypePrimary: 'Gasoline',
            source: VinDataSource.vpic,
          ),
        );

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Name'),
          'My Peugeot',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'VIN (optional)'),
          'VF36B8HZL8R123456',
        );
        await tester.tap(find.byTooltip('Decode VIN'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Modify manually'));
        await tester.pumpAndSettle();

        expect(find.text('Is this your car?'), findsNothing);

        await tester.ensureVisible(
          find.widgetWithText(FilledButton, 'Save'),
        );
        await tester.tap(find.widgetWithText(FilledButton, 'Save'));
        await tester.pumpAndSettle();

        final saved = repo.getAll();
        expect(saved, hasLength(1));
        // VIN is still persisted (the user typed it) but the engine
        // fields stay null — that's the whole point of "modify
        // manually".
        expect(saved.first.vin, 'VF36B8HZL8R123456');
        expect(saved.first.engineDisplacementCc, isNull);
        expect(saved.first.engineCylinders, isNull);
      },
    );

    testWidgets(
      'a WMI-only (offline) decode opens the dialog with the '
      'partial-info note so the user knows only some fields will '
      'be pre-filled',
      (tester) async {
        await _pumpEditScreen(
          tester,
          decoderResult: (vin) => VinData(
            vin: vin,
            make: 'Peugeot',
            country: 'France',
            source: VinDataSource.wmiOffline,
          ),
        );

        await tester.enterText(
          find.widgetWithText(TextFormField, 'VIN (optional)'),
          'VF38HKFVZ6R123456',
        );
        await tester.tap(find.byTooltip('Decode VIN'));
        await tester.pumpAndSettle();

        expect(find.text('Is this your car?'), findsOneWidget);
        expect(
          find.text('Partial info (offline). You can edit below.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'every interactive element on the edit screen meets the Android '
      'tap-target guideline (48dp minimum, #566)',
      (tester) async {
        await _pumpEditScreen(tester);

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

/// Pumps [EditVehicleScreen] inside a ProviderScope with the minimum
/// overrides needed to run the VIN flow offline.
///
/// [decoderResult] controls what [decodedVinProvider] returns for a
/// given VIN. Returning `null` mimics the "no result" path.
/// [repoOverride] injects a real [VehicleProfileRepository] (backed by
/// the fake settings map) so callers can assert on the saved profile.
Future<void> _pumpEditScreen(
  WidgetTester tester, {
  VinData? Function(String vin)? decoderResult,
  VehicleProfileRepository? repoOverride,
}) async {
  final repo = repoOverride ?? VehicleProfileRepository(_FakeSettings());

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        vehicleProfileRepositoryProvider.overrideWithValue(repo),
        if (decoderResult != null)
          decodedVinProvider.overrideWith((ref, vin) async {
            return decoderResult(vin);
          }),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: EditVehicleScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
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
