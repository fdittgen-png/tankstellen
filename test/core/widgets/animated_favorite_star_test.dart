import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/widgets/animated_favorite_star.dart';

void main() {
  group('AnimatedFavoriteStar', () {
    testWidgets('renders star_border when isFavorite=false',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: AnimatedFavoriteStar(isFavorite: false)),
      ));

      expect(find.byIcon(Icons.star_border), findsOneWidget);
      expect(find.byIcon(Icons.star), findsNothing);
    });

    testWidgets('renders filled star with amber color when isFavorite=true',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: AnimatedFavoriteStar(isFavorite: true)),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.star), findsOneWidget);
      final icon = tester.widget<Icon>(find.byIcon(Icons.star));
      expect(icon.color, Colors.amber);
    });

    testWidgets('bounces through scale > 1.0 when isFavorite flips',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: AnimatedFavoriteStar(isFavorite: false)),
      ));
      await tester.pumpAndSettle();

      // Flip the flag — drives the 300 ms bounce.
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: AnimatedFavoriteStar(isFavorite: true)),
      ));
      // Advance to roughly the peak of the bounce sequence (1.0 → 1.3
      // at mid-curve, so ~150 ms lands near the 1.3 apex).
      await tester.pump(const Duration(milliseconds: 150));

      // AnimatedSwitcher may keep both old/new children around briefly,
      // each with its own ScaleTransition; pick the outer one that
      // descends from our AnimatedFavoriteStar host.
      final scaleTransitions = tester
          .widgetList<ScaleTransition>(find.descendant(
            of: find.byType(AnimatedFavoriteStar),
            matching: find.byType(ScaleTransition),
          ))
          .toList();
      expect(scaleTransitions, isNotEmpty);
      final maxScale = scaleTransitions
          .map((t) => t.scale.value)
          .reduce((a, b) => a > b ? a : b);
      expect(maxScale, greaterThan(1.0),
          reason: 'Mid-bounce scale should exceed 1.0 so the user sees '
              'the star pop.');
      expect(maxScale, lessThanOrEqualTo(1.3),
          reason: 'Peak scale per #595 spec is 1.3.');

      // Settle so pending timers don't leak into the next test.
      await tester.pumpAndSettle();
    });

    testWidgets(
        'hosted in an IconButton keeps the 48dp tap target (#566 a11y)',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: IconButton(
              icon: const AnimatedFavoriteStar(isFavorite: false),
              tooltip: 'Fav',
              onPressed: () {},
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await expectLater(
        tester,
        meetsGuideline(androidTapTargetGuideline),
      );
    });

    testWidgets('does not bounce on identical rebuilds', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: AnimatedFavoriteStar(isFavorite: true)),
      ));
      await tester.pumpAndSettle();

      // Re-pump with the same flag — should not kick the controller
      // again (no running animations after one frame).
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: AnimatedFavoriteStar(isFavorite: true)),
      ));
      await tester.pump();

      expect(tester.hasRunningAnimations, isFalse);
    });
  });
}
