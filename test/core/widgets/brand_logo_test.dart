import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/widgets/brand_logo.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('BrandLogo', () {
    testWidgets('shows fallback icon for unknown brand', (tester) async {
      await pumpApp(tester, const BrandLogo(brand: 'UnknownBrand'));

      // Should show generic fuel pump icon
      expect(find.byIcon(Icons.local_gas_station), findsOneWidget);
      // Should not attempt to load a network image
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('shows fallback icon for empty brand', (tester) async {
      await pumpApp(tester, const BrandLogo(brand: ''));

      expect(find.byIcon(Icons.local_gas_station), findsOneWidget);
    });

    testWidgets('attempts to load network image for known brand',
        (tester) async {
      await pumpApp(tester, const BrandLogo(brand: 'Shell'));

      // Should find an Image widget (network image attempt)
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('respects custom size parameter', (tester) async {
      await pumpApp(tester, const BrandLogo(brand: '', size: 64));

      // The fallback container should be 64x64
      final renderBox =
          tester.renderObject<RenderBox>(find.byType(Container).first);
      expect(renderBox.size.width, 64);
      expect(renderBox.size.height, 64);
    });

    testWidgets('uses ClipRRect for known brand', (tester) async {
      await pumpApp(tester, const BrandLogo(brand: 'ARAL'));

      expect(find.byType(ClipRRect), findsOneWidget);
    });

    testWidgets('default size is 48', (tester) async {
      await pumpApp(tester, const BrandLogo(brand: ''));

      final renderBox =
          tester.renderObject<RenderBox>(find.byType(Container).first);
      expect(renderBox.size.width, 48);
      expect(renderBox.size.height, 48);
    });
  });
}
