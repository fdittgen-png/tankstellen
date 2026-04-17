import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/map/presentation/widgets/station_marker.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';

import '../../../../fixtures/stations.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  group('StationMarkerBuilder.priceColor', () {
    test('returns green for cheapest price', () {
      final color = StationMarkerBuilder.priceColor(1.50, 1.50, 1.90);
      expect(color.green, greaterThan(color.red));
    });

    test('returns red for most expensive price', () {
      final color = StationMarkerBuilder.priceColor(1.90, 1.50, 1.90);
      expect(color.red, greaterThan(color.green));
    });

    test('returns grey for null price', () {
      final color = StationMarkerBuilder.priceColor(null, 1.50, 1.90);
      expect(color, Colors.grey);
    });

    test('returns green when min equals max', () {
      final color = StationMarkerBuilder.priceColor(1.70, 1.70, 1.70);
      expect(color, Colors.green);
    });

    test('returns mid-range color for middle price', () {
      final color = StationMarkerBuilder.priceColor(1.70, 1.50, 1.90);
      expect(color, isNot(Colors.green));
      expect(color, isNot(Colors.red));
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
          child: ((marker.child as Semantics).child as GestureDetector).child,
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
          child: ((marker.child as Semantics).child as GestureDetector).child,
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
          child: ((marker.child as Semantics).child as GestureDetector).child,
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
          child: ((marker.child as Semantics).child as GestureDetector).child,
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
      expect(cheapColor.green, greaterThan(cheapColor.red));
      expect(expensiveColor.red, greaterThan(expensiveColor.green));
      expect(cheapMarker.width, kStationMarkerWidth);
      expect(expensiveMarker.width, kStationMarkerWidth);
    });
  });
}
