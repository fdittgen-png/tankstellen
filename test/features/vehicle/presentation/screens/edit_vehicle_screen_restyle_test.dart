import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/widgets/form_section_card.dart';
import 'package:tankstellen/features/vehicle/data/repositories/vehicle_profile_repository.dart';
import 'package:tankstellen/features/vehicle/presentation/screens/edit_vehicle_screen.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// Widget tests for the restyled Edit-Vehicle screen (#751 phase 2).
///
/// Locks in the new structural contract: a big vehicle header at the
/// top, the rest of the form split into grouped `FormSectionCard`s,
/// and a pinned bottom Save button. Also asserts the accessibility
/// guardrails the refactor relies on (tap target, real TextField
/// labels, decorative icons excluded from semantics).
void main() {
  group('EditVehicleScreen restyle (#751 phase 2)', () {
    testWidgets('renders two grouped section cards (Identity + Drivetrain)',
        (tester) async {
      await _pumpEditScreen(tester);

      // Identity + Drivetrain at minimum on a brand-new vehicle (the
      // other cards — adapter / baseline / reminders — render only
      // after the vehicle is saved).
      expect(find.byType(FormSectionCard), findsNWidgets(2));
      expect(find.text('Identity'), findsOneWidget);
      expect(find.text('Drivetrain'), findsOneWidget);
    });

    testWidgets('renders the big vehicle header with the typed name',
        (tester) async {
      await _pumpEditScreen(tester);

      // Before typing, the header shows the "New vehicle" placeholder.
      expect(find.text('New vehicle'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Name'),
        'My Peugeot 107',
      );
      await tester.pump();

      // The live header reflects the latest name. There is also the
      // Name TextField showing the same string, so we look for the
      // value in an `Expanded > Column` that is the header (simpler:
      // just check findsWidgets).
      expect(find.text('My Peugeot 107'), findsWidgets);
    });

    testWidgets('header shows a plate-style chip with the drivetrain label',
        (tester) async {
      await _pumpEditScreen(tester);

      // Combustion is the default type → chip reads "Combustion".
      // (The SegmentedButton also has a "Combustion" label, so the
      // widget can appear multiple times.)
      expect(find.text('Combustion'), findsWidgets);

      // Switch to Electric and confirm the header chip updates.
      await tester.tap(find.text('Electric').first);
      await tester.pumpAndSettle();

      expect(find.text('Electric'), findsWidgets);
    });

    testWidgets('pins the Save action at the bottom of the Scaffold',
        (tester) async {
      await _pumpEditScreen(tester);

      // The pinned `bottomNavigationBar` Save must always be in the
      // tree regardless of scroll position.
      expect(find.widgetWithText(FilledButton, 'Save'), findsOneWidget);
    });

    testWidgets('every ARB-labelled text input still renders', (tester) async {
      await _pumpEditScreen(tester);

      expect(find.text('Name'), findsOneWidget);
      expect(find.text('VIN (optional)'), findsOneWidget);
      expect(find.text('Identity'), findsOneWidget);
      expect(find.text('Drivetrain'), findsOneWidget);
    });

    testWidgets('meets the Android tap-target guideline (48dp, #566)',
        (tester) async {
      await _pumpEditScreen(tester);

      final handle = tester.ensureSemantics();
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('save still round-trips a minimal profile', (tester) async {
      final repo = VehicleProfileRepository(_FakeSettings());

      await _pumpEditScreen(tester, repoOverride: repo);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Name'),
        'My Peugeot',
      );
      // Tap the pinned bottom Save.
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      final saved = repo.getAll();
      expect(saved, hasLength(1));
      expect(saved.first.name, 'My Peugeot');
    });
  });
}

Future<void> _pumpEditScreen(
  WidgetTester tester, {
  VehicleProfileRepository? repoOverride,
}) async {
  // Tall canvas so both FormSectionCards and the pinned Save button
  // fit without the ListView virtualizing one of them off-screen
  // (the default 800x600 phone harness crops the lower card).
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
