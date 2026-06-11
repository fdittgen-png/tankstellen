// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/widgets/star_rating.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

void main() {
  group('StarRating', () {
    testWidgets('renders 5 star icons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: StarRating(rating: 0, onRatingChanged: (_) {})),
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
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: StarRating(rating: 3, onRatingChanged: (_) {})),
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
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: StarRating(rating: null, onRatingChanged: (_) {}),
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
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: StarRating(rating: 5, onRatingChanged: (_) {})),
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
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
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
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
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

  // #1687 — each star is an icon-only tappable affordance; before this
  // fix the tap target was the bare ~28-32 dp icon glyph and a screen
  // reader announced nothing.
  group('StarRating accessibility (#1687)', () {
    Widget harness() => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: StarRating(rating: 2, onRatingChanged: (_) {})),
    );

    testWidgets('each star has at least a 48dp tap target', (tester) async {
      await tester.pumpWidget(harness());

      final boxes = tester
          .widgetList<SizedBox>(
            find.descendant(
              of: find.byType(StarRating),
              matching: find.byType(SizedBox),
            ),
          )
          .where((b) => (b.width ?? 0) >= 48 && (b.height ?? 0) >= 48)
          .toList();
      expect(boxes.length, 5);
    });

    testWidgets('star tap targets meet the Android tap-target guideline', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(harness());

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('each star exposes a button semantics label', (tester) async {
      await tester.pumpWidget(harness());

      // en ARB plural: 'Rate 1 star' / 'Rate {n} stars' (#3162).
      for (var n = 1; n <= 5; n++) {
        final expected = n == 1 ? 'Rate 1 star' : 'Rate $n stars';
        final semantics = tester.widgetList<Semantics>(find.byType(Semantics));
        final star = semantics.where((s) => s.properties.label == expected);
        expect(star.length, 1, reason: 'star $n missing its semantics label');
        expect(star.first.properties.button, isTrue);
      }
    });
  });
}
