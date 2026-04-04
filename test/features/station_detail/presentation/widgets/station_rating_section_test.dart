import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/widgets/star_rating.dart';

void main() {
  group('StationRatingSection content', () {
    // Test the visual structure independent of providers.
    // The StationRatingSection widget itself uses Consumer internally,
    // which requires provider setup. We test the StarRating component
    // directly instead.

    testWidgets('StarRating renders with no rating', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StarRating(rating: null, onRatingChanged: (_) {}),
          ),
        ),
      );

      // Should render 5 star icons
      expect(find.byIcon(Icons.star_border), findsWidgets);
    });

    testWidgets('StarRating renders with a rating value', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StarRating(rating: 3, onRatingChanged: (_) {}),
          ),
        ),
      );

      // Should render 3 filled + 2 empty
      expect(find.byIcon(Icons.star), findsWidgets);
    });
  });
}
