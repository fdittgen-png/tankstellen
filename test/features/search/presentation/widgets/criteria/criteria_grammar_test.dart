// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

// #3949 (Epic #3947) — the criteria sheet against the visual grammar:
// section headers in the title role, one row of Reset + Search in the
// action bar, and choice-chip groups that fit two rows at 320 dp.

// The mocktail Mock* storage doubles are deprecated as a steering hint
// (prefer the stateful fakes) but remain sanctioned for widget tests that
// stub reads exclusively -- see test/helpers/mock_providers.dart (#3742).
// ignore_for_file: deprecated_member_use_from_same_package

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/country/country_config.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/theme/app_text.dart';
import 'package:tankstellen/features/search/presentation/widgets/criteria/criteria_chip_group.dart';
import 'package:tankstellen/features/search/presentation/widgets/criteria/criteria_section_header.dart';
import 'package:tankstellen/features/search/presentation/widgets/fuel_type_selector.dart';
import 'package:tankstellen/features/search/presentation/widgets/search_radius_slider.dart';

import '../../../../../helpers/mock_providers.dart';
import '../../../../../helpers/pump_app.dart';

/// Pumps [child] on the 320 dp surface the text-expansion suite uses.
Future<void> pumpAt320(
  WidgetTester tester,
  Widget child, {
  List<Object>? overrides,
}) async {
  tester.view.physicalSize = const Size(320, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await pumpApp(tester, child, overrides: overrides);
  expect(tester.takeException(), isNull);
}

/// How many distinct rows a set of chips occupies (distinct top edges).
int rowsOf(WidgetTester tester, Finder chips) {
  final count = chips.evaluate().length;
  final ys = <double>{};
  for (var i = 0; i < count; i++) {
    ys.add(tester.getTopLeft(chips.at(i)).dy.roundToDouble());
  }
  return ys.length;
}

/// Average Roboto advance width relative to the font size for the mixed
/// Latin text of a fuel label: "Super E10" at 14 sp is 63 px in Roboto,
/// i.e. 0.50 em per glyph; 0.52 is the bound used below.
const double kProportionalGlyphFactor = 0.52;

/// The criteria form's content width at 320 dp (16 dp padding each side).
const double kFormContentWidthAt320 = 288;

/// How many rows the chips would wrap onto at [width] if their labels were
/// set in a proportional font.
///
/// The test font ("FlutterTest") gives EVERY glyph a 1 em advance, so a
/// label measures ~1.8× its on-device width and a Wrap that fits two rows
/// on a phone measures three here. This helper takes each chip's real
/// chrome (padding, avatar, gaps) from the layout and re-scales only the
/// label text by [kProportionalGlyphFactor], then replays the Wrap's
/// greedy row fill. It models what the user sees; the raw test-font row
/// count would model a phone whose every letter is a capital W.
int proportionalRows(
  WidgetTester tester,
  Finder chips, {
  required double width,
  double spacing = 8,
}) {
  final count = chips.evaluate().length;
  var rows = 1;
  var x = 0.0;
  for (var i = 0; i < count; i++) {
    final chip = chips.at(i);
    final label = find.descendant(of: chip, matching: find.byType(Text)).first;
    final textWidth = tester.getSize(label).width;
    final chromeWidth = tester.getSize(chip).width - textWidth;
    final chipWidth = chromeWidth + textWidth * kProportionalGlyphFactor;
    if (x > 0 && x + spacing + chipWidth > width) {
      rows++;
      x = chipWidth;
    } else {
      x = x == 0 ? chipWidth : x + spacing + chipWidth;
    }
  }
  return rows;
}

void main() {
  group('CriteriaSectionHeader (#3949)', () {
    testWidgets('renders in the title role', (tester) async {
      late BuildContext ctx;
      await pumpApp(
        tester,
        Builder(
          builder: (context) {
            ctx = context;
            return const CriteriaSectionHeader('Fuel type');
          },
        ),
      );
      final text = tester.widget<Text>(find.text('Fuel type'));
      expect(text.style?.fontSize, AppText.title(ctx).fontSize);
      expect(text.style?.fontWeight, FontWeight.w600);
    });
  });

  group('criteria choice chips fit two rows at 320 dp (#3949)', () {
    testWidgets('the German fuel set (E5 · E10 · Diesel · Electric · All)', (
      tester,
    ) async {
      final storage = mockHiveStorageOverride();
      when(() => storage.mock.getActiveProfileId()).thenReturn(null);
      when(() => storage.mock.getSetting(any())).thenReturn(null);

      await pumpAt320(
        tester,
        const FuelTypeSelector(),
        overrides: [
          storage.override,
          activeCountryOverride(Countries.germany),
          selectedFuelTypeOverride(FuelType.all),
        ],
      );

      final chips = find.byType(ChoiceChip);
      expect(chips, findsNWidgets(5));
      // Every chip carries the tightened criteria geometry …
      for (final chip in tester.widgetList<ChoiceChip>(chips)) {
        expect(chip.padding, kCriteriaChipPadding);
        expect(chip.labelPadding, kCriteriaChipLabelPadding);
        expect(chip.avatarBoxConstraints, kCriteriaChipAvatarBox);
      }
      // … and with proportional glyphs the five wrap onto two rows inside
      // the form's content width at 320 dp (the square test font alone
      // would show three — see [proportionalRows]).
      expect(
        proportionalRows(tester, chips, width: kFormContentWidthAt320),
        lessThanOrEqualTo(2),
      );
    });

    testWidgets('the radius presets', (tester) async {
      await pumpAt320(
        tester,
        SearchRadiusSlider(radiusKm: 10, onChanged: (_) {}),
      );

      final chips = find.byType(ChoiceChip);
      expect(chips, findsNWidgets(3));
      // Three short presets fit one row even in the square test font.
      expect(rowsOf(tester, chips), 1);
      for (final chip in tester.widgetList<ChoiceChip>(chips)) {
        expect(chip.padding, kCriteriaChipPadding);
      }
      // The section name is the title role; the value keeps the primary
      // colour beside it.
      final header = tester.widget<Text>(find.text('Radius'));
      expect(header.style?.fontWeight, FontWeight.w600);
      expect(find.text('10 km'), findsWidgets);
    });
  });
}
