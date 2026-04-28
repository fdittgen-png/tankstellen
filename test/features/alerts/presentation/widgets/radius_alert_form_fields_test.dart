import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/alerts/presentation/widgets/radius_alert_form_fields.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// Wraps a child widget in a localized MaterialApp so that
/// `AppLocalizations.of(context)` resolves to English copy. The form
/// fields are pure stateless — no Riverpod, no Hive — so a plain
/// MaterialApp is enough (no `pumpApp` / ProviderScope needed).
Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(body: child),
    );

void main() {
  group('RadiusAlertLabelField', () {
    testWidgets('renders the localized hint text', (tester) async {
      await tester.pumpWidget(
        _wrap(RadiusAlertLabelField(
          controller: TextEditingController(),
          onChanged: () {},
        )),
      );
      await tester.pumpAndSettle();

      expect(find.text('Label (e.g. Home diesel)'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('fires onChanged on every keystroke', (tester) async {
      final controller = TextEditingController();
      var fired = 0;

      await tester.pumpWidget(
        _wrap(RadiusAlertLabelField(
          controller: controller,
          onChanged: () => fired++,
        )),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Home');
      expect(fired, 1);
      expect(controller.text, 'Home');
    });
  });

  group('RadiusAlertFuelTypeField', () {
    testWidgets('renders with the current value selected', (tester) async {
      await tester.pumpWidget(
        _wrap(RadiusAlertFuelTypeField(
          value: FuelType.diesel,
          onChanged: (_) {},
        )),
      );
      await tester.pumpAndSettle();

      expect(find.text('Fuel type'), findsOneWidget);
      // The currently-selected value renders inside the closed dropdown.
      expect(find.text(FuelType.diesel.displayName), findsOneWidget);
    });

    testWidgets('fires onChanged when the user picks a new fuel',
        (tester) async {
      final picked = <FuelType>[];

      await tester.pumpWidget(
        _wrap(RadiusAlertFuelTypeField(
          value: FuelType.diesel,
          onChanged: picked.add,
        )),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButtonFormField<FuelType>));
      await tester.pumpAndSettle();

      // Multiple matches exist when the menu is open (closed-state label
      // + open-menu item); picking .last selects the menu item.
      await tester.tap(find.text(FuelType.e10.displayName).last);
      await tester.pumpAndSettle();

      expect(picked, [FuelType.e10]);
    });

    testWidgets('does NOT include FuelType.all in the menu items',
        (tester) async {
      await tester.pumpWidget(
        _wrap(RadiusAlertFuelTypeField(
          value: FuelType.diesel,
          onChanged: (_) {},
        )),
      );
      await tester.pumpAndSettle();

      // Open the dropdown so the menu items render in the overlay; we
      // then introspect the live `DropdownMenuItem<FuelType>` widgets
      // (the non-public `.items` getter on the form field is not
      // available in Flutter 3.29+). Flutter clones the selected item
      // for the closed-state header, so we deduplicate to the unique
      // value set the user can pick.
      await tester.tap(find.byType(DropdownButtonFormField<FuelType>));
      await tester.pumpAndSettle();

      final menuValues = tester
          .widgetList<DropdownMenuItem<FuelType>>(
            find.byType(DropdownMenuItem<FuelType>),
          )
          .map((i) => i.value)
          .toSet();

      expect(menuValues, isNot(contains(FuelType.all)));
      // Sanity-check: the concrete fuels we exclude `all` from are present.
      expect(menuValues, contains(FuelType.diesel));
      expect(menuValues, contains(FuelType.e10));
      expect(menuValues.length, FuelType.values.length - 1);
    });
  });

  group('RadiusAlertThresholdField', () {
    testWidgets('renders the localized label', (tester) async {
      await tester.pumpWidget(
        _wrap(RadiusAlertThresholdField(
          controller: TextEditingController(text: '1.499'),
          onChanged: () {},
        )),
      );
      await tester.pumpAndSettle();

      expect(find.text('Threshold (€/L)'), findsOneWidget);
      expect(find.text('1.499'), findsOneWidget);
    });

    testWidgets('uses a decimal keyboard type', (tester) async {
      await tester.pumpWidget(
        _wrap(RadiusAlertThresholdField(
          controller: TextEditingController(),
          onChanged: () {},
        )),
      );
      await tester.pumpAndSettle();

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.keyboardType,
          const TextInputType.numberWithOptions(decimal: true));
    });

    testWidgets('fires onChanged when the user types', (tester) async {
      final controller = TextEditingController();
      var fired = 0;

      await tester.pumpWidget(
        _wrap(RadiusAlertThresholdField(
          controller: controller,
          onChanged: () => fired++,
        )),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '1.55');
      expect(fired, 1);
      expect(controller.text, '1.55');
    });
  });

  group('RadiusAlertRadiusSlider', () {
    testWidgets('renders the localized title and km readout', (tester) async {
      await tester.pumpWidget(
        _wrap(RadiusAlertRadiusSlider(
          value: 12,
          onChanged: (_) {},
        )),
      );
      await tester.pumpAndSettle();

      expect(find.text('Radius (km)'), findsOneWidget);
      expect(find.text('12 km'), findsOneWidget);
    });

    testWidgets('exposes min=1, max=50, divisions=49 with synced label',
        (tester) async {
      await tester.pumpWidget(
        _wrap(RadiusAlertRadiusSlider(
          value: 7,
          onChanged: (_) {},
        )),
      );
      await tester.pumpAndSettle();

      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.min, 1);
      expect(slider.max, 50);
      expect(slider.divisions, 49);
      expect(slider.label, '7 km');
      expect(slider.value, 7);
    });

    testWidgets('fires onChanged when the user drags the thumb',
        (tester) async {
      final picked = <double>[];

      await tester.pumpWidget(
        _wrap(RadiusAlertRadiusSlider(
          value: 10,
          onChanged: picked.add,
        )),
      );
      await tester.pumpAndSettle();

      // Drag the slider thumb a noticeable distance to the right; we only
      // care that `onChanged` fires with a different value, not the exact
      // pixel-to-km mapping.
      await tester.drag(find.byType(Slider), const Offset(120, 0));
      await tester.pumpAndSettle();

      expect(picked, isNotEmpty);
      expect(picked.last, isNot(10));
    });
  });

  group('RadiusAlertFrequencyField', () {
    testWidgets('renders all four daily-frequency options', (tester) async {
      await tester.pumpWidget(
        _wrap(RadiusAlertFrequencyField(
          value: 1,
          onChanged: (_) {},
        )),
      );
      await tester.pumpAndSettle();

      // Closed-state assertions: shows the selected label + field title.
      expect(find.text('Once a day'), findsOneWidget);
      expect(find.text('Check frequency'), findsOneWidget);

      // Open the menu to introspect the four DropdownMenuItem<int>
      // entries (Flutter 3.29 hides the form-field `.items` getter).
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();

      // Flutter renders an extra "selected display" copy of the chosen
      // item alongside the four menu items, so we deduplicate to the
      // unique value set the user can actually pick.
      final menuValues = tester
          .widgetList<DropdownMenuItem<int>>(
            find.byType(DropdownMenuItem<int>),
          )
          .map((i) => i.value)
          .toSet();

      expect(menuValues, {1, 2, 3, 4});
      // All four labels render in the open menu.
      expect(find.text('Twice a day'), findsOneWidget);
      expect(find.text('Three times a day'), findsOneWidget);
      expect(find.text('Four times a day'), findsOneWidget);
    });

    testWidgets('fires onChanged when the user picks a new frequency',
        (tester) async {
      final picked = <int>[];

      await tester.pumpWidget(
        _wrap(RadiusAlertFrequencyField(
          value: 1,
          onChanged: picked.add,
        )),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Three times a day').last);
      await tester.pumpAndSettle();

      expect(picked, [3]);
    });
  });

  group('RadiusAlertCenterButtons', () {
    testWidgets('renders both labelled buttons with their icons',
        (tester) async {
      await tester.pumpWidget(
        _wrap(RadiusAlertCenterButtons(
          onUseMyLocation: () {},
          onPickOnMap: () {},
        )),
      );
      await tester.pumpAndSettle();

      expect(find.text('Use my location'), findsOneWidget);
      expect(find.text('Pick on map'), findsOneWidget);
      expect(find.byIcon(Icons.my_location), findsOneWidget);
      expect(find.byIcon(Icons.map_outlined), findsOneWidget);
    });

    testWidgets('routes taps to the correct callback', (tester) async {
      var gpsTaps = 0;
      var mapTaps = 0;

      await tester.pumpWidget(
        _wrap(RadiusAlertCenterButtons(
          onUseMyLocation: () => gpsTaps++,
          onPickOnMap: () => mapTaps++,
        )),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Use my location'));
      await tester.pumpAndSettle();
      expect(gpsTaps, 1);
      expect(mapTaps, 0);

      await tester.tap(find.text('Pick on map'));
      await tester.pumpAndSettle();
      expect(gpsTaps, 1);
      expect(mapTaps, 1);
    });
  });

  group('RadiusAlertPostalCodeField', () {
    testWidgets('renders the localized label', (tester) async {
      await tester.pumpWidget(
        _wrap(RadiusAlertPostalCodeField(
          controller: TextEditingController(),
          onChanged: () {},
        )),
      );
      await tester.pumpAndSettle();

      expect(find.text('Postal code'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('fires onChanged when the user types', (tester) async {
      final controller = TextEditingController();
      var fired = 0;

      await tester.pumpWidget(
        _wrap(RadiusAlertPostalCodeField(
          controller: controller,
          onChanged: () => fired++,
        )),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '34120');
      expect(fired, 1);
      expect(controller.text, '34120');
    });
  });

  group('RadiusAlertActionButtons', () {
    testWidgets('renders Cancel + Save with their localized labels',
        (tester) async {
      await tester.pumpWidget(
        _wrap(RadiusAlertActionButtons(
          onCancel: () {},
          onSave: () {},
        )),
      );
      await tester.pumpAndSettle();

      expect(find.widgetWithText(OutlinedButton, 'Cancel'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Save'), findsOneWidget);
    });

    testWidgets('routes Cancel and Save taps to their callbacks',
        (tester) async {
      var cancels = 0;
      var saves = 0;

      await tester.pumpWidget(
        _wrap(RadiusAlertActionButtons(
          onCancel: () => cancels++,
          onSave: () => saves++,
        )),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel'));
      await tester.pumpAndSettle();
      expect(cancels, 1);
      expect(saves, 0);

      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();
      expect(cancels, 1);
      expect(saves, 1);
    });

    testWidgets('disables the Save button when onSave is null',
        (tester) async {
      await tester.pumpWidget(
        _wrap(RadiusAlertActionButtons(
          onCancel: () {},
          onSave: null,
        )),
      );
      await tester.pumpAndSettle();

      final save = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Save'),
      );
      expect(save.onPressed, isNull);
    });
  });
}
