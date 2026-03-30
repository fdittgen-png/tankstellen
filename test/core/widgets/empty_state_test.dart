import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/widgets/empty_state.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('EmptyState', () {
    testWidgets('renders icon and title', (tester) async {
      await pumpApp(
        tester,
        const EmptyState(
          icon: Icons.star_outline,
          title: 'No favorites yet',
        ),
      );

      expect(find.byIcon(Icons.star_outline), findsOneWidget);
      expect(find.text('No favorites yet'), findsOneWidget);
    });

    testWidgets('renders subtitle when provided', (tester) async {
      await pumpApp(
        tester,
        const EmptyState(
          icon: Icons.star_outline,
          title: 'Title',
          subtitle: 'A helpful subtitle',
        ),
      );

      expect(find.text('A helpful subtitle'), findsOneWidget);
    });

    testWidgets('does not render subtitle when null', (tester) async {
      await pumpApp(
        tester,
        const EmptyState(
          icon: Icons.star_outline,
          title: 'Title',
        ),
      );

      // Only icon, title — no subtitle text
      expect(find.byType(Text), findsOneWidget);
    });

    testWidgets('renders action button when label and callback provided', (tester) async {
      var tapped = false;
      await pumpApp(
        tester,
        EmptyState(
          icon: Icons.search,
          title: 'No results',
          actionLabel: 'Search now',
          onAction: () => tapped = true,
        ),
      );

      expect(find.text('Search now'), findsOneWidget);
      await tester.tap(find.text('Search now'));
      expect(tapped, true);
    });

    testWidgets('does not render button when action is null', (tester) async {
      await pumpApp(
        tester,
        const EmptyState(
          icon: Icons.search,
          title: 'No results',
        ),
      );

      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('uses custom icon size', (tester) async {
      await pumpApp(
        tester,
        const EmptyState(
          icon: Icons.map,
          title: 'Test',
          iconSize: 80,
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.map));
      expect(icon.size, 80);
    });
  });
}
