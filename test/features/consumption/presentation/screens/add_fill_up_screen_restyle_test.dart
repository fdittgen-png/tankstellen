import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/widgets/form_section_card.dart';
import 'package:tankstellen/features/consumption/presentation/screens/add_fill_up_screen.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/fill_up_numeric_field.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/fill_up_price_per_liter_readout.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';

import '../../../../helpers/pump_app.dart';

/// Widget tests for the restyled Add-Fill-up screen.
///
/// The form groups fields into two cards ("What you filled" /
/// "Where you were") and pins the Save action at the bottom of the
/// Scaffold. The import affordance is a pair of side-by-side buttons
/// (Receipt + Pump display) — restored from the single "Import from…"
/// chip via #951 because OBD-II odometer reading is unreliable on
/// real hardware. These tests lock in the structural contract so a
/// future styling tweak can't silently drop one of the pieces.
class _StubVehicleList extends VehicleProfileList {
  @override
  List<VehicleProfile> build() => const [
        VehicleProfile(
          id: 'stub-vehicle',
          name: 'Stub Car',
          type: VehicleType.combustion,
        ),
      ];
}

final _withVehicle = <Object>[
  vehicleProfileListProvider.overrideWith(() => _StubVehicleList()),
];

/// Larger test surface so the two grouped cards and the pinned
/// Save button all fit without ListView virtualization hiding the
/// lower one (the default 800x600 crops the second card on phones —
/// real devices only do that behind a scrollable).
Future<void> _pumpWithTallView(
  WidgetTester tester,
  Widget child, {
  List<Object>? overrides,
}) async {
  tester.view.physicalSize = const Size(900, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await pumpApp(tester, child, overrides: overrides);
}

Finder _fieldByLabel(String label) => find.ancestor(
      of: find.text(label),
      matching: find.byType(FillUpNumericField),
    );

TextField _textFieldFor(WidgetTester tester, String label) {
  final fillUpField = tester.widget<FillUpNumericField>(_fieldByLabel(label));
  return tester.widget<TextField>(
    find.descendant(
      of: find.byWidget(fillUpField),
      matching: find.byType(TextField),
    ),
  );
}

void main() {
  group('AddFillUpScreen restyle (#751 phase 2)', () {
    testWidgets('renders the two grouped cards with their titles',
        (tester) async {
      await _pumpWithTallView(
        tester,
        const AddFillUpScreen(),
        overrides: _withVehicle,
      );

      expect(find.byType(FormSectionCard), findsNWidgets(2));
      expect(find.text('What you filled'), findsOneWidget);
      expect(find.text('Where you were'), findsOneWidget);
    });

    testWidgets(
        'renders two visible import buttons (Receipt + Pump display) '
        'and hides the OBD-II import path (#951)', (tester) async {
      await _pumpWithTallView(
        tester,
        const AddFillUpScreen(),
        overrides: _withVehicle,
      );

      // Two side-by-side OutlinedButtons — keyed for stable lookup.
      expect(find.byKey(const Key('import_receipt_button')), findsOneWidget);
      expect(find.byKey(const Key('import_pump_button')), findsOneWidget);
      expect(find.text('Receipt'), findsOneWidget);
      expect(find.text('Pump display'), findsOneWidget);

      // The single "Import from…" chip and the OBD-II import tile
      // must NOT appear on this screen — they were rolled back in
      // #951 because PID 0xA6 odometer is unreliable on real
      // hardware. The full OBD-II trip flow lives on the
      // Consumption screen and is unaffected.
      expect(find.text('Import from…'), findsNothing);
      expect(find.byType(ActionChip), findsNothing);
      expect(find.text('OBD-II adapter'), findsNothing);
      expect(find.text('OBD-II'), findsNothing);
    });

    testWidgets('price-per-liter derivation renders under the cost field '
        'when both liters and cost are set', (tester) async {
      await _pumpWithTallView(
        tester,
        const AddFillUpScreen(),
        overrides: _withVehicle,
      );

      expect(find.byType(FillUpPricePerLiterReadout), findsOneWidget,
          reason: 'Readout widget is always mounted; it self-hides.');
      expect(find.textContaining('Price per liter'), findsNothing,
          reason: 'Initially no liters/cost → hidden.');

      final liters = _textFieldFor(tester, 'Liters');
      liters.controller!.text = '30';
      await tester.pump();

      final cost = _textFieldFor(tester, 'Total cost');
      cost.controller!.text = '60';
      await tester.pump();

      // 60 / 30 = 2.000
      expect(find.textContaining('Price per liter'), findsOneWidget);
      expect(find.textContaining('2.000'), findsOneWidget);
    });

    testWidgets('pins the Save action at the bottom of the Scaffold',
        (tester) async {
      await _pumpWithTallView(
        tester,
        const AddFillUpScreen(),
        overrides: _withVehicle,
      );

      // The FilledButton containing "Save" must always be in the tree —
      // it's pinned via `bottomNavigationBar`, not at the end of a
      // scroll view that could virtualize it.
      expect(find.widgetWithText(FilledButton, 'Save'), findsOneWidget);
    });

    testWidgets('every ARB label referenced in the form still renders',
        (tester) async {
      await _pumpWithTallView(
        tester,
        const AddFillUpScreen(),
        overrides: _withVehicle,
      );

      // Field labels.
      expect(find.text('Date'), findsOneWidget);
      expect(find.text('Liters'), findsOneWidget);
      expect(find.text('Total cost'), findsOneWidget);
      expect(find.text('Odometer (km)'), findsOneWidget);
      expect(find.text('Notes (optional)'), findsOneWidget);
      // Card headers + import button labels.
      expect(find.text('What you filled'), findsOneWidget);
      expect(find.text('Where you were'), findsOneWidget);
      expect(find.text('Receipt'), findsOneWidget);
      expect(find.text('Pump display'), findsOneWidget);
    });

    testWidgets('meets the Android tap-target guideline (48dp, #566)',
        (tester) async {
      await _pumpWithTallView(
        tester,
        const AddFillUpScreen(),
        overrides: _withVehicle,
      );

      final handle = tester.ensureSemantics();
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets(
        'station pre-fill banner renders when a stationName is passed',
        (tester) async {
      await _pumpWithTallView(
        tester,
        const AddFillUpScreen(
          stationId: 's-1',
          stationName: 'Totale Castelnau',
        ),
        overrides: _withVehicle,
      );

      expect(find.text('Totale Castelnau'), findsOneWidget);
      expect(find.text('Station pre-filled'), findsOneWidget);
    });
  });

  group('AddFillUpScreen isFullTank toggle (#1195)', () {
    testWidgets('toggle defaults to ON', (tester) async {
      await _pumpWithTallView(
        tester,
        const AddFillUpScreen(),
        overrides: _withVehicle,
      );

      // The full-tank label is rendered in the form.
      expect(find.text('Full tank'), findsOneWidget);

      // The Switch starts in the "on" position (default true).
      final toggle = tester.widget<SwitchListTile>(
        find.byKey(const Key('add_fill_up_is_full_tank_toggle')),
      );
      expect(toggle.value, isTrue);
    });

    testWidgets('toggle flips to OFF when tapped', (tester) async {
      await _pumpWithTallView(
        tester,
        const AddFillUpScreen(),
        overrides: _withVehicle,
      );

      await tester.tap(
        find.byKey(const Key('add_fill_up_is_full_tank_toggle')),
      );
      await tester.pumpAndSettle();

      final toggle = tester.widget<SwitchListTile>(
        find.byKey(const Key('add_fill_up_is_full_tank_toggle')),
      );
      expect(toggle.value, isFalse);
    });
  });
}
