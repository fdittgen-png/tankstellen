import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/widgets/page_scaffold.dart';
import 'package:tankstellen/features/vehicle/data/repositories/vehicle_profile_repository.dart';
import 'package:tankstellen/features/vehicle/presentation/screens/edit_vehicle_screen.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// Regression: EditVehicleScreen must render its chrome via
/// [PageScaffold] (#923 phase 3k). The `bottomNavigationBar` is still
/// wired through (pinned Save) so the save-bar button remains findable.
void main() {
  group('EditVehicleScreen — PageScaffold migration (#923 phase 3k)', () {
    testWidgets('chrome is rendered via PageScaffold (add-new vehicle path)',
        (tester) async {
      await _pumpEditScreen(tester);

      expect(find.byType(PageScaffold), findsOneWidget);
    });

    testWidgets('page title reads "Add vehicle" when creating a new profile',
        (tester) async {
      await _pumpEditScreen(tester);

      // Title flows through PageScaffold → AppBar.title.
      expect(find.text('Add vehicle'), findsOneWidget);
    });

    testWidgets('app-bar Save action is still wired as an IconButton',
        (tester) async {
      await _pumpEditScreen(tester);

      // The app-bar action is the only IconButton with Icons.check in
      // the tree (drivetrain/extras rows render distinct icons).
      final saveAction = find.widgetWithIcon(IconButton, Icons.check);
      expect(saveAction, findsOneWidget);
    });

    testWidgets('pinned bottom Save survives the PageScaffold migration',
        (tester) async {
      await _pumpEditScreen(tester);

      // The VehicleSaveBar sits in PageScaffold.bottomNavigationBar;
      // its Save button must still be findable.
      expect(find.widgetWithText(FilledButton, 'Save'), findsOneWidget);
    });
  });
}

Future<void> _pumpEditScreen(
  WidgetTester tester, {
  VehicleProfileRepository? repoOverride,
}) async {
  // Tall canvas so the form and the pinned save bar both fit (see
  // edit_vehicle_screen_restyle_test.dart for the same rationale).
  tester.view.physicalSize = const Size(900, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final repo = repoOverride ?? VehicleProfileRepository(_FakeSettings());
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        vehicleProfileRepositoryProvider.overrideWithValue(repo),
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
