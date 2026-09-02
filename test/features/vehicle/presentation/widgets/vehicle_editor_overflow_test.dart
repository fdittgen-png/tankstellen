// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/features/trips/presentation/widgets/vehicle_adapter_section.dart';
import 'package:tankstellen/features/vehicle/presentation/widgets/vehicle_identity_section.dart';
import 'package:tankstellen/features/vehicle/presentation/widgets/vehicle_type_selector.dart';

import '../../../../helpers/pump_app.dart';

/// #3899 (Epic #3897) — the vehicle editor's chrome under expanded text:
/// the motorisation control must never wrap a word mid-way, the adapter
/// card's two actions must stack instead of clipping, and the identity
/// rows carry their icon exactly once. Same harness as
/// `test/l10n/text_expansion_test.dart`: the `en_XA` pseudo-locale at a
/// 320 dp viewport, plus the 1.3x text-scale pass.
void main() {
  const pseudoLocale = Locale('en', 'XA');

  Future<void> pumpNarrow(
    WidgetTester tester,
    Widget child, {
    Locale locale = const Locale('en'),
    double textScale = 1.0,
    double width = 320,
  }) async {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1.0;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpApp(
      tester,
      Padding(padding: const EdgeInsets.all(16), child: child),
      locale: locale,
    );
    expect(tester.takeException(), isNull);
  }

  Widget typeSelector() =>
      VehicleTypeSelector(selected: VehicleType.hybrid, onChanged: (_) {});

  Axis selectorDirection(WidgetTester tester) => tester
      .widget<SegmentedButton<VehicleType>>(
        find.byKey(const Key('vehicleTypeSelector')),
      )
      .direction;

  group('VehicleTypeSelector — structural no-mid-word-wrap (#3899)', () {
    test('fitsOnOneRow budgets three segments plus their chrome', () {
      // 3 × (60 + 54 chrome + 6 slack) = 360.
      expect(
        VehicleTypeSelector.fitsOnOneRow(
          maxWidth: 360,
          labelWidths: const [40, 60, 50],
        ),
        isTrue,
      );
      expect(
        VehicleTypeSelector.fitsOnOneRow(
          maxWidth: 359,
          labelWidths: const [40, 60, 50],
        ),
        isFalse,
      );
    });

    testWidgets('wide viewport keeps the three segments on one row',
        (tester) async {
      // 800 dp: the test font paints every glyph 14 dp wide, so this is
      // the "tablet" case the real fonts reach at ~400 dp.
      await pumpNarrow(tester, typeSelector(), width: 800);
      expect(selectorDirection(tester), Axis.horizontal);
      expect(find.text('Combustion'), findsOneWidget);
      expect(find.text('Hybrid'), findsOneWidget);
      expect(find.text('Electric'), findsOneWidget);
    });

    testWidgets('en_XA at 320 dp stacks the segments vertically — no '
        'overflow, every label on its own full-width row', (tester) async {
      await pumpNarrow(tester, typeSelector(), locale: pseudoLocale);
      expect(selectorDirection(tester), Axis.vertical);
      // Each label is a single unbroken line.
      for (final text in tester.widgetList<Text>(find.descendant(
        of: find.byKey(const Key('vehicleTypeSelector')),
        matching: find.byType(Text),
      ))) {
        expect(text.maxLines, 1);
        expect(text.softWrap, isFalse);
      }
    });

    testWidgets('1.3x text scale at 320 dp renders without overflow',
        (tester) async {
      await pumpNarrow(tester, typeSelector(), textScale: 1.3);
    });

    testWidgets('en_XA + 1.3x text scale at 320 dp renders without overflow',
        (tester) async {
      await pumpNarrow(
        tester,
        typeSelector(),
        locale: pseudoLocale,
        textScale: 1.3,
      );
      expect(selectorDirection(tester), Axis.vertical);
    });

    testWidgets('a stacked segment still forwards the tapped type',
        (tester) async {
      VehicleType? picked;
      await pumpNarrow(
        tester,
        VehicleTypeSelector(
          selected: VehicleType.combustion,
          onChanged: (t) => picked = t,
        ),
        locale: pseudoLocale,
      );
      expect(selectorDirection(tester), Axis.vertical);
      await tester.tap(find.byIcon(Icons.electric_car));
      await tester.pumpAndSettle();
      expect(picked, VehicleType.ev);
    });
  });

  group('VehicleAdapterSection — actions stack instead of clipping (#3899)',
      () {
    Widget paired() => VehicleAdapterSection(
          adapterMac: 'AA:BB:CC:DD:EE:FF',
          adapterName: 'vLinker FS',
          onPaired: (_, _) {},
          onForget: () {},
        );

    testWidgets('the two actions live in an OverflowBar', (tester) async {
      await pumpNarrow(tester, paired(), width: 600);
      final bar = find.byKey(const Key('vehicleAdapterActions'));
      expect(bar, findsOneWidget);
      expect(tester.widget(bar), isA<OverflowBar>());
    });

    testWidgets('en_XA at 320 dp: no overflow and the actions wrap onto '
        'two rows', (tester) async {
      await pumpNarrow(tester, paired(), locale: pseudoLocale);
      final reset = tester.getTopLeft(
        find.byKey(const Key('vehicleAdapterReset')),
      );
      final forget = tester.getTopLeft(
        find.byKey(const Key('vehicleAdapterForget')),
      );
      expect(forget.dy, greaterThan(reset.dy),
          reason: 'the Forget action must drop to a second row');
    });

    testWidgets('en_XA + 1.3x text scale at 320 dp renders without overflow',
        (tester) async {
      await pumpNarrow(
        tester,
        paired(),
        locale: pseudoLocale,
        textScale: 1.3,
      );
    });
  });

  group('VehicleIdentitySection — icon once per row (#3899)', () {
    testWidgets('name and VIN carry their glyph as the field prefix only',
        (tester) async {
      final nameCtrl = TextEditingController();
      final vinCtrl = TextEditingController();
      final vinFocus = FocusNode();
      addTearDown(() {
        nameCtrl.dispose();
        vinCtrl.dispose();
        vinFocus.dispose();
      });
      await pumpNarrow(
        tester,
        Form(
          child: VehicleIdentitySection(
            nameController: nameCtrl,
            vinController: vinCtrl,
            vinFocus: vinFocus,
            accent: Colors.blue,
            decodingVin: false,
            onDecodeVin: () {},
            onShowVinInfo: () {},
          ),
        ),
        width: 600,
      );
      expect(find.byIcon(Icons.directions_car_outlined), findsOneWidget);
      expect(find.byIcon(Icons.qr_code_2_outlined), findsOneWidget);
      // …and each of those lives INSIDE its text field, not beside it.
      expect(
        find.descendant(
          of: find.byType(TextField),
          matching: find.byIcon(Icons.directions_car_outlined),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(TextField),
          matching: find.byIcon(Icons.qr_code_2_outlined),
        ),
        findsOneWidget,
      );
    });
  });
}
