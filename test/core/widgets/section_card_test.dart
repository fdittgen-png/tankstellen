// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/theme/spacing.dart';
import 'package:tankstellen/core/widgets/section_card.dart';
import 'package:tankstellen/core/widgets/section_header.dart';

void main() {
  group('SectionCard', () {
    Future<void> pump(WidgetTester tester, Widget child) {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: child),
        ),
      );
    }

    testWidgets('wraps the child in a Card honouring the theme elevation',
        (tester) async {
      // #2488 — SectionCard no longer hard-pins elevation 0; it reads
      // `theme.cardTheme.elevation` (light = 0, eco/dark = 1). With no
      // explicit cardTheme on this bare MaterialApp the elevation resolves
      // to 0, so the tint-only base contract still holds.
      await pump(
        tester,
        const SectionCard(child: Text('Body content')),
      );
      expect(find.text('Body content'), findsOneWidget);
      final card = tester.widget<Card>(find.byType(Card));
      expect(card.elevation, 0);
    });

    testWidgets('eco/dark card elevation flows through from the theme',
        (tester) async {
      // #2488 — when the ambient theme sets a 1 dp card elevation (as eco
      // and dark do) SectionCard honours it rather than forcing 0.
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(cardTheme: const CardThemeData(elevation: 1)),
          home: const Scaffold(body: SectionCard(child: Text('Body'))),
        ),
      );
      final card = tester.widget<Card>(find.byType(Card));
      expect(card.elevation, 1);
    });

    testWidgets('draws a hairline surfaceContainerHighest outline (#2488)',
        (tester) async {
      // The outline guarantees a card↔scaffold delta on every theme —
      // most importantly on dark, where a 1 dp shadow is too faint to read.
      late ColorScheme scheme;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              scheme = Theme.of(context).colorScheme;
              return const Scaffold(body: SectionCard(child: Text('Body')));
            },
          ),
        ),
      );
      final card = tester.widget<Card>(find.byType(Card));
      final shape = card.shape as RoundedRectangleBorder;
      expect(shape.side.color, scheme.surfaceContainerHighest);
      expect(shape.side.width, greaterThan(0));
    });

    testWidgets('uses surfaceContainerLow as background', (tester) async {
      late ThemeData capturedTheme;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              capturedTheme = Theme.of(context);
              return const Scaffold(
                body: SectionCard(child: Text('Body')),
              );
            },
          ),
        ),
      );
      final card = tester.widget<Card>(find.byType(Card));
      expect(card.color, capturedTheme.colorScheme.surfaceContainerLow);
    });

    testWidgets('applies Spacing.cardPadding by default', (tester) async {
      await pump(
        tester,
        const SectionCard(child: Text('Body')),
      );
      final paddings = tester
          .widgetList<Padding>(
            find.descendant(
              of: find.byType(Card),
              matching: find.byType(Padding),
            ),
          )
          .toList();
      expect(
        paddings.any((p) => p.padding == Spacing.cardPadding),
        isTrue,
        reason: 'Expected one Padding descendant to use Spacing.cardPadding, '
            'got ${paddings.map((p) => p.padding).toList()}',
      );
    });

    testWidgets('uses zero margin by default', (tester) async {
      await pump(
        tester,
        const SectionCard(child: Text('Body')),
      );
      final card = tester.widget<Card>(find.byType(Card));
      expect(card.margin, EdgeInsets.zero);
    });

    testWidgets('renders an internal SectionHeader when title is set',
        (tester) async {
      await pump(
        tester,
        const SectionCard(
          title: 'Section title',
          subtitle: 'Section subtitle',
          leadingIcon: Icons.info_outline,
          child: Text('Body'),
        ),
      );
      expect(find.byType(SectionHeader), findsOneWidget);
      expect(find.text('Section title'), findsOneWidget);
      expect(find.text('Section subtitle'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
      expect(find.text('Body'), findsOneWidget);
    });

    testWidgets('omits the header when title is null', (tester) async {
      await pump(
        tester,
        const SectionCard(child: Text('Body')),
      );
      expect(find.byType(SectionHeader), findsNothing);
      expect(find.text('Body'), findsOneWidget);
    });

    testWidgets('respects custom padding and margin', (tester) async {
      const customPadding = EdgeInsets.all(4);
      const customMargin = EdgeInsets.symmetric(vertical: 8);
      await pump(
        tester,
        const SectionCard(
          padding: customPadding,
          margin: customMargin,
          child: Text('Body'),
        ),
      );
      final card = tester.widget<Card>(find.byType(Card));
      expect(card.margin, customMargin);
      final paddings = tester
          .widgetList<Padding>(
            find.descendant(
              of: find.byType(Card),
              matching: find.byType(Padding),
            ),
          )
          .toList();
      expect(
        paddings.any((p) => p.padding == customPadding),
        isTrue,
        reason: 'Expected one Padding descendant to use $customPadding, '
            'got ${paddings.map((p) => p.padding).toList()}',
      );
    });
  });
}
