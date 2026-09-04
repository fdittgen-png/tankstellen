// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

// #3949 (Epic #3947) — the results card laid out against the visual
// grammar: the display-role price leads top-left with the brand mark, the
// title / body / label roles follow in order, and the 24 h + open state
// fold into the status dot's tooltip so the card keeps ONE metadata line.
//
// Structural assertions only (no goldens): geometry via `tester.getSize` /
// `getTopLeft`, roles via the `AppText` styles, at the 320 dp viewport the
// text-expansion suite also uses.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/core/theme/app_text.dart';
import 'package:tankstellen/core/widgets/brand_logo.dart';
import 'package:tankstellen/features/search/presentation/widgets/station_card.dart';

import '../../../../fixtures/stations.dart';
import '../../../../helpers/pump_app.dart';

const _station24h = Station(
  id: '24h-station',
  name: '24h Tankstelle',
  brand: 'ARAL',
  street: 'Leipziger Str.',
  postCode: '10117',
  place: 'Berlin',
  lat: 52.5100,
  lng: 13.3900,
  dist: 2.5,
  e10: 1.809,
  diesel: 1.669,
  isOpen: true,
  is24h: true,
  updatedAt: '10:30',
);

/// Pumps [card] on a 320 dp × 800 dp surface (the narrowest phone in the
/// support matrix) and fails on any layout exception.
Future<void> pumpAt320(WidgetTester tester, Widget card) async {
  tester.view.physicalSize = const Size(320, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await pumpApp(tester, card);
  expect(tester.takeException(), isNull);
}

/// The display-role price: the one RichText whose style is the
/// `displaySmall` slot.
Finder priceFinder(BuildContext context) {
  final displaySize = AppText.display(context).fontSize;
  return find.byWidgetPredicate(
    (w) => w is RichText && w.text.style?.fontSize == displaySize,
  );
}

void main() {
  group('StationCard — visual grammar (#3949)', () {
    testWidgets('a single-price card is at most 150 dp tall at 320 dp', (
      tester,
    ) async {
      await pumpAt320(
        tester,
        const StationCard(
          station: testStation,
          selectedFuelType: FuelType.e10,
        ),
      );
      final height = tester.getSize(find.byType(StationCard)).height;
      expect(
        height,
        lessThanOrEqualTo(150),
        reason: 'the grammar caps a single-price result row at 150 dp '
            '(measured $height dp)',
      );
    });

    testWidgets('cheapest + favourite + tier arrow still fits the cap', (
      tester,
    ) async {
      await pumpAt320(
        tester,
        const StationCard(
          station: testStation,
          selectedFuelType: FuelType.e10,
          isCheapest: true,
          isFavorite: true,
        ),
      );
      expect(
        tester.getSize(find.byType(StationCard)).height,
        lessThanOrEqualTo(150),
      );
    });

    testWidgets('the price leads: display role, top-left, brand mark beside '
        'it, unit on the same baseline', (tester) async {
      late BuildContext ctx;
      await pumpAt320(
        tester,
        Builder(
          builder: (context) {
            ctx = context;
            return const StationCard(
              station: testStation,
              selectedFuelType: FuelType.e10,
            );
          },
        ),
      );

      final price = priceFinder(ctx);
      expect(price, findsOneWidget, reason: 'exactly one display number');

      // The unit sits beside the number in the unit role.
      final unit = find.text('€/L');
      expect(unit, findsOneWidget);
      final unitStyle = tester.widget<Text>(unit).style;
      expect(unitStyle?.fontSize, AppText.unit(ctx).fontSize);
      expect(tester.getTopLeft(unit).dx, greaterThan(tester.getTopLeft(price).dx));

      // Brand mark on the headline row, leading the price.
      final mark = find.byType(BrandLogo);
      expect(mark, findsOneWidget);
      expect(tester.getTopLeft(mark).dx, lessThan(tester.getTopLeft(price).dx));

      // The title (brand) and address are BELOW the headline row.
      final title = find.text('STAR');
      expect(tester.getTopLeft(title).dy, greaterThan(tester.getBottomLeft(price).dy - 1));
      final address = find.textContaining('Hauptstr.');
      expect(tester.getTopLeft(address).dy, greaterThan(tester.getTopLeft(title).dy));
    });

    testWidgets('name is the title role, address the body role, distance '
        'the label role', (tester) async {
      late BuildContext ctx;
      await pumpAt320(
        tester,
        Builder(
          builder: (context) {
            ctx = context;
            return const StationCard(
              station: testStation,
              selectedFuelType: FuelType.e10,
            );
          },
        ),
      );

      final title = tester.widget<Text>(find.text('STAR'));
      expect(title.style?.fontSize, AppText.title(ctx).fontSize);
      expect(title.style?.fontWeight, FontWeight.w600);

      final address = tester.widget<Text>(find.textContaining('Hauptstr.'));
      expect(address.style?.fontSize, AppText.body(ctx).fontSize);

      final distance = tester.widget<Text>(find.textContaining('1,5 km'));
      expect(distance.style?.fontSize, AppText.label(ctx).fontSize);
    });

    testWidgets('distance · freshness · status share ONE label line', (
      tester,
    ) async {
      await pumpAt320(
        tester,
        const StationCard(
          station: _station24h,
          selectedFuelType: FuelType.e10,
        ),
      );

      final distance = find.textContaining('2,5 km');
      final updated = find.textContaining('Updated 10:30');
      final dot = find.byKey(const Key('station_card_status_dot'));
      expect(distance, findsOneWidget);
      expect(updated, findsOneWidget);
      expect(dot, findsOneWidget);

      final distanceCenter = tester.getCenter(distance).dy;
      expect(tester.getCenter(updated).dy, closeTo(distanceCenter, 8));
      expect(tester.getCenter(dot).dy, closeTo(distanceCenter, 8));
      // Left to right: distance, freshness, dot.
      expect(tester.getTopLeft(distance).dx, lessThan(tester.getTopLeft(updated).dx));
      expect(tester.getTopLeft(updated).dx, lessThan(tester.getTopLeft(dot).dx));
    });

    testWidgets('24 h and the open state fold into the status dot — tooltip '
        '+ semantics, no separate badge', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpAt320(
        tester,
        const StationCard(
          station: _station24h,
          selectedFuelType: FuelType.e10,
        ),
      );

      // No visible 24h chip any more …
      expect(find.text('24h'), findsNothing);
      // … the dot's tooltip carries the state and the 24 h flag …
      final tooltip = tester.widget<Tooltip>(
        find.byKey(const Key('station_card_status_dot')),
      );
      expect(tooltip.message, 'Open · 24 h');
      // … and a screen reader hears both on the dot and on the row.
      expect(find.bySemanticsLabel(RegExp('Open · 24 h')), findsWidgets);
      expect(
        find.bySemanticsLabel(RegExp('Open 24 hours')),
        findsOneWidget,
        reason: 'the row semantic label announces the 24 h flag',
      );
      handle.dispose();
    });

    testWidgets('a closed station: tooltip says Closed, no 24 h suffix', (
      tester,
    ) async {
      await pumpAt320(
        tester,
        StationCard(
          station: testStationList[2], // isOpen: false
          selectedFuelType: FuelType.e10,
        ),
      );
      final tooltip = tester.widget<Tooltip>(
        find.byKey(const Key('station_card_status_dot')),
      );
      expect(tooltip.message, 'Closed');
    });

    testWidgets('the Cheapest badge and the star sit on the headline row, '
        'trailing the price', (tester) async {
      late BuildContext ctx;
      await pumpAt320(
        tester,
        Builder(
          builder: (context) {
            ctx = context;
            return const StationCard(
              station: testStation,
              selectedFuelType: FuelType.e10,
              isCheapest: true,
              isFavorite: true,
            );
          },
        ),
      );

      final price = priceFinder(ctx);
      final badge = find.text('Cheapest');
      final star = find.byIcon(Icons.star);
      final priceCenter = tester.getCenter(price).dy;
      expect(tester.getCenter(badge).dy, closeTo(priceCenter, 12));
      expect(tester.getCenter(star).dy, closeTo(priceCenter, 12));
      expect(tester.getTopLeft(badge).dx, greaterThan(tester.getTopRight(price).dx - 1));
      expect(tester.getTopLeft(star).dx, greaterThan(tester.getTopRight(badge).dx - 1));
    });

    testWidgets('all-fuels rows fold under the meta line as a Wrap', (
      tester,
    ) async {
      await pumpAt320(
        tester,
        const StationCard(
          station: testStation,
          selectedFuelType: FuelType.all,
        ),
      );
      expect(find.text('E5: '), findsOneWidget);
      expect(find.text('E10: '), findsOneWidget);
      expect(find.text('Diesel: '), findsOneWidget);
      final distanceBottom = tester.getBottomLeft(find.textContaining('1,5 km')).dy;
      expect(tester.getTopLeft(find.text('E5: ')).dy, greaterThan(distanceBottom - 1));
    });

    testWidgets('a known-closed station greys the display number only', (
      tester,
    ) async {
      late BuildContext ctx;
      await pumpAt320(
        tester,
        Builder(
          builder: (context) {
            ctx = context;
            return StationCard(
              station: testStationList[2],
              selectedFuelType: FuelType.e10,
            );
          },
        ),
      );
      final price = tester.widget<RichText>(priceFinder(ctx));
      expect(price.text.style?.color, Theme.of(ctx).colorScheme.onSurfaceVariant);
      final title = tester.widget<Text>(find.text('SHELL'));
      expect(title.style?.color, Theme.of(ctx).colorScheme.onSurface);
    });
  });
}
