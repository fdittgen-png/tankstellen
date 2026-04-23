import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/features/vehicle/data/repositories/vehicle_profile_repository.dart';
import 'package:tankstellen/features/vehicle/presentation/screens/edit_vehicle_screen.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// Widget tests for the in-place VIN explanation sheet (#895).
///
/// The info icon next to the VIN field opens a bottom sheet with
/// four labelled sections. These tests verify the tap target, the
/// Semantics label, the four section headings, and that dismissing
/// returns focus to the VIN field.
void main() {
  group('EditVehicleScreen — VIN info sheet (#895)', () {
    testWidgets('renders the info icon with the correct Semantics label',
        (tester) async {
      final handle = tester.ensureSemantics();
      await _pumpEditScreen(tester);

      // Tooltip is the primary mechanism; the Semantics wrapper
      // mirrors it so screen readers announce the same thing.
      expect(
        find.byTooltip('What is a VIN?'),
        findsOneWidget,
        reason:
            'The info icon must expose a tooltip identical to the Semantics label.',
      );
      expect(
        find.bySemanticsLabel('What is a VIN?'),
        findsWidgets,
        reason: 'Semantics label must be set so TalkBack reads it aloud.',
      );
      expect(find.byIcon(Icons.info_outline), findsOneWidget);

      handle.dispose();
    });

    testWidgets(
      'tapping the info icon opens the sheet with all four '
      'section headings',
      (tester) async {
        await _pumpEditScreen(tester);

        await tester.tap(find.byTooltip('What is a VIN?'));
        await tester.pumpAndSettle();

        // Every section title must be visible — verifying by
        // find.text catches both the top header (same text as the
        // first section title) and each subsequent section heading.
        expect(find.text('What is a VIN?'), findsWidgets);
        expect(find.text('Why we ask'), findsOneWidget);
        expect(find.text('Privacy'), findsOneWidget);
        expect(find.text('Where to find it'), findsOneWidget);
      },
    );

    testWidgets(
      'dismissing the sheet returns focus to the VIN text field',
      (tester) async {
        // Use a taller test window so the full bottom sheet (with
        // the dismiss button) fits without having to scroll.
        await tester.binding.setSurfaceSize(const Size(800, 1200));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await _pumpEditScreen(tester);

        await tester.tap(find.byTooltip('What is a VIN?'));
        await tester.pumpAndSettle();

        // Scroll the dismiss button into view and tap it.
        await tester.ensureVisible(find.text('Got it'));
        await tester.tap(find.text('Got it'));
        await tester.pumpAndSettle();

        // Sheet should be gone.
        expect(find.text('Why we ask'), findsNothing);

        // Focus must sit on the VIN TextFormField: find the
        // EditableText descendant and check its FocusNode.
        final editable = tester.widget<EditableText>(
          find.descendant(
            of: find.widgetWithText(TextFormField, 'VIN (optional)'),
            matching: find.byType(EditableText),
          ),
        );
        expect(
          editable.focusNode.hasFocus,
          isTrue,
          reason:
              'After the VIN info sheet closes, focus must return to '
              'the VIN TextFormField so TalkBack users can keep '
              'typing without hunting for the input.',
        );
      },
    );

    testWidgets(
      'the info icon meets the 48dp Android tap-target guideline',
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

Future<void> _pumpEditScreen(WidgetTester tester) async {
  final repo = VehicleProfileRepository(_FakeSettings());
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
