import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/widgets/staggered_fade_in.dart';

void main() {
  group('StaggeredFadeIn (#1773 — shared timeline)', () {
    testWidgets('renders a FadeTransition, not a per-row AnimatedOpacity',
        (tester) async {
      final controller = AnimationController(
        vsync: const TestVSync(),
        duration: StaggeredFadeIn.timelineDuration,
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: StaggeredFadeIn(
            controller: controller,
            index: 0,
            child: const Text('card'),
          ),
        ),
      ));

      // Scope to the StaggeredFadeIn subtree — MaterialApp's own route
      // transitions also use FadeTransition.
      expect(
        find.descendant(
          of: find.byType(StaggeredFadeIn),
          matching: find.byType(FadeTransition),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(StaggeredFadeIn),
          matching: find.byType(AnimatedOpacity),
        ),
        findsNothing,
      );
    });

    testWidgets('the index-0 row leads the timeline; a clamped row trails it',
        (tester) async {
      final controller = AnimationController(
        vsync: const TestVSync(),
        duration: StaggeredFadeIn.timelineDuration,
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              StaggeredFadeIn(
                controller: controller,
                index: 0,
                child: const Text('lead'),
              ),
              // index >> maxStaggered → clamped to the cap delay.
              StaggeredFadeIn(
                controller: controller,
                index: 1000,
                child: const Text('trail'),
              ),
            ],
          ),
        ),
      ));

      double opacityOf(String text) => tester
          .widget<FadeTransition>(
            find.descendant(
              of: find.ancestor(
                of: find.text(text),
                matching: find.byType(StaggeredFadeIn),
              ),
              matching: find.byType(FadeTransition),
            ),
          )
          .opacity
          .value;

      // Timeline at 0 → nothing has faded in yet.
      expect(opacityOf('lead'), 0.0);
      expect(opacityOf('trail'), 0.0);

      // Just past the index-0 interval (~0.31 of the timeline) the lead
      // row is fully in, while the clamped row has not started.
      controller.value = 0.35;
      await tester.pump();
      expect(opacityOf('lead'), 1.0,
          reason: 'index 0 finishes its fade in the first slice');
      expect(opacityOf('trail'), 0.0,
          reason: 'a clamped row only starts near the end of the timeline');

      // Timeline complete → every row fully visible.
      controller.value = 1.0;
      await tester.pump();
      expect(opacityOf('lead'), 1.0);
      expect(opacityOf('trail'), 1.0);
    });

    test('timelineDuration is the last start offset plus one fade', () {
      // maxStaggered (10) * stepMs (50) + fadeMs (220) = 720 ms.
      expect(
        StaggeredFadeIn.timelineDuration,
        const Duration(milliseconds: 720),
      );
    });
  });
}
