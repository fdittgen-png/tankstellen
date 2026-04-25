import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/achievements/domain/achievement.dart';
import 'package:tankstellen/features/achievements/presentation/widgets/badge_shelf.dart';
import 'package:tankstellen/features/achievements/providers/achievements_provider.dart';

import '../../../../helpers/pump_app.dart';

/// Widget tests for [BadgeShelf] (#561 — was zero coverage).
///
/// The shelf reads `achievementsProvider` and renders either a
/// `SizedBox.shrink` (no earned badges) or a Card with a header and a
/// horizontal row of six `_BadgeTile`s — one per `AchievementId`.
/// Earned tiles use `primaryContainer` for the background; unearned
/// tiles use `surfaceContainerHighest`.
void main() {
  EarnedAchievement earn(AchievementId id) => EarnedAchievement(
        id: id,
        earnedAt: DateTime(2025, 1, 1),
      );

  group('BadgeShelf — empty state', () {
    testWidgets(
      'renders SizedBox.shrink with zero size when no badges earned',
      (tester) async {
        await pumpApp(
          tester,
          const BadgeShelf(),
          overrides: [
            achievementsProvider.overrideWithValue(
              const <EarnedAchievement>[],
            ),
          ],
        );

        // Card is the visible container — must not be present.
        expect(find.byType(Card), findsNothing);

        // The widget itself still exists, but as a zero-height shell.
        final shelfFinder = find.byType(BadgeShelf);
        expect(shelfFinder, findsOneWidget);
        final size = tester.getSize(shelfFinder);
        expect(size.height, 0.0);
      },
    );
  });

  group('BadgeShelf — non-empty state', () {
    testWidgets(
      'renders Card + 6 tiles + count "1/6" when one badge earned',
      (tester) async {
        await pumpApp(
          tester,
          const BadgeShelf(),
          overrides: [
            achievementsProvider.overrideWithValue([
              earn(AchievementId.firstTrip),
            ]),
          ],
        );

        expect(find.byType(Card), findsOneWidget);
        // Title + count.
        expect(find.text('Achievements'), findsOneWidget);
        expect(find.text('1/6'), findsOneWidget);
        // All six labels are rendered (one per AchievementId).
        expect(find.text('First trip'), findsOneWidget);
        expect(find.text('First fill-up'), findsOneWidget);
        expect(find.text('10 trips'), findsOneWidget);
        expect(find.text('Smooth driver'), findsOneWidget);
        expect(find.text('Eco week'), findsOneWidget);
        expect(find.text('Price win'), findsOneWidget);
      },
    );

    testWidgets('count text reads "3/6" when three badges earned',
        (tester) async {
      await pumpApp(
        tester,
        const BadgeShelf(),
        overrides: [
          achievementsProvider.overrideWithValue([
            earn(AchievementId.firstTrip),
            earn(AchievementId.firstFillUp),
            earn(AchievementId.tenTrips),
          ]),
        ],
      );

      expect(find.text('3/6'), findsOneWidget);
    });

    testWidgets('count text reads "6/6" when all badges earned',
        (tester) async {
      await pumpApp(
        tester,
        const BadgeShelf(),
        overrides: [
          achievementsProvider.overrideWithValue([
            for (final id in AchievementId.values) earn(id),
          ]),
        ],
      );

      expect(find.text('6/6'), findsOneWidget);
    });
  });

  group('BadgeShelf — tile visuals', () {
    /// Walks up the parent chain from a label `Text` widget to find the
    /// outer tile `Container` (the one with a `BoxDecoration`).
    BoxDecoration tileDecorationFor(WidgetTester tester, String label) {
      final textElement = tester.element(find.text(label));
      BoxDecoration? found;
      textElement.visitAncestorElements((ancestor) {
        final widget = ancestor.widget;
        if (widget is Container && widget.decoration is BoxDecoration) {
          found = widget.decoration as BoxDecoration;
          return false; // stop at the first decorated Container.
        }
        return true;
      });
      expect(
        found,
        isNotNull,
        reason: 'No decorated Container ancestor found for "$label"',
      );
      return found!;
    }

    testWidgets(
      'earned tile uses primaryContainer background',
      (tester) async {
        await pumpApp(
          tester,
          const BadgeShelf(),
          overrides: [
            achievementsProvider.overrideWithValue([
              earn(AchievementId.firstTrip),
            ]),
          ],
        );

        final context = tester.element(find.byType(BadgeShelf));
        final scheme = Theme.of(context).colorScheme;
        final decoration = tileDecorationFor(tester, 'First trip');
        expect(decoration.color, scheme.primaryContainer);
      },
    );

    testWidgets(
      'unearned tile uses surfaceContainerHighest background',
      (tester) async {
        await pumpApp(
          tester,
          const BadgeShelf(),
          overrides: [
            // Earn one badge so the shelf renders, but leave priceWin
            // unearned so we can inspect its background.
            achievementsProvider.overrideWithValue([
              earn(AchievementId.firstTrip),
            ]),
          ],
        );

        final context = tester.element(find.byType(BadgeShelf));
        final scheme = Theme.of(context).colorScheme;
        final decoration = tileDecorationFor(tester, 'Price win');
        expect(decoration.color, scheme.surfaceContainerHighest);
      },
    );
  });

  group('BadgeShelf — accessibility', () {
    testWidgets('renders a Tooltip for every tile', (tester) async {
      await pumpApp(
        tester,
        const BadgeShelf(),
        overrides: [
          achievementsProvider.overrideWithValue([
            earn(AchievementId.firstTrip),
          ]),
        ],
      );

      // One Tooltip per `_BadgeTile` — six in total.
      expect(find.byType(Tooltip), findsNWidgets(6));

      // Sample one description string to confirm tooltip messages are
      // wired through the l10n fallback.
      final priceWinTooltip = find.byWidgetPredicate(
        (w) =>
            w is Tooltip &&
            (w.message ?? '').contains('30-day average'),
      );
      expect(priceWinTooltip, findsOneWidget);
    });
  });
}
