// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/app/theme.dart';
import 'package:tankstellen/core/theme/app_radius.dart';
import 'package:tankstellen/core/theme/spacing.dart';
import 'package:tankstellen/core/widgets/station_card_shell.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('StationCardShell (#2493)', () {
    testWidgets('owns the canonical card frame: margin, radius, clip', (
      tester,
    ) async {
      await pumpApp(tester, const StationCardShell(child: Text('body')));

      final card = tester.widget<Card>(find.byType(Card));
      // #3948 — the grammar's surface margin (12 / 8).
      expect(card.margin, Spacing.surfaceMargin);
      expect(card.clipBehavior, Clip.antiAlias);
      final shape = card.shape as RoundedRectangleBorder;
      expect(shape.borderRadius, AppRadius.lg);
      expect(find.text('body'), findsOneWidget);
    });

    for (final (name, theme) in [
      ('light', AppTheme.light()),
      ('dark', AppTheme.dark()),
      ('eco', AppTheme.eco()),
    ]) {
      testWidgets(
          'carries primary-card semantics under $name: surfaceContainerLow, '
          '1 dp outlineVariant edge, no elevation (#3948)', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: const Scaffold(body: StationCardShell(child: Text('x'))),
          ),
        );
        await tester.pumpAndSettle();
        final card = tester.widget<Card>(find.byType(Card));
        expect(card.elevation, 0);
        expect(card.color, theme.colorScheme.surfaceContainerLow);
        final shape = card.shape as RoundedRectangleBorder;
        expect(shape.side.color, theme.colorScheme.outlineVariant);
        expect(shape.side.width, 1);
      });
    }

    testWidgets('draws a left stripe in the requested colour and width', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const StationCardShell(
          stripeColor: Color(0xFF123456),
          stripeWidth: 6,
          child: Text('body'),
        ),
      );

      final box = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(StationCardShell),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      final border = (box.decoration as BoxDecoration).border! as Border;
      expect(border.left.color, const Color(0xFF123456));
      expect(border.left.width, 6);
    });

    testWidgets('draws NO stripe when stripeColor is null', (tester) async {
      await pumpApp(tester, const StationCardShell(child: Text('body')));
      // The shell itself adds no bordered DecoratedBox when stripeColor is
      // null (any DecoratedBox present would come from the Card/Material).
      final bordered = tester
          .widgetList<DecoratedBox>(
            find.descendant(
              of: find.byType(InkWell),
              matching: find.byType(DecoratedBox),
            ),
          )
          .where((b) {
            final d = b.decoration;
            return d is BoxDecoration && d.border is Border;
          });
      expect(bordered, isEmpty);
    });

    testWidgets('forwards taps through the InkWell', (tester) async {
      var taps = 0;
      await pumpApp(
        tester,
        StationCardShell(onTap: () => taps++, child: const Text('body')),
      );
      await tester.tap(find.text('body'));
      expect(taps, 1);
    });
  });
}
