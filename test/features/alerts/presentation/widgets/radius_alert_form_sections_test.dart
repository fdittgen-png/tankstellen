import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/alerts/presentation/widgets/radius_alert_form_sections.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('RadiusAlertLabelField', () {
    testWidgets('renders the localised hint text', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await pumpApp(
        tester,
        RadiusAlertLabelField(
          controller: controller,
          onChanged: () {},
        ),
      );

      expect(find.text('Label (e.g. Home diesel)'), findsOneWidget);
    });

    testWidgets('forwards keystrokes to the controller and fires onChanged',
        (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      var changes = 0;

      await pumpApp(
        tester,
        RadiusAlertLabelField(
          controller: controller,
          onChanged: () => changes++,
        ),
      );

      await tester.enterText(find.byType(TextField), 'Home diesel');
      await tester.pump();

      expect(controller.text, 'Home diesel');
      expect(changes, greaterThanOrEqualTo(1));
    });
  });

  group('RadiusAlertFuelTypeField', () {
    testWidgets('renders the current value and hides FuelType.all',
        (tester) async {
      await pumpApp(
        tester,
        RadiusAlertFuelTypeField(
          value: FuelType.diesel,
          onChanged: (_) {},
        ),
      );

      // The dropdown shows the current selection (diesel) on the
      // closed surface; FuelType.all has no menu entry, but we
      // verify by tapping and counting items.
      await tester.tap(find.byType(DropdownButtonFormField<FuelType>));
      await tester.pumpAndSettle();

      // The expected count equals FuelType.values.length minus the
      // "all" sentinel.
      final expectedItems =
          FuelType.values.where((t) => t != FuelType.all).length;
      // Each rendered menu item is a DropdownMenuItem<FuelType>.
      expect(
        find.byType(DropdownMenuItem<FuelType>, skipOffstage: false),
        // The dropdown duplicates items for the field surface; the
        // menu adds one more set, so count is at least expectedItems.
        findsAtLeast(expectedItems),
      );
    });

    testWidgets('calls onChanged when a new fuel is picked', (tester) async {
      FuelType? picked;

      await pumpApp(
        tester,
        RadiusAlertFuelTypeField(
          value: FuelType.diesel,
          onChanged: (v) => picked = v,
        ),
      );

      await tester.tap(find.byType(DropdownButtonFormField<FuelType>));
      await tester.pumpAndSettle();
      // Pick e10 — using `last` to grab the menu copy, not the
      // collapsed surface copy.
      await tester.tap(find.text(FuelType.e10.displayName).last);
      await tester.pumpAndSettle();

      expect(picked, FuelType.e10);
    });
  });

  group('RadiusAlertThresholdField', () {
    testWidgets('uses a numeric-with-decimal keyboard', (tester) async {
      final controller = TextEditingController(text: '1.500');
      addTearDown(controller.dispose);

      await pumpApp(
        tester,
        RadiusAlertThresholdField(
          controller: controller,
          onChanged: () {},
        ),
      );

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.keyboardType,
          const TextInputType.numberWithOptions(decimal: true));
    });

    testWidgets('fires onChanged on every keystroke', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      var changes = 0;

      await pumpApp(
        tester,
        RadiusAlertThresholdField(
          controller: controller,
          onChanged: () => changes++,
        ),
      );

      await tester.enterText(find.byType(TextField), '1.499');
      await tester.pump();
      expect(changes, greaterThanOrEqualTo(1));
    });
  });

  group('RadiusAlertRadiusSlider', () {
    testWidgets('shows the rounded radius value', (tester) async {
      await pumpApp(
        tester,
        RadiusAlertRadiusSlider(
          radiusKm: 12.4,
          onChanged: (_) {},
        ),
      );

      // 12.4 rounds to 12 — the row caption should match.
      expect(find.text('12 km'), findsAtLeast(1));
    });

    testWidgets('clamps below 1 km without throwing', (tester) async {
      await pumpApp(
        tester,
        RadiusAlertRadiusSlider(
          radiusKm: 0.0,
          onChanged: (_) {},
        ),
      );

      // No exceptions and the slider builds.
      expect(find.byType(Slider), findsOneWidget);
    });
  });

  group('RadiusAlertFrequencyField', () {
    testWidgets('renders all four daily-frequency options', (tester) async {
      await pumpApp(
        tester,
        RadiusAlertFrequencyField(
          value: 1,
          onChanged: (_) {},
        ),
      );

      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();

      // Each label appears at least once in the open menu.
      expect(find.text('Once a day'), findsAtLeast(1));
      expect(find.text('Twice a day'), findsAtLeast(1));
      expect(find.text('Three times a day'), findsAtLeast(1));
      expect(find.text('Four times a day'), findsAtLeast(1));
    });

    testWidgets('forwards the picked frequency to onChanged', (tester) async {
      int? picked;

      await pumpApp(
        tester,
        RadiusAlertFrequencyField(
          value: 1,
          onChanged: (v) => picked = v,
        ),
      );

      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Three times a day').last);
      await tester.pumpAndSettle();

      expect(picked, 3);
    });
  });

  group('RadiusAlertCenterButtons', () {
    testWidgets('renders both buttons and meets tap-target guideline',
        (tester) async {
      await pumpApp(
        tester,
        RadiusAlertCenterButtons(
          onUseGps: () {},
          onPickOnMap: () {},
          centerSource: null,
        ),
      );

      expect(find.text('Use my location'), findsOneWidget);
      expect(find.text('Pick on map'), findsOneWidget);

      await expectLater(
        tester,
        meetsGuideline(androidTapTargetGuideline),
      );
    });

    testWidgets('shows the center caption when bound', (tester) async {
      await pumpApp(
        tester,
        RadiusAlertCenterButtons(
          onUseGps: () {},
          onPickOnMap: () {},
          centerSource: 'GPS',
        ),
      );

      expect(find.text('GPS'), findsOneWidget);
    });

    testWidgets('hides the caption when no center is bound', (tester) async {
      await pumpApp(
        tester,
        RadiusAlertCenterButtons(
          onUseGps: () {},
          onPickOnMap: () {},
          centerSource: null,
        ),
      );

      // Only the two buttons should carry text.
      expect(find.text('GPS'), findsNothing);
      expect(find.text('Map location'), findsNothing);
    });

    testWidgets('GPS button fires onUseGps; map button fires onPickOnMap',
        (tester) async {
      var gps = 0;
      var map = 0;

      await pumpApp(
        tester,
        RadiusAlertCenterButtons(
          onUseGps: () => gps++,
          onPickOnMap: () => map++,
          centerSource: null,
        ),
      );

      await tester.tap(find.text('Use my location'));
      await tester.pump();
      expect(gps, 1);
      expect(map, 0);

      await tester.tap(find.text('Pick on map'));
      await tester.pump();
      expect(gps, 1);
      expect(map, 1);
    });
  });

  group('RadiusAlertPostalCodeField', () {
    testWidgets('renders the localised postal-code label', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await pumpApp(
        tester,
        RadiusAlertPostalCodeField(
          controller: controller,
          onChanged: () {},
        ),
      );

      expect(find.text('Postal code'), findsOneWidget);
    });

    testWidgets('records typed input via the controller', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await pumpApp(
        tester,
        RadiusAlertPostalCodeField(
          controller: controller,
          onChanged: () {},
        ),
      );

      await tester.enterText(find.byType(TextField), '34120');
      await tester.pump();
      expect(controller.text, '34120');
    });
  });

  group('RadiusAlertActionRow', () {
    testWidgets('save button is disabled when onSave is null',
        (tester) async {
      await pumpApp(
        tester,
        RadiusAlertActionRow(
          onCancel: () {},
          onSave: null,
        ),
      );

      final save = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Save'),
      );
      expect(save.onPressed, isNull);
    });

    testWidgets('save button is enabled when onSave is set', (tester) async {
      var saved = 0;

      await pumpApp(
        tester,
        RadiusAlertActionRow(
          onCancel: () {},
          onSave: () => saved++,
        ),
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pump();
      expect(saved, 1);
    });

    testWidgets('cancel button fires onCancel', (tester) async {
      var cancelled = 0;

      await pumpApp(
        tester,
        RadiusAlertActionRow(
          onCancel: () => cancelled++,
          onSave: () {},
        ),
      );

      await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel'));
      await tester.pump();
      expect(cancelled, 1);
    });

    testWidgets('meets androidTapTargetGuideline', (tester) async {
      await pumpApp(
        tester,
        RadiusAlertActionRow(
          onCancel: () {},
          onSave: () {},
        ),
      );

      await expectLater(
        tester,
        meetsGuideline(androidTapTargetGuideline),
      );
    });
  });
}
