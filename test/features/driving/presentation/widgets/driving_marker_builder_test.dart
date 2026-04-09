import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/driving/presentation/widgets/driving_marker_builder.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';

import '../../../../fixtures/stations.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  group('DrivingMarkerBuilder.build', () {
    testWidgets('shows brand name prominently', (tester) async {
      var tapped = false;
      final marker = DrivingMarkerBuilder.build(
        testStation,
        FuelType.e10,
        1.50,
        2.00,
        onTap: () => tapped = true,
      );
      await pumpApp(
        tester,
        SizedBox(
          width: marker.width,
          height: marker.height,
          child: (marker.child as GestureDetector).child,
        ),
      );

      expect(find.text('STAR'), findsOneWidget);
      expect(tapped, isFalse);
    });

    testWidgets('shows formatted price', (tester) async {
      final marker = DrivingMarkerBuilder.build(
        testStation,
        FuelType.e10,
        1.50,
        2.00,
        onTap: () {},
      );
      await pumpApp(
        tester,
        SizedBox(
          width: marker.width,
          height: marker.height,
          child: (marker.child as GestureDetector).child,
        ),
      );

      // testStation.e10 = 1.799 => "1,799"
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
      final marker = DrivingMarkerBuilder.build(
        noPriceStation,
        FuelType.e10,
        1.50,
        2.00,
        onTap: () {},
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
        brand: 'INTERMARCHE SUPER PLUS EXTRA',
        street: 'Test St.',
        postCode: '12345',
        place: 'Test',
        lat: 52.0,
        lng: 13.0,
        e10: 1.799,
        isOpen: true,
      );
      final marker = DrivingMarkerBuilder.build(
        longBrandStation,
        FuelType.e10,
        1.50,
        2.00,
        onTap: () {},
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
      expect(find.text('INTERMARCHE SUPER PLUS EXTRA'), findsNothing);
      // Should show truncated version with ellipsis
      expect(find.textContaining('\u2026'), findsOneWidget);
    });

    testWidgets('shows tier icon for cheap station', (tester) async {
      final marker = DrivingMarkerBuilder.build(
        testStationList[0], // cheap station, e10 = 1.739
        FuelType.e10,
        1.739,
        1.859,
        onTap: () {},
      );
      await pumpApp(
        tester,
        SizedBox(
          width: marker.width,
          height: marker.height,
          child: (marker.child as GestureDetector).child,
        ),
      );

      expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
    });

    testWidgets('shows tier icon for expensive station', (tester) async {
      final marker = DrivingMarkerBuilder.build(
        testStationList[2], // expensive station, e10 = 1.859
        FuelType.e10,
        1.739,
        1.859,
        onTap: () {},
      );
      await pumpApp(
        tester,
        SizedBox(
          width: marker.width,
          height: marker.height,
          child: (marker.child as GestureDetector).child,
        ),
      );

      expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
    });

    testWidgets('has white border for high contrast', (tester) async {
      final marker = DrivingMarkerBuilder.build(
        testStation,
        FuelType.e10,
        1.50,
        2.00,
        onTap: () {},
      );
      await pumpApp(
        tester,
        SizedBox(
          width: marker.width,
          height: marker.height,
          child: (marker.child as GestureDetector).child,
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).last);
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.border, isNotNull);
    });

    test('marker has larger dimensions than normal map marker', () {
      final marker = DrivingMarkerBuilder.build(
        testStation,
        FuelType.e10,
        1.50,
        2.00,
        onTap: () {},
      );

      // Driving markers should be oversized for glanceability
      expect(marker.width, greaterThanOrEqualTo(140));
      expect(marker.height, greaterThanOrEqualTo(50));
    });
  });
}
