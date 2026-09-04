// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/app/theme.dart';
import 'package:tankstellen/core/theme/app_radius.dart';
import 'package:tankstellen/core/theme/spacing.dart';
import 'package:tankstellen/core/widgets/panel_card.dart';
import 'package:tankstellen/core/widgets/primary_card.dart';

/// #3948 (Epic #3947) — the two surface levels must render as visibly
/// different surfaces in every theme: the primary card is the outlined
/// figure, the panel is the borderless ground, and neither floats.
void main() {
  Future<void> pumpBoth(WidgetTester tester, ThemeData theme) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Scaffold(
          body: Column(
            children: [
              PrimaryCard(key: Key('primary'), child: Text('primary')),
              PanelCard(key: Key('panel'), child: Text('panel')),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Card cardUnder(WidgetTester tester, Key key) => tester.widget<Card>(
        find.descendant(of: find.byKey(key), matching: find.byType(Card)),
      );

  for (final (name, theme) in [
    ('light', AppTheme.light()),
    ('dark', AppTheme.dark()),
    ('eco', AppTheme.eco()),
  ]) {
    group('PrimaryCard vs PanelCard under AppTheme.$name', () {
      testWidgets('render distinct fills: surfaceContainerLow vs '
          'surfaceContainerHighest', (tester) async {
        await pumpBoth(tester, theme);
        final cs = theme.colorScheme;
        final primary = cardUnder(tester, const Key('primary'));
        final panel = cardUnder(tester, const Key('panel'));
        expect(primary.color, cs.surfaceContainerLow);
        expect(panel.color, cs.surfaceContainerHighest);
        expect(primary.color, isNot(panel.color));
      });

      testWidgets('primary is outlined 1 dp outlineVariant, panel has no edge',
          (tester) async {
        await pumpBoth(tester, theme);
        final cs = theme.colorScheme;
        final primaryShape = cardUnder(tester, const Key('primary')).shape
            as RoundedRectangleBorder;
        final panelShape =
            cardUnder(tester, const Key('panel')).shape as RoundedRectangleBorder;
        expect(primaryShape.side.color, cs.outlineVariant);
        expect(primaryShape.side.width, 1);
        expect(panelShape.side, BorderSide.none);
        expect(primaryShape.borderRadius, AppRadius.lg);
        expect(panelShape.borderRadius, AppRadius.lg);
      });

      testWidgets('neither level floats: elevation 0 and no surface tint', (
        tester,
      ) async {
        await pumpBoth(tester, theme);
        for (final key in const [Key('primary'), Key('panel')]) {
          final card = cardUnder(tester, key);
          expect(card.elevation, 0);
          expect(card.surfaceTintColor, Colors.transparent);
          expect(card.clipBehavior, Clip.antiAlias);
        }
      });
    });
  }

  testWidgets('both levels share the grammar margin and padding', (
    tester,
  ) async {
    await pumpBoth(tester, AppTheme.light());
    for (final key in const [Key('primary'), Key('panel')]) {
      expect(cardUnder(tester, key).margin, Spacing.surfaceMargin);
      // `.last`: the Card's own margin is also a Padding (Container.margin),
      // and it sits ABOVE the body padding in the tree.
      final padding = tester.widget<Padding>(
        find
            .descendant(of: find.byKey(key), matching: find.byType(Padding))
            .last,
      );
      expect(padding.padding, Spacing.cardPadding);
    }
  });

  testWidgets('onTap wraps the body in an InkWell with the card radius', (
    tester,
  ) async {
    var primaryTaps = 0;
    var panelTaps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              PrimaryCard(
                onTap: () => primaryTaps++,
                child: const Text('primary'),
              ),
              PanelCard(onTap: () => panelTaps++, child: const Text('panel')),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.text('primary'));
    await tester.tap(find.text('panel'));
    expect(primaryTaps, 1);
    expect(panelTaps, 1);
    for (final ink in tester.widgetList<InkWell>(find.byType(InkWell))) {
      expect(ink.borderRadius, AppRadius.lg);
    }
  });

  testWidgets('without onTap there is no InkWell', (tester) async {
    await pumpBoth(tester, AppTheme.light());
    expect(find.byType(InkWell), findsNothing);
  });

  testWidgets('padding and margin are overridable for full-bleed bodies', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PrimaryCard(
            padding: EdgeInsets.zero,
            margin: EdgeInsets.zero,
            child: Text('x'),
          ),
        ),
      ),
    );
    final card = tester.widget<Card>(find.byType(Card));
    expect(card.margin, EdgeInsets.zero);
    final padding = tester.widget<Padding>(
      find.descendant(of: find.byType(Card), matching: find.byType(Padding)).last,
    );
    expect(padding.padding, EdgeInsets.zero);
  });
}
