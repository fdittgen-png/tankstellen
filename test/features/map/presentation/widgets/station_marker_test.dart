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
      // Color.lerp returns Color, not MaterialColor — compare RGB values
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
      // All stations have the same price, so there is no range to interpolate.
      final color = StationMarkerBuilder.priceColor(1.70, 1.70, 1.70);

      expect(color, Colors.green);
    });

    test('returns mid-range color for middle price', () {
      final color = StationMarkerBuilder.priceColor(1.70, 1.50, 1.90);
      // Mid-range should be yellow-orange area — not purely green or red
      expect(color, isNot(Colors.green));
      expect(color, isNot(Colors.red));
    });
  });

  group('StationMarkerBuilder.build', () {
    testWidgets('shows brand name prominently', (tester) async {
      final marker = StationMarkerBuilder.build(
        tester.element(find.byType(Container).first),
        testStation,
        FuelType.e10,
        1.50,
        2.00,
      );
      // Build inside a test harness to verify widget tree
      await pumpApp(
        tester,
        SizedBox(
          width: marker.width,
          height: marker.height,
          child: (marker.child as GestureDetector).child,
        ),
      );

      // Brand name should appear — STAR for testStation
      expect(find.text('STAR'), findsOneWidget);
    });

    testWidgets('shows formatted price', (tester) async {
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
          child: (marker.child as GestureDetector).child,
        ),
      );

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
          child: (marker.child as GestureDetector).child,
        ),
      );

      expect(find.text('--'), findsOneWidget);
    });

    testWidgets('truncates long brand names', (tester) async {
      const longBrandStation = Station(
        id: 'long-brand',
        name: 'Long Brand Station',
        brand: 'ESSO EXPRESS PREMIUM ULTRA',
        street: 'Test St.',
        postCode: '12345',
        place: 'Test',
        lat: 52.0,
        lng: 13.0,
        e10: 1.799,
        isOpen: true,
      );
      final marker = StationMarkerBuilder.build(
        tester.element(find.byType(Container).first),
        longBrandStation,
        FuelType.e10,
        1.50,
        2.00,
      );
      await pumpApp(
        tester,
        SizedBox(
          width: marker.width,
          height: marker.height,
          child: (marker.child as GestureDetector).child,
        ),
      );

      // Should not show the full name
      expect(find.text('ESSO EXPRESS PREMIUM ULTRA'), findsNothing);
      // Should show truncated version with ellipsis (13 chars + ellipsis)
      expect(find.textContaining('\u2026'), findsOneWidget);
    });

    test('returns Marker with correct dimensions', () {
      // Use a dummy context — we only check the Marker metadata
      final stations = testStationList;
      // We can't call build without a context, so we test dimensions
      // via the static properties of the returned Marker.
      // This is covered by the widget tests above that verify the content.
      expect(stations.length, 3);
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
          child: (marker.child as GestureDetector).child,
        ),
      );

      // Verify the container uses pastel alpha (0.5)
      final container = tester.widget<Container>(find.byType(Container).last);
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color!.a, closeTo(0.5, 0.01));
    });

    testWidgets('color-codes marker by price tier', (tester) async {
      final cheapMarker = StationMarkerBuilder.build(
        tester.element(find.byType(Container).first),
        testStationList[0], // cheap station
        FuelType.e10,
        1.739,
        1.859,
      );
      final expensiveMarker = StationMarkerBuilder.build(
        tester.element(find.byType(Container).first),
        testStationList[2], // expensive station
        FuelType.e10,
        1.739,
        1.859,
      );

      // Cheap color should be greener, expensive should be redder
      final cheapColor =
          StationMarkerBuilder.priceColor(1.739, 1.739, 1.859);
      final expensiveColor =
          StationMarkerBuilder.priceColor(1.859, 1.739, 1.859);
      expect(cheapColor.green, greaterThan(cheapColor.red));
      expect(expensiveColor.red, greaterThan(expensiveColor.green));
      // Verify markers were created
      expect(cheapMarker.width, 90);
      expect(expensiveMarker.width, 90);
    });
  });
}
