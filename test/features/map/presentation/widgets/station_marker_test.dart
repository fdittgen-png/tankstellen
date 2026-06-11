// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/theme/price_band_colors.dart';
import 'package:tankstellen/core/widgets/animated_price_text.dart';
import 'package:tankstellen/features/map/presentation/widgets/station_marker.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/station.dart';

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

  group('StationMarkerBuilder selected-fuel price (#2510)', () {
    // #2510 — the marker shows STRICTLY the selected fuel's price, exactly
    // like the search LIST (`StationCard`). It must NOT fall back to E10 /
    // another fuel: that #2400 fallback chain made the map read "E10
    // 2,099" on an E85 search while the list showed the E85 price. A
    // station lacking the selected fuel renders "--", never a re-labelled
    // other-fuel price.

    // A station that sells multiple fuels, including a cheap E85 — the
    // real-world Intermarché / Pézenas case from the bug report.
    const multiFuelStation = Station(
      id: 'multi-fuel',
      name: 'Intermarché',
      brand: 'Intermarché',
      street: 'Av. de Pézenas',
      postCode: '34120',
      place: 'Pézenas',
      lat: 43.46,
      lng: 3.42,
      e10: 2.099,
      diesel: 1.899,
      e85: 0.799,
      isOpen: true,
    );

    testWidgets(
      'with E85 selected, a multi-fuel station shows the E85 price, '
      'NOT the E10 default',
      (tester) async {
        final marker = StationMarkerBuilder.build(
          tester.element(find.byType(Container).first),
          multiFuelStation,
          FuelType.e85,
          0.50,
          2.50,
        );

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

        // The E85 price (0.799 => "0,799") is shown — matching the list.
        expect(find.text('0,799'), findsOneWidget);
        // The E10 default (2.099) must NOT appear, and there is no fuel
        // code prefix — the selected fuel resolved directly.
        expect(find.text('2,099'), findsNothing);
        expect(find.text('E10'), findsNothing);
      },
    );

    testWidgets(
      'a station lacking the selected fuel shows "--", NOT an E10 fallback',
      (tester) async {
        // Diesel-only station while E85 is selected. The list would show a
        // dash for E85 here; the marker must match — no fallback to diesel.
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
        final marker = StationMarkerBuilder.build(
          tester.element(find.byType(Container).first),
          dieselOnlyStation,
          FuelType.e85,
          0.50,
          2.50,
        );

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

        // Graceful dash — never the diesel price, never a fuel code.
        expect(find.text('--'), findsOneWidget);
        expect(find.text('1,699'), findsNothing);
        expect(find.text('Diesel'), findsNothing);
      },
    );
  });

  group('StationMarkerBuilder cross-border fuelResolver (#2631)', () {
    // A Spanish MITECO station: E10 priced, NO E85 grade — the exact shape
    // that rendered '--' on an E85 search before the per-country fix. The
    // `es-` id prefix attributes it to ES.
    const esStation = Station(
      id: 'es-12345',
      name: 'Repsol',
      brand: 'Repsol',
      street: 'Av. Diagonal',
      postCode: '08001',
      place: 'Barcelona',
      lat: 41.39,
      lng: 2.17,
      e10: 1.609,
      isOpen: true,
    );

    testWidgets(
      'with a resolver mapping the ES station to E10, the marker shows the '
      'E10 price even though the active fuel is E85',
      (tester) async {
        final marker = StationMarkerBuilder.build(
          tester.element(find.byType(Container).first),
          esStation,
          FuelType.e85, // active fuel — null on this station…
          0.50,
          2.50,
          // …but the cross-border resolver picks ES → E10.
          fuelResolver: (_) => FuelType.e10,
        );

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

        // The E10 price (1.609 => "1,609") is shown, NOT the '--' the active
        // E85 would have produced.
        expect(find.text('1,609'), findsOneWidget);
        expect(find.text('--'), findsNothing);
      },
    );

    testWidgets(
      'WITHOUT a resolver, the same ES station still shows "--" on an E85 '
      'search (locks the strict #2510 single-fuel behaviour)',
      (tester) async {
        final marker = StationMarkerBuilder.build(
          tester.element(find.byType(Container).first),
          esStation,
          FuelType.e85,
          0.50,
          2.50,
          // No resolver → strict active-fuel price → '--'.
        );

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
        expect(find.text('1,609'), findsNothing);
      },
    );
  });

  group('StationMarkerBuilder compact dot (#2510)', () {
    testWidgets('a compact marker is a small price-less dot', (tester) async {
      final marker = StationMarkerBuilder.build(
        tester.element(find.byType(Container).first),
        testStation, // has e10 = 1.799
        FuelType.e10,
        1.50,
        2.00,
        compact: true,
      );
      // The dot is markedly smaller than the full price bubble.
      expect(marker.width, kStationDotSize);
      expect(marker.height, kStationDotSize);
      expect(marker.width, lessThan(kStationMarkerWidth));

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

      // No price label is painted on a compact dot — it is a pure colour
      // swatch, so the bounded result set stays uncluttered.
      expect(find.text('1,799'), findsNothing);
    });

    testWidgets('a compact marker still announces its price for a11y',
        (tester) async {
      final marker = StationMarkerBuilder.build(
        tester.element(find.byType(Container).first),
        testStation,
        FuelType.e10,
        1.50,
        2.00,
        compact: true,
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
      // Even a de-emphasized dot stays a labelled button so a screen-
      // reader user can find it (#566).
      expect(find.bySemanticsLabel(RegExp(r'STAR.*1[.,]7')), findsOneWidget);
      handle.dispose();
    });
  });

  group('StationMarkerBuilder driving variant (#3002, Epic #2997)', () {
    // The DRIVING map adopts the shared price-band colours + pill grammar but
    // keeps a big, driver-legible CONTENT variant: brand on top + a price-tier
    // icon + a LARGE price, at ~150x62. It is a real content variant, NOT a
    // size scale of the default price-only pill (whose brand lives in a
    // tooltip that's useless while driving).

    testWidgets('the driving variant is the large 150x62 driver card',
        (tester) async {
      final marker = StationMarkerBuilder.build(
        tester.element(find.byType(Container).first),
        testStation,
        FuelType.e10,
        1.50,
        2.00,
        variant: StationMarkerVariant.driving,
      );
      // Big driver-legible dimensions, NOT the compact pill.
      expect(marker.width, kDrivingMarkerWidth);
      expect(marker.height, kDrivingMarkerHeight);
      expect(marker.width, greaterThan(kStationMarkerWidth));
      expect(marker.height, greaterThan(kStationMarkerHeight));
    });

    testWidgets('the driving variant PAINTS the brand line (not just a tooltip)',
        (tester) async {
      final marker = StationMarkerBuilder.build(
        tester.element(find.byType(Container).first),
        testStation, // brand STAR, e10 1.799
        FuelType.e10,
        1.50,
        2.00,
        variant: StationMarkerVariant.driving,
      );
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

      // The brand is RENDERED as text on the card — the whole point of the
      // driver-legible variant (the default pill hides it in a tooltip).
      expect(find.text('STAR'), findsOneWidget);
      // The large price is rendered too.
      expect(find.text('1,799'), findsOneWidget);
    });

    testWidgets('the driving variant renders the price-tier icon',
        (tester) async {
      // A cheapest station → downward (cheap) tier arrow.
      final marker = StationMarkerBuilder.build(
        tester.element(find.byType(Container).first),
        testStationList[0], // cheap, e10 1.739
        FuelType.e10,
        1.739,
        1.859,
        variant: StationMarkerVariant.driving,
      );
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

      expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
    });

    testWidgets('the driving variant colours from the shared PriceBandColors '
        'ramp (cheapest = the canonical cheap stop)', (tester) async {
      final marker = StationMarkerBuilder.build(
        tester.element(find.byType(Container).first),
        testStationList[0], // cheapest in the range below
        FuelType.e10,
        1.739,
        1.859,
        variant: StationMarkerVariant.driving,
      );
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

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration! as BoxDecoration;
      // The fill is the shared ramp's cheap stop (with the variant's alpha),
      // proving driving folds onto the ONE canonical ramp — not its old
      // bespoke _drivingStops palette.
      expectSameColor(
        decoration.color!.withValues(alpha: 1.0),
        PriceBandColors.cheap,
      );
    });

    testWidgets('the driving variant keeps the RepaintBoundary + onTap hook',
        (tester) async {
      var tapped = false;
      final marker = StationMarkerBuilder.build(
        tester.element(find.byType(Container).first),
        testStation,
        FuelType.e10,
        1.50,
        2.00,
        variant: StationMarkerVariant.driving,
        onTap: () => tapped = true,
      );
      // Same wrapping contract as the default marker (#1772).
      expect(marker.child, isA<RepaintBoundary>());

      await pumpApp(
        tester,
        SizedBox(
          width: marker.width,
          height: marker.height,
          child: marker.child,
        ),
      );
      await tester.tap(find.byType(GestureDetector).first);
      expect(tapped, isTrue);
    });

    testWidgets('the DEFAULT variant is unchanged — small price-only pill, '
        'brand only in the tooltip', (tester) async {
      // Locks that adding the driving variant did NOT alter the default
      // marker the nearby/radar/route maps render.
      final marker = StationMarkerBuilder.build(
        tester.element(find.byType(Container).first),
        testStation,
        FuelType.e10,
        1.50,
        2.00,
      );
      expect(marker.width, kStationMarkerWidth);
      expect(marker.height, kStationMarkerHeight);

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

      // The brand is NOT painted on the default pill (tooltip only).
      expect(find.text('STAR'), findsNothing);
      expect(find.text('1,799'), findsOneWidget);
    });
  });

  group('StationMarkerBuilder price-flash — selected only (#2973)', () {
    Future<void> pumpMarker(WidgetTester tester, Marker marker) =>
        pumpApp(
          tester,
          SizedBox(
            width: marker.width,
            height: marker.height,
            child: (((marker.child as RepaintBoundary).child as Semantics)
                    .child as GestureDetector)
                .child,
          ),
        );

    testWidgets('the SELECTED marker wraps its price in AnimatedPriceText',
        (tester) async {
      final marker = StationMarkerBuilder.build(
        tester.element(find.byType(Container).first),
        testStation, // e10 = 1.799
        FuelType.e10,
        1.50,
        2.00,
        selected: true,
      );
      await pumpMarker(tester, marker);
      expect(find.byType(AnimatedPriceText), findsOneWidget,
          reason: 'the chosen station flashes on a price refresh');
      expect(find.text('1,799'), findsOneWidget);
    });

    testWidgets('an UN-selected bubble has NO AnimatedPriceText',
        (tester) async {
      final marker = StationMarkerBuilder.build(
        tester.element(find.byType(Container).first),
        testStation,
        FuelType.e10,
        1.50,
        2.00,
        // selected defaults to false.
      );
      await pumpMarker(tester, marker);
      expect(find.byType(AnimatedPriceText), findsNothing,
          reason: 'the flash must never run across the whole marker layer — '
              'only the selected marker animates');
    });

    testWidgets('a compact dot has NO AnimatedPriceText', (tester) async {
      final marker = StationMarkerBuilder.build(
        tester.element(find.byType(Container).first),
        testStation,
        FuelType.e10,
        1.50,
        2.00,
        compact: true,
      );
      await pumpMarker(tester, marker);
      expect(find.byType(AnimatedPriceText), findsNothing);
    });
  });
}
