import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/widgets/staggered_fade_in.dart';

void main() {
  group('StaggeredFadeIn', () {
    testWidgets('first card (index 0) fades in immediately', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: StaggeredFadeIn(
            index: 0,
            child: Text('card-0'),
          ),
        ),
      ));

      // First frame: opacity target is 0, widget is invisible.
      final first = tester
          .widget<AnimatedOpacity>(find.byType(AnimatedOpacity))
          .opacity;
      expect(first, 0.0);

      // Microtask elapses → opacity target flips to 1.0, AnimatedOpacity
      // starts lerping immediately (no Timer delay for index 0).
      await tester.pump();
      final target = tester
          .widget<AnimatedOpacity>(find.byType(AnimatedOpacity))
          .opacity;
      expect(target, 1.0);
    });

    testWidgets('cards beyond maxStaggered clamp to the cap delay',
        (tester) async {
      // index = 1000, step = 50 ms, cap = 10 → effective delay = 500 ms.
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: StaggeredFadeIn(
            index: 1000,
            child: Text('card-clamped'),
          ),
        ),
      ));

      // At 499 ms the Timer has not fired yet → target still 0.
      await tester.pump(const Duration(milliseconds: 499));
      expect(
        tester
            .widget<AnimatedOpacity>(find.byType(AnimatedOpacity))
            .opacity,
        0.0,
      );

      // At 501 ms the Timer has fired → target now 1.0.
      await tester.pump(const Duration(milliseconds: 2));
      expect(
        tester
            .widget<AnimatedOpacity>(find.byType(AnimatedOpacity))
            .opacity,
        1.0,
      );

      await tester.pumpAndSettle();
    });

    testWidgets('staggers index=3 to kick in around 150 ms', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: StaggeredFadeIn(
            index: 3,
            child: Text('card-3'),
          ),
        ),
      ));

      // At 100 ms the Timer (150 ms) has not fired.
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        tester
            .widget<AnimatedOpacity>(find.byType(AnimatedOpacity))
            .opacity,
        0.0,
      );

      // At 160 ms the Timer has fired.
      await tester.pump(const Duration(milliseconds: 60));
      expect(
        tester
            .widget<AnimatedOpacity>(find.byType(AnimatedOpacity))
            .opacity,
        1.0,
      );

      await tester.pumpAndSettle();
    });
  });
}
