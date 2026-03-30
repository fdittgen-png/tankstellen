import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/widgets/star_rating.dart';

void main() {
  group('StarRating', () {
    testWidgets('renders 5 star icons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StarRating(
              rating: 0,
              onRatingChanged: (_) {},
            ),
          ),
        ),
      );

      // Count all star icons (filled + border)
      final starFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Icon &&
            (widget.icon == Icons.star || widget.icon == Icons.star_border),
      );
      expect(starFinder, findsNWidgets(5));
    });

    testWidgets('rating=3 shows 3 filled and 2 border stars', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StarRating(
              rating: 3,
              onRatingChanged: (_) {},
            ),
          ),
        ),
      );

      final filledStars = find.byIcon(Icons.star);
      final borderStars = find.byIcon(Icons.star_border);

      expect(filledStars, findsNWidgets(3));
      expect(borderStars, findsNWidgets(2));
    });

    testWidgets('rating=null shows all 5 border stars', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StarRating(
              rating: null,
              onRatingChanged: (_) {},
            ),
          ),
        ),
      );

      final filledStars = find.byIcon(Icons.star);
      final borderStars = find.byIcon(Icons.star_border);

      expect(filledStars, findsNothing);
      expect(borderStars, findsNWidgets(5));
    });

    testWidgets('rating=5 shows all 5 filled stars', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StarRating(
              rating: 5,
              onRatingChanged: (_) {},
            ),
          ),
        ),
      );

      final filledStars = find.byIcon(Icons.star);
      final borderStars = find.byIcon(Icons.star_border);

      expect(filledStars, findsNWidgets(5));
      expect(borderStars, findsNothing);
    });

    testWidgets('tapping star 4 calls onRatingChanged with 4', (tester) async {
      int? tappedRating;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StarRating(
              rating: null,
              onRatingChanged: (rating) {
                tappedRating = rating;
              },
            ),
          ),
        ),
      );

      // Stars are 1-indexed; find all star icons and tap the 4th one
      final starFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Icon &&
            (widget.icon == Icons.star || widget.icon == Icons.star_border),
      );
      expect(starFinder, findsNWidgets(5));

      // Tap the 4th star (index 3)
      await tester.tap(starFinder.at(3));
      await tester.pump();

      expect(tappedRating, 4);
    });

    testWidgets('tapping star 1 calls onRatingChanged with 1', (tester) async {
      int? tappedRating;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StarRating(
              rating: 3,
              onRatingChanged: (rating) {
                tappedRating = rating;
              },
            ),
          ),
        ),
      );

      final starFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Icon &&
            (widget.icon == Icons.star || widget.icon == Icons.star_border),
      );

      // Tap the 1st star (index 0)
      await tester.tap(starFinder.at(0));
      await tester.pump();

      expect(tappedRating, 1);
    });
  });
}
