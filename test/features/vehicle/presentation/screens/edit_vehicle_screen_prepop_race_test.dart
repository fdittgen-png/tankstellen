import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/features/vehicle/data/repositories/vehicle_profile_repository.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/presentation/screens/edit_vehicle_screen.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// Widget tests for the VIN pre-population race fix (#1328).
///
/// The original bug: `_loadExisting()` runs in a postFrameCallback and
/// reads `vehicleProfileListProvider` once — if the provider hasn't
/// resolved (Hive box still hydrating, settings storage swap, etc.), it
/// sees an empty list and the VIN textfield (and every other field)
/// stays blank. The fix wires a `ref.listen` in `build()` that re-runs
/// the controller load the moment the provider produces a list
/// containing the target id.
void main() {
  group('EditVehicleScreen — VIN pre-population race (#1328)', () {
    testWidgets(
      'happy path: a profile with a stored VIN populates the VIN '
      'textfield within a frame',
      (tester) async {
        final repo = VehicleProfileRepository(_FakeSettings());
        await repo.save(
          const VehicleProfile(
            id: 'v1',
            name: 'My Test Car',
            vin: 'VF36B8HZL8R123456',
          ),
        );

        await _pumpScreen(tester, repo: repo, vehicleId: 'v1');

        // pump a frame for the postFrameCallback, then a second frame
        // so the setState propagates into the rendered TextField.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

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
      'race regression: provider initially returns an empty list, then '
      'transitions to data; the VIN field gets populated by the second-'
      'chance refill',
      (tester) async {
        // Two repos: an empty one for the initial pump (mimics the
        // race — Hive hasn't returned the saved profile yet), and a
        // populated one we swap in mid-flight via container override.
        final emptyRepo = VehicleProfileRepository(_FakeSettings());
        final hydratedRepo = VehicleProfileRepository(_FakeSettings());
        await hydratedRepo.save(
          const VehicleProfile(
            id: 'v1',
            name: 'My Test Car',
            vin: 'VF36B8HZL8R123456',
          ),
        );

        // Use a notifier-style override so we can mutate the list AFTER
        // the screen mounts — exactly the race the bug describes.
        final container = ProviderContainer(
          overrides: [
            vehicleProfileRepositoryProvider.overrideWithValue(emptyRepo),
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
        // Initial pump: provider is empty, postFrameCallback runs and
        // _loadExisting finds nothing → field stays blank.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        var field = tester.widget<TextField>(
          find.descendant(
            of: find.widgetWithText(TextFormField, 'VIN (optional)'),
            matching: find.byType(TextField),
          ),
        );
        expect(field.controller?.text, isEmpty,
            reason: 'Pre-fix baseline: empty repo → blank field');

        // Mid-flight provider transition: push the hydrated profile
        // into the notifier. The `ref.listen` in build() must catch
        // this and re-run the controller load.
        container.read(vehicleProfileListProvider.notifier).state = [
          const VehicleProfile(
            id: 'v1',
            name: 'My Test Car',
            vin: 'VF36B8HZL8R123456',
          ),
        ];
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        field = tester.widget<TextField>(
          find.descendant(
            of: find.widgetWithText(TextFormField, 'VIN (optional)'),
            matching: find.byType(TextField),
          ),
        );
        expect(
          field.controller?.text,
          'VF36B8HZL8R123456',
          reason: 'After provider resolves the field must populate '
              '(the #1328 fix).',
        );
      },
    );

    testWidgets(
      'second-chance refill does not clobber user edits made after the '
      'initial load',
      (tester) async {
        final repo = VehicleProfileRepository(_FakeSettings());
        await repo.save(
          const VehicleProfile(
            id: 'v1',
            name: 'My Test Car',
            vin: 'VF36B8HZL8R123456',
          ),
        );

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
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        // Initial load completed; user edits the VIN.
        await tester.enterText(
          find.widgetWithText(TextFormField, 'VIN (optional)'),
          'USEREDITS123456XX',
        );
        await tester.pump();

        // A subsequent provider update fires (e.g. another screen saved
        // an unrelated change). The `_hasInitiallyLoaded` guard must
        // prevent the listener from re-loading and stomping on the
        // user's text.
        container.read(vehicleProfileListProvider.notifier).state = [
          const VehicleProfile(
            id: 'v1',
            name: 'My Test Car',
            vin: 'VF36B8HZL8R123456',
          ),
        ];
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        final field = tester.widget<TextField>(
          find.descendant(
            of: find.widgetWithText(TextFormField, 'VIN (optional)'),
            matching: find.byType(TextField),
          ),
        );
        expect(
          field.controller?.text,
          'USEREDITS123456XX',
          reason: 'User edits must survive subsequent provider rebuilds.',
        );
      },
    );
  });
}

Future<void> _pumpScreen(
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
