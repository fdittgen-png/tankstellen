import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/search/presentation/widgets/search_radius_slider.dart';

void main() {
  group('SearchRadiusSlider', () {
    Future<void> pumpSlider(
      WidgetTester tester, {
      required double radius,
      required ValueChanged<double> onChanged,
      double minKm = 1,
      double maxKm = 25,
    }) {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchRadiusSlider(
              radiusKm: radius,
              minKm: minKm,
              maxKm: maxKm,
              onChanged: onChanged,
            ),
          ),
        ),
      );
    }

    testWidgets('renders the rounded radius value with km suffix',
        (tester) async {
      await pumpSlider(tester, radius: 10.4, onChanged: (_) {});
      // Title row + slider label both render the rounded value.
      expect(find.text('10 km'), findsWidgets);
    });

    testWidgets('clamps the slider value into [minKm, maxKm]', (tester) async {
      // radiusKm above the max should clamp; we pass 50 with default max 25.
      await pumpSlider(tester, radius: 50, onChanged: (_) {});
      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.value, 25);
    });

    testWidgets('clamps below the minimum', (tester) async {
      await pumpSlider(tester, radius: -5, onChanged: (_) {});
      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.value, 1);
    });

    testWidgets('uses (max - min) divisions so each integer km is a tick',
        (tester) async {
      await pumpSlider(tester, radius: 5, minKm: 1, maxKm: 10, onChanged: (_) {});
      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.divisions, 9);
    });

    testWidgets('forwards onChanged when the slider is dragged', (tester) async {
      double? captured;
      await pumpSlider(
        tester,
        radius: 10,
        onChanged: (v) => captured = v,
      );
      // Tap halfway across the slider track. tester.drag is the closest we
      // can get without geometry — assert just that *something* is forwarded.
      await tester.tap(find.byType(Slider));
      await tester.pump();
      expect(captured, isNotNull);
    });
  });
}
