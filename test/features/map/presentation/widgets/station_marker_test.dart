// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/theme/price_band_colors.dart';
import 'package:tankstellen/features/map/presentation/widgets/station_marker.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';

import '../../../../fixtures/stations.dart';
import '../../../../helpers/pump_app.dart';

/// Asserts two colours match within a sub-1/255 epsilon. `Color.lerp` at
/// t == 1.0 returns the end stop but can introduce a tiny float drift in
/// the linear channels, so exact `==` is too strict for ramp endpoints.
void expectSameColor(Color actual, Color expected) {
  expect(actual.a, closeTo(expected.a, 0.002));
  expect(actual.r, closeTo(expected.r, 0.002));
  expect(actual.g, closeTo(expected.g, 0.002));
  expect(actual.b, closeTo(expected.b, 0.002));
}

void main() {
  group('StationMarkerBuilder.priceColor', () {
    test('returns green for cheapest price', () {
      final color = StationMarkerBuilder.priceColor(1.50, 1.50, 1.90);
      expect(color.g, greaterThan(color.r));
    });

    test('returns red for most expensive price', () {
      final color = StationMarkerBuilder.priceColor(1.90, 1.50, 1.90);
      expect(color.r, greaterThan(color.g));
    });

    test('returns grey for null price', () {
      final color = StationMarkerBuilder.priceColor(null, 1.50, 1.90);
      expect(color, Colors.grey);
    });

    test('returns the canonical cheap band when min equals max', () {
      // #2492 — degenerate range falls back to the shared ramp's cheap
      // stop, not a bare Colors.green.
      final color = StationMarkerBuilder.priceColor(1.70, 1.70, 1.70);
      expect(color, PriceBandColors.cheap);
    });

    test('returns mid-range color for middle price', () {
      final color = StationMarkerBuilder.priceColor(1.70, 1.50, 1.90);
      expect(color, isNot(PriceBandColors.cheap));
      expect(color, isNot(PriceBandColors.expensive));
    });

    test('cheapest price resolves to the ramp cheap stop', () {
      // t == 0 -> exactly stops[0].
      expect(
        StationMarkerBuilder.priceColor(1.50, 1.50, 1.90),
        PriceBandColors.cheap,
      );
    });

    test('most expensive price resolves to the ramp expensive stop', () {
      // t == 1 -> stops[3] (Color.lerp may drift by a sub-1/255 epsilon).
      expectSameColor(
        StationMarkerBuilder.priceColor(1.90, 1.50, 1.90),
        PriceBandColors.expensive,
      );
    });
  });

  group('canonical price-band ramp (#2492)', () {
    test('the ramp has exactly 4 stops', () {
      expect(PriceBandColors.ramp.length, 4);
    });

    test('the marker gradient consumes the ONE canonical ramp', () {
      // priceColor must produce the ramp's own boundary colours, proving
      // the marker and the legend draw from the same source.
      expect(StationMarkerBuilder.priceColor(0, 0, 1), PriceBandColors.cheap);
      expectSameColor(
          StationMarkerBuilder.priceColor(1, 0, 1), PriceBandColors.expensive);
    });

    test('the middle stop is amber, not pure yellow', () {
      // #FFEB00 (Colors.yellow) was near-invisible on white-bordered
      // bubbles; the ramp uses a saturated amber instead.
      expect(PriceBandColors.belowAverage, const Color(0xFFF9A825));
      expect(PriceBandColors.belowAverage, isNot(Colors.yellow));
    });
  });

  group('StationMarkerBuilder.build', () {
    testWidgets('marker is compact (width < 60dp)', (tester) async {
      final marker = StationMarkerBuilder.build(
        tester.element(find.byType(Container).first),
        testStation,
        FuelType.e10,
        1.50,
        2.00,
      );
      expect(marker.width, lessThan(60));
      expect(marker.width, kStationMarkerWidth);
      expect(marker.height, kStationMarkerHeight);
    });

    testWidgets('shows only the price (brand name not rendered)',
        (tester) async {
      final marker = StationMarkerBuilder.build(
        tester.element(find.byType(Container).first),
        testStation,
        FuelType.e10,
        1.50,
        2.00,
      );
      await pumpApp(
        tester,
        SizedBox(
          width: marker.width,
          height: marker.height,
          // #1772 — the marker child is wrapped in a RepaintBoundary.
          child: (((marker.child as RepaintBoundary).child as Semantics)
                  .child as GestureDetector)
              .child,
        ),
      );

      // Brand name (STAR) is now hidden in default view — only the price
      // is rendered as a Text widget. Tooltip text is not painted unless
      // the user long-presses, so it should not be findable as Text.
      expect(find.text('STAR'), findsNothing);
      // testStation.e10 = 1.799 => formatted as "1,799"
      expect(find.text('1,799'), findsOneWidget);
    });

    testWidgets('shows -- when price is null', (tester) async {
      const noPriceStation = Station(
        id: 'no-price',
        name: 'No Price',
        brand: 'TEST',
        street: 'Test St.',
        postCode: '12345',
        place: 'Test',
        lat: 52.0,
        lng: 13.0,
        isOpen: true,
      );
      final marker = StationMarkerBuilder.build(
        tester.element(find.byType(Container).first),
        noPriceStation,
        FuelType.e10,
        1.50,
        2.00,
      );
      await pumpApp(
        tester,
        SizedBox(
          width: marker.width,
          height: marker.height,
          // #1772 — the marker child is wrapped in a RepaintBoundary.
          child: (((marker.child as RepaintBoundary).child as Semantics)
                  .child as GestureDetector)
              .child,
        ),
      );

      expect(find.text('--'), findsOneWidget);
    });

    testWidgets('brand name is exposed via tooltip for accessibility',
        (tester) async {
      final marker = StationMarkerBuilder.build(
        tester.element(find.byType(Container).first),
        testStation,
        FuelType.e10,
        1.50,
        2.00,
      );
      await pumpApp(
        tester,
        SizedBox(
          width: marker.width,
          height: marker.height,
          // #1772 — the marker child is wrapped in a RepaintBoundary.
          child: (((marker.child as RepaintBoundary).child as Semantics)
                  .child as GestureDetector)
              .child,
        ),
      );

      final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tooltip.message, contains('STAR'));
    });

    testWidgets('uses pastel colors when pastel is true', (tester) async {
      final marker = StationMarkerBuilder.build(
        tester.element(find.byType(Container).first),
        testStation,
        FuelType.e10,
        1.50,
        2.00,
        pastel: true,
      );
      await pumpApp(
        tester,
        SizedBox(
          width: marker.width,
          height: marker.height,
          // #1772 — the marker child is wrapped in a RepaintBoundary.
          child: (((marker.child as RepaintBoundary).child as Semantics)
                  .child as GestureDetector)
              .child,
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).last);
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color!.a, closeTo(0.5, 0.01));
    });

    testWidgets(
        'exposes a Semantics button label combining brand + price (#566)',
        (tester) async {
      final marker = StationMarkerBuilder.build(
        tester.element(find.byType(Container).first),
        testStation,
        FuelType.e10,
        1.50,
        2.00,
      );
      await pumpApp(
        tester,
        SizedBox(
          width: marker.width,
          height: marker.height,
          child: marker.child,
        ),
      );

      final handle = tester.ensureSemantics();
      // Assert the marker is announced as a button with brand + price.
      // testStation has brand 'STAR' and e10 price 1.799.
      expect(
        find.bySemanticsLabel(RegExp(r'STAR.*1[.,]7')),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('color-codes marker by price tier', (tester) async {
      final cheapMarker = StationMarkerBuilder.build(
        tester.element(find.byType(Container).first),
        testStationList[0],
        FuelType.e10,
        1.739,
        1.859,
      );
      final expensiveMarker = StationMarkerBuilder.build(
        tester.element(find.byType(Container).first),
        testStationList[2],
        FuelType.e10,
        1.739,
        1.859,
      );

      final cheapColor =
          StationMarkerBuilder.priceColor(1.739, 1.739, 1.859);
      final expensiveColor =
          StationMarkerBuilder.priceColor(1.859, 1.739, 1.859);
      expect(cheapColor.g, greaterThan(cheapColor.r));
      expect(expensiveColor.r, greaterThan(expensiveColor.g));
      expect(cheapMarker.width, kStationMarkerWidth);
      expect(expensiveMarker.width, kStationMarkerWidth);
    });
  });

  group('StationMarkerBuilder fallback fuel display (#2400)', () {
    // Tankerkönig returns only the queried fuel's price. A diesel-only
    // station while E10 is selected used to render "--"; it must now fall
    // back to the diesel price with a labelled fuel code.
    const dieselOnlyStation = Station(
      id: 'diesel-only',
      name: 'Diesel Only',
      brand: 'TOTAL',
      street: 'Rue Diesel',
      postCode: '75001',
      place: 'Paris',
      lat: 48.0,
      lng: 2.0,
      diesel: 1.699,
      isOpen: true,
    );

    testWidgets(
      'a diesel-only station on an E10 search shows the diesel price, '
      'never "--"',
      (tester) async {
        final marker = StationMarkerBuilder.build(
          tester.element(find.byType(Container).first),
          dieselOnlyStation,
          FuelType.e10,
          1.50,
          2.00,
        );
        // Fallback widens the marker so the fuel code + price both fit.
        expect(marker.width, kStationMarkerWideWidth);

        await pumpApp(
          tester,
          SizedBox(
            width: marker.width,
            height: marker.height,
            child: (((marker.child as RepaintBoundary).child as Semantics)
                    .child as GestureDetector)
                .child,
          ),
        );

        // The diesel price is shown (1.699 => "1,699"); never "--".
        expect(find.text('1,699'), findsOneWidget);
        expect(find.text('--'), findsNothing);
        // The fallback fuel code is labelled so the price is unambiguous.
        expect(find.text('Diesel'), findsOneWidget);
      },
    );

    testWidgets(
      'a truly price-less station still shows "--"',
      (tester) async {
        const emptyStation = Station(
          id: 'empty',
          name: 'Empty',
          brand: 'TEST',
          street: 'Nowhere',
          postCode: '00000',
          place: 'Void',
          lat: 0.0,
          lng: 0.0,
          isOpen: true,
        );
        final marker = StationMarkerBuilder.build(
          tester.element(find.byType(Container).first),
          emptyStation,
          FuelType.e10,
          1.50,
          2.00,
        );
        // No fallback fuel → no widening, no fuel label.
        expect(marker.width, kStationMarkerWidth);

        await pumpApp(
          tester,
          SizedBox(
            width: marker.width,
            height: marker.height,
            child: (((marker.child as RepaintBoundary).child as Semantics)
                    .child as GestureDetector)
                .child,
          ),
        );

        expect(find.text('--'), findsOneWidget);
      },
    );

    testWidgets(
      'no fallback label when the selected fuel has its own price',
      (tester) async {
        final marker = StationMarkerBuilder.build(
          tester.element(find.byType(Container).first),
          testStation, // has e10
          FuelType.e10,
          1.50,
          2.00,
        );
        expect(marker.width, kStationMarkerWidth);

        await pumpApp(
          tester,
          SizedBox(
            width: marker.width,
            height: marker.height,
            child: (((marker.child as RepaintBoundary).child as Semantics)
                    .child as GestureDetector)
                .child,
          ),
        );

        expect(find.text('1,799'), findsOneWidget);
        // No fuel code when the selected fuel resolved directly.
        expect(find.text('Diesel'), findsNothing);
        expect(find.text('E10'), findsNothing);
      },
    );
  });
}
