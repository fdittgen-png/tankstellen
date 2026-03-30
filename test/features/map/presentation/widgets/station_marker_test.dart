import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/map/presentation/widgets/station_marker.dart';

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
  });
}
